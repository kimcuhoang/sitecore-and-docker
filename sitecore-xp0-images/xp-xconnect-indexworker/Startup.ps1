<#
The Startup.ps1 script of sitecore_xconnect_indexworker
#>
param (
    [string] $SitecoreInstancePrefix,
    [int] $SitecoreSolrPort,
    [int] $xConnectPort,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $xConnectIndexWorkerPath,
    [string] $xConnectJobs
)

$ErrorActionPreference = 'Stop'

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportSecret

$SitecoreSolrHostName = "$($SitecoreInstancePrefix)_solr"
$xConnectHostName = "$($SitecoreInstancePrefix)_xconnect.dev.local"

$SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)/solr"
$xConnectUrl = "https://$($xConnectHostName):$($xConnectPort)"

& "C:\Scripts\Test-Connection.ps1" -ToUrl $SolrUrl
& "C:\Scripts\Test-Connection.ps1" -ToUrl $xConnectUrl

$IndexWorkerJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\IndexWorker"
If (-not (Test-Path -Path "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe")) {
    Copy-Item -Path "$($IndexWorkerJobPath)\*" -Destination "$($xConnectIndexWorkerPath)" -Recurse -Force
}

& "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe"