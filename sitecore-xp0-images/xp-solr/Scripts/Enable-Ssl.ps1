param (
    [string] $SitecoreInstancePrefix,
    [string] $SolrHostName,
    [string] $SolrInstallPath,
    [string] $CertExportSecret,
    [string] $CertExportPath
)

$CertName = "$($SitecoreInstancePrefix).pfx"
$CertFile = Join-Path -Path $CertExportPath -ChildPath $CertName

$BackupCert = Join-Path -Path "$($SolrInstallPath)\server\etc" -ChildPath $CertName
If (-not (Test-Path -Path $BackupCert)) {
    Copy-Item -Path $CertFile -Destination $BackupCert
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