<#
The Startup.ps1 script of sitecore_xconnect_automationengine
#>
param (
    [string] $SitecoreInstancePrefix,
    [int] $xConnectPort,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $xConnectAutomationEnginePath,
    [string] $xConnectJobs
)

$ErrorActionPreference = 'Stop'

$xConnectHostName = "$($SitecoreInstancePrefix)_xconnect.dev.local"
$xConnectUrl = "https://$($xConnectHostName):$($xConnectPort)"

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportSecret

& "C:\Scripts\Test-Connection.ps1" -ToUrl $xConnectUrl

$AutomationEngineJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\AutomationEngine"
If (-not (Test-Path -Path "$($xConnectAutomationEnginePath)\maengine.exe")) {
    Copy-Item -Path "$($AutomationEngineJobPath)\*" -Destination "$($xConnectAutomationEnginePath)" -Recurse -Force
}

& "$($xConnectAutomationEnginePath)\maengine.exe"