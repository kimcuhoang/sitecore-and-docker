# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV XCONNECT_JOBS_PATH=C:/xConnectJobs `
    XCONNECT_PROCESSING_ENGINE_PATH=C:/ProcessingEngine `
    SITECORE_XCONNECT_HOST_NAME=sitecore_xconnect.dev.local `
    SITECORE_XCONNECT_PORT=444 `
    CERT_EXPORT_PATH=C:/Certificates `
    CERT_EXPORT_SECRET=Abc@123

RUN New-Item -Path $env:XCONNECT_PROCESSING_ENGINE_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; 

COPY /Startup.ps1 /

CMD C:/Startup.ps1 -xConnectJobsPath $env:XCONNECT_JOBS_PATH `
                   -xConnectProcessingEnginePath $env:XCONNECT_PROCESSING_ENGINE_PATH`
                   -xConnectHostName $env:SITECORE_XCONNECT_HOST_NAME `
                   -xConnectPort $env:SITECORE_XCONNECT_PORT `
                   -CertExportPath $env:CERT_EXPORT_PATH `
                   -CertExportSecret $env:CERT_EXPORT_SECRET