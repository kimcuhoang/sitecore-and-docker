param (
    [string] $xConnectClientCertName,
    [int] $xConnectSitePort,
    [string] $SitecoreSolrPort,
    [string] $CertExportPath,
    [string] $CertExportSecret, 
    [string] $SitecoreInstallPath,
    [string] $SqlServerPort,
    [string] $SqlAdminUser,
    [string] $SqlAdminSecret,
    [string] $SitecoreInstancePrefix
)

$ErrorActionPreference = 'Stop'

Write-Host "=======> Import Certificate ..........................."
& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportSecret

$xConnectHostName = "$($SitecoreInstancePrefix)_xconnect.dev.local"
$xConnectClientCertName = "$($SitecoreInstancePrefix)_xconnect_client.dev.local"
$SitecoreSolrHostName = "$($SitecoreInstancePrefix)_solr"
$SqlServerHostName = "$($SitecoreInstancePrefix)_sqlserver"

$SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)/solr"
& "C:\Scripts\Test-Connection.ps1" -ToUrl $SolrUrl

$xConnectWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($xConnectHostName)"
If (-not (Test-Path -Path "$($xConnectWebRoot)\web.config")) {

    If ($SqlServerPort -ne "1433") {
        $SqlServerHostName = "$($SqlServerHostName), $($SqlServerPort)"
    }

    Install-SitecoreConfiguration `
            -Path (Join-Path -Path $SitecoreInstallPath -ChildPath 'xconnect-xp0.json') `
            -Package (Join-Path -Path $SitecoreInstallPath -ChildPath 'Sitecore_xp0xconnect.scwdp.zip') `
            -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath 'license.xml') `
            -Sitename $xConnectHostName `
            -Port $xConnectSitePort `
            -SolrUrl $SolrUrl `
            -SolrCorePrefix $SitecoreInstancePrefix `
            -XConnectCert $SitecoreInstancePrefix `
            -SSLCert $SitecoreInstancePrefix `
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

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }

& C:\ServiceMonitor.exe w3svc

