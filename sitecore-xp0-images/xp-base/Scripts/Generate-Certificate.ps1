param (
    [string] $SitecoreInstancePrefix,
    [string] $CertExportPath,
    [string] $CertExportSecret
)

$ErrorActionPreference = "STOP"

$CertStoreLocation = "Cert:\LocalMachine\My"
$CertFile = Join-Path -Path $CertExportPath -ChildPath "$($SitecoreInstancePrefix).pfx"
$secret = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText

$cert = Get-ChildItem -Path $_ | Where-Object { $_.Subject -eq "CN=$($SitecoreInstancePrefix)"}

If ($null -eq $cert) {
    $IssueDate = Get-Date
    $ExpireDate = (Get-Date).AddYears(5)

    $HostNames = @("$($SitecoreInstancePrefix)_solr" ,
                "$($SitecoreInstancePrefix)_identityserver.dev.local",
                "$($SitecoreInstancePrefix)_xconnect.dev.local",
                "$($SitecoreInstancePrefix)_xconnect_client.dev.local")

    $cert = New-SelfSignedCertificate -DnsName $HostNames `
                                -CertStoreLocation $CertStoreLocation `
                                -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider' `
                                -NotBefore $IssueDate -NotAfter $ExpireDate `
                                -FriendlyName $SitecoreInstancePrefix `
                                -Subject $SitecoreInstancePrefix
} 

If (-not (Test-Path -Path $CertFile)) {
    Export-PfxCertificate -cert $cert -FilePath $CertFile -Password $secret
}