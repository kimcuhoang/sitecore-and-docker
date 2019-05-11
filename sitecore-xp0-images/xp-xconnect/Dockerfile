# escape=`

ARG XP_WEBSERVER_IMG
ARG XP_WEBSERVER_IMG_TAG

FROM ${XP_WEBSERVER_IMG}:${XP_WEBSERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SITECORE_XCONNECT_PORT_ARG=444

ENV SITECORE_XCONNECT_HOST_NAME=sitecore_xconnect.dev.local `
    SITECORE_XCONNECT_CLIENT_CERT_NAME=sitecore_xconnect_client.dev.local `
    SITECORE_XCONNECT_PORT=${SITECORE_XCONNECT_PORT_ARG} `
    CERT_EXPORT_PATH=C:\Certificates `
    CERT_EXPORT_SECRET=secret `
    SITECORE_SOLR_HOST_NAME=sitecore_solr `
    SITECORE_SOLR_PORT=8983 `
    SITECORE_INSTALL_PATH=C:\SitecoreInstall `
    SQLSERVER_HOST_NAME=sitecore_sqlserver `
    SQLSERVER_PORT=1433 `
    SQL_ADMIN_USER=sa `
    SQL_ADMIN_SECRET=Abc@123 `
    SITECORE_INSTANCE_PREFIX=sitecore

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SITECORE_INSTALL_PATH -ItemType Directory | Out-Null; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'xconnect-xp0.json') -Destination $env:SITECORE_INSTALL_PATH; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'Sitecore_xp0xconnect.scwdp.zip') -Destination $env:SITECORE_INSTALL_PATH; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'license.xml') -Destination $env:SITECORE_INSTALL_PATH; `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;

## Modify SIF-Json file
RUN $config = Get-Content (Join-Path -Path $env:SITECORE_INSTALL_PATH -ChildPath 'xconnect-xp0.json')  | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    # $config.Variables.'Site.PhysicalPath' = 'C:\inetpub\wwwroot\{0}' -f $env:XCONNECT_SITE; `
    $portParam = @{'Type' = 'int';'DefaultValue' = $env:SITECORE_XCONNECT_PORT;'Description' = 'The port to bind to.'}; `
    $config.Parameters | Add-Member -Name "Port" -Value $portParam -MemberType NoteProperty; `
    $config.Variables.'Sql.Database.ProcessingEngineStorage' = '[concat(parameter(''SqlDbPrefix''), ''_Processing.engine.storage'')]'; `
    $config.Variables.'Sql.Database.ProcessingEngineTasks' = '[concat(parameter(''SqlDbPrefix''), ''_Processing.engine.tasks'')]'; `
    $config.Variables.'Endpoint.MarketingAutomation' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Variables.'Endpoint.Collection' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Variables.'Endpoint.Processing.BlobStorage' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Variables.'Endpoint.Processing.TableStorage' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Tasks.CreateBindingsWithThumbprint.Params.Add[0] | Add-Member -Name 'Port' -Value '[parameter(''Port'')]' -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path (Join-Path -Path $env:SITECORE_INSTALL_PATH -ChildPath 'xconnect-xp0.json')

COPY /Scripts /Scripts

EXPOSE ${SITECORE_XCONNECT_PORT}

CMD C:\Scripts\Startup.ps1 -xConnectHostName $env:SITECORE_XCONNECT_HOST_NAME `
                           -xConnectClientCertName $env:SITECORE_XCONNECT_CLIENT_CERT_NAME `
                           -xConnectSitePort $env:SITECORE_XCONNECT_PORT `
                           -SitecoreSolrHostName $env:SITECORE_SOLR_HOST_NAME `
                           -SitecoreSolrPort $env:SITECORE_SOLR_PORT `
                           -CertExportPath $env:CERT_EXPORT_PATH `
                           -CertExportSecret $env:CERT_EXPORT_SECRET `
                           -SitecoreInstallPath $env:SITECORE_INSTALL_PATH `
                           -SqlServerHostName $env:SQLSERVER_HOST_NAME `
                           -SqlServerPort $env:SQLSERVER_PORT `
                           -SqlAdminUser $env:SQL_ADMIN_USER `
                           -SqlAdminSecret $env:SQL_ADMIN_SECRET `
                           -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX