# Active-Directory-Domain-Services-Setup-Script
PowerShell script to automate Active Directory Domain Services (AD DS) installation and forest creation.


### Get interface alias
현재 사용 중인 Windows Server는 회사 환경에 한정되기 때문에 무조건 "Ethernet"이 나옵니다.
```$ifAlias = Get-Netadapter | Select-Object -ExpandProperty Name```

### Get ip information
Ethernet 중에 IPv4의 정보를 가져오는 코드 입니다.
```$currentIpInfo = Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4```

### Get ip address
Select-Object는 객체 그대로를 반환하기 때문에 ExpandProperty를 사용하여, 그 속성의 값만 꺼내서 반환하도록 만들었습니다.
```$ipAddress = $currentIpInfo | Select-Object -ExpandProperty IPAddress```

### Get subnet mask
NetIpAddress 부분에서 사용되는 것은 CIDR 형태이기 때문에 출력되는 그대로를 변수에 담았습니다.
```$prefix = $currentIpInfo | Select-Object -ExpandProperty PrefixLength```

### Get default gateway
```$defaultGateway = (Get-netIPConfiguration -InterfaceAlias $ifAlias).IPv4DefaultGateway.NextHop```

### 자동으로 dhcp에서 정보를 받아와서 ip를 설정하는 옵션을 끕니다.
회사 환경에서는 가상환경이기 때문에 중간에 네트워크가 끊겨 연결이 끊길 수 있습니다.
실무에서 빠르게 환경을 구현해야하기 때문에 ErrorAction을 SilentlyContinue로 변경했습니다.
```Set-NetIPInterface -InterfaceAlias $ifAlias -Dhcp Disabled -ErrorAction SilentlyContinue```

### 새로운 IP주소를 생성합니다.(Static)
```New-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $ipAddress -PrefixLength $prefix -DefaultGateway $defaultGateway -ErrorAction SilentlyContinue```

### IP주소를 적용합니다.
```Set-DnsClientServerAddress -InterfaceAlias $ifAlias -ServerAddresses $ipAddress```

###AD Domain Service를 설치합니다
```Install-WindowsFeature AD-Domain-Services -IncludeManagementTools -Verbose```
```Import-Module ADDSDeployment -ErrorAction SilentlyContinue```

### Forest를 설정합니다.
```$dsrm = Read-Host "DSRM password를 입력해주세요" -AsSecureString```
```$domainName = Read-Host "Domain Name을 입력해주세요.예시)abc.com" -AsSecureString```
```$netBios = Read-Host "Net Bios를 입력해주세요. 예시)ABC" -AsSecureString```
```Install-ADDSForest -DomainName $domainName  -DomainNetbiosName $netBios -SafeModeAdministratorPassword $dsrm -InstallDns -Force```
