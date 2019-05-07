# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV CERT_EXPORT_PATH=C:/Certificates `
    CERT_EXPORT_SECRET=Abc@123 `
    SITECORE_SOLR_HOST_NAME=sitecore_xconnect.dev.local `
    SITECORE_SOLR_PORT=444 `
    XCONNECT_JOBS_PATH=C:/xConnectJobs `
    XCONNECT_INDEX_WORKER_PATH=C:/IndexWorker

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_INDEX_WORKER_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; 

COPY /Startup.ps1 /
CMD C:/Startup.ps1 -SitecoreSolrHostName $env:SITECORE_SOLR_HOST_NAME `
                   -SitecoreSolrPort $env:SITECORE_SOLR_PORT `
                   -CertExportPath $env:CERT_EXPORT_PATH `
                   -CertExportSecret $env:CERT_EXPORT_SECRET `
                   -xConnectIndexWorkerPath $env:XCONNECT_INDEX_WORKER_PATH `
                   -xConnectJobs $env:XCONNECT_JOBS_PATH