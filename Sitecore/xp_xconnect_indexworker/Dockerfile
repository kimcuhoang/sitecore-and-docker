# escape=`

ARG XCONNECT_IMG
ARG XCONNECT_IMG_TAG

ARG WEB_SERVER_IMG
ARG WEB_SERVER_IMG_TAG

FROM ${XCONNECT_IMG}:${XCONNECT_IMG_TAG} as xconnect

FROM ${WEB_SERVER_IMG}:${WEB_SERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY --from=xconnect ["/Certificates", "/Certificates"]
COPY --from=xconnect ["/xconnect_jobs/IndexWorker", "/IndexWorker"]

ENV CERT_PATH=C:/Certificates
ARG SOLR_HOST_NAME
ARG CERT_EXPORT_PASSWORD
## Import Solr Certificate
RUN $certPassword = (ConvertTo-SecureString -String $env:CERT_EXPORT_PASSWORD -Force -AsPlainText); `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:SOLR_HOST_NAME); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'cert:\localmachine\root' -Password $certPassword; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'cert:\localmachine\my' -Password $certPassword

RUN Remove-Item -Path 'C:\\IndexWorker\\App_Data\\logs' -Force -Recurse; `
    Stop-Service -Name 'W3SVC' -Force; `
    Remove-Item -Path 'C:\\ServiceMonitor.exe' -Force;

ARG SOLR_URL

HEALTHCHECK --interval=5s `
 CMD powershell -command `
    try { `
     $response  = iwr $env:SOLR_URL; `
     if ($response.StatusCode -eq 200) { return 0} `
     else {return 1}; `
    } catch { return 1 ;}

ENTRYPOINT [ "C:\\IndexWorker\\XConnectSearchIndexer.exe" ]