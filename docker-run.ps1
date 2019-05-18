param (
    [string] $SitecoreInstancePrefix = "habitat",
    [string] $MainHostVolumePath = "E:\SitecoreDocker",
    [string] $CertExportSecret = "PoqNCUErvc",
    [int] $PortInitialize = 9111,
    [string] $SitecoreProjectSource = "D:\forks\Habitat",
    [switch] $Up,
    [switch] $ExecutePostStep,
    [switch] $EnableRemoteDebug,
    [switch] $RetrieveIP,
    [switch] $Down
)

$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

$MainHostVolumePath = "$($MainHostVolumePath)-$($SitecoreInstancePrefix)"

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

$SitecoreSitePostFix = "dev.local"
$SitecoreSite = "$($SitecoreInstancePrefix).$($SitecoreSitePostFix)"
$IdentityServerSite = "$($SitecoreInstancePrefix)_identityserver.$($SitecoreSitePostFix)"
$xConnectSite = "$($SitecoreInstancePrefix)_xconnect.$($SitecoreSitePostFix)"
$xConnectClient = "$($SitecoreInstancePrefix)_xconnect_client.$($SitecoreSitePostFix)"
$SqlServerHostName = "$($SitecoreInstancePrefix)_sqlserver"
$SolrHostName = "$($SitecoreInstancePrefix)_solr"

$SitecoreSitePort = $PortInitialize
$IdentityServerSitePort = $PortInitialize + 1
$xConnectSitePort = $PortInitialize + 2
$solrPort = $PortInitialize + 3
$sqlServerPort = $PortInitialize + 4

Function Init-Volume-Paths {
    If (Test-Path -Path $MainHostVolumePath) {
        Remove-Item -Path $MainHostVolumePath -Recurse -Force
    }

    New-Item -Path $MainHostVolumePath -ItemType Directory | Out-Null
    $SubFolders.Keys | ForEach-Object {
        New-Item -Path $SubFolders[$_] -ItemType Directory
    }
}

Function Generate-Json-Config {
    $JsonFile = Join-Path -Path $SubFolders['Certificates'] -ChildPath "$($SitecoreInstancePrefix).json"

    $JsonContent = @{
        SitecoreInstancePrefix = $SitecoreInstancePrefix
        CertExportSecret = $CertExportSecret
        SitecoreSite = @{
            Hostname = $SitecoreSite
            Port = $SitecoreSitePort
            Url = "http://$($SitecoreSite)"
            AdminPassword = 'b'
        }
        SitecoreIdentityServerSite = @{
            Hostname = $IdentityServerSite
            Port = $IdentityServerSitePort
            ClientSecret = 'DLUcqr]CE$'
            Url = "https://$($IdentityServerSite)"
        }
        SitecoreXConnectSite = @{
            Hostname = $xConnectSite
            Port = $xConnectSitePort
            Url = "https://$($xConnectSite)"
        }
        Solr = @{
            Hostname = $SolrHostName
            Port = 8983
            Url = "https://$($SolrHostName):8983/solr"
        }
        SqlServer = @{
            Hostname = $SqlServerHostName
            Port = 1433
            SqlAdminAccount = 'sa'
            SqlAdminPassword = 'Kim@123'
        }
    }

    If ($SitecoreSitePort -ne 80) {
        $SitecoreSiteUrl = $JsonContent.SitecoreSite.Url
        $JsonContent.SitecoreSite.Url = "$($SitecoreSiteUrl):$($SitecoreSitePort)"
    }

    If ($IdentityServerSitePort -ne 443) {
        $IdentityServerUrl = $JsonContent.SitecoreIdentityServerSite.Url
        $JsonContent.SitecoreIdentityServerSite.Url = "$($IdentityServerUrl):$($IdentityServerSitePort)"
    }

    If ($xConnectSitePort -ne 443) {
        $xConnectSiteUrl = $JsonContent.SitecoreXConnectSite.Url
        $JsonContent.SitecoreXConnectSite.Url = "$($xConnectSiteUrl):$($xConnectSitePort)"
    }

    Set-Content $JsonFile  (ConvertTo-Json -InputObject $JsonContent -Depth 6 )
}

Function Generate-RunContext {
    param (
        [string] $RunContextPath
    )

    New-Item -Path "$($RunContextPath)" -ItemType Directory | Out-Null
    $TemplatePath = "$($PWD)\template-run-not-used"
    $EnvTemplateFile = Join-Path -Path $TemplatePath -ChildPath ".env.template"
    $DockerComposeTemplateFile = Join-Path -Path $TemplatePath -ChildPath "docker-compose.template"

    Write-Host "##### Update .env file #########" -ForegroundColor Green
    $env = Join-Path -Path "$($RunContextPath)" -ChildPath ".env"
    $envContent = Get-Content -Path $EnvTemplateFile

    $newcontent = $envContent | ForEach-Object { $_ -replace 'SITECORE_INSTANCE_PREFIX=.*?$', "SITECORE_INSTANCE_PREFIX=$($SitecoreInstancePrefix)" }

    $newcontent = $newcontent | ForEach-Object { $_ -replace 'CERT_EXPORT_PASSWORD=.*?$', "CERT_EXPORT_PASSWORD=$($CertExportSecret)" }

    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_CERTIFICATE_PATH=.*?$', "HOST_CERTIFICATE_PATH=$($SubFolders['Certificates'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_SOLR_DATA_PATH=.*?$', "HOST_SOLR_DATA_PATH=$($SubFolders['Solr'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_SQLSERVER_DATA_PATH=.*?$', "HOST_SQLSERVER_DATA_PATH=$($SubFolders['SqlServer'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_IDENTITYSERVER_WEBROOT=.*?$', "HOST_IDENTITYSERVER_WEBROOT=$($SubFolders['IdentityServer'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_WEBROOT=.*?$', "HOST_XCONNECT_WEBROOT=$($SubFolders['xConnect'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_AUTOMATION_ENGINE=.*?$', "HOST_XCONNECT_AUTOMATION_ENGINE=$($SubFolders['xConnect_AutomationEngine'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_INDEX_WORKER=.*?$', "HOST_XCONNECT_INDEX_WORKER=$($SubFolders['xConnect_IndexWorker'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_XCONNECT_PROCESSING_ENGINE=.*?$', "HOST_XCONNECT_PROCESSING_ENGINE=$($SubFolders['xConnect_ProcessingEngine'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'HOST_SITECORE_WEBROOT=.*?$', "HOST_SITECORE_WEBROOT=$($SubFolders['SitecoreSite'])" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_PROJECT_SOURCE=.*?$', "SITECORE_PROJECT_SOURCE=$($SitecoreProjectSource)" }

    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SITECORE_SITE_PORT=.*?$', "SITECORE_SITE_PORT=$($SitecoreSitePort)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'IDENTITYSERVER_PORT=.*?$', "IDENTITYSERVER_PORT=$($IdentityServerSitePort)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'XCONNECT_PORT=.*?$', "XCONNECT_PORT=$($xConnectSitePort)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SOLR_PORT=.*?$', "SOLR_PORT=$($solrPort)" }
    $newcontent = $newcontent | ForEach-Object { $_ -replace 'SQL_PORT=.*?$', "SQL_PORT=$($sqlServerPort)" }

    $newcontent | Set-Content -Path $env

    Write-Host "##### Update docker-compose file file #########" -ForegroundColor Green
    $dockerCompose = Join-Path -Path "$($RunContextPath)" -ChildPath "docker-compose.yaml"

    $dockerComposeContent = Get-Content -Path $DockerComposeTemplateFile

    $newcontent = $dockerComposeContent | ForEach-Object { $_ -replace 'SITECORE_NETWORK', "$($SitecoreInstancePrefix)" }

    $newcontent | Set-Content -Path $dockerCompose
}

Function Update-Hosts-File {
    Write-Host "######### Update Hosts file........." -ForegroundColor Yellow
    $IPAddress = "127.0.0.1"
    $Hosts = @($SitecoreSite, $IdentityServerSite, $xConnectSite, $SqlServerHostName, $SolrHostName)
    $hostsFile = Join-Path -Path $env:windir -ChildPath "system32\drivers\etc\hosts"

    $Hosts | ForEach-Object {
        $pattern = '^\s*' + [Regex]::Escape($IPAddress) + '\s*' + [Regex]::Escape($_) + '\s*$'
        $existingEntries = @((Get-Content -Path $hostsFile -Encoding UTF8)) -match $pattern
        if($existingEntries.Count -eq 0) {
            Add-Content -Path $hostsFile -Value "`n$IPAddress`t$_" -Encoding UTF8
            Start-Sleep 2
        }
    }
}

Function Remove-Host-Names {
    Write-Host "######### Remove host names .............." -ForegroundColor Yellow

    $IPAddress = "127.0.0.1"
    $Hosts = @($SitecoreSite, $IdentityServerSite, $xConnectSite, $SqlServerHostName, $SolrHostName)
    $hostsFile = Join-Path -Path $env:windir -ChildPath "system32\drivers\etc\hosts"

    $Hosts | ForEach-Object {
        $pattern = '^\s*' + [Regex]::Escape($IPAddress) + '\s*' + [Regex]::Escape($_) + '\s*$'
        $hostsContent = Get-Content -Path $hostsFile -Encoding UTF8
        $updatedHostsContent = $hostsContent | Select-String -Pattern $pattern -NotMatch

        if ($null -ne $updatedHostsContent -and @(Compare-Object -ReferenceObject $hostsContent -DifferenceObject $updatedHostsContent).Count -eq 0) {
            Write-Verbose -Message "No existing host entry found for $IPAddress with hostname '$HostName'"
            return
        }

        Set-Content -Path $hostsFile -Value $updatedHostsContent -Encoding UTF8
        Write-Verbose -Message "Host entry for $IPAddress with hostname '$HostName' has been removed"
        Start-Sleep 2
    }
}


Function Import-Certificates {
    Write-Host "######### Import Certificates to $($CertStore)........." -ForegroundColor Yellow
    $CertPath = $SubFolders['Certificates']
    $CertPassword = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText
    Get-ChildItem -Path "$($CertPath)\*" -Filter "*.pfx" | ForEach-Object {
        $certFile = $_.FullName
        $cert = Get-ChildItem -Path $CertStore | Where-Object { $_.Subject -eq "CN=$($_.BaseName)"}
        If ($null -eq $cert) {
            Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $CertPassword
        }
    }
}

Function Remove-Certificates {
    Write-Host "######## Remove Certificates from $($CertStore)........."
    $Certs = @($SitecoreSite, $IdentityServerSite, $xConnectSite, $xConnectClient, $SqlServerHostName, $SolrHostName)

    $Certs | ForEach-Object {
        $Sitename = $_
        Get-ChildItem -Path $CertStore | Where-Object { $_.Subject -eq "CN=$($Sitename)"} | Remove-Item
    }
}

######################################################################################
######################################################################################

$RunContextPath = "$($PWD)\run-$($SitecoreInstancePrefix)"

If (-not (Test-Path -Path $RunContextPath)) {
    If ($null -eq $PortInitialize) {
        throw "Must define the value for PortInitialize"
    }
    Generate-RunContext -RunContextPath $RunContextPath
}



$CertStore = "Cert:\LocalMachine\Root"

$CurentPath = $PWD
Set-Location $RunContextPath
try {
    If ($Up) {
        Init-Volume-Paths
        Generate-Json-Config
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" down -v
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" up -d
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" logs -f -t --tail="all"
    } 
    elseif ($ExecutePostStep) {
        Update-Hosts-File
        Import-Certificates
        Write-Host "---------> Restart containers ................"
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" stop
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" start
    }
    elseif ($EnableRemoteDebug) {
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" exec -d sitecore_xp0 "C:/Enable-Remote-Debug.cmd"
    }
    elseif ($RetrieveIP) {
        & docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$($SitecoreSite)"
    }
    elseif ($Down) {
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" down -v
        Remove-Certificates
        Remove-Host-Names
        Set-Location $CurentPath
        $FoldersToRemove = @($MainHostVolumePath, $RunContextPath)
        $FoldersToRemove | ForEach-Object {
            If (Test-Path -Path $_) {
                Remove-Item -Path $_ -Recurse -Force
            }
        }
    }
    else {
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" stop
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" start
        & docker-compose -f docker-compose.yaml -p "$($SitecoreInstancePrefix)" logs -f -t --tail="all"
    }
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
}
Set-Location $CurentPath