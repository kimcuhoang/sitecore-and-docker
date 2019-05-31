[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$AssetInstallPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string]$DatabasesPath,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()] 
    [string]$DatabasePrefix
)

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($env:COMPUTERNAME)
$server.Properties["DefaultFile"].Value = $DatabasesPath
$server.Properties["DefaultLog"].Value = $DatabasesPath
$server.Alter()

$sqlPackageExePath = Get-Item "C:\tools\*\lib\net46\SqlPackage.exe" | Select-Object -Last 1 -Property FullName -ExpandProperty FullName

Get-ChildItem -Path $AssetInstallPath -Filter "*.dacpac" | ForEach-Object {
    $databaseName = $_.BaseName.Replace("Sitecore.", "$DatabasePrefix`_")
    $dacpacPath = Join-Path -Path $AssetInstallPath -ChildPath $_.Name

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q

    # Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false'"
}


## Do modules
$TextInfo = (Get-Culture).TextInfo
Get-ChildItem -Path $AssetInstallPath -Include "core.dacpac", "master.dacpac" -Recurse | ForEach-Object {
    $dacpacPath = $_.FullName
    $databaseName = "$DatabasePrefix`_" + $TextInfo.ToTitleCase($_.BaseName)

    # do
    Write-Host "install module path: $AssetInstallPath dacpac: $dacpacPath dbname: $databaseName"

    # Install
    & $sqlPackageExePath /a:Publish /sf:$dacpacPath /tdn:$databaseName /tsn:$env:COMPUTERNAME /q    
}

# detach DBs
Get-ChildItem -Path $DatabasesPath -Filter "*.mdf" | ForEach-Object {
    $databaseName = $_.BaseName.Replace("_Primary", "")

    Write-Host "### Detach: $databaseName"

    Invoke-Sqlcmd -Query "EXEC MASTER.dbo.sp_detach_db @dbname = N'$databaseName', @keepfulltextindexfile = N'false'"
}