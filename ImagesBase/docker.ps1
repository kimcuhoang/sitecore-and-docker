$ErrorActionPreference = "STOP"

$AssetFolder = Resolve-Path -Path "..\Assets"

If (-not (Test-Path -Path $AssetFolder)) {
    throw "Could not found $($AssetFolder)"
}

Function Check-Install-Folder-And-Copy-Files {
    param (
        [string] $InstallFolder,
        [string[]] $FileNames,
        [string] $SourceFolder
    )

    If (-not (Test-Path -Path $InstallFolder)) {
        New-Item -Path $InstallFolder -ItemType Directory
    }

    $FileNames | ForEach-Object {
        $file = Join-Path -Path $InstallFolder -ChildPath $_
        If (-not (Test-Path -Path $file)) {
            Copy-Item -Path (Join-Path -Path $SourceFolder -ChildPath $_) -Destination $InstallFolder
        }
    }
}

Function Copy-Assets {
    $InstallationFiles = @{
        Openjdk = "java-1.8.0-openjdk-1.8.0.161-1.b14.ojdkbuild.windows.x86_64.zip"
        Solr = "solr-7.2.1.zip"
        SQLexe = "SQLServer2017-DEV-x64-ENU.exe"
        SQLbox = "SQLServer2017-DEV-x64-ENU.box"
        VcRedist = "vc_redist.x64.exe"
        WebDeploy = "WebDeploy_amd64_en-US.msi"
        RewriteUrl = "rewrite_amd64_en-US.msi"
    }

    ### Validate installation files are existing
    $InstallationFiles.Keys | ForEach-Object {
        $key = $_
        $file = Join-Path -Path $AssetFolder -ChildPath $InstallationFiles[$key]
        If (-not (Test-Path -Path $file)) {
            throw "**** Missing file $($InstallationFiles[$key])"
        }
    }

    ### Copy to relative folder
    Check-Install-Folder-And-Copy-Files -InstallFolder (Join-Path -Path ".\aspnet472" -ChildPath "Install") `
                                        -FileNames @($InstallationFiles["WebDeploy"], $InstallationFiles["VcRedist"], $InstallationFiles["RewriteUrl"]) `
                                        -SourceFolder $AssetFolder
                                        
    Check-Install-Folder-And-Copy-Files -InstallFolder (Join-Path -Path ".\mssqlserver" -ChildPath "Install") `
                                        -FileNames @($InstallationFiles["SQLexe"], $InstallationFiles["SQLbox"]) `
                                        -SourceFolder $AssetFolder    
                                        
    Check-Install-Folder-And-Copy-Files -InstallFolder (Join-Path -Path ".\openjdk_solr" -ChildPath "Install") `
                                        -FileNames @($InstallationFiles["Openjdk"], $InstallationFiles["Solr"]) `
                                        -SourceFolder $AssetFolder   
}


Copy-Assets

& docker-compose -f .\docker-compose.yaml build -m 4g
