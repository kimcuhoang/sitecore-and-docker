# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV XCONNECT_JOBS_PATH=C:/xConnectJobs `
    XCONNECT_PROCESSING_ENGINE_PATH=C:/ProcessingEngine `
    SITECORE_INSTANCE_PREFIX=sitecore `
    CERT_EXPORT_PATH=C:/Certificates

RUN New-Item -Path $env:XCONNECT_PROCESSING_ENGINE_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null;  `
    Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;

COPY /Startup.ps1 /

CMD C:/Startup.ps1 -xConnectJobsPath $env:XCONNECT_JOBS_PATH `
                   -xConnectProcessingEnginePath $env:XCONNECT_PROCESSING_ENGINE_PATH`
                   -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX `
                   -CertExportPath $env:CERT_EXPORT_PATH