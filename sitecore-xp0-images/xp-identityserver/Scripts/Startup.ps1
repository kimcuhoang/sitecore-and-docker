param (
    [string] $SitecoreInstancePrefix,
    [int] $SitecoreIdentityServerPort,
    [string] $SitecoreIdentityServerClientSecret,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $SitecoreInstallPath,
    [string] $SqlServerPort,
    [string] $SqlAdminUser,
    [string] $SqlAdminSecret,
    [int] $SitecoreSitePort
)

$SitecoreSiteHostName = "$($SitecoreInstancePrefix).dev.local"
$SitecoreIdentityServerHostName = "$($SitecoreInstancePrefix)_identityserver.dev.local"
$SqlServerHostName = "$($SitecoreInstancePrefix)_sqlserver"

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportSecret


$SitecoreIdentityServerUrl = "https://$($SitecoreIdentityServerHostName)"

If ($SitecoreIdentityServerPort -ne 443) {
    $SitecoreIdentityServerUrl = "$($SitecoreIdentityServerUrl):$($SitecoreIdentityServerPort)"
}

$SitecoreIdentityServerWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreIdentityServerHostName)"
$WebConfig = Join-Path -Path $SitecoreIdentityServerWebRoot -ChildPath "web.config"

If (-not (Test-Path -Path $WebConfig)) {
    $SitecoreSiteUrl = "http://$($SitecoreSiteHostName)"
    If ($SitecoreSitePort -ne 80) {
        $SitecoreSiteUrl = "http://$($SitecoreSiteHostName):$($SitecoreSitePort)"
    }

    Write-Host "#### Install Sitecore's Identity Server at $($SitecoreIdentityServerUrl)"

    If ($SqlServerPort -ne "1433") {
        $SqlServerHostName = "$($SqlServerHostName), $($SqlServerPort)"
    }

    Install-SitecoreConfiguration `
            -Path (Join-Path -Path $SitecoreInstallPath -ChildPath 'IdentityServer.json') `
            -Package (Join-Path -Path $SitecoreInstallPath -ChildPath 'Sitecore_identityserver.scwdp.zip') `
            -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath 'license.xml') `
            -Sitename $SitecoreIdentityServerHostName `
            -Port $SitecoreIdentityServerPort `
            -SqlServer $SqlServerHostName `
            -SqlDbPrefix $SitecoreInstancePrefix `
            -SqlCoreUser $SqlAdminUser -SqlCorePassword $SqlAdminSecret `
            -PasswordRecoveryUrl $SitecoreSiteUrl `
            -AllowedCorsOrigins $SitecoreSiteUrl `
            -ClientSecret $SitecoreIdentityServerClientSecret `
            -SitecoreIdentityCert $SitecoreInstancePrefix `
            -Skip "CreateHostHeader"
}

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

Write-Host "IIS Started..."
while ($true) { Start-Sleep -Seconds 3600 }

& C:\ServiceMonitor.exe w3svc