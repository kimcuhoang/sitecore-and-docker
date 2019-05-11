param (
    [Parameter(Mandatory=$true)]
    [string] $SitecoreInstancePrefix,
    [switch] $StartOrRestart,
    [switch] $InstallOrReinstall
)

$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

$MainHostVolumePath = "E:\SitecoreDocker-$($SitecoreInstancePrefix)"

$SubFolders = @{
    Certificates = Join-Path -Path $MainHostVolumePath -ChildPath "Certificates"
    SqlServer = Join-Path -Path $MainHostVolumePath -ChildPath "SqlServer"
    Solr = Join-Path -Path $MainHostVolumePath -ChildPath "Solr"
    IdentityServer = Join-Path -Path $MainHostVolumePath -ChildPath "IdentityServer"
    xConnect = Join-Path -Path $MainHostVolumePath -ChildPath "xConnect"
    xConnect_AutomationEngine = Join-Path -Path $MainHostVolumePath -ChildPath "xConnect_AutomationEngine"
    xConnect_IndexWorker = Join-Path -Path $MainHostVolumePath -ChildPath "xConnect_IndexWorker"
    xConnect_ProcessingEngine = Join-Path -Path $MainHostVolumePath -ChildPath "xConnect_ProcessingEngine"
    SitecoreSite = Join-Path -Path $MainHostVolumePath -ChildPath "SitecoreSite"
}

Function Init-Volume-Paths {
    If (Test-Path -Path $MainHostVolumePath) {
        Remove-Item -Path $MainHostVolumePath -Recurse -Force
    }

    New-Item -Path $MainHostVolumePath -ItemType Directory | Out-Null
    $SubFolders.Keys | ForEach-Object {
        New-Item -Path $SubFolders[$_] -ItemType Directory
    }
}

Function Update-Docker-ENV-File {
    $envFile = Join-Path -Path $PWD -ChildPath ".env"

    $envContent = Get-Content -Path $envFile

    $newcontent = $envContent | ForEach-Object { $_ -replace 'SITECORE_INSTANCE_PREFIX=.*?$', "SITECORE_INSTANCE_PREFIX=$($SitecoreInstancePrefix)" }

    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_CERTIFICATE_PATH=.*?$', "HOST_CERTIFICATE_PATH=$($SubFolders['Certificates'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_SOLR_DATA_PATH=.*?$', "HOST_SOLR_DATA_PATH=$($SubFolders['Solr'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_SQLSERVER_DATA_PATH=.*?$', "HOST_SQLSERVER_DATA_PATH=$($SubFolders['SqlServer'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_IDENTITYSERVER_WEBROOT=.*?$', "HOST_IDENTITYSERVER_WEBROOT=$($SubFolders['IdentityServer'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_WEBROOT=.*?$', "HOST_XCONNECT_WEBROOT=$($SubFolders['xConnect'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_AUTOMATION_ENGINE=.*?$', "HOST_XCONNECT_AUTOMATION_ENGINE=$($SubFolders['xConnect_AutomationEngine'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_INDEX_WORKER=.*?$', "HOST_XCONNECT_INDEX_WORKER=$($SubFolders['xConnect_IndexWorker'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_PROCESSING_ENGINE=.*?$', "HOST_XCONNECT_PROCESSING_ENGINE=$($SubFolders['xConnect_ProcessingEngine'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_SITECORE_WEBROOT=.*?$', "HOST_SITECORE_WEBROOT=$($SubFolders['SitecoreSite'])" }

    $newcontent | Set-Content -Path $envFile
}

######################################################################################
######################################################################################
Update-Docker-ENV-File
If ($InstallOrReinstall) {
    Init-Volume-Paths
    & docker-compose -p "$($SitecoreInstancePrefix)" down -v
    & docker-compose -p "$($SitecoreInstancePrefix)" up -d
    & docker-compose -p "$($SitecoreInstancePrefix)" logs -f -t --tail="all"
} elseif ($StartOrRestart) {
    & docker-compose -p "$($SitecoreInstancePrefix)" stop
    & docker-compose -p "$($SitecoreInstancePrefix)" start
    & docker-compose -p "$($SitecoreInstancePrefix)" logs -f -t --tail="all"
} else {
    Update-Docker-ENV-File
    & docker-compose build -m 4g
}
