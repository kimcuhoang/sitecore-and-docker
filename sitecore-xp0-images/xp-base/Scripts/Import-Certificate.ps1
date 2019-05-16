param (
    [string] $SitecoreInstancePrefix,
    [string] $CertExportPath,
    [string] $CertExportSecret
)

$ErrorActionPreference = "STOP"


$CertFile = Join-Path -Path $CertExportPath -ChildPath "$($SitecoreInstancePrefix).pfx"
$secret = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText

If (-not (Test-Path -Path $CertFile)) {
    throw "Could not find the pfx file: $($CertFile)"
}

$CertStoreLocations = @("Cert:\LocalMachine\My", "Cert:\LocalMachine\Root")
$CertStoreLocations | ForEach-Object {
    $cert = Get-ChildItem -Path $_ | Where-Object { $_.Subject -eq "CN=$($SitecoreInstancePrefix)"}

    If ($null -eq $cert) {
        Import-PfxCertificate -FilePath $CertFile -CertStoreLocation $_ -Password $secret
    }
}