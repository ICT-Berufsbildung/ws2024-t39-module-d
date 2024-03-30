Import-Module ActiveDirectory

Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $False -MinPasswordLength 4


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
    New-ADUser -Name $u -SamAccountName $item[1].ToLower() -AccountPassword (ConvertTo-SecureString "Skills39" -AsPlainText -Force) -Enable $true
}

foreach ($group in @('Marketing', 'IT', 'Finance')) {
    New-ADGroup -Name "GL-$group" -SamAccountName "GL-$group" -GroupCategory Security -GroupScope Global -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"
}

Add-ADGroupMember -Identity GL-IT -Members moss,page,terry,martinez
Add-ADGroupMember -Identity GL-Marketing -Members weiss,hogan,jimenez
Add-ADGroupMember -Identity GL-Finance -Members french,hull,carter,dominguez

New-ADGroup -Name "DL-FS_Finance-RW" -SamAccountName "DL-FS_Finance-RW" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"
New-ADGroup -Name "DL-FS_Finance-RO" -SamAccountName "DL-FS_Finance-RO" -GroupCategory Security -GroupScope DomainLocal -Path "OU=Groups,OU=HQ,DC=wsc2024,DC=local"


Add-ADGroupMember -Identity "DL-FS_Finance-RW" -Members GL-Finance

Write-Host "Create DNS reverse zones"
Add-DnsServerPrimaryZone -NetworkID "10.1.64.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "10.1.0.0/23" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "10.1.128.0/25" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "2001:db8:cafe:200::/64" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "2001:db8:cafe:100::/64" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "2001:db8:cafe:150::/64" -ReplicationScope "Forest"


Add-DnsServerResourceRecordA -Name "lnx01" -ZoneName "wsc2024.local" -IPv4Address "10.1.64.10" -CreatePtr
Add-DnsServerResourceRecordA -Name "lnx02" -ZoneName "wsc2024.local" -IPv4Address "10.1.64.11" -CreatePtr
Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "lnx01.wsc2024.local" -ZoneName "wsc2024.local"

Add-DnsServerResourceRecordAAAA -Name "lnx01" -ZoneName "wsc2024.local" -AllowUpdateAny -IPv6Address "2001:db8:cafe:200::10" -CreatePtr
Add-DnsServerResourceRecordAAAA -Name "lnx02" -ZoneName "wsc2024.local" -AllowUpdateAny -IPv6Address "2001:db8:cafe:200::11" -CreatePtr

Write-Host "Create new share"
New-Item -Path 'c:\Share' -ItemType Directory
New-Item -Path 'c:\Share\IT' -ItemType Directory
New-SMBShare –Name IT-Departement –Path 'c:\Share\IT' –FullAccess Everyone
