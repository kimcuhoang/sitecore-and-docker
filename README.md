# Deploy Sitecore 9.1.x to Docker

## Prerequisites

- Windows 10 Pro Version 1809
- [Docker for Windows](https://hub.docker.com/editions/community/docker-ce-desktop-windows)
  - Switch to Windows Container

## Preparations

1. Suppose this repo is cloned on our local at - `D:\sitecore-and-docker`
1. Download the following tools then put into `Assets` folder
   - [java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip](https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.161-1/java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip)
   - [solr-7.2.1.zip](http://archive.apache.org/dist/lucene/solr/7.2.1/solr-7.2.1.zip)
   - [SQLServer2017-DEV-x64-ENU.exe](https://go.microsoft.com/fwlink/?linkid=840945)
   - [SQLServer2017-DEV-x64-ENU.box](https://go.microsoft.com/fwlink/?linkid=840944)
   - [WebDeploy_amd64_en-US.msi](https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi)
   - [rewrite_amd64_en-US.msi](https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi)
   - [VC_redist.x64.exe](https://aka.ms/vs/15/release/VC_redist.x64.exe)
   - [dotnet-hosting-2.1.3-win.exe](https://dotnet.microsoft.com/download/thank-you/dotnet-runtime-2.1.9-windows-hosting-bundle-installer)
   - [vs_remotetool.exe](https://aka.ms/vs/15/release/RemoteTools.amd64ret.enu.exe)
   - [Sitecore 9.1.0 rev. 001564 (WDP XP0 packages).zip](https://dev.sitecore.net)
   - [Sitecore 9.1.1 rev. 002459 (WDP XP0 packages).zip](https://dev.sitecore.net)
1. Also, put our Sitecore license - **license.xml** into `Assets` folder

## Build Images Base

[TBD]

## Resources

- I'm inspired by the repository - [Repository of Sitecore Docker base images](https://github.com/sitecoreops/sitecore-images)
- [USING THE PKCS #12 (.PFX) FORMAT FOR SOLR SSL SECURITY](https://blogs.perficientdigital.com/2018/08/20/using-the-pkcs12-pfx-format-for-solr-ssl-security/)
- [Microsoft/dotnet-framework-docker](https://github.com/Microsoft/dotnet-framework-docker/blob/master/4.7.2/runtime/windowsservercore-ltsc2019/Dockerfile)
- [Microsoft/aspnet-docker](https://github.com/Microsoft/aspnet-docker/blob/master/4.7.2-windowsservercore-1709/runtime/Dockerfile)
- [Debugging Windows containers with Visual Studio](https://medium.com/@marco.fiocco/debugging-windows-containers-with-visual-studio-yes-also-c-apps-740f6e1965b8)