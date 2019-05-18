param (
    [string] $xConnectJobsPath,
    [string] $xConnectProcessingEnginePath,
    [string] $SitecoreInstancePrefix,
    [string] $CertExportPath
)

$ErrorActionPreference = 'Stop'

. "C:\Scripts\Parameters.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportPassword

& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreXConnectSiteUrl

$ProcessingEngineJobPath = Join-Path -Path $xConnectJobsPath -ChildPath "App_Data\jobs\continuous\ProcessingEngine"
If (-not (Test-Path -Path "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe")) {
    Copy-Item -Path "$($ProcessingEngineJobPath)\*" -Destination "$($xConnectProcessingEnginePath)" -Recurse -Force
}

& "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe"