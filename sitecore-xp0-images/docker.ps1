
$ErrorActionPreference = "STOP"
$ProgressPreference = "SilentlyContinue"

$AssetFolder = Resolve-Path "$($PSScriptRoot)\assets"
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

$PrerequisiteFiles | ForEach-Object {
    $package = Get-Item -Path (Join-Path -Path "$($AssetFolder)" -ChildPath $_)

    If ($null -eq $package) {
        throw "Could not find $($package)"
    }

    Copy-Item -Path $package.FullName -Destination "$($XpBaseInstallPath)" -Force
}

& docker-compose -f .\docker-compose.yaml build -m 4g