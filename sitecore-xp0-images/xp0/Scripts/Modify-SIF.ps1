param (
    [string] $SitecoreInstallPath
)

$JsonFile = Join-Path -Path "$($SitecoreInstallPath)" -ChildPath "sitecore-XP0.json"

$config = Get-Content -Path "$($JsonFile)" | Where-Object { $_ -notmatch '^\s*\/\/'} | Out-String | ConvertFrom-Json;


### Add 'Port' parameter
$Port = @{
    Type = 'int'
    DefaultValue = ''
    Description = 'The port to bind to.'
}
$config.Parameters | Add-Member -Name "Port" -Value $Port -MemberType NoteProperty;

### Add 'SSLCert' parameter
$SSLCert = @{
    Type         = 'string'
    DefaultValue = ''
    Description  = 'The certificate to use for HTTPS web bindings. Provide the name or the thumbprint. If not provided a certificate will be generated.'
}
$config.Parameters | Add-Member -Name "SSLCert" -Value $SSLCert -Type NoteProperty

### Add 'Security.SSL.CertificateThumbprint' variable
If ($null -eq $config.Variables.'Security.SSL.CertificateThumbprint') {
    $CertificateThumbprint = "[GetCertificateThumbprint(parameter('SSLCert'), 'Cert:\Localmachine\My')]"
    $config.Variables | Add-Member -Name 'Security.SSL.CertificateThumbprint' -Value $CertificateThumbprint -Type NoteProperty
}

### Add/Update tasks

$config.Tasks.InstallWDP.Params.Arguments | Add-Member -Name 'Skip' -Value @(@{'ObjectName' = 'dbDacFx'}, @{'ObjectName' = 'dbFullSql'}) -MemberType NoteProperty;

$config.Tasks.CreateWebsite.Params | Add-Member -Name 'Port' -Value "[parameter('port')]" -MemberType NoteProperty;

$config.Tasks.UpdateSolrSchema.Params.SitecoreInstanceRoot = "[concat('https://', concat(parameter('DnsName'), concat(':', parameter('Port'))))]"

$RemoveDefaultBindingTask = @{
    Description = "Removes the default *:80 web binding"
    Type = "WebBinding"
    Params = @{
        SiteName = "[parameter('SiteName')]"
        Remove = @(
            @{
                Port = "[parameter('port')]"
                IPAddress = "*"
            })
    }
}

$CreateBindingsWithThumbprintTask = @{
    Description = "Configures the site bindings for the website."
        Type = "WebBinding"
        Params = @{
            SiteName = "[parameter('SiteName')]"
            Add = @(
                @{
                    HostHeader = "[parameter('SiteName')]"
                    Protocol = "https"
                    SSLFlags = 1
                    Port = "[parameter('Port')]"
                    Thumbprint = "[variable('Security.SSL.CertificateThumbprint')]"
                })
        }
        Skip = "[not(parameter('SSLCert'))]"
}

$NewTasks = New-Object PSCustomObject

$config.Tasks.PSObject.Properties | ForEach-Object {
    $taskName = $_.Name
    Write-Host $taskName
    
    If ($taskName -eq "CreateBindings") {
        $NewTasks | Add-Member -MemberType NoteProperty -Name "RemoveDefaultBinding" -Value $RemoveDefaultBindingTask
        $NewTasks | Add-Member -MemberType NoteProperty -Name "CreateBindingsWithThumbprint" -Value $CreateBindingsWithThumbprintTask
    } else {
        $NewTasks | Add-Member -MemberType NoteProperty -Name $taskName -Value $_.Value
    }
}

$config.Tasks = $NewTasks

ConvertTo-Json $config -Depth 50 | Set-Content -Path $JsonFile