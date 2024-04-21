Write-Host "Prepare domain join"
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:01:00
$options = New-ScheduledJobOption -StartIfOnBattery -RunElevated
$psJobsPathInScheduler = "\";
Register-ScheduledJob -Name "WSC2024_DOMAINJOIN" -Trigger $trigger -ScriptBlock {    
    # Pause for 5 seconds per loop
    while ((gwmi win32_computersystem).partofdomain -eq $false) {   
        $password = "Skills39" | ConvertTo-SecureString -asPlainText -Force
        $username = "WSC2024\sysop" 
        $credential = New-Object System.Management.Automation.PSCredential($username,$password)
        try {
            Add-Computer -DomainName "wsc2024.local" -Credential $credential -Restart -OUPath "OU=Computers,OU=Finance,OU=HQ,DC=wsc2024,DC=local" -ErrorAction Stop
        } catch {
            # Sleep 15 seconds
            Start-Sleep -s 15
        }
    }
    Unregister-ScheduledTask -TaskName "WSC2024_DOMAINJOIN" -Confirm:$false
}
$psJobsPathInScheduler = "\Microsoft\Windows\PowerShell\ScheduledJobs";
$settings = New-ScheduledTaskSettingsSet
$settings.Priority = 4
Set-ScheduledTask -TaskPath $psJobsPathInScheduler -TaskName "WSC2024_DOMAINJOIN" -Principal $principal -Settings $settings

# Break pwsh path
$removePath = 'C:\Program Files\Powershell\7\'
$addPath = 'C:\Program Files\Powershell\asdf\'
$regexRemovePath = [regex]::Escape($removePath)
$arrPath = $env:Path -split ';' | Where-Object {$_ -notMatch "^$regexRemovePath\\?"}
[System.Environment]::SetEnvironmentVariable('Path',(($arrPath + $addPath) -join ';'), 'Machine')

# Instal notepad++
choco install notepadplusplus -y