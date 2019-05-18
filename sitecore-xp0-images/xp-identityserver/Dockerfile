# escape=`

ARG XP_WEBSERVER_IMG
ARG XP_WEBSERVER_IMG_TAG

FROM ${XP_WEBSERVER_IMG}:${XP_WEBSERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Start-Process (Join-Path $env:INSTALL_PATH '\\dotnet-hosting-2.1.3-win.exe') -ArgumentList '/install', '/passive', '/norestart' -NoNewWindow -Wait

ARG SITECORE_IDENTITYSERVER_PORT_ARG=443

ENV SITECORE_IDENTITYSERVER_PORT=${SITECORE_IDENTITYSERVER_PORT_ARG} `
    CERT_EXPORT_PATH=C:\Certificates `
    SITECORE_INSTALL_PATH=C:\SitecoreInstall `
    SITECORE_INSTANCE_PREFIX=sitecore

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SITECORE_INSTALL_PATH -ItemType Directory | Out-Null; `
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

CMD & C:\Scripts\Startup.ps1 -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX `
                             -CertExportPath $env:CERT_EXPORT_PATH `
                             -SitecoreInstallPath $env:SITECORE_INSTALL_PATH