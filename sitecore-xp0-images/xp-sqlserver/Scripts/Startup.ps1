param (
    [string] $SqlServerHostName,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string] $AssetInstallPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string] $FreshDatabasesPath,
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string] $DatabasesPath,
    [string] $SASecret,
    [string] $AcceptEula = 'Y',
    [string] $DatabasePrefix,
    [string] $DefaultDBPrefix
)

If ($null -eq (Get-ChildItem -Path $DatabasesPath -Filter "*.mdf")) {
    Write-Host "### Sitecore databases not found in '$DatabasesPath', seeding clean databases..."

    Get-ChildItem -Path "$($FreshDatabasesPath)/*" | ForEach-Object {
        $newName = $_.Name.Replace("$($DefaultDBPrefix)", "$($DatabasePrefix)")
        Copy-Item -Path $_.FullName -Destination "$($DatabasesPath)\$($newName)"
    }

    Get-ChildItem -Path $DatabasesPath -Filter "*.mdf" | ForEach-Object {
        $databaseName = $_.BaseName.Replace("_Primary", "")
        $mdfPath = $_.FullName
        $ldfPath = $mdfPath.Replace(".mdf", ".ldf")
        $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '$databaseName') BEGIN EXEC sp_detach_db [$databaseName] END;CREATE DATABASE [$databaseName] ON (FILENAME = N'$mdfPath'), (FILENAME = N'$ldfPath') FOR ATTACH;"
    
        Write-Host "### Attaching '$databaseName'..."
    
        Invoke-Sqlcmd -Query $sqlcmd
    }

    # See http://jonne.github.io/2017/dockerizing-sitecore-9-xp0/ for details...
    Invoke-Sqlcmd -Query ("EXEC sp_MSforeachdb 'IF charindex(''{0}'', ''?'' ) = 1 BEGIN EXEC [?]..sp_changedbowner ''sa'' END'" -f $DatabasePrefix)

    # See http://jonnekats.nl/2017/sql-connection-issue-xconnect/ for details...
    Invoke-Sqlcmd -Query ("UPDATE [{0}_Xdb.Collection.ShardMapManager].[__ShardManagement].[ShardsGlobal] SET ServerName = '{1}'" -f $DatabasePrefix, $SqlServerHostName)
    Invoke-Sqlcmd -Query ("UPDATE [{0}_Xdb.Collection.Shard0].[__ShardManagement].[ShardsLocal] SET ServerName = '{1}'" -f $DatabasePrefix, $SqlServerHostName)
    Invoke-Sqlcmd -Query ("UPDATE [{0}_Xdb.Collection.Shard1].[__ShardManagement].[ShardsLocal] SET ServerName = '{1}'" -f $DatabasePrefix, $SqlServerHostName)
}

Write-Host "### Sitecore databases ready!"
Remove-Item -Path $env:INSTALL_PATH -Recurse -Force

# Call Start.ps1 from the base image https://github.com/Microsoft/mssql-docker/blob/master/windows/mssql-server-windows-developer/dockerfile
& C:\Scripts\Start-SqlServer.ps1 -sa_password $SASecret `
                                 -ACCEPT_EULA $AcceptEula `
                                 -attach_dbs "[]" -Verbose