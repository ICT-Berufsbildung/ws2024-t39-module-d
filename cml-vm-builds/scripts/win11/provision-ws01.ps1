
Write-Host "Prepare domain join"
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$trigger = New-JobTrigger -AtStartup
$options = New-ScheduledJobOption -StartIfOnBattery -RunElevated
$psJobsPathInScheduler = "\";
Register-ScheduledJob -Name "WSC2024_DOMAINJOIN" -Trigger $trigger -ScriptBlock {    
    if ((gwmi win32_computersystem).partofdomain -eq $false) {
        $password = "Skills39" | ConvertTo-SecureString -asPlainText -Force
        $username = "WSC2024\sysop" 
        $credential = New-Object System.Management.Automation.PSCredential($username,$password)
        Add-Computer -DomainName "wsc2024.local" -Credential $credential -Restart -OUPath "OU=Computers,OU=Finance,OU=HQ,DC=wsc2024,DC=local"
    } else {
        Unregister-ScheduledTask -TaskName "WSC2024_DOMAINJOIN" -Confirm:$false
    }
}
$psJobsPathInScheduler = "\Microsoft\Windows\PowerShell\ScheduledJobs";
$settings = New-ScheduledTaskSettingsSet
$settings.Priority = 4
Set-ScheduledTask -TaskPath $psJobsPathInScheduler -TaskName "WSC2024_DOMAINJOIN" -Principal $principal -Settings $settings