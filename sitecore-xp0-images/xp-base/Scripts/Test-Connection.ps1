param (
    [string] $ToUrl
)

$ErrorActionPreference = "STOP"

Write-Host "#### Test connection to ------>  $($ToUrl)"
$Request = [System.Net.WebRequest]::Create($ToUrl)
$Response = $Request.GetResponse()
$Status = [int] $Response.StatusCode
If ($Status -ne 200) {
    throw "Could not connect to '$ToUrl'. Response status was $($Status)"
} 
Write-Host "Connected with status: $($Status)"