param (
    [string] $SqlPort
)

if ($SqlPort -ne "1433") {
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")|Out-Null
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")|Out-Null

    $mc = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $env:COMPUTERNAME
    $Instances = $mc.ServerInstances

    $temp = $Instances[0]
    $temp.ServerProtocols['Tcp'].IPAddresses['IPAll'].IPAddressProperties['TcpPort'].Value = "$($SqlPort)"
    $temp.ServerProtocols['Tcp'].Alter()

    Stop-Service MSSQLSERVER
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -Name tcpport -Value $SqlPort
}

