# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV XCONNECT_JOBS_PATH=C:/xConnectJobs `
    XCONNECT_PROCESSING_ENGINE_PATH=C:/ProcessingEngine

RUN New-Item -Path $env:XCONNECT_PROCESSING_ENGINE_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:XCONNECT_JOBS_PATH -ItemType Directory | Out-Null; 

COPY /Startup.ps1 /

CMD C:/Startup.ps1 -xConnectJobsPath $env:XCONNECT_JOBS_PATH `
                   -xConnectProcessingEnginePath $env:XCONNECT_PROCESSING_ENGINE_PATH