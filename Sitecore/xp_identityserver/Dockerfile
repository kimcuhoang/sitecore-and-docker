# escape=`

ARG SOURCE_IMG
ARG SOURCE_IMG_TAG

FROM ${SOURCE_IMG}:${SOURCE_IMG_TAG}

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY /Install /Install

RUN Start-Process (Join-Path $env:INSTALL_TEMP '\\dotnet-hosting-2.1.3-win.exe') -ArgumentList '/install', '/passive', '/norestart' -NoNewWindow -Wait

ARG SITECORE_IDENTITYSERVER_SITENAME
ARG IDENTITYSERVER_MAP_PORT
ARG SQL_HOST
ARG SQL_ADMIN_USER
ARG SQL_ADMIN_PASSWORD
ARG SQL_DB_PREFIX
ARG SITECORE_SITE
ARG SITECORE_SITE_PORT
ARG SITECORE_IDENTITYSERVER_CLIENTSECRET
ARG CERT_EXPORT_PASSWORD

## Import Certificate
RUN $pwd = ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText; `
    $certFile = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:SITECORE_IDENTITYSERVER_SITENAME); `
    Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\My' -Password $pwd; `
    Import-PfxCertificate -FilePath $certFile -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $pwd

## Modify SIF-Json file
RUN $config = Get-Content (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'IdentityServer.json')  | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    $config.Variables.'Site.PhysicalPath' = 'C:\inetpub\wwwroot\{0}' -f $env:SITECORE_IDENTITYSERVER_SITENAME; `
    $portParam = @{'Type' = 'int';'DefaultValue' = $env:IDENTITYSERVER_MAP_PORT;'Description' = 'The port to bind to.'}; `
    $config.Parameters | Add-Member -Name 'Port' -Value $portParam -MemberType NoteProperty; `
    $config.Tasks.CreateBindingsWithThumbprint.Params.Add[0] | Add-Member -Name 'Port' -Value '[parameter(''Port'')]' -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'IdentityServer.json')

## Install IdentityServer
RUN $SitecoreSiteUrl = ('http://{0}:{1}' -f $env:SITECORE_SITE,$env:SITECORE_SITE_PORT); `
    If ($env:SITECORE_SITE_PORT -eq 80) { `
        $SitecoreSiteUrl = ('http://{0}' -f $env:SITECORE_SITE); `
    } `
    Install-SitecoreConfiguration `
    -Path (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'IdentityServer.json') `
    -Package (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'Sitecore_identityserver.scwdp.zip') `
    -LicenseFile (Join-Path -Path $env:INSTALL_TEMP -ChildPath 'license.xml') `
    -Sitename $env:SITECORE_IDENTITYSERVER_SITENAME `
    -Port $env:IDENTITYSERVER_MAP_PORT `
    -SqlServer $env:SQL_HOST `
    -SqlDbPrefix $env:SQL_DB_PREFIX `
    -SqlCoreUser $env:SQL_ADMIN_USER -SqlCorePassword $env:SQL_ADMIN_PASSWORD `
    -PasswordRecoveryUrl $SitecoreSiteUrl `
    -AllowedCorsOrigins $SitecoreSiteUrl `
    -ClientSecret $env:SITECORE_IDENTITYSERVER_CLIENTSECRET `
    -SitecoreIdentityCert $env:SITECORE_IDENTITYSERVER_SITENAME `
    -Skip "CreateHostHeader"

RUN Remove-Item -Path $env:INSTALL_TEMP -Force -Recurse

ENV DEFAULT_PORT=${IDENTITYSERVER_MAP_PORT}

EXPOSE ${DEFAULT_PORT}

ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]