# escape=`

ARG WEB_SERVER_IMG
ARG WEB_SERVER_IMG_TAG

FROM ${WEB_SERVER_IMG}:${WEB_SERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY /Install /Install
COPY /Certificates /Certificates

ARG SITECORE_ZIP_FILE
ARG SIF_VERSION

ENV CERT_PATH=C:\Certificates `
    INSTALL_TEMP=C:\Install

COPY /Init.ps1 /

RUN C:\Init.ps1 -InstallFolder $env:INSTALL_TEMP -SitecoreInstallPackage $env:SITECORE_ZIP_FILE

RUN Install-PackageProvider -Name NuGet -Force | Out-Null; `
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2; `
    Install-Module SitecoreInstallFramework -RequiredVersion $env:SIF_VERSION -Force; `
    Install-Module -Name SqlServer -AllowClobber -Force

RUN Import-Module SqlServer ; `
    Import-Module WebAdministration