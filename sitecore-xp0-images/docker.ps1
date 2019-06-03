
$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

Function Import-SitecoreAzureToolkit-Module {
    $SitecoreAzureToolkit = Get-Item -Path "$($AssetFolder)\Sitecore Azure Toolkit*.zip"
    If ($null -eq $SitecoreAzureToolkit) {
        throw "Not found Sitecore Azure Toolkit package"
    }
    
    $SitecoreAzureToolkitFolder = "$($AssetFolder)\SitecoreAzureToolkit"
    If (-not (Test-Path -Path $SitecoreAzureToolkitFolder)) {
        Expand-Archive -Path $SitecoreAzureToolkit.FullName -DestinationPath "$($SitecoreAzureToolkitFolder)"
    }
    
    Import-Module "$($SitecoreAzureToolkitFolder)\tools\Sitecore.Cloud.Cmdlets.dll" -Force
}

Function Convert-To-SCWDP {
    
    $SitecorePackagesFolder = Join-Path -Path "$($XpBaseInstallPath)" -ChildPath "SitecorePackages"

    If (-not (Test-Path -Path "$($SitecorePackagesFolder)")) {
        New-Item -Path "$($SitecorePackagesFolder)" -ItemType Directory | Out-Null
    }

    $Modules = @("Sitecore Experience Accelerator", "Sitecore PowerShell Extensions")

    $Modules | ForEach-Object {
        $module = Get-Item -Path "$($AssetFolder)\$($_)*.zip"
        

        If ($null -eq $module) {
            throw "Could not find $($_) package"
        }

        $moduleName = $module.Name
        If (-not (Test-Path -Path (Join-Path -Path "$($SitecorePackagesFolder)" -ChildPath $moduleName.Replace("zip", "scwdp.zip")))){
            ConvertTo-SCModuleWebDeployPackage -Path $module.FullName -Destination $SitecorePackagesFolder -Force    
        }
    }
}

Function Copy-Prerequisite-Files {
    
    $PrerequisiteFiles | ForEach-Object {
        $package = Get-Item -Path (Join-Path -Path "$($AssetFolder)" -ChildPath $_)

        If ($null -eq $package) {
            throw "Could not find $($package)"
        }

        Copy-Item -Path $package.FullName -Destination "$($XpBaseInstallPath)" -Force
    }
    
}

$AssetFolder = Resolve-Path "$($PSScriptRoot)\assets"
$PrerequisiteAssetFolder = Join-Path -Path "$($AssetFolder)" -ChildPath "Prerequisite"
$XpBaseInstallPath = Join-Path -Path "$($PSScriptRoot)\xp-base" -ChildPath "Install"

$PrerequisiteFiles = @(
        'java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip',
        'solr-7.2.1.zip',
        'SQLServer2017-DEV-x64-ENU.box',
        'SQLServer2017-DEV-x64-ENU.exe',
        'dotnet-hosting-2.1.3-win.exe',
        'rewrite_amd64_en-US.msi',
        'vc_redist.x64.exe',
        'vs_remotetools.exe',
        'WebDeploy_amd64_en-US.msi',
        'Sitecore 9.1.1 rev. 002459 (WDP XP0 packages).zip',
        'license.xml'
    )

Import-SitecoreAzureToolkit-Module

Convert-To-SCWDP

Copy-Prerequisite-Files

& docker-compose -f .\docker-compose.yaml build -m 4g