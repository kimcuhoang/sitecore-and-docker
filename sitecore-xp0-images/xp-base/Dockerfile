# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY /Install /Install

ARG SITECORE_ZIP_FILE
ARG SIF_VERSION

ENV INSTALL_PATH=C:\Install

COPY /Init.ps1 /

RUN C:\Init.ps1 -InstallFolder $env:INSTALL_PATH -SitecoreInstallPackage $env:SITECORE_ZIP_FILE

RUN Install-PackageProvider -Name NuGet -Force | Out-Null; `
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2; `
    Install-Module SitecoreInstallFramework -RequiredVersion $env:SIF_VERSION -Force; `
    Install-Module -Name SqlServer -AllowClobber -Force; `
    Import-Module SqlServer