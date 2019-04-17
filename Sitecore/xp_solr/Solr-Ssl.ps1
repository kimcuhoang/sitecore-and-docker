param (
    [string] $SOLR_HOST_NAME,
    [string] $CERT_PATH,
    [string] $CERT_EXPORT_PASSWORD,
    [string] $SOLR_PATH
)

# https://blogs.perficientdigital.com/2018/08/20/using-the-pkcs12-pfx-format-for-solr-ssl-security/

$certName = ('{0}.pfx' -f $SOLR_HOST_NAME);
$certPath = Join-Path -Path $CERT_PATH -ChildPath $certName; 

$pwd = ConvertTo-SecureString -String $CERT_EXPORT_PASSWORD -Force -AsPlainText; 
Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd; 

$newCertPath = ('C:\solr\server\etc\{0}' -f $certName); 
Copy-Item -Path $certPath -Destination $newCertPath; 

$cfg = Get-Content 'C:\solr\bin\solr.in.cmd'; 
Rename-Item "$($SOLR_PATH)\bin\solr.in.cmd" "$($SOLR_PATH)\bin\solr.in.cmd.old"; 
$newCfg = $cfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$($newCertPath)" }; 
$newCfg = $newCfg | ForEach-Object { $_ -replace "REM SOLR_SSL_KEY_STORE_TYPE=JKS", "SOLR_SSL_KEY_STORE_TYPE=PKCS12" }; 
$newCfg = $newCfg | ForEach-Object { $_ -replace "REM SOLR_SSL_TRUST_STORE_TYPE=JKS", "SOLR_SSL_TRUST_STORE_TYPE=PKCS12" }; 
$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", ('set SOLR_SSL_KEY_STORE_PASSWORD={0}' -f $CERT_EXPORT_PASSWORD) }; 
$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$($newCertPath)" }; 
$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", ('set SOLR_SSL_TRUST_STORE_PASSWORD={0}' -f $CERT_EXPORT_PASSWORD) }; 
$newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_HOST=192.168.1.1", ('set SOLR_HOST={0}' -f $SOLR_HOST_NAME) }; 
$newCfg | Set-Content "$($SOLR_PATH)\bin\solr.in.cmd"