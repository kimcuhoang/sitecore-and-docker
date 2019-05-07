# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV CERT_EXPORT_PATH=C:/Certificates `
    CERT_EXPORT_SECRET=Abc@123 `
    SITECORE_XCONNECT_HOST_NAME=sitecore_xconnect.dev.local `
    SITECORE_XCONNECT_PORT=444 `
    SITECORE_XCONNECT_CLIENT_CERT_NAME=sitecore_xconnect_client.dev.local `
    XCONNECT_AUTOMATION_ENGINE_PATH=C:/AutomationEngine `
    XCONNECT_JOBS_PATH=C:/xConnectJobs

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_AUTOMATION_ENGINE_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; 

COPY /Startup.ps1 /
CMD C:/Startup.ps1 -xConnectHostName $env:SITECORE_XCONNECT_HOST_NAME `
                   -xConnectPort $env:SITECORE_XCONNECT_PORT `
                   -xConnectClientCertName $env:SITECORE_XCONNECT_CLIENT_CERT_NAME `
                   -CertExportPath $env:CERT_EXPORT_PATH `
                   -CertExportSecret $env:CERT_EXPORT_SECRET `
                   -xConnectAutomationEnginePath $env:XCONNECT_AUTOMATION_ENGINE_PATH `
                   -xConnectJobs $env:XCONNECT_JOBS_PATH