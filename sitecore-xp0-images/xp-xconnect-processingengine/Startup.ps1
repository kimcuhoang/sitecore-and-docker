param (
    [string] $xConnectJobsPath,
    [string] $xConnectProcessingEnginePath
)

$ProcessingEngineJobPath = Join-Path -Path $xConnectJobsPath -ChildPath "App_Data\jobs\continuous\ProcessingEngine"
If (-not (Test-Path -Path "$($IndexWorkerJobPath)\Sitecore.ProcessingEngine.exe.config")) {
    Copy-Item -Path "$($ProcessingEngineJobPath)\*" -Destination "$($xConnectProcessingEnginePath)" -Recurse
}

& "$($xConnectProcessingEnginePath)\Sitecore.ProcessingEngine.exe"