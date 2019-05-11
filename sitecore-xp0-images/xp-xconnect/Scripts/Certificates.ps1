param (
    [string] $CertName,
    [string] $CertExportPath,
    [string] $CertExportSecret,
    [switch] $Import
)

$secret = ConvertTo-SecureString -String $CertExportSecret -Force -AsPlainText;
$CertPfxFile = "$($CertName).pfx"
$CertPfxPath = Join-Path -Path $CertExportPath -ChildPath $CertPfxFile

If ($Import) {
    $CertStore = 'Cert:\LocalMachine\Root'
    $cert = Get-ChildItem -Path $CertStore | Where-Object { $_.subject -eq "CN=$($CertName)"}
    If ($null -eq $cert) {
        Import-PfxCertificate -FilePath $CertPfxPath -CertStoreLocation $CertStore -Password $secret;
    }
} Else {
    $CertStore = 'Cert:\LocalMachine\My'
    $cert = Get-ChildItem -Path $CertStore | Where-Object { $_.subject -eq "CN=$($CertName)"}

    if ($null -eq $cert) {

        if (Test-Path -Path $CertPfxPath) {
            Write-Host "######### Importing $($CertPfxFile) since it's existing ######################"

            Import-PfxCertificate -FilePath $CertPfxPath -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $secret;
            Import-PfxCertificate -FilePath $CertPfxPath -CertStoreLocation 'Cert:\LocalMachine\My' -Password $secret;
        } else {
            Write-Host "######### Generating $($CertPfxFile) since it's not existed ##################"

            $cert = New-SelfSignedCertificate `
                    -CertStoreLocation $CertStore -DnsName $CertName `
                    -KeyExportPolicy Exportable -Provider 'Microsoft Enhanced RSA and AES Cryptographic Provider'
            
            Export-PfxCertificate -cert $cert -FilePath $CertPfxPath -Password $secret

            Import-PfxCertificate -FilePath $CertPfxPath -CertStoreLocation 'Cert:\LocalMachine\Root' -Password $secret;
        }
        
    } else {
        If (-not (Test-Path -Path $CertPfxPath)) {
            Export-PfxCertificate -cert $cert -FilePath $CertPfxPath -Password $secret
        }
    }
}

