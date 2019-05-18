# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV CERT_EXPORT_PATH=C:/Certificates `
    XCONNECT_JOBS_PATH=C:/xConnectJobs `
    XCONNECT_INDEX_WORKER_PATH=C:/IndexWorker `
    SITECORE_INSTANCE_PREFIX=sitecore

RUN New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_INDEX_WORKER_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;

COPY /Startup.ps1 /
CMD C:/Startup.ps1 -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX `
                   -CertExportPath $env:CERT_EXPORT_PATH `
                   -xConnectIndexWorkerPath $env:XCONNECT_INDEX_WORKER_PATH `
                   -xConnectJobs $env:XCONNECT_JOBS_PATH