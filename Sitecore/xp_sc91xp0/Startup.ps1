param (
    [string] $WebSiteName
)

$originWebRootPath = Join-Path -Path 'C:\inetpub\wwwroot' -ChildPath $WebSiteName
$newWebRootPath = Join-Path -Path "C:\" -ChildPath $WebSiteName
If (-not (Test-Path -Path "$($newWebRootPath)\web.config")) {
    Copy-Item -Path "$($originWebRootPath)\*" -Destination $newWebRootPath -Recurse
}

Import-Module WebAdministration
$PhysicalPath = Get-ItemProperty -Path "IIS:\Sites\$($WebSiteName)" -name "physicalPath"
If ($PhysicalPath -ne $newWebRootPath) {
    Set-ItemProperty -Path "IIS:\Sites\$($WebSiteName)" -name "physicalPath" -value $newWebRootPath
}

& C:\ServiceMonitor.exe w3svc