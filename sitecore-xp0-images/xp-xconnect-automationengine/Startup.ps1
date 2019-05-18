<#
The Startup.ps1 script of sitecore_xconnect_automationengine
#>
param (
    [string] $SitecoreInstancePrefix,
    [string] $CertExportPath,
    [string] $xConnectAutomationEnginePath,
    [string] $xConnectJobs
)

$ErrorActionPreference = 'Stop'

. "C:\Scripts\Parameters.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportPassword

& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreXConnectSiteUrl

$AutomationEngineJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\AutomationEngine"
If (-not (Test-Path -Path "$($xConnectAutomationEnginePath)\maengine.exe")) {
    Copy-Item -Path "$($AutomationEngineJobPath)\*" -Destination "$($xConnectAutomationEnginePath)" -Recurse -Force
}

& "$($xConnectAutomationEnginePath)\maengine.exe"