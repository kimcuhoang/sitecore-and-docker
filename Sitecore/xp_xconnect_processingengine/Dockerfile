# escape=`

ARG XCONNECT_IMG
ARG XCONNECT_IMG_TAG

ARG WEB_SERVER_IMG
ARG WEB_SERVER_IMG_TAG

FROM ${XCONNECT_IMG}:${XCONNECT_IMG_TAG} as xconnect

FROM ${WEB_SERVER_IMG}:${WEB_SERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY --from=xconnect ["/xconnect_jobs/ProcessingEngine", "/ProcessingEngine"]

RUN Remove-Item -Path 'C:\\ProcessingEngine\\App_Data\\logs' -Force -Recurse; `
    Stop-Service -Name 'W3SVC' -Force; `
    Remove-Item -Path 'C:\\ServiceMonitor.exe' -Force;

ENTRYPOINT [ "C:\\ProcessingEngine\\Sitecore.ProcessingEngine.exe" ]