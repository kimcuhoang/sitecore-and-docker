# escape=`

ARG SOURCE_IMG
ARG SOURCE_IMG_TAG

FROM ${SOURCE_IMG}:${SOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY /Sitecore /Sitecore

ARG CERT_EXPORT_PASSWORD
# Import xConnect certificates
ARG XCONNECT_SITE
ARG XCONNECT_PORT
ARG XCONNECT_CLIENT_CERT

RUN $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:XCONNECT_SITE); `
    $pwd = ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd; `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:XCONNECT_CLIENT_CERT); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd;

# Import IdentityServer Certificate
ARG SITECORE_IDENTITYSERVER_SITENAME
ARG SITECORE_IDENTITYSERVER_CLIENTSECRET
ARG SOLR_HOST_NAME

RUN $pwd = ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText; `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:SITECORE_IDENTITYSERVER_SITENAME); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd

## Import Solr Certificate
RUN $certPassword = (ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText); `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:SOLR_HOST_NAME); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'cert:\localmachine\root' -Password $certPassword; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'cert:\localmachine\my' -Password $certPassword

ARG SITE_NAME
ARG DEFAUL_HTTP_PORT
ARG SOLR_URL

ARG SQL_HOSTNAME
ARG SQL_DB_PREFIX
ARG SQL_ADMIN_PASSWORD
ARG SQL_ADMIN_USER
ARG SITECORE_ADMIN_PASSWORD
ARG IDENTITYSERVER_MAP_PORT

## Modify SIF-Json file
RUN $config = Get-Content (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'sitecore-XP0.json')  | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    $config.Variables.'Site.PhysicalPath' = 'C:\inetpub\wwwroot\{0}' -f $env:SITE_NAME; `
    $portParam = @{'Type' = 'int';'DefaultValue' = $env:DEFAUL_HTTP_PORT;'Description' = 'The port to bind to.'}; `
    $config.Parameters | Add-Member -Name "Port" -Value $portParam -MemberType NoteProperty; `
    $config.Tasks.CreateBindings.Params.Add[0] | Add-Member -Name 'Port' -Value '[parameter(''Port'')]' -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'sitecore-XP0.json')

# Install Sitecore, apply tweaks and cleanup
RUN $IdentityServerUrl = ('https://{0}:{1}' -f $env:SITECORE_IDENTITYSERVER_SITENAME,$env:IDENTITYSERVER_MAP_PORT); `
    If ($env:IDENTITYSERVER_MAP_PORT -eq 443) { `
        $IdentityServerUrl = ('https://{0}' -f $env:SITECORE_IDENTITYSERVER_SITENAME); `
    } `
    Install-SitecoreConfiguration `
    -Path (Join-Path $env:INSTALL_TEMP '\\sitecore-XP0.json') `  
    -Package (Join-Path $env:INSTALL_TEMP '\Sitecore_single.scwdp.zip') `
    -SqlServer $env:SQL_HOSTNAME `
    -SqlAdminUser $env:SQL_ADMIN_USER -SqlAdminPassword $env:SQL_ADMIN_PASSWORD `
    -SqlSecurityUser $env:SQL_ADMIN_USER -SqlSecurityPassword $env:SQL_ADMIN_PASSWORD `
    -SqlDbPrefix $env:SQL_DB_PREFIX `
    -SqlCoreUser $env:SQL_ADMIN_USER -SqlCorePassword $env:SQL_ADMIN_PASSWORD `
    -SqlMasterUser $env:SQL_ADMIN_USER -SqlMasterPassword $env:SQL_ADMIN_PASSWORD `
    -SqlWebUser $env:SQL_ADMIN_USER -SqlWebPassword $env:SQL_ADMIN_PASSWORD `
    -SqlFormsUser $env:SQL_ADMIN_USER -SqlFormsPassword $env:SQL_ADMIN_PASSWORD `
    -SqlExmMasterUser $env:SQL_ADMIN_USER -SqlExmMasterPassword $env:SQL_ADMIN_PASSWORD `
    -SqlMessagingUser $env:SQL_ADMIN_USER -SqlMessagingPassword $env:SQL_ADMIN_PASSWORD `
    -SqlMarketingAutomationUser $env:SQL_ADMIN_USER -SqlMarketingAutomationPassword $env:SQL_ADMIN_PASSWORD `
    -SqlReferenceDataUser $env:SQL_ADMIN_USER -SqlReferenceDataPassword $env:SQL_ADMIN_PASSWORD `
    -SqlProcessingTasksUser $env:SQL_ADMIN_USER -SqlProcessingTasksPassword $env:SQL_ADMIN_PASSWORD `
    -SqlProcessingPoolsUser $env:SQL_ADMIN_USER -SqlProcessingPoolsPassword $env:SQL_ADMIN_PASSWORD `
    -SqlReportingUser $env:SQL_ADMIN_USER -SqlReportingPassword $env:SQL_ADMIN_PASSWORD `
    -SolrUrl $env:SOLR_URL `
    -SolrCorePrefix $env:SQL_DB_PREFIX `
    -XConnectCert $env:XCONNECT_CLIENT_CERT `
    -XConnectCollectionService ('https://{0}:{1}' -f $env:XCONNECT_SITE,$env:XCONNECT_PORT) `
    -LicenseFile (Join-Path $env:INSTALL_TEMP '\license.xml') `
    -Sitename $env:SITE_NAME `
    -Port $env:DEFAUL_HTTP_PORT `
    -SitecoreAdminPassword $env:SITECORE_ADMIN_PASSWORD `
    -SitecoreIdentityAuthority  $IdentityServerUrl `
    -SitecoreIdentitySecret $env:SITECORE_IDENTITYSERVER_CLIENTSECRET `
    -Skip "CreateHostHeader", "UpdateSolrSchema", "DisplayPassword"

RUN Copy-Item -Path 'C:\\Sitecore\\Config\\*.*' -Destination ('C:\\inetpub\\wwwroot\\{0}\\App_Config\\Include' -f $env:SITE_NAME); `
    $iisPath = ('IIS:\Sites\{0}' -f $env:SITE_NAME); `
    Set-WebConfiguration -PSPath $iisPath -Filter '/system.web/customErrors/@mode' -Value 'Off'; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules' -Name '.' -Value @{name = 'MakeLocationHeaderRelative' ; preCondition = 'IsSitecoreAbsoluteRedirect'; match = @{serverVariable = 'RESPONSE_LOCATION'; pattern = '(https?://[^:/]+):?([0-9]+)?(.*)'}; action = @{type = 'Rewrite'; value = '{R:3}'}}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions' -Name '.' -Value @{name = 'IsSitecoreAbsoluteRedirect'}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions/preCondition[@name=''IsSitecoreAbsoluteRedirect'']' -Name '.' -Value @{input = '{RESPONSE_LOCATION}'; pattern = '(https?://[^:/]+):?([0-9]+)?/sitecore/(.*)'}; `
    Add-WebConfigurationProperty -PSPath $iisPath -Filter '/system.webServer/rewrite/outboundRules/preConditions/preCondition[@name=''IsSitecoreAbsoluteRedirect'']' -Name '.' -Value @{input = '{RESPONSE_STATUS}'; pattern = '3[0-9][0-9]'}; `
    Add-LocalGroupMember -Group 'Performance Monitor Users' -Member ('IIS AppPool\{0}' -f $env:SITE_NAME)

# Enable to remote debugging
COPY /Install /Install
COPY /Enable-Remote-Debug.cmd /
RUN Start-Process (Join-Path $env:INSTALL_TEMP '\\vs_remotetools.exe') -ArgumentList '/install', '/passive', '/norestart' -NoNewWindow -Wait; `
    setx /M PATH ('{0};{1}' -f 'C:\Program Files\Microsoft Visual Studio 15.0\Common7\IDE\Remote Debugger\x64', $env:PATH); 

RUN Remove-Item -Path 'C:\\*.log'; `
    Remove-Item -Path ('C:\\inetpub\\wwwroot\\{0}\\App_Data\\logs' -f $env:SITE_NAME) -Force -Recurse; `
    Remove-Item -Path $env:INSTALL_TEMP -Force -Recurse; `
    Remove-Item -Path 'C:\\Sitecore\\Config' -Force -Recurse;

ENV HTTP_PORT_DEFAULT=${DEFAUL_HTTP_PORT} `
    WEBSITE_NAME=${SITE_NAME}

EXPOSE ${HTTP_PORT_DEFAULT}

RUN New-Item -Path ('C:\{0}' -f $env:WEBSITE_NAME) -ItemType Directory; `
    New-Item -Path 'C:\UnicornSource' -ItemType Directory; 

COPY /Startup.ps1 /

CMD C:/Startup.ps1 -WebSiteName $env:WEBSITE_NAME