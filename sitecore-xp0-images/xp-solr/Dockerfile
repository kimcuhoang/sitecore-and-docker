# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SOLR_PORT_ARG=8983

# Install JAVA
ENV JAVA_HOME=C:\OpenJDK `
    SIF_CONFIG_PATH=C:\SIFConfig `
    SOLR_PATH=C:\\Solr `
    SOLR_DATA_PATH=C:\SolrData`
    CERT_PATH=C:\Certificates `
    SOLR_PORT=${SOLR_PORT_ARG} `
    CERT_EXPORT_SECRET=secret `
    SITECORE_INSTANCE_PREFIX=sitecore `
    DEFAULT_SOLR_CORE_PREFIX=sitecore

RUN New-Item -Path $env:SIF_CONFIG_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SOLR_DATA_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SOLR_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:CERT_PATH -ItemType Directory | Out-Null; `
    Copy-Item -Path ('{0}\{1}' -f $env:INSTALL_PATH,'*-solr.json') -Destination $env:SIF_CONFIG_PATH

#Install OpenJDK
RUN setx /M PATH ('{0}\bin;{1}' -f $env:JAVA_HOME, $env:PATH); `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Expand-Archive -Path ('{0}\{1}' -f $env:INSTALL_PATH,'java-*-openjdk-*.zip') -DestinationPath $env:INSTALL_PATH; `
    Move-Item -Path ('{0}\{1}' -f $env:INSTALL_PATH,'java-*-openjdk-*') -Destination $env:JAVA_HOME; 

# Install Solr
ARG SOLR_ZIP_PACKAGE
RUN Expand-Archive -Path ('{0}\{1}' -f $env:INSTALL_PATH,'solr-*.zip') -DestinationPath $env:INSTALL_PATH; `
    Move-Item -Path ('{0}\{1}' -f $env:INSTALL_PATH,'solr-*\\*') -Destination $env:SOLR_PATH;

RUN Remove-Item -Path $env:INSTALL_PATH -Recurse -Force;
COPY /Scripts /Scripts

RUN & ('{0}\bin\solr.cmd' -f $env:SOLR_PATH) start -port $env:SOLR_PORT_ARG; `
    Install-SitecoreConfiguration -Path ('{0}\sitecore-solr.json' -f $env:SIF_CONFIG_PATH) `
                                    -SolrUrl ('http://localhost:{0}/solr' -f $env:SOLR_PORT_ARG) `
                                    -SolrRoot $env:SOLR_PATH `
                                    -SolrService "void" `
                                    -CorePrefix $env:DEFAULT_SOLR_CORE_PREFIX `
                                    -Skip "StopSolr", "StartSolr"; `
    Install-SitecoreConfiguration -Path ('{0}\xconnect-solr.json' -f $env:SIF_CONFIG_PATH) `
                                   -SolrUrl ('http://localhost:{0}/solr' -f $env:SOLR_PORT_ARG) `
                                    -SolrRoot $env:SOLR_PATH `
                                    -SolrService "void" `
                                    -CorePrefix $env:DEFAULT_SOLR_CORE_PREFIX `
                                    -Skip "StopSolr", "StartSolr"; `
    Install-SitecoreConfiguration -Path 'C:\Scripts\SIFs\sxa-solr.json' `
                                    -SolrConfigJson 'C:\Scripts\SIFs\sxa-solr-config.json' `
                                    -SolrUrl ('http://localhost:{0}/solr' -f $env:SOLR_PORT_ARG) `
                                    -SolrRoot $env:SOLR_PATH `
                                    -CorePrefix $env:DEFAULT_SOLR_CORE_PREFIX; `
    Get-Process -Name "java" | Stop-Process -Force;

EXPOSE ${SOLR_PORT}

CMD C:\Scripts\Startup.ps1 -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX `
                           -SolrInstallPath $env:SOLR_PATH `
                           -SolrDataPath $env:SOLR_DATA_PATH `
                           -DefaultSolrCorePrefix $env:DEFAULT_SOLR_CORE_PREFIX `
                           -CertPath $env:CERT_PATH