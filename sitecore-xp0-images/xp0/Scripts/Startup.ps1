param (
    [int] $SitecoreSitePort,
    [string] $SitecoreAdminSecret = "b",
    [int] $SitecoreIdentityServerPort,
    [string] $SitecoreIdentityServerClientSecret,
    [int] $xConnectSitePort,
    [int] $SitecoreSolrPort,
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

$SitecoreSiteHostName = "$($SitecoreInstancePrefix).dev.local"
$SitecoreIdentityServerHostName = "$($SitecoreInstancePrefix)_identityserver.dev.local"
$xConnectHostName = "$($SitecoreInstancePrefix)_xconnect.dev.local"
$SitecoreSolrHostName = "$($SitecoreInstancePrefix)_solr"
$SqlServerHostName = "$($SitecoreInstancePrefix)_sqlserver"

$SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)/solr"

$SitecoreXConnectUrl = "https://$($xConnectHostName):$($xConnectSitePort)"

$SitecoreIdentityServerUrl = "https://$($SitecoreIdentityServerHostName)"
If ($SitecoreIdentityServerPort -ne 443) {
    $SitecoreIdentityServerUrl = "$($SitecoreIdentityServerUrl):$($SitecoreIdentityServerPort)"
}

& "C:\Scripts\Test-Connection.ps1" -ToUrl $SolrUrl
& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreXConnectUrl
& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreIdentityServerUrl

$SitecoreWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreSiteHostName)"
If (-not (Test-Path -Path "$($SitecoreWebRoot)\web.config")) {
    
    $SitecoreSiteUrl = "http://$($SitecoreSiteHostName)"
    If ($SitecoreSitePort -ne 80) {
        $SitecoreSiteUrl = "http://$($SitecoreSiteHostName):$($SitecoreSitePort)"
    }


    Write-Host "############### Start Installing Sitecore's Instance #############"
    Write-Host "Sitecore's Site: $($SitecoreSiteUrl)"
    Write-Host "Identity Server: $($SitecoreIdentityServerUrl)"
    Write-Host "xConnect Url: $($SitecoreXConnectUrl)"
    Write-Host "##################################################################"

    If ($SqlServerPort -ne "1433") {
        $SqlServerHostName = "$($SqlServerHostName), $($SqlServerPort)"
    }

    Install-SitecoreConfiguration -Path (Join-Path -Path $SitecoreInstallPath -ChildPath "sitecore-XP0.json") `
                                    -Package (Join-Path -Path $SitecoreInstallPath -ChildPath "Sitecore_single.scwdp.zip") `
                                    -SqlServer $SqlServerHostName `
                                    -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminSecret `
                                    -SqlSecurityUser $SqlAdminUser -SqlSecurityPassword $SqlAdminSecret `
                                    -SqlDbPrefix $SitecoreInstancePrefix `
                                    -SqlCoreUser $SqlAdminUser -SqlCorePassword $SqlAdminSecret `
                                    -SqlMasterUser $SqlAdminUser -SqlMasterPassword $SqlAdminSecret `
                                    -SqlWebUser $SqlAdminUser -SqlWebPassword $SqlAdminSecret `
                                    -SqlFormsUser $SqlAdminUser -SqlFormsPassword $SqlAdminSecret `
                                    -SqlExmMasterUser $SqlAdminUser -SqlExmMasterPassword $SqlAdminSecret `
                                    -SqlMessagingUser $SqlAdminUser -SqlMessagingPassword $SqlAdminSecret `
                                    -SqlMarketingAutomationUser $SqlAdminUser -SqlMarketingAutomationPassword $SqlAdminSecret `
                                    -SqlReferenceDataUser $SqlAdminUser -SqlReferenceDataPassword $SqlAdminSecret `
                                    -SqlProcessingTasksUser $SqlAdminUser -SqlProcessingTasksPassword $SqlAdminSecret `
                                    -SqlProcessingPoolsUser $SqlAdminUser -SqlProcessingPoolsPassword $SqlAdminSecret `
                                    -SqlReportingUser $SqlAdminUser -SqlReportingPassword $SqlAdminSecret `
                                    -SolrUrl $SolrUrl `
                                    -SolrCorePrefix $SitecoreInstancePrefix `
                                    -XConnectCert $SitecoreInstancePrefix `
                                    -XConnectCollectionService $SitecoreXConnectUrl `
                                    -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath "license.xml") `
                                    -Sitename $SitecoreSiteHostName `
                                    -Port $SitecoreSitePort `
                                    -SitecoreAdminPassword $SitecoreAdminSecret `
                                    -SitecoreIdentityAuthority  $SitecoreIdentityServerUrl `
                                    -SitecoreIdentitySecret $SitecoreIdentityServerClientSecret `
                                    -Skip "DisplayPassword"

    $iisPath = ('IIS:\Sites\{0}' -f $SitecoreSiteHostName); `
    Set-WebConfiguration -PSPath $iisPath -Filter '/system.web/customErrors/@mode' -Value 'Off'; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules' -Name '.' -Value @{name = 'MakeLocationHeaderRelative' ; preCondition = 'IsSitecoreAbsoluteRedirect'; match = @{serverVariable = 'RESPONSE_LOCATION'; pattern = '(https?://[^:/]+):?([0-9]+)?(.*)'}; action = @{type = 'Rewrite'; value = '{R:3}'}}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions' -Name '.' -Value @{name = 'IsSitecoreAbsoluteRedirect'}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions/preCondition[@name=''IsSitecoreAbsoluteRedirect'']' -Name '.' -Value @{input = '{RESPONSE_LOCATION}'; pattern = '(https?://[^:/]+):?([0-9]+)?/sitecore/(.*)'}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions/preCondition[@name=''IsSitecoreAbsoluteRedirect'']' -Name '.' -Value @{input = '{RESPONSE_STATUS}'; pattern = '3[0-9][0-9]'}; `
    
    try {
        Add-LocalGroupMember -Group 'Performance Monitor Users' -Member ('IIS AppPool\{0}' -f $SitecoreSiteHostName)
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SitecoreSiteHostName) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }

    try {
        Add-LocalGroupMember -Group "Performance Log Users" -Member ('IIS AppPool\{0}' -f $SitecoreSiteHostName)
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SitecoreSiteHostName) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }

    Write-Host "########## Sitecore: $($SitecoreSiteHostName) installed successfully"

}

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }

& C:\ServiceMonitor.exe w3svc