param (
    [string] $SitecoreIdentityServerHostName,
    [string] $CertExportPath,
    [string] $CertExportSecret
)

$CertStore = "Cert:\LocalMachine\My"

$CertName = "$($SitecoreIdentityServerHostName).pfx"
$certFile = Join-Path -Path $CertExportPath -ChildPath $CertName
$cert = Get-ChildItem -Path $CertStore | Where-Object { $_.subject -eq "CN=$($SitecoreIdentityServerHostName)"}
$secret = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText

if ($null -eq $cert) {

    if (Test-Path -Path $certFile) {
        Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\My' -Password $secret;
    } else {
        $cert = New-SelfSignedCertificate `
                -CertStoreLocation $CertStore -DnsName $SitecoreIdentityServerHostName `
                -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'
        
        Export-PfxCertificate -cert $cert -FilePath $certFile -Password $secret
    }

} else {
    If (-not (Test-Path -Path $certFile)) {
        Export-PfxCertificate -cert $cert -FilePath $certFile -Password $secret
    }
}