# escape=`

ARG SOURCE_IMG
ARG SOURCE_IMG_TAG

ARG OPENJDK_SOLR_IMG
ARG OPENJDK_SOLR_IMG_TAG

FROM ${SOURCE_IMG}:${SOURCE_IMG_TAG} as sitecore_resource

FROM ${OPENJDK_SOLR_IMG}:${OPENJDK_SOLR_IMG_TAG} as builder
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SIF_VERSION

RUN Install-PackageProvider -Name NuGet -Force | Out-Null; `
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2; `
    Install-Module SitecoreInstallFramework -RequiredVersion $env:SIF_VERSION -Force;

COPY --from=sitecore_resource /Install/sitecore-solr.json /Install/sitecore-solr.json
COPY --from=sitecore_resource /Install/xconnect-solr.json /Install/xconnect-solr.json
COPY --from=sitecore_resource /Certificates /Certificates

## Generate Solr's cores
ARG SOLR_PREFIX

RUN & 'c:/solr/bin/solr.cmd' start -p 8983; `
    Install-SitecoreConfiguration -Path 'C:\Install\sitecore-solr.json' `
    -SolrUrl "http://localhost:8983/solr" `
    -SolrRoot "c:/solr" `
    -SolrService "void" `
    -CorePrefix $env:SOLR_PREFIX `
    -Skip "StopSolr", "StartSolr"; `
    Install-SitecoreConfiguration -Path 'C:\Install\xconnect-solr.json' `
    -SolrUrl "http://localhost:8983/solr" `
    -SolrRoot "c:/solr" `
    -SolrService "void" `
    -CorePrefix $env:SOLR_PREFIX `
    -Skip "StopSolr", "StartSolr"; `
    Get-Process -Name "java" | Stop-Process -Force;

ARG SOLR_HOST_NAME
ARG CERT_EXPORT_PASSWORD

ENV JAVA_HOME=C:\\OpenJDK `
    CERT_PATH=C://Certificates `
    SOLR_HOME=c:/data `
    SOLR_PATH=C:/solr

COPY /Solr-Ssl.ps1 /
RUN .\Solr-Ssl.ps1 -SOLR_HOST_NAME $env:SOLR_HOST_NAME -CERT_PATH 'C:/Certificates' -CERT_EXPORT_PASSWORD $env:CERT_EXPORT_PASSWORD -SOLR_PATH $env:SOLR_PATH

# Expose default port
EXPOSE 8983

# Boot
COPY /Boot.cmd /

CMD .\Boot.cmd c:\\solr 8983 c:\\solr\\server\\solr c:\\data