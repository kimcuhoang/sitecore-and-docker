param (
    [string] $CertName,
    [string] $CertExportPath,
    [string] $CertExportSecret
)
$ErrorActionPreference = 'Stop'

Function Import-Certificate {
    param (
        [string] $HostName
    )
    Write-Host "####### Importing Certificate for $($HostName)"
    $CertPfxFilePath = Join-Path -Path $CertExportPath -ChildPath "$($CertName).pfx"
    if (-not (Test-Path -Path $CertPfxFilePath)) {
        throw "Could not find $($CertName).pfx"
    }

    $CertStores = @("Cert:\LocalMachine\Root", "Cert:\LocalMachine\My")
    $CertSecret = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText;
    $CertStores | ForEach-Object {
        $cert = Get-ChildItem -Path $_ | Where-Object { $_.Subject -eq "CN=$($HostName)"}
        If ($null -eq $cert) {
            Import-PfxCertificate -FilePath $CertPfxFilePath -CertStoreLocation $_ -Password $CertSecret;
        }
    }
    Write-Host "####### Imported Successfully Certificate for $($HostName)"
}

Import-Certificate -HostName $CertName -CertPfxFilePath $CertPfxPath