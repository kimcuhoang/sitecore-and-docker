# escape=`

ARG SOURCE_IMG
ARG SOURCE_IMG_TAG

FROM ${SOURCE_IMG}:${SOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG XCONNECT_SITE
ARG XCONNECT_CLIENT_CERT
ARG XCONNECT_PORT

ARG SQL_DB_PREFIX
ARG SQL_HOST
ARG SQL_ADMIN_USER
ARG SQL_ADMIN_PASSWORD

ARG SOLR_URL
ARG SOLR_HOST_NAME

ARG CERT_EXPORT_PASSWORD

### Import xConnect Certificates
RUN $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:XCONNECT_SITE); `
    $pwd = ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:XCONNECT_CLIENT_CERT); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd; 

## Import Solr Certificate
RUN $certPassword = (ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText); `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:SOLR_HOST_NAME); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'cert:\localmachine\root' -Password $certPassword; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'cert:\localmachine\my' -Password $certPassword

## Modify SIF-Json file
RUN $config = Get-Content (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'xconnect-xp0.json')  | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    $config.Variables.'Site.PhysicalPath' = 'C:\inetpub\wwwroot\{0}' -f $env:XCONNECT_SITE; `
    $portParam = @{'Type' = 'int';'DefaultValue' = $env:XCONNECT_PORT;'Description' = 'The port to bind to.'}; `
    $config.Parameters | Add-Member -Name "Port" -Value $portParam -MemberType NoteProperty; `
    $config.Variables.'Endpoint.MarketingAutomation' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Variables.'Endpoint.Collection' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Variables.'Endpoint.Processing.BlobStorage' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Variables.'Endpoint.Processing.TableStorage' = '[concat(''https://'', concat(parameter(''SiteName''),concat('':'', parameter(''Port''))))]'; `
    $config.Tasks.CreateBindingsWithThumbprint.Params.Add[0] | Add-Member -Name 'Port' -Value '[parameter(''Port'')]' -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'xconnect-xp0.json')


# Install XConnect
RUN Install-SitecoreConfiguration `
    -Path (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'xconnect-xp0.json') `
    -Package (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'Sitecore_xp0xconnect.scwdp.zip') `
    -LicenseFile (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'license.xml') `
    -Sitename $env:XCONNECT_SITE `
    -Port $env:XCONNECT_PORT `
    -SolrUrl $env:SOLR_URL `
    -SolrCorePrefix $env:SQL_DB_PREFIX `
    -XConnectCert $env:XCONNECT_CLIENT_CERT `
    -SSLCert $env:XCONNECT_SITE `
    -SqlServer $env:SQL_HOST `
    -SqlDbPrefix $env:SQL_DB_PREFIX `
    -SqlAdminUser $env:SQL_ADMIN_USER -SqlAdminPassword $env:SQL_ADMIN_PASSWORD `
    -SqlCollectionUser $env:SQL_ADMIN_USER -SqlCollectionPassword $env:SQL_ADMIN_PASSWORD `
    -SqlMessagingUser $env:SQL_ADMIN_USER -SqlMessagingPassword $env:SQL_ADMIN_PASSWORD `
    -SqlProcessingEngineUser $env:SQL_ADMIN_USER -SqlProcessingEnginePassword $env:SQL_ADMIN_PASSWORD `
    -SqlReportingUser $env:SQL_ADMIN_USER -SqlReportingPassword $env:SQL_ADMIN_PASSWORD `
    -SqlMarketingAutomationUser $env:SQL_ADMIN_USER -SqlMarketingAutomationPassword $env:SQL_ADMIN_PASSWORD `
    -SqlReferenceDataUser $env:SQL_ADMIN_USER -SqlReferenceDataPassword $env:SQL_ADMIN_PASSWORD `
    -SqlProcessingPoolsUser $env:SQL_ADMIN_USER -SqlProcessingPoolsPassword $env:SQL_ADMIN_PASSWORD `
    -Skip "CreateHostHeader", "StopServices", "RemoveServices", "CleanShards", "CreateShards", "CreateShardApplicationDatabaseServerLoginSqlCmd", "CreateShardManagerApplicationDatabaseUserSqlCmd", "CreateShard0ApplicationDatabaseUserSqlCmd", "CreateShard1ApplicationDatabaseUserSqlCmd", "InstallServices", "StartServices", "ConfigureSolrSchemas"

RUN Set-WebConfiguration -PSPath ('IIS:\Sites\{0}' -f $env:XCONNECT_SITE) -Filter '/system.web/customErrors/@mode' -Value 'Off'; `
    Add-LocalGroupMember -Group 'Performance Monitor Users' -Member ('IIS AppPool\{0}' -f $env:XCONNECT_SITE); 

RUN New-Item -Path 'C:\xconnect_jobs' -ItemType Directory; `
    Copy-Item -Path ('C:/inetpub/wwwroot/{0}/App_Data/jobs/continuous/*' -f $env:XCONNECT_SITE) -Recurse -Destination 'C:\xconnect_jobs'; `
    Remove-Item -Path $env:INSTALL_TEMP -Force -Recurse

#XConnectCert: The certificate to use for encryption. Provide the name or the thumbprint.
#SSLCert: The certificate to use for HTTPS web bindings. Provide the name or the thumbprint. If not provided a certificate will be generated.

ENV XCONNECT_DEFAULT_PORT=${XCONNECT_PORT}

EXPOSE ${XCONNECT_DEFAULT_PORT}

ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]