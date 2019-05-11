param (
    [string] $SolrHostName,
    [string] $SolrInstallPath,
    [string] $CertExportSecret,
    [string] $CertExportPath
)

$CertStore = "Cert:\LocalMachine\My"

$CertName = "$($SolrHostName).pfx"
$certFile = Join-Path -Path $CertExportPath -ChildPath $CertName
$cert = Get-ChildItem -Path $CertStore | Where-Object { $_.Subject -eq "CN=$($SolrHostName)"}
$pwd = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText

if ($null -eq $cert) {
    if (Test-Path -Path $certFile) {
        Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\My' -Password $pwd
        Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $pwd
    } else {
        $cert = New-SelfSignedCertificate `
                -CertStoreLocation $CertStore -DnsName $SolrHostName `
                -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'

        Export-PfxCertificate -cert $cert -FilePath $certFile -Password $pwd
        Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $pwd; 
    }
} else {
    If (-not (Test-Path -Path $certFile)) {
        Export-PfxCertificate -cert $cert -FilePath $certFile -Password $pwd
    }
}


$BackupCert = Join-Path -Path "$($SolrInstallPath)\server\etc" -ChildPath $CertName
If (-not (Test-Path -Path $BackupCert)) {
    Copy-Item -Path $certFile -Destination $BackupCert
}


If (-not (Test-Path -Path "$($SolrInstallPath)\bin\solr.in.cmd.old")) {

    $cfg = Get-Content "$($SolrInstallPath)\bin\solr.in.cmd"; 
    
    Rename-Item "$($SolrInstallPath)\bin\solr.in.cmd" "$($SolrInstallPath)\bin\solr.in.cmd.old"; 
    
    $newCfg = $cfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$($BackupCert)" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM SOLR_SSL_KEY_STORE_TYPE=JKS", "SOLR_SSL_KEY_STORE_TYPE=PKCS12" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM SOLR_SSL_TRUST_STORE_TYPE=JKS", "SOLR_SSL_TRUST_STORE_TYPE=PKCS12" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", ('set SOLR_SSL_KEY_STORE_PASSWORD={0}' -f $CertExportSecret) }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$($BackupCert)" }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", ('set SOLR_SSL_TRUST_STORE_PASSWORD={0}' -f $CertExportSecret) }; 
    $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_HOST=192.168.1.1", ('set SOLR_HOST={0}' -f $SolrHostName) }; 
    $newCfg | Set-Content "$($SolrInstallPath)\bin\solr.in.cmd"
}