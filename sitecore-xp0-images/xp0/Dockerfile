# escape=`

ARG XP_WEBSERVER_IMG
ARG XP_WEBSERVER_IMG_TAG

FROM ${XP_WEBSERVER_IMG}:${XP_WEBSERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SITECORE_SITE_PORT_ARG=80

ENV SITECORE_SITE_PORT=${SITECORE_SITE_PORT_ARG} `
    CERT_EXPORT_PATH=C:\Certificates `
    SITECORE_INSTALL_PATH=C:\SitecoreInstall `
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
    Copy-Item -Path ('{0}\{1}\*' -f $env:INSTALL_PATH,'SitecorePackages' ) -Filter '*.scwdp.zip' -Destination $env:SITECORE_INSTALL_PATH; `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;

COPY /Scripts /Scripts

## Modify SIF-Json file
RUN C:\Scripts\Modify-SIF.ps1 -SitecoreInstallPath $env:SITECORE_INSTALL_PATH

EXPOSE ${SITECORE_SITE_PORT} 4022 4023

CMD C:\Scripts\Startup.ps1 -CertExportPath $env:CERT_EXPORT_PATH `
                             -SitecoreInstallPath $env:SITECORE_INSTALL_PATH `
                             -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX