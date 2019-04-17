# escape=`

FROM mcr.microsoft.com/windows/servercore:ltsc2019
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY /Install /

# Install JAVA
ENV JAVA_HOME=C:\OpenJDK
ARG OPENJDK_ZIP_PACKAGE_NAME

#Install OpenJDK
RUN setx /M PATH ('{0}\bin;{1}' -f $env:JAVA_HOME, $env:PATH); `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Expand-Archive $env:OPENJDK_ZIP_PACKAGE_NAME -DestinationPath C:\; `
    Move-Item -Path ('C:\{0}' -f ($env:OPENJDK_ZIP_PACKAGE_NAME -Replace '.zip', '')) -Destination $env:JAVA_HOME; 

# Install Solr
ARG SOLR_ZIP_PACKAGE
RUN Expand-Archive -Path $env:SOLR_ZIP_PACKAGE -DestinationPath /temp; `
    Move-Item -Path "C:/temp/solr-*" -Destination "c:/solr";