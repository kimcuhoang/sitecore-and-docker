# escape=`

ARG XCONNECT_IMG
ARG XCONNECT_IMG_TAG

ARG WEB_SERVER_IMG
ARG WEB_SERVER_IMG_TAG

FROM ${XCONNECT_IMG}:${XCONNECT_IMG_TAG} as xconnect

FROM ${WEB_SERVER_IMG}:${WEB_SERVER_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY --from=xconnect ["/Certificates", "/Certificates"]
COPY --from=xconnect ["/xconnect_jobs/AutomationEngine", "/AutomationEngine"]

ENV CERT_PATH=C:/Certificates

ARG XCONNECT_SITE
ARG XCONNECT_CLIENT_CERT
ARG XCONNECT_CERT_PASSWORD

RUN $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:XCONNECT_SITE); `
    $pwd = ConvertTo-SecureString -String $env:XCONNECT_CERT_PASSWORD -Force -AsPlainText; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd; `
    $certPath = Join-Path -Path $env:CERT_PATH -ChildPath ('{0}.pfx' -f $env:XCONNECT_CLIENT_CERT); `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\root' -Password $pwd; `
    Import-PfxCertificate -FilePath $certPath -CertStoreLocation 'Cert:\localmachine\my' -Password $pwd;


RUN Remove-Item -Path 'C:\\AutomationEngine\\App_Data\\logs' -Force -Recurse; `
    Stop-Service -Name 'W3SVC' -Force; `
    Remove-Item -Path 'C:\\ServiceMonitor.exe' -Force;

ENTRYPOINT [ "C:\\AutomationEngine\\maengine.exe" ]