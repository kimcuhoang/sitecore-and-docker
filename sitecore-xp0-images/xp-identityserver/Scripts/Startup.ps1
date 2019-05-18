param (
    [string] $SitecoreInstancePrefix,
    [string] $CertExportPath,
    [string] $SitecoreInstallPath
)

. "C:\Scripts\Parameters.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix

& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                      -CertExportPath $CertExportPath `
                                      -CertExportSecret $CertExportPassword


$SitecoreIdentityServerWebRoot = Join-Path -Path "C:\inetpub\wwwroot" -ChildPath "$($SitecoreIdentityServerSite)"
$WebConfig = Join-Path -Path $SitecoreIdentityServerWebRoot -ChildPath "web.config"

If (-not (Test-Path -Path $WebConfig)) {

    Write-Host "#### Install Sitecore's Identity Server at $($SitecoreIdentityServerSiteUrl)"

    Install-SitecoreConfiguration `
            -Path (Join-Path -Path $SitecoreInstallPath -ChildPath 'IdentityServer.json') `
            -Package (Join-Path -Path $SitecoreInstallPath -ChildPath 'Sitecore_identityserver.scwdp.zip') `
            -LicenseFile (Join-Path -Path $SitecoreInstallPath -ChildPath 'license.xml') `
            -Sitename $SitecoreIdentityServerSite `
            -Port $SitecoreIdentityServerSitePort `
            -SqlServer $SqlServerForConnectionString `
            -SqlDbPrefix $SitecoreInstancePrefix `
            -SqlCoreUser $SqlServerAdminUser -SqlCorePassword $SqlServerAdminPassword `
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