# escape=`

ARG XP_WEBSERVER_IMG
ARG XP_WEBSERVER_IMG_TAG

FROM ${XP_WEBSERVER_IMG}:${XP_WEBSERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Start-Process (Join-Path $env:INSTALL_PATH '\\dotnet-hosting-2.1.3-win.exe') -ArgumentList '/install', '/passive', '/norestart' -NoNewWindow -Wait

ENV SITECORE_IDENTITYSERVER_HOST_NAME=sitecore_identityserver.dev.local `
    SITECORE_IDENTITYSERVER_PORT=443 `
    SITECORE_IDENTITYSERVER_CLIENT_SECRET=Abc@123 `
    CERT_EXPORT_SECRET=secret `
    CERT_EXPORT_PATH=C:\Certificates `
    SITECORE_INSTALL_PATH=C:\SitecoreInstall `
    SQLSERVER_HOST_NAME=sitecore_sqlserver `
    DATABASE_PREFIX=sitecore `
    SQL_ADMIN_USER=sa `
    SQL_ADMIN_SECRET=Abc@123 `
    SITECORE_SITE_HOST_NAME=sitecore.dev.local `
    SITECORE_SITE_PORT=80

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SITECORE_INSTALL_PATH -ItemType Directory | Out-Null; `
    New-Item -Path ('C:\{0}' -f $env:SITECORE_IDENTITYSERVER_HOST_NAME) -ItemType Directory | Out-Null; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'IdentityServer.json') -Destination $env:SITECORE_INSTALL_PATH; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'Sitecore_identityserver.scwdp.zip') -Destination $env:SITECORE_INSTALL_PATH; `
    Copy-Item -Path (Join-Path -Path $env:INSTALL_PATH -ChildPath 'license.xml') -Destination $env:SITECORE_INSTALL_PATH; `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force

## Modify SIF-Json file
RUN $config = Get-Content (Join-Path -Path $env:SITECORE_INSTALL_PATH -ChildPath 'IdentityServer.json')  | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json; `
    $config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty; `
    #$config.Variables.'Site.PhysicalPath' = 'C:\inetpub\wwwroot\{0}' -f $env:SITECORE_IDENTITYSERVER_HOST_NAME; `
    $portParam = @{'Type' = 'int';'DefaultValue' = $env:SITECORE_IDENTITYSERVER_PORT;'Description' = 'The port to bind to.'}; `
    $config.Parameters | Add-Member -Name 'Port' -Value $portParam -MemberType NoteProperty; `
    $config.Tasks.CreateBindingsWithThumbprint.Params.Add[0] | Add-Member -Name 'Port' -Value '[parameter(''Port'')]' -MemberType NoteProperty; `
    ConvertTo-Json $config -Depth 50 | Set-Content -Path (Join-Path -Path $env:SITECORE_INSTALL_PATH -ChildPath 'IdentityServer.json')

EXPOSE ${SITECORE_IDENTITYSERVER_PORT}

COPY /Scripts /Scripts

CMD & C:\Scripts\Startup.ps1 -SitecoreIdentityServerHostName $env:SITECORE_IDENTITYSERVER_HOST_NAME `
                             -SitecoreIdentityServerPort $env:SITECORE_IDENTITYSERVER_PORT `
                             -SitecoreIdentityServerClientSecret $env:SITECORE_IDENTITYSERVER_CLIENT_SECRET `
                             -CertExportPath $env:CERT_EXPORT_PATH `
                             -CertExportSecret $env:CERT_EXPORT_SECRET `
                             -SitecoreInstallPath $env:SITECORE_INSTALL_PATH `
                             -SqlServerHostName $env:SQLSERVER_HOST_NAME `
                             -DatabasePrefix $env:DATABASE_PREFIX `
                             -SqlAdminUser $env:SQL_ADMIN_USER `
                             -SqlAdminSecret $env:SQL_ADMIN_SECRET `
                             -SitecoreSiteHostName $env:SITECORE_SITE_HOST_NAME `
                             -SitecoreSitePort $env:SITECORE_SITE_PORT