# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG SQLSERVER_PORT_ARG=1433

ENV SQLSERVER_PORT=${SQLSERVER_PORT_ARG} `
    SA_PASSWORD=Abc@123`
    ACCEPT_EULA='Y'`
    CERT_EXPORT_PATH=C:\Certificates `
    SQLSERVER_DATA_PATH=C:\SitecoreDatabases`
    SQLSERVER_DATA_BACKUP_PATH=C:\Fresh-SitecoreDatabases`
    DEFAULT_DB_PREFIX=sitecore `
    SITECORE_INSTANCE_PREFIX=sitecore

RUN New-Item -Path $env:SQLSERVER_DATA_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SQLSERVER_DATA_BACKUP_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:CERT_EXPORT_PATH -ItemType Directory | Out-Null;

### Install SqlServer
RUN Start-Process -Wait -FilePath ('{0}\{1}' -f $env:INSTALL_PATH,'SQLServer2017-DEV-x64-ENU.exe') -ArgumentList /qs, /x:setup; `
    .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

RUN Stop-Service MSSQLSERVER; `
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name tcpdynamicports -Value ''; `
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name tcpport -Value 1433; `
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver' -Name LoginMode -Value 2;

ADD https://dist.nuget.org/win-x86-commandline/v4.1.0/nuget.exe C:\\Windows\\nuget.exe

RUN New-Item -Path 'C:/tools' -ItemType Directory | Out-Null; `
    & nuget install Microsoft.Data.Tools.Msbuild -Version 10.0.61710.120 -OutputDirectory c:/tools

COPY /Scripts /Scripts

RUN $AssetInstallPath = $env:INSTALL_PATH; `
    $FreshDatabasesPath = $env:SQLSERVER_DATA_BACKUP_PATH;`
    $DatabasePrefix = $env:DEFAULT_DB_PREFIX; `
    & C:\Scripts\Extract-Databases.ps1 -AssetInstallPath $AssetInstallPath; `
    & C:\Scripts\Install-Databases.ps1 -AssetInstallPath $AssetInstallPath `
                                       -DatabasesPath $FreshDatabasesPath `
                                       -DatabasePrefix $DatabasePrefix; `
    & C:\Scripts\Install-Shards.ps1 -AssetInstallPath $AssetInstallPath `
                                    -DatabasesPath $FreshDatabasesPath `
                                    -DatabasePrefix $DatabasePrefix

RUN & C:/Scripts/ChangePort-SqlServer.ps1 -SqlPort $env:SQLSERVER_PORT

RUN Remove-Item -Path $env:INSTALL_PATH -Recurse -Force

EXPOSE ${SQLSERVER_PORT}

CMD C:\Scripts\Startup.ps1 -SitecoreInstancePrefix $env:SITECORE_INSTANCE_PREFIX `
                           -FreshDatabasesPath $env:SQLSERVER_DATA_BACKUP_PATH `
                           -DatabasesPath $env:SQLSERVER_DATA_PATH `
                           -AcceptEula $env:ACCEPT_EULA `
                           -DefaultDBPrefix $env:DEFAULT_DB_PREFIX