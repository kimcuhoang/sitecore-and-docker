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
& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreXConnectSiteUrl
& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreIdentityServerSiteUrl

$SitecoreWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreSite)"
If (-not (Test-Path -Path "$($SitecoreWebRoot)\web.config")) {
    
    $SqlAdminUser = $SqlServerAdminUser
    $SqlAdminSecret = $SqlServerAdminPassword

    Write-Host "############### Start Installing Sitecore's Instance #############"
    Write-Host "Sitecore's Site: $($SitecoreSiteUrl)"
    Write-Host "Identity Server: $($SitecoreIdentityServerSiteUrl)"
    Write-Host "xConnect Url: $($SitecoreXConnectSiteUrl)"
    Write-Host "##################################################################"

    Install-SitecoreConfiguration -Path (Join-Path -Path $SitecoreInstallPath -ChildPath "sitecore-XP0.json") `
                                    -Package (Join-Path -Path $SitecoreInstallPath -ChildPath "Sitecore_single.scwdp.zip") `
                                    -SqlServer $SqlServerForConnectionString `
                                    -SqlDbPrefix $SitecoreInstancePrefix `
                                    -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminSecret `
                                    -SqlSecurityUser $SqlAdminUser -SqlSecurityPassword $SqlAdminSecret `
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
                                    -XConnectCollectionService $SitecoreXConnectSiteUrl `
                                    -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath "license.xml") `
                                    -Sitename $SitecoreSite `
                                    -Port $SitecoreSitePort `
                                    -SSLCert $SitecoreInstancePrefix `
                                    -SitecoreAdminPassword $SitecoreAdminSecret `
                                    -SitecoreIdentityAuthority  $SitecoreIdentityServerSiteUrl `
                                    -SitecoreIdentitySecret $SitecoreIdentityServerClientSecret `
                                    -Skip "UpdateSolrSchema", "DisplayPassword"

    $iisPath = ('IIS:\Sites\{0}' -f $SitecoreSite); `
    Set-WebConfiguration -PSPath $iisPath -Filter '/system.web/customErrors/@mode' -Value 'Off'; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules' -Name '.' -Value @{name = 'MakeLocationHeaderRelative' ; preCondition = 'IsSitecoreAbsoluteRedirect'; match = @{serverVariable = 'RESPONSE_LOCATION'; pattern = '(https?://[^:/]+):?([0-9]+)?(.*)'}; action = @{type = 'Rewrite'; value = '{R:3}'}}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions' -Name '.' -Value @{name = 'IsSitecoreAbsoluteRedirect'}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions/preCondition[@name=''IsSitecoreAbsoluteRedirect'']' -Name '.' -Value @{input = '{RESPONSE_LOCATION}'; pattern = '(https?://[^:/]+):?([0-9]+)?/sitecore/(.*)'}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions/preCondition[@name=''IsSitecoreAbsoluteRedirect'']' -Name '.' -Value @{input = '{RESPONSE_STATUS}'; pattern = '3[0-9][0-9]'}; `
    
    try {
        Add-LocalGroupMember -Group 'Performance Monitor Users' -Member ('IIS AppPool\{0}' -f $SitecoreSite)
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SitecoreSite) to Performance Monitor Users -- user may already exist" -ForegroundColor Yellow
    }

    try {
        Add-LocalGroupMember -Group "Performance Log Users" -Member ('IIS AppPool\{0}' -f $SitecoreSite)
    } catch {
        Write-Host "Warning: Couldn't add IIS AppPool\$($SitecoreSite) to Performance Log Users -- user may already exist" -ForegroundColor Yellow
    }

    Write-Host "########## Sitecore: $($SitecoreSite) installed successfully"
    Write-Host "########################################"
    Write-Host "########## Install SPE & SXA ##############"
    $Modules = @(
        "Sitecore PowerShell Extensions",
        "Sitecore Experience Accelerator"
    )

    $InstallModuleSIF = Resolve-Path "$($PSScriptRoot)\SIFs\install-module.json"
    $Modules | ForEach-Object {
        $package = Get-Item -Path "$($SitecoreInstallPath)\$($_)*.scwdp.zip"

        Install-SitecoreConfiguration -Path "$($InstallModuleSIF)" `
                                    -Package "$($package.FullName)" `
                                    -SiteName $SitecoreSite
    }

    Write-Host "########## Configure SXA Search Indexes ##############"
    Install-SitecoreConfiguration -Path (Resolve-Path "$($PSScriptRoot)\SIFs\configure-search-indexes.json") `
                                    -SiteName $SitecoreSite `
                                    -SolrCorePrefix $SitecoreInstancePrefix `
                                    -SitecoreSiteUrl $SitecoreSiteUrl `
                                    -SitecoreAdminPassword $SitecoreAdminSecret
}

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }

& C:\ServiceMonitor.exe w3svc