Import-Module ActiveDirectory

Set-ADDefaultDomainPasswordPolicy -Identity wsc2024.local -ComplexityEnabled $False -MinPasswordLength 4


New-ADOrganizationalUnit -Name "HQ" -Path "DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "Groups" -Path "OU=HQ,DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "IT" -Path "OU=HQ,DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "Marketing" -Path "OU=HQ,DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "Finance" -Path "OU=HQ,DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=IT,OU=HQ,DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Marketing,OU=HQ,DC=wsc2024,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "OU=Finance,OU=HQ,DC=wsc2024,DC=local"


$users = @('Rooney Dominguez',
    'Hamilton Cooley',
    'Adele Jimenez',
    'Lydia Callahan',
    'Kylie Carter',
    'Hayley Cunningham',
    'Sharon Hoover',
    'William Hull',
    'Uma Williams',
    'Shea Hogan',
    'Brendan Moss',
    'Kane Mcconnell',
    'Roary Page',
    'Maggy Clemons',
    'Nigel Weiss',
    'Cadman Rodriquez',
    'Reese Terry',
    'Quon Beasley',
    'Haviva French',
    'Craig Martinez'
)
Write-Host "Create users"
foreach ($u in $users){
    $item = $u.Split(" ")
    $username = $item[1].ToLower()
    New-ADUser -Name $u -SamAccountName $username -UserPrincipalName "$username@wsc2024.local" -AccountPassword (ConvertTo-SecureString "Skills39" -AsPlainText -Force) -Enable $true
}

$Logonhours = [byte[]]$LogonHours = @(0,255,3, 0,255,3, 0,255,3, 0,255,3, 0,255,3, 0,255,3, 0,255,3)
Set-ADUser -Identity "terry" -replace @{logonhours = $Logonhours}

foreach ($group in @('Marketing', 'IT', 'Finance')) {
    New-ADGroup -Name "GL-$group" -SamAccountName "GL-$group" -GroupCategory Security -GroupScope Global -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"
}

Add-ADGroupMember -Identity GL-IT -Members moss,page,terry,martinez
Add-ADGroupMember -Identity GL-Marketing -Members weiss,hogan,jimenez
Add-ADGroupMember -Identity GL-Finance -Members french,hull,carter,dominguez

New-ADGroup -Name "DL-FS_Finance-RW" -SamAccountName "DL-FS_Finance-RW" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"
New-ADGroup -Name "DL-FS_Finance-RO" -SamAccountName "DL-FS_Finance-RO" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"

New-ADGroup -Name "DL-FS_Marketing-RW" -SamAccountName "DL-FS_Marketing-RW" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"
New-ADGroup -Name "DL-FS_Marketing-RO" -SamAccountName "DL-FS_Marketing-RO" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"
New-ADGroup -Name "DL-FS_Marketing-Project-Alpha-RW" -SamAccountName "DL-FS_Marketing-Project-Alpha-RW" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"

Add-ADGroupMember -Identity "DL-FS_Marketing-RW" -Members GL-Marketing
Add-ADGroupMember -Identity "DL-FS_Marketing-Project-Alpha-RW" -Members weiss

Write-Host "Create GPO"
$gpo = New-GPO -Name "WSC2024_DO_NOT_ALLOW_REGEDIT"
Set-GPRegistryValue -Name "WSC2024_DO_NOT_ALLOW_REGEDIT" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName DisableRegistryTools -Type DWord -Value 2
New-GPLink -Guid $gpo.Id -Target "DC=wsc2024,DC=local" -LinkEnabled No -Order 1
Set-GPPermissions -Name "WSC2024_DO_NOT_ALLOW_REGEDIT" -TargetName "GL-Marketing" -PermissionLevel GpoApply -TargetType 'Group'
dsacls "cn={$($gpo.id)},cn=policies,$((Get-ADDomain).SystemsContainer)" /R "Authenticated Users"

$gpo = New-GPO -Name "WSC2024_Proxy"
Set-GPRegistryValue -Name "WSC2024_Proxy" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName ProxyServer -Type String -Value "proxy.wsc2024.local:3128"
Set-GPRegistryValue -Name "WSC2024_Proxy" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName ProxyEnable -Type DWord -Value 1
Set-GPRegistryValue -Name "WSC2024_Proxy" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -ValueName ProxyOverride -Type String -Value "*.wsc2024.local;10.*;"
New-GPLink -Guid $gpo.Id -Target "DC=wsc2024,DC=local" -LinkEnabled Yes -Order 2

Write-Host "Create DNS reverse zones"
Add-DnsServerPrimaryZone -NetworkID "10.1.64.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "10.1.0.0/23" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "10.1.128.0/25" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "2001:db8:cafe:200::/64" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "2001:db8:cafe:100::/64" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "2001:db8:cafe:150::/64" -ReplicationScope "Forest"


Add-DnsServerResourceRecordA -Name "lnx01" -ZoneName "wsc2024.local" -IPv4Address "10.1.64.10" -CreatePtr
Add-DnsServerResourceRecordA -Name "lnx02" -ZoneName "wsc2024.local" -IPv4Address "10.1.64.11" -CreatePtr
Add-DnsServerResourceRecordA -Name "lnx03" -ZoneName "wsc2024.local" -IPv4Address "10.1.64.12" -CreatePtr
Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "lnx01.wsc2024.local" -ZoneName "wsc2024.local"
Add-DnsServerResourceRecordCName -Name "app" -HostNameAlias "lnx01.wsc2024.local" -ZoneName "wsc2024.local"
Add-DnsServerResourceRecordCName -Name "proxy" -HostNameAlias "lnx03.wsc2024.local" -ZoneName "wsc2024.local"

Add-DnsServerResourceRecordAAAA -Name "lnx01" -ZoneName "wsc2024.local" -AllowUpdateAny -IPv6Address "2001:db8:cafe:200::10" -CreatePtr
Add-DnsServerResourceRecordAAAA -Name "lnx02" -ZoneName "wsc2024.local" -AllowUpdateAny -IPv6Address "2001:db8:cafe:200::11" -CreatePtr
Add-DnsServerResourceRecordAAAA -Name "lnx03" -ZoneName "wsc2024.local" -AllowUpdateAny -IPv6Address "2001:db8:cafe:200::12" -CreatePtr

Add-DnsServerConditionalForwarderZone -Name "wsc2024.org" -ReplicationScope "Forest" -MasterServers 2001:db8:cafe:200::10,10.1.64.10
(Get-DnsServerForwarder).IPAddress | foreach { Remove-DnsServerForwarder -IPAddress $_ -Force -Confirm:$false}
Add-DnsServerForwarder -IPAddress 2001:AB12:10::ef,9.9.9.9

Write-Host "Create new share"
New-Item -Path 'c:\Share' -ItemType Directory
$financeFolder = 'c:\Share\Finance'
$marketingFolder = 'c:\Share\Marketing'
New-Item -Path $financeFolder -ItemType Directory
New-Item -Path $marketingFolder -ItemType Directory

New-SMBShare –Name Finance –Path $financeFolder -NoAccess Everyone -FolderEnumerationMode "AccessBased"
New-SMBShare –Name Marketing –Path $marketingFolder –FullAccess Everyone -FolderEnumerationMode "Unrestricted"

Write-Host "Set file permissions"
$acl = Get-Acl -Path $financeFolder
$everyone = New-Object System.Security.Principal.NTAccount("Everyone")
# Define Full Control Group
$fcRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\GL-IT","FullControl","ContainerInherit,ObjectInherit","None","Allow")
# Define Modify Group
$mdRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\DL-FS_Finance-RW","Modify","ContainerInherit,ObjectInherit","None","Allow")
# Define Read Only Group
$roRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\DL-FS_Finance-RO","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow")
# Disable Inheritance
$acl.SetAccessRuleProtection($true,$false)
$acl.PurgeAccessRules($everyone)
# Add Full Control Rule
$acl.SetAccessRule($fcRule)
# Add Modify Rule
$acl.SetAccessRule($mdRule)
# Add Read Only Rule
$acl.SetAccessRule($roRule)

Set-Acl -Path $financeFolder -AclObject $acl

Write-Host "Set file permissions"
$acl = Get-Acl -Path $marketingFolder
$everyone = New-Object System.Security.Principal.NTAccount("Everyone")
# Define Full Control Group
$fcRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\GL-IT","FullControl","ContainerInherit,ObjectInherit","None","Allow")
# Define Modify Group
$mdRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\DL-FS_Marketing-RW","Modify","ContainerInherit,ObjectInherit","None","Allow")
# Define Read Only Group
$roRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\DL-FS_Marketing-RO","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow")
# Disable Inheritance
$acl.SetAccessRuleProtection($true,$false)
$acl.PurgeAccessRules($everyone)
# Add Full Control Rule
$acl.SetAccessRule($fcRule)
# Add Modify Rule
$acl.SetAccessRule($mdRule)
# Add Read Only Rule
$acl.SetAccessRule($roRule)

Set-Acl -Path $marketingFolder -AclObject $acl

$alpha_folder = "$marketingFolder\PROJECT_ALPHA"
New-Item -Path $alpha_folder -ItemType Directory
Write-Host "Set file permissions"
$acl = Get-Acl -Path $alpha_folder
# Define Full Control Group
$fcRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\GL-IT","FullControl","ContainerInherit,ObjectInherit","None","Allow")
# Define Modify Group
$mdRule = New-Object System.Security.AccessControl.FileSystemAccessRule("WSC2024\DL-FS_Marketing-Project-Alpha-RW","Modify","ContainerInherit,ObjectInherit","None","Allow")
# Disable Inheritance
$acl.SetAccessRuleProtection($true,$false)
$acl.PurgeAccessRules($everyone)
# Add Full Control Rule
$acl.SetAccessRule($fcRule)
# Add Modify Rule
$acl.SetAccessRule($mdRule)

Set-Acl -Path $alpha_folder -AclObject $acl

# Block CSV file
New-FsrmFileGroup -Name "WSC2024_Blacklist" -IncludePattern @("*.csv", "*.html")
New-FsrmFileScreen -Path $marketingFolder -IncludeGroup "WSC2024_Blacklist" -Active