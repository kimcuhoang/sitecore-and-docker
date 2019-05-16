# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV SITECORE_INSTANCE_PREFIX=sitecore `
    CERT_EXPORT_PATH=C:/Certificates `
    CERT_EXPORT_SECRET=Abc@123 `
    SITECORE_XCONNECT_PORT=444 `
    XCONNECT_AUTOMATION_ENGINE_PATH=C:/AutomationEngine `
    XCONNECT_JOBS_PATH=C:/xConnectJobs

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_AUTOMATION_ENGINE_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;

COPY /Startup.ps1 /
CMD C:/Startup.ps1 -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX `
                   -xConnectPort $env:SITECORE_XCONNECT_PORT `
                   -CertExportPath $env:CERT_EXPORT_PATH `
                   -CertExportSecret $env:CERT_EXPORT_SECRET `
                   -xConnectAutomationEnginePath $env:XCONNECT_AUTOMATION_ENGINE_PATH `
                   -xConnectJobs $env:XCONNECT_JOBS_PATH