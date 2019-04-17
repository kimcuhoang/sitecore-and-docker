Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()] 
    [string] $SitecorePrefix = 'habitat',
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()] 
    [ValidateSet("9.1.0", "9.1.1")]
    [string] $SitecoreVersion = '9.1.0',
    [int] $PortInit = 8000,
    [switch] $Build,
    [switch] $Init,
    [switch] $Start,
    [switch] $Down,
    [switch] $RenewContainers
)

$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

$SitePostFix = 'dev.local'
$CertPassword = 'PoqNCUErvc'
$IdentityServerClientSecret = 'DLUcqr]CE$'
$SqlAdminPassword = 'Xkv+YPX)oj'
$SitecoreTag = "sc-$($SitecoreVersion)-xp0"


$MainFolder = "E:/SitecoreDocker"
$MainFolder = "$($MainFolder)-$($SitecoreVersion)"
If (-not (Test-Path -Path $MainFolder)) {
    New-Item -Path $MainFolder -ItemType Directory
}

$SubFolders = @{
    SQL = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_SqlServer"
    Solr = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_Solr"
    IdentityServerLogs = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_IdentityServerLogs"
    xConnect = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_xConnect"
    xConnect_AutomationEngine = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_xConnect_AutomationEngine"
    xConnect_IndexWorker = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_xConnect_IndexWorker"
    xConnect_ProcessingEngine = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_xConnect_ProcessingEngine"
    SitecoreSite = Join-Path -Path $MainFolder -ChildPath "$($SitecorePrefix)_SitecoreSite"
}

### Sitecore Sites
$SitecoreSiteName = "$($SitecorePrefix).$($SitePostFix)"
$xConnectSiteName = "$($SitecorePrefix)_xconnect.$($SitePostFix)"
$xConnectClientCertName = "$($SitecorePrefix)_xconnect_client.$($SitePostFix)"
$IdentityServerSiteName = "$($SitecorePrefix)_identityserver.$($SitePostFix)"
$TagName = "$($SitecorePrefix)_$($SitecoreTag)"


### Images's Name
$SitecoreResourceImage = "$($SitecorePrefix)_sitecore_resource"
$SolrImage = "$($SitecorePrefix)_solr"
$SqlServerImage = "$($SitecorePrefix)_sqlserver"
$IdentityServerImage = "$($SitecorePrefix)_identity_server"
$xConnectImage = "$($SitecorePrefix)_xconnect"
$xConnectAutomationEngineImage = "$($SitecorePrefix)_xconnect_automationengine"
$xConnectIndexWorkerImage = "$($SitecorePrefix)_xconnect_indexworker"
$xConnectProcessingEngineImage = "$($SitecorePrefix)_xconnect_processingengine"
$SitecoreImage = "$($SitecorePrefix)_website"

$SolrUrl = "https://$($SolrImage):8983/solr"

### For Habitat
$SolutionFolder = "D:\forks\Habitat"
$SourceFolder = Join-Path -Path "$($SolutionFolder)" -ChildPath "src"

Function Get-Sitecore-Package-By-Version {
    switch ($SitecoreVersion) {
        "9.1.1" { return "Sitecore 9.1.1 rev. 002459 (WDP XP0 packages).zip" }
        Default { return "Sitecore 9.1.0 rev. 001564 (WDP XP0 packages).zip"}
    }
}

Function Get-SIF-Version-By-Sitecore-Version {
    switch ($SitecoreVersion) {
        "9.1.1" { return "2.1.0" }
        Default { return "2.0.0" }
    }
}

Function Prepare-Installation-Files {

    Function Check-Install-Folder-And-Copy-Files {
        param (
            [string] $InstallFolder,
            [string[]] $FileNames,
            [string] $SourceFolder
        )

        If (-not (Test-Path -Path $InstallFolder)) {
            New-Item -Path $InstallFolder -ItemType Directory
        }

        $FileNames | ForEach-Object {
            $file = Join-Path -Path $InstallFolder -ChildPath $_
            If (-not (Test-Path -Path $file)) {
                Copy-Item -Path (Join-Path -Path $SourceFolder -ChildPath $_) -Destination $InstallFolder
            }
        }
    }

    $MainAssetFolder = ".\Assets"
    If (-not (Test-Path -Path $MainAssetFolder)) {
        throw 'The Assets folder is not existed.'
    }

    $InstallationFiles = @{
        DotNetHosting = "dotnet-hosting-2.1.3-win.exe"
        SitecoreWDPPackage = Get-Sitecore-Package-By-Version
        SitecoreLicense = "license.xml"
        RemoteDebugVS2017 = "vs_remotetools.exe"
    }
    
    ### Validate installation files are existing
    $InstallationFiles.Keys | ForEach-Object {
        $key = $_
        $file = Join-Path -Path $MainAssetFolder -ChildPath $InstallationFiles[$key]
        If (-not (Test-Path -Path $file)) {
            throw "**** Missing file $($InstallationFiles[$key])"
        }
    }
    
    ### Copy to relative folder
    Check-Install-Folder-And-Copy-Files -InstallFolder (Join-Path -Path ".\Sitecore\xp_base" -ChildPath "Install") `
                                        -FileNames @($InstallationFiles["SitecoreWDPPackage"], $InstallationFiles["SitecoreLicense"]) `
                                        -SourceFolder $MainAssetFolder
                                        
    Check-Install-Folder-And-Copy-Files -InstallFolder (Join-Path -Path ".\Sitecore\xp_identityserver" -ChildPath "Install") `
                                        -FileNames @($InstallationFiles["DotNetHosting"]) `
                                        -SourceFolder $MainAssetFolder    
                                        
    Check-Install-Folder-And-Copy-Files -InstallFolder (Join-Path -Path ".\Sitecore\xp_sc91xp0" -ChildPath "Install") `
                                        -FileNames @($InstallationFiles["RemoteDebugVS2017"]) `
                                        -SourceFolder $MainAssetFolder   
}

Function Prepare-Certificate-Files {
    Function Generate-Certificates {
        Param(
            [string] $CertName = ""
        )
    
        $certfile = Join-Path -Path $CertPath -ChildPath "$($CertName).pfx"
        If (-not (Test-Path -Path $certfile)) {
            $cert = New-SelfSignedCertificate `
                        -certstorelocation 'cert:\localmachine\my' -dnsname $CertName `
                        -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'
    
            $pwd = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
    
        
            Export-PfxCertificate -cert $cert -FilePath $certfile -Password $pwd
        }
    }

    $CertPath = ".\Sitecore\xp_base\Certificates"
    If (-not (Test-Path -Path $CertPath)) {
        New-Item -Path $CertPath -ItemType Directory
    }
    Generate-Certificates -CertName $xConnectSiteName
    Generate-Certificates -CertName $xConnectClientCertName
    Generate-Certificates -CertName $IdentityServerSiteName
    Generate-Certificates -CertName $SolrImage
}

Function Prepare-Mount-Folders {

    If (Test-Path -Path $MainFolder) {
        Remove-Item -Path $MainFolder -Recurse -Force
    }
    New-Item -Path $MainFolder -ItemType Directory

    $SubFolders.Keys | ForEach-Object {
        New-Item -Path $SubFolders[$_] -ItemType Directory
    }
}

Function Set-Ports-Mapping {
    param(
        $content
    )
    
    $Ports = @{
        MainSite = $PortInit + 1
        IdentityServer = $PortInit + 2
        xConnect = $PortInit + 3
        Solr = $PortInit + 4
        SqlServer = $PortInit + 5
    }

    $content = $content | ForEach-Object { $_ -replace 'SQL_SERVER_MAP_PORT=.*?$', "SQL_SERVER_MAP_PORT=$($Ports['SqlServer'])" }
    $content = $content | ForEach-Object { $_ -replace 'SOLR_PORT=.*?$', "SOLR_PORT=$($Ports['Solr'])" }
    $content = $content | ForEach-Object { $_ -replace 'SITECORE_HTTP_MAP_PORT=.*?$', "SITECORE_HTTP_MAP_PORT=$($Ports['MainSite'])" }
    $content = $content | ForEach-Object { $_ -replace 'IDENTITYSERVER_MAP_PORT=.*?$', "IDENTITYSERVER_MAP_PORT=$($Ports['IdentityServer'])" }
    $content = $content | ForEach-Object { $_ -replace 'XCONNECT_MAP_PORT=.*?$', "XCONNECT_MAP_PORT=$($Ports['xConnect'])" }

    return $content
}

Function Create-ENV-File {
    $envFileExample = Resolve-Path -Path ".\.env.example"
    $content = Get-Content -Path $envFileExample

    $newcontent = $content | ForEach-Object { $_ -replace 'SITECORE_INSTANCE_PREFIX=.*?$',"SITECORE_INSTANCE_PREFIX=$($SitecorePrefix)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_TAG=.*?$',"SITECORE_TAG=$($TagName)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SITE=.*?$',"SITECORE_SITE=$($SitecoreSiteName)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'XCONNECT_SITE=.*?$',"XCONNECT_SITE=$($xConnectSiteName)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'XCONNECT_CLIENT_CERT=.*?$',"XCONNECT_CLIENT_CERT=$($xConnectClientCertName)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'IDENTITYSERVER_SITE=.*?$',"IDENTITYSERVER_SITE=$($IdentityServerSiteName)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'CERT_EXPORT_PASSWORD=.*?$', "CERT_EXPORT_PASSWORD=$($CertPassword)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SOLR_URL=.*?$', "SOLR_URL=$($SolrUrl)" }
    ### Images Name
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_RESOURCE_IMG=.*?$',"SITECORE_RESOURCE_IMG=$($SitecoreResourceImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SOLR_IMG=.*?$',"SITECORE_SOLR_IMG=$($SolrImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SQL_IMG=.*?$',"SITECORE_SQL_IMG=$($SqlServerImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_IDENTITYSERVER_IMG=.*?$',"SITECORE_IDENTITYSERVER_IMG=$($IdentityServerImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_IMG=.*?$',"SITECORE_XCONNECT_IMG=$($xConnectImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_AUTOMATIONENGINE_IMG=.*?$',"SITECORE_XCONNECT_AUTOMATIONENGINE_IMG=$($xConnectAutomationEngineImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_INDEXWORKER_IMG=.*?$',"SITECORE_XCONNECT_INDEXWORKER_IMG=$($xConnectIndexWorkerImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_PROCESSINGENGINE_IMG=.*?$',"SITECORE_XCONNECT_PROCESSINGENGINE_IMG=$($xConnectProcessingEngineImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XP_INSTANCE_IMG=.*?$',"SITECORE_XP_INSTANCE_IMG=$($SitecoreImage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SQL_ADMIN_PASSWORD=.*?$', "SQL_ADMIN_PASSWORD=$($SqlAdminPassword)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_IDENTITYSERVER_CLIENTSECRET=.*?$', "SITECORE_IDENTITYSERVER_CLIENTSECRET=$($IdentityServerClientSecret)" }
    ### Mount Folders
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SQL_MOUNT_HOST=.*?$', "SITECORE_SQL_MOUNT_HOST=$($SubFolders['SQL'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SOLR_MOUNT_HOST=.*?$', "SITECORE_SOLR_MOUNT_HOST=$($SubFolders['Solr'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_LOG_MOUNT_HOST=.*?$', "SITECORE_XCONNECT_LOG_MOUNT_HOST=$($SubFolders['xConnect'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_AUTOMATIONENGINE_LOG_MOUNT_HOST=.*?$', "SITECORE_XCONNECT_AUTOMATIONENGINE_LOG_MOUNT_HOST=$($SubFolders['xConnect_AutomationEngine'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_INDEXWORKER_LOG_MOUNT_HOST=.*?$', "SITECORE_XCONNECT_INDEXWORKER_LOG_MOUNT_HOST=$($SubFolders['xConnect_IndexWorker'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_XCONNECT_PROCESSINGENGINE_LOG_MOUNT_HOST=.*?$', "SITECORE_XCONNECT_PROCESSINGENGINE_LOG_MOUNT_HOST=$($SubFolders['xConnect_ProcessingEngine'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_IDENTITYSERVER_LOGS_MOUNT_HOST=.*?$', "SITECORE_IDENTITYSERVER_LOGS_MOUNT_HOST=$($SubFolders['IdentityServerLogs'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SITE_MOUNT_HOST=.*?$', "SITECORE_SITE_MOUNT_HOST=$($SubFolders['SitecoreSite'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_PROJECT_SRC_MOUNT=.*?$', "SITECORE_PROJECT_SRC_MOUNT=$($SourceFolder)" }

    $SitecorePackage = Get-Sitecore-Package-By-Version
    $SIFVersion = Get-SIF-Version-By-Sitecore-Version
    $SCVersion = $SitecoreVersion.Replace(".", "")
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_ZIP_FILE=.*?$', "SITECORE_ZIP_FILE=$($SitecorePackage)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SIF_VERSION=.*?$', "SIF_VERSION=$($SIFVersion)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_VERSION=.*?$', "SITECORE_VERSION=$($SCVersion)" }
    
    $newcontent = Set-Ports-Mapping -content $newcontent

    $newcontent | Set-Content -Path ".\.env"
}

##################################################################################
##################################################################################
##################################################################################
Write-Host "Create .env file" -ForegroundColor Green
Create-ENV-File

If ($Build) {
    Write-Host "Prepare Installation Files" -ForegroundColor Green
    Prepare-Installation-Files

    Write-Host "Generates certificate files" -ForegroundColor Green
    Prepare-Certificate-Files

    Write-Host "Build Images" -ForegroundColor Green
    & docker-compose build --compress --force-rm -m 4g

    $LASTEXITCODE -ne 0 | Where-Object { $_ } | ForEach-Object { throw "Failed." }
}

If ($Start) {

    If ($RenewContainers)
    {
        Write-Host "Remove existing containers.................." -ForegroundColor Yellow
        & docker-compose -f .\docker-compose.yml -p "$($SitecorePrefix)_$($SitecoreVersion)" down -v
    }

    If ($Init -or (-not (Test-Path -Path $MainFolder))) 
    {
        Write-Host "Initialize mount host folder................" -ForegroundColor Green
        Prepare-Mount-Folders
    }

    & docker-compose -f .\docker-compose.yml -p "$($SitecorePrefix)_$($SitecoreVersion)" up -d
    $LASTEXITCODE -ne 0 | Where-Object { $_ } | ForEach-Object { throw "Failed." }
}

If ($Down) {
    & docker-compose -f .\docker-compose.yml -p "$($SitecorePrefix)_$($SitecoreVersion)" down -v
}