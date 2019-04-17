param (
    [string] $SitecoreInstallPackage,
    [string] $InstallFolder
)

Expand-Archive "$($InstallFolder)\$($SitecoreInstallPackage)" -DestinationPath "$($InstallFolder)"

$SIFConfigurationZip = Get-Item -Path "$($InstallFolder)\XP0 Configuration files*.zip"
Rename-Item $SIFConfigurationZip "$($InstallFolder)\XP0 Configuration files.zip"
Expand-Archive -Path "$($InstallFolder)\XP0 Configuration files.zip" -DestinationPath $InstallFolder
    
$xConnectXP0Zip = Get-Item -Path "$($InstallFolder)\Sitecore*_xp0xconnect.scwdp.zip"
Rename-Item $xConnectXP0Zip "$($InstallFolder)\Sitecore_xp0xconnect.scwdp.zip"

$IdentityServerZip = Get-Item -Path "$($InstallFolder)\Sitecore*_identityserver.scwdp.zip"
Rename-Item $IdentityServerZip "$($InstallFolder)\Sitecore_identityserver.scwdp.zip"
    
$SitecoreSingle = Get-Item -Path "$($InstallFolder)\Sitecore*_single.scwdp.zip"
Rename-Item $SitecoreSingle "$($InstallFolder)\Sitecore_single.scwdp.zip"
