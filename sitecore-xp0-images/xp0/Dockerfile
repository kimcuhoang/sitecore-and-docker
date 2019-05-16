# escape=`

ARG XP_WEBSERVER_IMG
ARG XP_WEBSERVER_IMG_TAG

FROM ${XP_WEBSERVER_IMG}:${XP_WEBSERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SITECORE_SITE_PORT_ARG=80

ENV SITECORE_SITE_PORT=${SITECORE_SITE_PORT_ARG} `
    SITECORE_ADMIN_SECRET='b' `
    SITECORE_IDENTITYSERVER_PORT=443 `
    SITECORE_IDENTITYSERVER_CLIENT_SECRET=Abc@123 `
    SITECORE_XCONNECT_PORT=444 `
    CERT_EXPORT_PATH=C:\Certificates `
    CERT_EXPORT_SECRET=secret `
    SITECORE_SOLR_PORT=8983 `
    SITECORE_INSTALL_PATH=C:\SitecoreInstall `
    SQLSERVER_PORT=1433 `
    SQL_ADMIN_USER=sa `
    SQL_ADMIN_SECRET=Abc@123 `
    SITECORE_INSTANCE_PREFIX=sitecore `
    SITECORE_PROJECT_SRC=C:\SitecoreProjectSource

### Enable Remote Debug
COPY /Enable-Remote-Debug.cmd /
RUN Start-Process (Join-Path $env:INSTALL_PATH '\\vs_remotetools.exe') -ArgumentList '/install', '/passive', '/norestart' -NoNewWindow -Wait; `
    setx /M PATH ('{0};{1}' -f 'C:\Program Files\Microsoft Visual Studio 15.0\Common7\IDE\Remote Debugger\x64', $env:PATH);

RUN New-Item -Path $env:SITECORE_INSTALL_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SITECORE_PROJECT_SRC -ItemType Directory | Out-Null; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'sitecore-XP0.json') -Destination $env:SITECORE_INSTALL_PATH; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'Sitecore_single.scwdp.zip') -Destination $env:SITECORE_INSTALL_PATH; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'license.xml') -Destination $env:SITECORE_INSTALL_PATH; `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;

## Modify SIF-Json file
RUN $config = Get-Content (Join-Path -Path $env:SITECORE_INSTALL_PATH -ChildPath 'sitecore-XP0.json')  | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    # $config.Variables.'Site.PhysicalPath' = 'C:\inetpub\wwwroot\{0}' -f $env:SITECORE_SITE_HOST_NAME; `
    $portParam = @{'Type' = 'int';'DefaultValue' = $env:SITECORE_SITE_PORT;'Description' = 'The port to bind to.'}; `
    $config.Parameters | Add-Member -Name "Port" -Value $portParam -MemberType NoteProperty; `
    $config.Tasks.CreateBindings.Params.Add[0] | Add-Member -Name 'Port' -Value '[parameter(''Port'')]' -MemberType NoteProperty; `
    $config.Tasks.UpdateSolrSchema.Params.SitecoreInstanceRoot = '[concat(''http://'', concat(parameter(''DnsName''),concat('':'', parameter(''Port''))))]'; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path (Join-Path -Path $env:SITECORE_INSTALL_PATH -ChildPath 'sitecore-XP0.json')

COPY /Scripts /Scripts

EXPOSE ${SITECORE_SITE_PORT} 4022 4023

CMD C:\Scripts\Startup.ps1 -SitecoreSitePort $env:SITECORE_SITE_PORT `
                             -SitecoreAdminSecret $env:SITECORE_ADMIN_SECRET `
                             -SitecoreIdentityServerPort $env:SITECORE_IDENTITYSERVER_PORT `
                             -SitecoreIdentityServerClientSecret $env:SITECORE_IDENTITYSERVER_CLIENT_SECRET `
                             -xConnectSitePort $env:SITECORE_XCONNECT_PORT `
                             -SitecoreSolrPort $env:SITECORE_SOLR_PORT `
                             -CertExportPath $env:CERT_EXPORT_PATH `
                             -CertExportSecret $env:CERT_EXPORT_SECRET `
                             -SitecoreInstallPath $env:SITECORE_INSTALL_PATH `
                             -SqlServerPort $env:SQLSERVER_PORT `
                             -SqlAdminUser $env:SQL_ADMIN_USER `
                             -SqlAdminSecret $env:SQL_ADMIN_SECRET `
                             -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX