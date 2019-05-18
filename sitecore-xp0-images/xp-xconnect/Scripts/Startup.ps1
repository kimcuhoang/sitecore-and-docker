param (
    [string] $CertExportPath,
    [string] $SitecoreInstallPath,
    [string] $SitecoreInstancePrefix
)

$ErrorActionPreference = 'Stop'

. "C:\Scripts\Parameters.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix

Write-Host "=======> Import Certificate ..........................."
& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportPassword

& "C:\Scripts\Test-Connection.ps1" -ToUrl $SolrUrl

$xConnectWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreXConnectSite)"
If (-not (Test-Path -Path "$($xConnectWebRoot)\web.config")) {

    Install-SitecoreConfiguration `
            -Path (Join-Path -Path $SitecoreInstallPath -ChildPath 'xconnect-xp0.json') `
            -Package (Join-Path -Path $SitecoreInstallPath -ChildPath 'Sitecore_xp0xconnect.scwdp.zip') `
            -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath 'license.xml') `
            -Sitename $SitecoreXConnectSite `
            -Port $SitecoreXConnectSitePort `
            -SolrUrl $SolrUrl `
            -SolrCorePrefix $SitecoreInstancePrefix `
            -XConnectCert $SitecoreInstancePrefix `
            -SSLCert $SitecoreInstancePrefix `
            -SqlServer $SqlServerForConnectionString `
            -SqlDbPrefix $SitecoreInstancePrefix `
            -SqlAdminUser $SqlServerAdminUser -SqlAdminPassword $SqlServerAdminPassword `
            -SqlCollectionUser $SqlServerAdminUser -SqlCollectionPassword $SqlServerAdminPassword `
            -SqlMessagingUser $SqlServerAdminUser -SqlMessagingPassword $SqlServerAdminPassword `
            -SqlProcessingEngineUser $SqlServerAdminUser -SqlProcessingEnginePassword $SqlServerAdminPassword `
            -SqlReportingUser $SqlServerAdminUser -SqlReportingPassword $SqlServerAdminPassword `
            -SqlMarketingAutomationUser $SqlServerAdminUser -SqlMarketingAutomationPassword $SqlServerAdminPassword `
            -SqlReferenceDataUser $SqlServerAdminUser -SqlReferenceDataPassword $SqlServerAdminPassword `
            -SqlProcessingPoolsUser $SqlServerAdminUser -SqlProcessingPoolsPassword $SqlServerAdminPassword `
            -Skip "StopServices", "RemoveServices", "CleanShards", "CreateShards", "CreateShardApplicationDatabaseServerLoginSqlCmd", "CreateShardManagerApplicationDatabaseUserSqlCmd", "CreateShard0ApplicationDatabaseUserSqlCmd", "CreateShard1ApplicationDatabaseUserSqlCmd", "InstallServices", "StartServices"

    Set-WebConfiguration -PSPath ('IIS:\Sites\{0}' -f $SitecoreXConnectSite) -Filter '/system.web/customErrors/@mode' -Value 'Off';
    
    try {
        Add-LocalGroupMember -Group 'Performance Monitor Users' -Member ('IIS AppPool\{0}' -f $SitecoreXConnectSite);
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SitecoreXConnectSite) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }

    try {
        Add-LocalGroupMember -Group "Performance Log Users" -Member ('IIS AppPool\{0}' -f $SitecoreXConnectSite)
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SitecoreXConnectSite) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }

    Write-Host "########## xConnect: $($SitecoreXConnectSite) installed successfully"
}

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }

& C:\ServiceMonitor.exe w3svc

