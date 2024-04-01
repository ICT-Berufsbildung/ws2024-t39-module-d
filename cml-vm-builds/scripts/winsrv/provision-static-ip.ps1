
Write-Host "Set static IP"
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:01:00
$options = New-ScheduledJobOption -StartIfOnBattery -RunElevated
$psJobsPathInScheduler = "\";
Register-ScheduledJob -Name "WSC2024_NETCFG" -Trigger $trigger -ScriptBlock {    
    $ifindex = Get-NetAdapter | select -ExpandProperty ifindex
    New-NetIPAddress -InterfaceIndex $ifindex -IPAddress 2001:db8:cafe:200::20 -PrefixLength 64
    New-NetIPAddress -InterfaceIndex $ifindex -IPAddress 10.1.64.20 -PrefixLength 24 -DefaultGateway 10.1.64.1
    Set-DnsClientServerAddress -InterfaceIndex $ifindex -ServerAddresses ("127.0.0.1", "::1")
    Unregister-ScheduledTask -TaskName "WSC2024_NETCFG" -Confirm:$false
    Restart-Computer -Confirm:$false
}
$psJobsPathInScheduler = "\Microsoft\Windows\PowerShell\ScheduledJobs";
$settings = New-ScheduledTaskSettingsSet
$settings.Priority = 4
Set-ScheduledTask -TaskPath $psJobsPathInScheduler -TaskName "WSC2024_NETCFG" -Principal $principal -Settings $settings