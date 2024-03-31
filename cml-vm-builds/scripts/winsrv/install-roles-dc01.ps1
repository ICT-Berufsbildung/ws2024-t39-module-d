Write-Host "Install Windows Roles"

# Install Windows Roles and features
Install-WindowsFeature DNS -IncludeManagementTools -Verbose
Install-Windowsfeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name GPMC
Install-Windowsfeature -Name FS-FileServer,FS-Resource-Manager -IncludeManagementTools

Install-ADDSForest -DomainName "wsc2024.local" -DomainNetBiosName "wsc2024" -NoDnsOnNetwork -InstallDns:$true -NoRebootOnCompletion:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "Skills39" -AsPlainText -Force) -Confirm:$false