param (
    [string] $xConnectJobsPath,
    [string] $xConnectProcessingEnginePath,
    [string] $xConnectHostName,
    [int] $xConnectPort,
    [string] $CertExportPath,
    [string] $CertExportSecret
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

Import-Certificate -HostName $xConnectHostName
Verify-Connection -Url "https://$($xConnectHostName):$($xConnectPort)"

$ProcessingEngineJobPath = Join-Path -Path $xConnectJobsPath -ChildPath "App_Data\jobs\continuous\ProcessingEngine"
If (-not (Test-Path -Path "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe")) {
    Copy-Item -Path "$($ProcessingEngineJobPath)\*" -Destination "$($xConnectProcessingEnginePath)" -Recurse -Force
}

& "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe"