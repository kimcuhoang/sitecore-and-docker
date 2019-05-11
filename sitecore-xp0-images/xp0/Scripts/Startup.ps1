param (
    [string] $SitecoreSiteHostName,
    [int] $SitecoreSitePort,
    [string] $SitecoreAdminSecret = "b",
    [string] $SitecoreIdentityServerHostName,
    [int] $SitecoreIdentityServerPort,
    [string] $SitecoreIdentityServerClientSecret,
    [string] $xConnectHostName,
    [string] $xConnectClientCertName,
    [int] $xConnectSitePort,
    [string] $SitecoreSolrHostName,
    [int] $SitecoreSolrPort,
    [string] $CertExportPath,
    [string] $CertExportSecret, 
    [string] $SitecoreInstallPath,
    [string] $SqlServerHostName,
    [string] $SqlServerPort,
    [string] $SqlAdminUser,
    [string] $SqlAdminSecret,
    [string] $SitecoreInstancePrefix
)

$ErrorActionPreference = 'Stop'

Function Import-Certificates {
    & C:/Scripts/Certificates.ps1 -CertName $SitecoreSolrHostName `
                                  -CertExportPath $CertExportPath `
                                  -CertExportSecret $CertExportSecret
    
    & C:/Scripts/Certificates.ps1 -CertName $xConnectHostName `
                                  -CertExportPath $CertExportPath `
                                  -CertExportSecret $CertExportSecret

    & C:/Scripts/Certificates.ps1 -CertName $xConnectClientCertName `
                                  -CertExportPath $CertExportPath `
                                  -CertExportSecret $CertExportSecret

    & C:/Scripts/Certificates.ps1 -CertName $SitecoreIdentityServerHostName `
                                  -CertExportPath $CertExportPath `
                                  -CertExportSecret $CertExportSecret
}

Function Install-XP0 {

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
                                    -XConnectCert $xConnectClientCertName `
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

Function Verify-Connection {
    param(
        [string] $Url
    )

    Write-Host "#### Verifying Connection to: $($Url)"
    $request = [System.Net.WebRequest]::Create($Url)
    $response = $request.GetResponse()
    $statusCode = [int] $response.StatusCode
    If ($statusCode -ne 200) {
        throw "Could not contact on '$Url'. Response status was $($statusCode)"
    }
    Write-Host "Connection: $($statusCode)"
}

#########################################################################################################
#########################################################################################################
#########################################################################################################
Import-Certificates

$SitecoreWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreSiteHostName)"
If (-not (Test-Path -Path "$($SitecoreWebRoot)\web.config")) {
    $SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)/solr"

    $SitecoreXConnectUrl = "https://$($xConnectHostName):$($xConnectSitePort)"

    $SitecoreIdentityServerUrl = "https://$($SitecoreIdentityServerHostName)"
    If ($SitecoreIdentityServerPort -ne 443) {
        $SitecoreIdentityServerUrl = "$($SitecoreIdentityServerUrl):$($SitecoreIdentityServerPort)"
    }

    $SitecoreSiteUrl = "http://$($SitecoreSiteHostName)"
    If ($SitecoreSitePort -ne 80) {
        $SitecoreSiteUrl = "http://$($SitecoreSiteHostName):$($SitecoreSitePort)"
    }

    Verify-Connection -Url $SolrUrl
    Verify-Connection -Url $SitecoreXConnectUrl

    Install-XP0
}

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }

& C:\ServiceMonitor.exe w3svc