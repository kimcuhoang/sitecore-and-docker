param (
    [string] $xConnectHostName,
    [string] $xConnectClientCertName,
    [int] $xConnectSitePort,
    [string] $SitecoreSolrHostName,
    [string] $SitecoreSolrPort,
    [string] $CertExportPath,
    [string] $CertExportSecret, 
    [string] $SitecoreInstallPath,
    [string] $SqlServerHostName,
    [string] $SqlAdminUser,
    [string] $SqlAdminSecret,
    [string] $SitecoreInstancePrefix
)

$ErrorActionPreference = 'Stop'

& C:/Scripts/Certificates.ps1 -Import `
                              -CertName $SitecoreSolrHostName `
                              -CertExportPath $CertExportPath `
                              -CertExportSecret $CertExportSecret

& C:/Scripts/Certificates.ps1 -CertName $xConnectHostName `
                              -CertExportPath $CertExportPath `
                              -CertExportSecret $CertExportSecret

& C:/Scripts/Certificates.ps1 -CertName $xConnectClientCertName `
                              -CertExportPath $CertExportPath `
                              -CertExportSecret $CertExportSecret


$SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)/solr"
Write-Host "#### Verifying Solr's Connection: $($SolrUrl)"
$SolrRequest = [System.Net.WebRequest]::Create($SolrUrl)
$SolrResponse = $SolrRequest.GetResponse()
$Status = [int] $SolrResponse.StatusCode
If ($Status -ne 200) {
    throw "Could not contact Solr on '$SolrUrl'. Response status was $($Status)"
} 
Write-Host "Solr's Connection: $($Status)"

$xConnectWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($xConnectHostName)"
If (-not (Test-Path -Path "$($xConnectWebRoot)\web.config")) {

    Install-SitecoreConfiguration `
            -Path (Join-Path -Path $SitecoreInstallPath -ChildPath 'xconnect-xp0.json') `
            -Package (Join-Path -Path $SitecoreInstallPath -ChildPath 'Sitecore_xp0xconnect.scwdp.zip') `
            -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath 'license.xml') `
            -Sitename $xConnectHostName `
            -Port $xConnectSitePort `
            -SolrUrl $SolrUrl `
            -SolrCorePrefix $SitecoreInstancePrefix `
            -XConnectCert $xConnectClientCertName `
            -SSLCert $xConnectHostName `
            -SqlServer $SqlServerHostName `
            -SqlDbPrefix $SitecoreInstancePrefix `
            -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminSecret `
            -SqlCollectionUser $SqlAdminUser -SqlCollectionPassword $SqlAdminSecret `
            -SqlMessagingUser $SqlAdminUser -SqlMessagingPassword $SqlAdminSecret `
            -SqlProcessingEngineUser $SqlAdminUser -SqlProcessingEnginePassword $SqlAdminSecret `
            -SqlReportingUser $SqlAdminUser -SqlReportingPassword $SqlAdminSecret `
            -SqlMarketingAutomationUser $SqlAdminUser -SqlMarketingAutomationPassword $SqlAdminSecret `
            -SqlReferenceDataUser $SqlAdminUser -SqlReferenceDataPassword $SqlAdminSecret `
            -SqlProcessingPoolsUser $SqlAdminUser -SqlProcessingPoolsPassword $SqlAdminSecret `
            -Skip "StopServices", "RemoveServices", "CleanShards", "CreateShards", "CreateShardApplicationDatabaseServerLoginSqlCmd", "CreateShardManagerApplicationDatabaseUserSqlCmd", "CreateShard0ApplicationDatabaseUserSqlCmd", "CreateShard1ApplicationDatabaseUserSqlCmd", "InstallServices", "StartServices"

    Set-WebConfiguration -PSPath ('IIS:\Sites\{0}' -f $xConnectHostName) -Filter '/system.web/customErrors/@mode' -Value 'Off';
    
    try {
        Add-LocalGroupMember -Group 'Performance Monitor Users' -Member ('IIS AppPool\{0}' -f $xConnectHostName);
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($xConnectHostName) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }

    try {
        Add-LocalGroupMember -Group "Performance Log Users" -Member ('IIS AppPool\{0}' -f $xConnectHostName)
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($xConnectHostName) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }
    
    Write-Host "########## xConnect: $($xConnectHostName) installed successfully"
}

& C:\ServiceMonitor.exe w3svc


