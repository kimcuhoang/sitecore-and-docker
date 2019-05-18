<#
The Startup.ps1 script of sitecore_xconnect_indexworker
#>
param (
    [string] $SitecoreInstancePrefix,
    [string] $CertExportPath,
    [string] $xConnectIndexWorkerPath,
    [string] $xConnectJobs
)

$ErrorActionPreference = 'Stop'

. "C:\Scripts\Parameters.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportPassword


& "C:\Scripts\Test-Connection.ps1" -ToUrl $SolrUrl
& "C:\Scripts\Test-Connection.ps1" -ToUrl $SitecoreXConnectSiteUrl

$IndexWorkerJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\IndexWorker"
If (-not (Test-Path -Path "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe")) {
    Copy-Item -Path "$($IndexWorkerJobPath)\*" -Destination "$($xConnectIndexWorkerPath)" -Recurse -Force
}

& "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe"