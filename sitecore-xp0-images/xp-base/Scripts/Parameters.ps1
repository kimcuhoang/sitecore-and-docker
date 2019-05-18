param (
    [string] $SitecoreInstancePrefix
)
$ErrorActionPreference = "STOP"

$JsonConfigPath = "C:\Certificates\$($SitecoreInstancePrefix).json"

If (-not (Test-Path -Path $JsonConfigPath)) {
    throw "Could not find $($JsonConfigPath)"
}

$json = Get-Content -Path $JsonConfigPath -Raw -Encoding Ascii | ConvertFrom-Json

### Parameter of Certificates
$CertExportPassword = $json.CertExportSecret
$CertName = $json.SitecoreInstancePrefix

### Parameters of Solr
$SolrHostName = $json.Solr.Hostname
$SolrPort = $json.Solr.Port
$SolrUrl = $json.Solr.Url
If ($SolrPort -ne 8983) {
    $SolrUrl = "https://$($SolrHostName):$($SolrPort)/solr"
}

### Parameters of SqlServer
$SqlServerHostName = $json.SqlServer.Hostname
$SqlServerPort = $json.SqlServer.Port
$SqlServerForConnectionString = $SqlServerHostName
If ($SqlServerPort -ne "1433") {
    $SqlServerForConnectionString = "$($SqlServerHostName), $($SqlServerPort)"
}
$SqlServerAdminUser = $json.SqlServer.SqlAdminAccount
$SqlServerAdminPassword = $json.SqlServer.SqlAdminPassword

### Paramerters of Sitecore XP site
$SitecoreInstancePrefix = $json.SitecoreInstancePrefix
$SitecoreSite = $json.SitecoreSite.Hostname
$SitecoreSitePort = $json.SitecoreSite.Port
$SitecoreSiteUrl = $json.SitecoreSite.Url
$SitecoreAdminSecret = $json.SitecoreSite.AdminPassword

### Parameter of Sitecore Identity Server site
$SitecoreIdentityServerSite = $json.SitecoreIdentityServerSite.Hostname
$SitecoreIdentityServerSitePort = $json.SitecoreIdentityServerSite.Port
$SitecoreIdentityServerSiteUrl = $json.SitecoreIdentityServerSite.Url
$SitecoreIdentityServerClientSecret = $json.SitecoreIdentityServerSite.ClientSecret

### Parameters of Sitecore xConnect site
$SitecoreXConnectSite = $json.SitecoreXConnectSite.Hostname
$SitecoreXConnectSitePort = $json.SitecoreXConnectSite.Port
$SitecoreXConnectSiteUrl = $json.SitecoreXConnectSite.Url

