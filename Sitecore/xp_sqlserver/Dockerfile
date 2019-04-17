# escape=`

ARG SOURCE_IMG
ARG SOURCE_IMG_TAG

ARG MSSQL_IMG
ARG MSSQL_IMG_TAG

FROM ${SOURCE_IMG}:${SOURCE_IMG_TAG} as sitecore_resource

FROM ${MSSQL_IMG}:${MSSQL_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

COPY /Scripts /
COPY --from=sitecore_resource ["/Install/Sitecore_identityserver.scwdp.zip", "/Install/Sitecore_xp0xconnect.scwdp.zip", "/Install/Sitecore_single.scwdp.zip", "/Install/"]


ADD https://dist.nuget.org/win-x86-commandline/v4.1.0/nuget.exe C:\\Windows\\nuget.exe

RUN New-Item -Path 'C:/tools' -ItemType Directory | Out-Null; `
    & nuget install Microsoft.Data.Tools.Msbuild -Version 10.0.61710.120 -OutputDirectory c:/tools

ARG DBPREFIX
ARG SQLHOSTNAME
ARG SQL_ADMIN_PASSWORD

ENV INSTALL_PATH=C:/Install `
    DATA_PATH=C:/data `
    DB_PREFIX=${DBPREFIX} `
    SQL_HOSTNAME=${SQLHOSTNAME} `
    ACCEPT_EULA=Y `
    SA_PASSWORD=${SQL_ADMIN_PASSWORD} `
    attach_dbs="[]" `
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password"

RUN New-Item -Path $env:DATA_PATH -ItemType Directory; `
    & .\Extract-Databases.ps1 -Path $env:INSTALL_PATH; `
    & .\Install-Databases.ps1 -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -DatabasePrefix $env:DB_PREFIX; `
    & .\Install-Shards.ps1 -InstallPath $env:INSTALL_PATH -DatabasePrefix $env:DB_PREFIX; `
    Remove-Item -Path 'C:\\tools' -Recurse -Force; `
    Get-ChildItem -Path $env:INSTALL_PATH -Exclude '*.mdf', '*.ldf' -Recurse -Force | Remove-Item -Force;

CMD C:/Boot.ps1 -InstallPath $env:INSTALL_PATH -DataPath $env:DATA_PATH -SqlHostname $env:SQL_HOSTNAME -DatabasePrefix $env:DB_PREFIX;