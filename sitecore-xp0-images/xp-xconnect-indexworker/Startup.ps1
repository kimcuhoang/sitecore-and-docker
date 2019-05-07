param (
    [string] $SitecoreSolrHostName,
    [int] $SitecoreSolrPort,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $xConnectIndexWorkerPath,
    [string] $xConnectJobs
)

$ErrorActionPreference = 'Stop'

Function Import-Certificate {
    param(
        [string] $HostName,
        [string] $CertStore
    )

    $PfxPath = Join-Path -Path $CertExportPath -ChildPath "$($HostName).pfx"
    $Secret = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText;
    If (-not (Test-Path -Path $PfxPath)) {
        throw "Could not find Certificate (*.pfx) of $($HostName)"
    }
    @("Cert:\LocalMachine\My", "Cert:\LocalMachine\Root") | ForEach-Object {
        $CertStore = $_
        $cert = Get-ChildItem -Path "$($CertStore)" | Where-Object { $_.Subject -eq "CN=$($HostName)"}

        If ($null -eq $cert) {
            Import-PfxCertificate -FilePath $PfxPath -CertStoreLocation $CertStore -Password $Secret;
        }
    }
}

Function Verify-Solr-Connection {
    $SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)"
    Write-Host "#### Verifying Solr's Connection: $($SolrUrl)"
    $request = [System.Net.WebRequest]::Create($SolrUrl)
    $response = $request.GetResponse()
    $StatusCode = [int]$response.StatusCode
    If ($response.StatusCode -ne 200) {
        throw "Could not contact Solr on '$SolrUrl'. Response status was $($StatusCode)"
    } 
    Write-Host "Solr's Connection: $($StatusCode)"
}

####################################################################################
####################################################################################
####################################################################################
Import-Certificate -HostName $SitecoreSolrHostName

Verify-Solr-Connection

$IndexWorkerJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\IndexWorker"
If (-not (Test-Path -Path "$($IndexWorkerJobPath)\XConnectSearchIndexer.exe.config")) {
    Copy-Item -Path "$($IndexWorkerJobPath)\*" -Destination "$($xConnectIndexWorkerPath)" -Recurse
}

& "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe"