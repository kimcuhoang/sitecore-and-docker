# escape=`

ARG XP_RESOURCE_IMG
ARG XP_RESOURCE_IMG_TAG

FROM ${XP_RESOURCE_IMG}:${XP_RESOURCE_IMG_TAG}
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# https://github.com/Microsoft/dotnet-framework-docker/blob/master/4.7.2/runtime/windowsservercore-ltsc2019/Dockerfile
ENV COMPLUS_NGenProtectedProcess_FeatureEnabled 0

RUN Enable-WindowsOptionalFeature -Online -FeatureName NetFx4ServerFeatures; `
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx4; `
    Enable-WindowsOptionalFeature -Online -FeatureName NetFx4Extended-ASPNET45; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility; `
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase;

#download Roslyn nupkg and ngen the compiler binaries
RUN Invoke-WebRequest https://api.nuget.org/packages/microsoft.net.compilers.2.9.0.nupkg -OutFile c:\microsoft.net.compilers.2.9.0.zip ; `	
    Expand-Archive -Path c:\microsoft.net.compilers.2.9.0.zip -DestinationPath c:\RoslynCompilers ; `
    Remove-Item c:\microsoft.net.compilers.2.9.0.zip -Force ; `
    &C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\RoslynCompilers\tools\csc.exe /ExeConfig:c:\RoslynCompilers\tools\csc.exe | `
    &C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\RoslynCompilers\tools\vbc.exe /ExeConfig:c:\RoslynCompilers\tools\vbc.exe  | `
    &C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe install c:\RoslynCompilers\tools\VBCSCompiler.exe /ExeConfig:c:\RoslynCompilers\tools\VBCSCompiler.exe | `
    &C:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe install c:\RoslynCompilers\tools\csc.exe /ExeConfig:c:\RoslynCompilers\tools\csc.exe | `
    &C:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe install c:\RoslynCompilers\tools\vbc.exe /ExeConfig:c:\RoslynCompilers\tools\vbc.exe | `
    &C:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe install c:\RoslynCompilers\tools\VBCSCompiler.exe  /ExeConfig:c:\RoslynCompilers\tools\VBCSCompiler.exe ;

ENV ROSLYN_COMPILER_LOCATION c:\\RoslynCompilers\\tools

# https://github.com/Microsoft/aspnet-docker/blob/master/4.7.2-windowsservercore-1709/runtime/Dockerfile
RUN Remove-Item -Recurse C:\inetpub\wwwroot\*; `
    Invoke-WebRequest -Uri https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.6/ServiceMonitor.exe -OutFile C:\ServiceMonitor.exe

RUN Start-Process msiexec.exe -ArgumentList '/i', (Join-Path $env:INSTALL_PATH '\\WebDeploy_amd64_en-US.msi'), '/quiet', '/norestart' -NoNewWindow -Wait; `
    Start-Process msiexec.exe -ArgumentList '/i', (Join-Path $env:INSTALL_PATH '\\rewrite_amd64_en-US.msi'), '/quiet', '/norestart' -NoNewWindow -Wait; `
    Start-Process (Join-Path $env:INSTALL_PATH '\\vc_redist.x64.exe') -ArgumentList '/install', '/passive', '/norestart' -NoNewWindow -Wait ;
    
COPY /Sitecore /Sitecore

RUN Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord; `
    setx /M PATH $($env:PATH + ';C:\Sitecore\Scripts'); `
    Remove-Website -Name 'Default Web Site';

RUN Import-Module WebAdministration