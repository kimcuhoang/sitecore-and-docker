param (
    [string] $SolrPort,
    [string] $SolrCertSecret,
    [string] $SolrInstallPath,
    [string] $SolrDataPath,
    [string] $DefaultSolrCorePrefix,
    [string] $SitecoreInstancePrefix,
    [string] $CertPath
)

Function Update-Hosts-File {
    param(
        [string] $IPAddress = "127.0.0.1",
        [string] $HostName
    )
    $hostsFile = Join-Path -Path $env:windir -ChildPath "system32\drivers\etc\hosts"
    $pattern = '^\s*' + [Regex]::Escape($IPAddress) + '\s*' + [Regex]::Escape($HostName) + '\s*$'
    $existingEntries = @((Get-Content -Path $hostsFile -Encoding UTF8)) -match $pattern
    if($existingEntries.Count -eq 0) {
        Add-Content -Path $hostsFile -Value "`n$IPAddress`t$HostName" -Encoding UTF8
    }
}


#########################################################################
#########################################################################

$SolrHostName = "$($SitecoreInstancePrefix)_solr"
$SolrUrl = "https://$($SolrHostName):$($SolrPort)/solr"

Write-Host "=====> Generate Certificate..................."
& "C:\Scripts\Generate-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                        -CertExportPath $CertPath `
                                        -CertExportSecret $SolrCertSecret

Write-Host "=====> Import Certificate..................."
& "C:\Scripts\Import-Certificate.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                                        -CertExportPath $CertPath `
                                        -CertExportSecret $SolrCertSecret
Write-Host "=====> Enable SSL for Solr..................."
& "C:\Scripts\Enable-Ssl.ps1" -SitecoreInstancePrefix $SitecoreInstancePrefix `
                              -SolrHostName $SolrHostName `
                              -SolrInstallPath $SolrInstallPath `
                              -CertExportSecret $SolrCertSecret `
                              -CertExportPath $CertPath

Update-Hosts-File -HostName $SolrHostName

If ((Get-ChildItem "$($SolrDataPath)" | Measure-Object).Count -eq 0) {

    Write-Host "### No Sitecore Solr cores found in $($SolrDataPath), seeding clean cores from $($SolrInstallPath)..."
    Copy-Item -Path "$($SolrInstallPath)\Server\Solr\*" -Destination "$($SolrDataPath)" -Recurse
    Remove-Item -Path "$($SolrDataPath)\*" -Include "write.lock"

    Get-ChildItem -Path $($SolrDataPath) -Directory | Where-Object { $_.BaseName -match "$($DefaultSolrCorePrefix)"} | ForEach-Object {
        $newname = $_.BaseName.Replace("$($DefaultSolrCorePrefix)", "$($SitecoreInstancePrefix)")
        $core_properties = Get-Content -Path "$($_.FullName)\core.properties"
        $content = $core_properties | ForEach-Object { $_ -replace 'name=.*?$', "name=$($newname)" }
        $content | Set-Content -Path "$($_.FullName)\core.properties"
        Rename-Item -Path $_.FullName -NewName $newname
    }
    
}

$env:SOLR_HOME = $SolrDataPath
Write-Host "#### Starting Solr at $($SolrUrl)"
& "$($SolrInstallPath)\bin\solr.cmd" start -port $SolrPort