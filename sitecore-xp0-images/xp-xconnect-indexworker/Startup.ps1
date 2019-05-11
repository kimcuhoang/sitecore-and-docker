param (
    [string] $SitecoreSolrHostName,
    [int] $SitecoreSolrPort,
    [string] $xConnectHostName,
    [int] $xConnectPort,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $xConnectIndexWorkerPath,
    [string] $xConnectJobs
)

$ErrorActionPreference = 'Stop'

Function Import-Certificate {
    param(
        [string] $HostName
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

Function Verify-Connection {
    param (
        [string] $Url
    )

    Write-Host "#### Verifying the connection to : $($Url)"
    $request = [System.Net.WebRequest]::Create($Url)
    $response = $request.GetResponse()
    $StatusCode = [int]$response.StatusCode
    If ($StatusCode -ne 200) {
        throw "Could not contact to '$Url'. Response status was $($StatusCode)"
    } 
    Write-Host "The connection status: $($StatusCode)"
}

####################################################################################
####################################################################################
####################################################################################
Import-Certificate -HostName $SitecoreSolrHostName
Import-Certificate -HostName $xConnectHostName

$SolrUrl = "https://$($SitecoreSolrHostName):$($SitecoreSolrPort)/solr"
$xConnectUrl = "https://$($xConnectHostName):$($xConnectPort)"

Verify-Connection -Url $SolrUrl
Verify-Connection -Url $xConnectUrl

$IndexWorkerJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\IndexWorker"
If (-not (Test-Path -Path "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe")) {
    Copy-Item -Path "$($IndexWorkerJobPath)\*" -Destination "$($xConnectIndexWorkerPath)" -Recurse -Force
}

& "$($xConnectIndexWorkerPath)\XConnectSearchIndexer.exe"