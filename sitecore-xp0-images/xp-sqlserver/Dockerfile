# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV SQLSERVER_HOST_NAME=sitecore_sqlserver`
    SA_PASSWORD=Abc@123`
    ACCEPT_EULA='Y'`
    SQLSERVER_DATA_PATH=C:\SitecoreDatabases`
    SQLSERVER_DATA_BACKUP_PATH=C:\Fresh-SitecoreDatabases`
    DEFAULT_DB_PREFIX=sitecore`
    DATABASE_PREFIX=sitecore

RUN New-Item -Path $env:SQLSERVER_DATA_PATH -ItemType Directory | Out-Null; `
    New-Item -Path $env:SQLSERVER_DATA_BACKUP_PATH -ItemType Directory | Out-Null;

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
    $SqlServerHostName = $env:SQLSERVER_HOST_NAME; `
    & C:\Scripts\Extract-Databases.ps1 -AssetInstallPath $AssetInstallPath; `
    & C:\Scripts\Install-Databases.ps1 -AssetInstallPath $AssetInstallPath `
                                       -DatabasesPath $FreshDatabasesPath `
                                       -DatabasePrefix $DatabasePrefix; `
    & C:\Scripts\Install-Shards.ps1 -AssetInstallPath $AssetInstallPath `
                                    -DatabasesPath $FreshDatabasesPath `
                                    -DatabasePrefix $DatabasePrefix `
                                    -SqlServerHostName $SqlServerHostName;

EXPOSE 1433

CMD C:\Scripts\Startup.ps1 -SqlServerHostName $env:SQLSERVER_HOST_NAME `
                           -AssetInstallPath $env:INSTALL_PATH `
                           -FreshDatabasesPath $env:SQLSERVER_DATA_BACKUP_PATH `
                           -DatabasesPath $env:SQLSERVER_DATA_PATH `
                           -SASecret $env:SA_PASSWORD `
                           -AcceptEula $env:ACCEPT_EULA `
                           -DatabasePrefix $env:DATABASE_PREFIX `
                           -DefaultDBPrefix $env:DEFAULT_DB_PREFIX