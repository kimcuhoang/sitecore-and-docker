param (
    [string] $xConnectHostName,
    [int] $xConnectPort,
    [string] $xConnectClientCertName,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $xConnectAutomationEnginePath,
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

Function Verify-xConnect-Connection {
    $xConnectUrl = "https://$($xConnectHostName):$($xConnectPort)"
    Write-Host "#### Verifying xConnect's Connection: $($xConnectUrl)"
    $request = [System.Net.WebRequest]::Create($xConnectUrl)
    $response = $request.GetResponse()
    $StatusCode = [int]$response.StatusCode
    If ($response.StatusCode -ne 200) {
        throw "Could not contact Solr on '$xConnectUrl'. Response status was $($StatusCode)"
    } 
    Write-Host "xConnect's Connection: $($StatusCode)"
}

####################################################################################
####################################################################################
####################################################################################
Import-Certificate -HostName $xConnectHostName
Import-Certificate -HostName $xConnectClientCertName

Verify-xConnect-Connection

$AutomationEngineJobPath = Join-Path -Path $xConnectJobs -ChildPath "App_Data\jobs\continuous\AutomationEngine"
If (-not (Test-Path -Path "$($xConnectAutomationEnginePath)\maengine.exe")) {
    Copy-Item -Path "$($AutomationEngineJobPath)\*" -Destination "$($xConnectAutomationEnginePath)" -Recurse -Force
}

& "$($xConnectAutomationEnginePath)\maengine.exe"