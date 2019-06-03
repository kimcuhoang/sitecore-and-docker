# Playing Sitecore-9.1.1 (xp0) with Docker

## Summary

- This repo aims to install Sitecore 9.1.1 (xp0) to docker
- It's also install **Sitecore PowerShell Extension** and **Sitecore Experience Accelerator**. 
- Everything is **https**

## Prerequisites

- Windows 10 Pro Version 1809
- Download and install [Docker for Windows](https://hub.docker.com/editions/community/docker-ce-desktop-windows); then **Switch to Windows Container**
- This repo must be cloned to local, for example - **`D:\sitecore-and-docker`**

## Preparations

Download the following tools then put into `D:\sitecore-and-docker\sitecore-xp0-images\assets` folder

- [java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip](https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.161-1/java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip)
- [solr-7.2.1.zip](http://archive.apache.org/dist/lucene/solr/7.2.1/solr-7.2.1.zip)
- [SQLServer2017-DEV-x64-ENU.exe](https://go.microsoft.com/fwlink/?linkid=840945)
- [SQLServer2017-DEV-x64-ENU.box](https://go.microsoft.com/fwlink/?linkid=840944)
- [WebDeploy_amd64_en-US.msi](https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi)
- [rewrite_amd64_en-US.msi](https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi)
- [VC_redist.x64.exe](https://aka.ms/vs/15/release/VC_redist.x64.exe)
- [dotnet-hosting-2.1.3-win.exe](https://dotnet.microsoft.com/download/thank-you/dotnet-runtime-2.1.9-windows-hosting-bundle-installer)
- [vs_remotetool.exe](https://aka.ms/vs/15/release/RemoteTools.amd64ret.enu.exe)
- [Sitecore 9.1.1 rev. 002459 (WDP XP0 packages).zip](https://dev.sitecore.net/Downloads/Sitecore_Experience_Platform/91/Sitecore_Experience_Platform_91_Update1.aspx)
- [Sitecore Azure Toolkit 2.2.0 rev. 190305.zip](https://dev.sitecore.net/Downloads/Sitecore_Azure_Toolkit/2x/Sitecore_Azure_Toolkit_220.aspx)
- [Sitecore PowerShell Extensions-5.0.zip](https://marketplace.sitecore.net/services/~/download/E988B12D15D74CCA83ADBFD0CA56192E.ashx?data=Sitecore%20PowerShell%20Extensions-5.0&itemId=6aaea046-83af-4ef1-ab91-87f5f9c1aa57)
- [Sitecore Experience Accelerator 1.8.1 rev. 190319 for 9.1.1.zip](https://dev.sitecore.net/Downloads/Sitecore_Experience_Accelerator/18/Sitecore_Experience_Accelerator_181.aspx)
- Of course, Sitecore's license file - **license.xml**

## How to use

- Open **PowerShell** as **Administrator** then execute the below command
- Change the working directory into `D:\sitecore-and-docker` by the below command

    ```powershell
    Set-Location -Path "D:\sitecore-and-docker"
    ```

### Build images

- Change the working directory into `sitecore-xp0-images` folder

    ```powershell
    Set-Location -Path ".\sitecore-xp0-images`
    ```

- Let's build the docker's images for Sitecore by executing the below command

    ```powershell
    .\docker.ps1
    ```

### Install Sitecore

- The Sitecore's sites and services are also installed while starting the docker's containers. But before starting container, we have to modify some configuration values in `docker-run.ps1` to match with current environment.

    ```powershell
    [string] $SitecoreInstancePrefix = "sc911",
    [string] $MainHostVolumePath = "E:\SitecoreDocker",
    [string] $CertExportSecret = "PoqNCUErvc",
    [int] $PortInitialize = 9111,
    [string] $SitecoreProjectSource = "",
    ```
    > **Explainations:**
    > - `$MainHostVolumePath`: where data from docker's container is persisted (also know as _Mount Volume_)
    > - `$PortInitialize`: the initial port number that is bounded for docker's containers. Below are example

    | Host  | Port  |
    |---|---|
    | sc911.dev.local | 9111 |
    | sc911_identiyserver.dev.local | 9112 |
    | sc911_xconnect.dev.local | 9113 |
    | sc911_solr | 9114 |
    | sc911_sqlserver | 9115|

    > - `$SitecoreProjectSource`: it's Unicorn Source; since it's usually stored inside project's source code. Leave it's empty if you don't want to deploy the source code

- Change the working directory to the main folder which is `D:\sitecore-and-docker` for example

    ```powershell
    Set-Location -Path "D:\sitecore-and-docker"
    ```
- Let's up the containers by the following command

    ```powershell
    .\docker-run.ps1 -Up
    ```
- Whenever this log appears (See below), it need to use the combination keys `Ctrl + Z + C` to exit the logs screen

    ```text
    sc911.dev.local                       | [---------------- UpdateMasterSXAIndex : SetXml ------------------------------]
    sc911.dev.local                       | [UpdateMasterSXAIndex]:[Update] C:\inetpub\wwwroot\sc911.dev.local\App_Config\Modules\SXA\Z.Foundation.Overrides\Sitecore.XA.Foundation.Search.Solr.config
    sc911.dev.local                       | [UpdateMasterSXAIndex]:[Update] //configuration/sitecore/contentSearch/configuration/indexes/index[@id='sitecore_sxa_master_index']/param[@desc='core'] => sc911_sxa_master_index
    sc911.dev.local                       |
    sc911.dev.local                       | [------------------- UpdateWebSXAIndex : SetXml ------------------------------]
    sc911.dev.local                       | [UpdateWebSXAIndex]:[Update] C:\inetpub\wwwroot\sc911.dev.local\App_Config\Modules\SXA\Z.Foundation.Overrides\Sitecore.XA.Foundation.Search.Solr.config
    sc911.dev.local                       | [UpdateWebSXAIndex]:[Update] //configuration/sitecore/contentSearch/configuration/indexes/index[@id='sitecore_sxa_web_index']/param[@desc='core'] => sc911_sxa_web_index
    sc911.dev.local                       |
    sc911.dev.local                       | [-------------------- UpdateSolrSchema : SitecoreUrl -------------------------]
    sc911.dev.local                       | [UpdateSolrSchema]:[Authenticating] https://sc911.dev.local:9111/sitecore/admin/PopulateManagedSchema.aspx?indexes=all
    sc911.dev.local                       | [UpdateSolrSchema]:[Requesting] https://sc911.dev.local:9111/sitecore/admin/PopulateManagedSchema.aspx?indexes=all
    sc911.dev.local                       | [UpdateSolrSchema]:[Success] Completed Request
    sc911.dev.local                       | [TIME] 00:06:09
    sc911.dev.local                       | IIS Started...
    ```
- Change the working directory to `D:\sitecore-and-docker`, then execute post steps

    ```powershell
    .\docker-run.ps1 -ExecutePostStep
    ```
    > **The post steps are:**
    > - Add host entries to hosts file (i.e. `sc911.dev.local`); its IP address is retrieved from docker
    > - Import the certificate
    > - Restart the docker's container

### Verify the installation

- Let's open the browser with the Url `https://sc911.dev.local:9111`
- Then it will redirect to the Identity Server at `https://sc911_identityserver.dev.local:9112`
- Use **admin/b** to log in

## Resources

- I'm inspired by the repository - [Repository of Sitecore Docker base images](https://github.com/sitecoreops/sitecore-images)
- [USING THE PKCS #12 (.PFX) FORMAT FOR SOLR SSL SECURITY](https://blogs.perficientdigital.com/2018/08/20/using-the-pkcs12-pfx-format-for-solr-ssl-security/)
- [Microsoft/dotnet-framework-docker](https://github.com/Microsoft/dotnet-framework-docker/blob/master/4.7.2/runtime/windowsservercore-ltsc2019/Dockerfile)
- [Microsoft/aspnet-docker](https://github.com/Microsoft/aspnet-docker/blob/master/4.7.2-windowsservercore-1709/runtime/Dockerfile)
- [Debugging Windows containers with Visual Studio](https://medium.com/@marco.fiocco/debugging-windows-containers-with-visual-studio-yes-also-c-apps-740f6e1965b8)
- [Instances and Ports with PowerShell](https://sqldbawithabeard.com/2015/04/22/instances-and-ports-with-powershell/)
- [Change SQL Server default TCP port](https://stackoverflow.com/questions/54387592/change-sql-server-default-tcp-port)
- [View logs output from docker-compose command](https://stackoverflow.com/questions/37195222/how-to-view-log-output-using-docker-compose-run)
- [How to convert a Sitecore package into a WDP package](https://sitecore.stackexchange.com/questions/18703/how-to-convert-a-sitecore-package-into-a-wdp-package)