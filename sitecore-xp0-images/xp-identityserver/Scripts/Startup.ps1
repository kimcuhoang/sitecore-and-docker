param (
    [string] $SitecoreIdentityServerHostName,
    [int] $SitecoreIdentityServerPort,
    [string] $SitecoreIdentityServerClientSecret,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [string] $SitecoreInstallPath,
    [string] $SqlServerHostName,
    [string] $SqlServerPort,
    [string] $DatabasePrefix,
    [string] $SqlAdminUser,
    [string] $SqlAdminSecret,
    [string] $SitecoreSiteHostName,
    [int] $SitecoreSitePort
)

& C:\Scripts\Certificates.ps1 -SitecoreIdentityServerHostName $SitecoreIdentityServerHostName `
                              -CertExportPath $CertExportPath `
                              -CertExportSecret $CertExportSecret

$SitecoreIdentityServerWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreIdentityServerHostName)"
$SitecoreIdentityServerUrl = "https://$($SitecoreIdentityServerHostName)"

If ($SitecoreIdentityServerPort -ne 443) {
    $SitecoreIdentityServerUrl = "$($SitecoreIdentityServerUrl):$($SitecoreIdentityServerPort)"
}

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
            -SqlDbPrefix $DatabasePrefix `
            -SqlCoreUser $SqlAdminUser -SqlCorePassword $SqlAdminSecret `
            -PasswordRecoveryUrl $SitecoreSiteUrl `
            -AllowedCorsOrigins $SitecoreSiteUrl `
            -ClientSecret $SitecoreIdentityServerClientSecret `
            -SitecoreIdentityCert $SitecoreIdentityServerHostName `
            -Skip "CreateHostHeader"
}

$w3svcService = Get-Service -Name "w3svc"
If (($null -eq $w3svcService) -or ($w3svcService.Status -ne "Running")) {
    Start-Service w3svc -Verbose
}

& C:\ServiceMonitor.exe w3svc