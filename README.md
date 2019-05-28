# Playing Sitecore-9.1.1 (xp0) with Docker

## Prerequisites

- Windows 10 Pro Version 1809
- [Docker for Windows](https://hub.docker.com/editions/community/docker-ce-desktop-windows)
  - Switch to Windows Container

## Preparations

1. Suppose this repo is cloned on our local at - `D:\sitecore-and-docker`
1. Download the following tools then put into `sitecore-xp0-images\Install` folder
   - [java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip](https://github.com/ojdkbuild/ojdkbuild/releases/download/1.8.0.161-1/java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip)
   - [solr-7.2.1.zip](http://archive.apache.org/dist/lucene/solr/7.2.1/solr-7.2.1.zip)
   - [SQLServer2017-DEV-x64-ENU.exe](https://go.microsoft.com/fwlink/?linkid=840945)
   - [SQLServer2017-DEV-x64-ENU.box](https://go.microsoft.com/fwlink/?linkid=840944)
   - [WebDeploy_amd64_en-US.msi](https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi)
   - [rewrite_amd64_en-US.msi](https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi)
   - [VC_redist.x64.exe](https://aka.ms/vs/15/release/VC_redist.x64.exe)
   - [dotnet-hosting-2.1.3-win.exe](https://dotnet.microsoft.com/download/thank-you/dotnet-runtime-2.1.9-windows-hosting-bundle-installer)
   - [vs_remotetool.exe](https://aka.ms/vs/15/release/RemoteTools.amd64ret.enu.exe)
   - [Sitecore 9.1.1 rev. 002459 (WDP XP0 packages).zip](https://dev.sitecore.net)
1. Also, put our Sitecore license - **license.xml** into `Assets` folder

## How to use

- Suppose that the repository is cloned at `D:\sitecore-and-docker` in local
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
    [string] $SitecoreInstancePrefix = "habitat",
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
    | habitat.dev.local | 9111 |
    | habitat_identiyserver.dev.local | 9112 |
    | habitat_xconnect.dev.local | 9113 |
    | habitat_solr | 9114 |
    | habitat_sqlserver | 9115|

    > - `$SitecoreProjectSource`: it's Unicorn Source; since it's usually stored inside project's source code. Leave it's empty if you don't want to deploy the source code (i.e. **Habitat**)

- Change the working directory to the main folder which is `D:\sitecore-and-docker` for example

    ```powershell
    Set-Location -Path "D:\sitecore-and-docker"
    ```
- Let's up the containers by the following command

    ```powershell
    .\docker-run.ps1 -Up
    ```
- Whenever this log appears, it need to use the combination keys `Ctrl + Z + C` to exit the logs screen

    ```text
    [-------------------- UpdateSolrSchema : SitecoreUrl -------------------------]
    [UpdateSolrSchema]:[Authenticating] http://habitat.dev.local:9111/sitecore/admin/PopulateManagedSchema.aspx?indexes=all
    [UpdateSolrSchema]:[Requesting] http://habitat.dev.local:9111/sitecore/admin/PopulateManagedSchema.aspx?indexes=all
    [UpdateSolrSchema]:[Success] Completed Request

    [----------- DisplayPassword [Skipped] : WriteInformation --------------------]
    [TIME] 00:07:12
    ########## Sitecore: habitat.dev.local installed successfully
    IIS Started...
    ```
- Then execute post steps

    ```powershell
    .\docker-run.ps1 -ExecutePostStep
    ```
    > **The post steps are:**
    > - Add host entries to hosts file (i.e. `habitat.dev.local`); its IP address is retrieved from docker
    > - Import the certificate
    > - Restart the docker's container

### Verify the installation

- Let's open the browser with the Url `http://habitat.dev.local:9111`
- Then it will redirect to the Identity Server at `https://habitat_identityserver.dev.local:9112`
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