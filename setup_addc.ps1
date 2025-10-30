Write-Host "`n[1/3] Network Configuration 시작`n"

$ifAlias = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1 -ExpandProperty Name)
$currentIpInfo = Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 | Select-Object -First 1

$ipAddress = $currentIpInfo.IPAddress
$prefix = $currentIpInfo.PrefixLength
$defaultGateway = (Get-NetIPConfiguration -InterfaceAlias $ifAlias).IPv4DefaultGateway.NextHop

Write-Host "Interface        : $ifAlias"
Write-Host "Current IP       : $ipAddress"
Write-Host "Prefix (CIDR)    : /$prefix"
Write-Host "Default Gateway  : $defaultGateway"

Write-Host "`nDHCP 비활성화 및 고정 IP 전환 중... (RDP 연결 시 주의)"
Set-NetIPInterface -InterfaceAlias $ifAlias -Dhcp Disabled -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $ipAddress -PrefixLength $prefix -DefaultGateway $defaultGateway -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias $ifAlias -ServerAddresses $ipAddress

Write-Host "Network configuration completed.`n"

Write-Host "[2/3] Installing Active Directory Domain Services`n"
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Verbose
Import-Module ADDSDeployment -ErrorAction SilentlyContinue
Write-Host "AD DS module loaded successfully.`n"

Write-Host "[3/3] Configuring AD Forest`n"
$dsrm = Read-Host "Enter DSRM password" -AsSecureString
Install-ADDSForest -DomainName "jestad.com" -DomainNetbiosName "JESTAD" -SafeModeAdministratorPassword $dsrm -InstallDns -Force

Write-Host "`nAD DS installation and forest configuration complete."
Write-Host "The server will reboot automatically after setup."
