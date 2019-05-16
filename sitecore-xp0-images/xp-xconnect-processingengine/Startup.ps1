param (
    [string] $xConnectJobsPath,
    [string] $xConnectProcessingEnginePath,
    [string] $SitecoreInstancePrefix,
    [int] $xConnectPort,
    [string] $CertExportPath,
    [string] $CertExportSecret
)

$ErrorActionPreference = 'Stop'

$xConnectHostName = "$($SitecoreInstancePrefix)_xconnect.dev.local"
$xConnectUrl = "https://$($xConnectHostName):$($xConnectPort)"

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportSecret

& "C:\Scripts\Test-Connection.ps1" -ToUrl $xConnectUrl

$ProcessingEngineJobPath = Join-Path -Path $xConnectJobsPath -ChildPath "App_Data\jobs\continuous\ProcessingEngine"
If (-not (Test-Path -Path "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe")) {
    Copy-Item -Path "$($ProcessingEngineJobPath)\*" -Destination "$($xConnectProcessingEnginePath)" -Recurse -Force
}

& "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe"