[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( {Test-Path $_ -PathType 'Container'})] 
    [string] $AssetInstallPath,
    [switch] $IsSitecorePackage
)

If ($IsSitecorePackage) {
    Get-ChildItem -Path $AssetInstallPath -Filter "*.scwdp.zip" | ForEach-Object { 
        Write-Host "Extract module: '$_.FullName'"
        Expand-Archive  $_.FullName -DestinationPath (Join-Path -Path $AssetInstallPath -ChildPath $_.GetHashCode())
    }
} Else {
    Add-Type -Assembly "System.IO.Compression.FileSystem";

    Get-ChildItem -Path $AssetInstallPath -Filter "*.scwdp.zip" | ForEach-Object {
        Write-Host "Extract module: '$_.FullName'"
        $zipPath = $_.FullName
        try
        {
            $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)

            ($zip.Entries | Where-Object { $_.FullName -like "Sitecore.*.dacpac" -and $_.Name -notlike "*.Xdb.Collection*.dacpac" }) | Foreach-Object { 
                [IO.Compression.ZipFileExtensions]::ExtractToFile($_, (Join-Path $AssetInstallPath $_.Name), $true)
            }
        }
        finally
        {
            if ($zip -ne $null)
            {
                $zip.Dispose()
            }
        }
    }
}

