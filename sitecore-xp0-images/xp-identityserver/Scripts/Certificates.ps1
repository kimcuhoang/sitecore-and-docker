param (
    [string] $SitecoreIdentityServerHostName,
    [string] $CertExportPath,
    [string] $CertExportSecret
)

$CertStore = "Cert:\LocalMachine\My"

$CertName = "$($SitecoreIdentityServerHostName).pfx"
$certFile = Join-Path -Path $CertExportPath -ChildPath $CertName
$cert = Get-ChildItem -Path $CertStore | where { $_.subject -eq "CN=$($SitecoreIdentityServerHostName)"}
$pwd = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText

if ($null -eq $cert) {
    $cert = New-SelfSignedCertificate `
                -CertStoreLocation $CertStore -DnsName $SitecoreIdentityServerHostName `
                -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'
}

if (-not (Test-Path -Path $certFile)) {
    Export-PfxCertificate -cert $cert -FilePath $certFile -Password $pwd
}