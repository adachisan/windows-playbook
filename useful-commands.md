## Download Links

https://www.microsoft.com/en-us/software-download/windows11

https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewiso

https://schneegans.de/windows/unattend-generator/

https://github.com/pbatard/rufus/releases

## Initial Setup

```powershell
# Allow local scripts without a signature prompt:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
# Activate Windows:
irm https://get.activated.win | iex
# Launch Chris Titus Windows Utility (debloat, drivers, tweaks):
irm https://christitus.com/windev | iex
```

## Performance Tweaks

```powershell
# Disable unused Windows services and features:
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5 -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" "AutoDownload" 2 -Force
Stop-Service DiagTrack -Force; Set-Service DiagTrack -StartupType Disabled
Stop-Service MapsBroker -Force; Set-Service MapsBroker -StartupType Disabled
Stop-Service wisvc -Force; Set-Service wisvc -StartupType Disabled
Stop-Service RetailDemo -Force; Set-Service RetailDemo -StartupType Disabled
Stop-Service Spooler -Force; Set-Service Spooler -StartupType Disabled
Stop-Service RemoteRegistry -Force; Set-Service RemoteRegistry -StartupType Disabled
Stop-Service SEMgrSvc -Force; Set-Service SEMgrSvc -StartupType Disabled
Stop-Service WerSvc -Force; Set-Service WerSvc -StartupType Disabled
Stop-Service PcaSvc -Force; Set-Service PcaSvc -StartupType Disabled
Stop-Service PhoneSvc -Force; Set-Service PhoneSvc -StartupType Disabled
# Disable the lock screen:
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /SETACTIVE SCHEME_CURRENT
Set-ItemProperty "HKCU:\Control Panel\Desktop" "DelayLockInterval" -1 -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1 -Force
# Optimize Windows Defender:
Set-MpPreference -ScanAvgCPULoadFactor 10 
Set-MpPreference -ScanScheduleDay 8
Set-MpPreference -DisableCatchupQuickScan $true
Set-MpPreference -DisableCatchupFullScan $true
Set-MpPreference -ScanOnlyIfIdleEnabled $true
Set-MpPreference -EnableLowCpuPriority $true
Set-MpPreference -ScanPurgeItemsAfterDelay 1
# Optimize memory and resource usage:
Enable-MMAgent -MemoryCompression
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagingFiles" @("C:\pagefile.sys 8192 8192") -Force
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" "SvcHostSplitThresholdInKB" 0x7fffffff -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "StartupBoostEnabled" 0 -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "BackgroundModeEnabled" 0 -Force
# Optimize network performance:
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0 -Force
Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses ('9.9.9.9', '8.8.8.8')
Get-NetAdapter -Physical | Set-NetIPInterface -AddressFamily IPv4 -NlMtuBytes 1400
Clear-DnsClientCache
# Speed up system shutdown:
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" -Force
Set-ItemProperty "HKCU:\Control Panel\Desktop" "AutoEndTasks" "1" -Force
Set-ItemProperty "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" "2000" -Force
Set-ItemProperty "HKCU:\Control Panel\Desktop" "HungAppTimeout" "1000" -Force
# Improve UI responsiveness:
Set-ItemProperty "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" -Force
Set-ItemProperty "HKCU:\Control Panel\Mouse" "MouseHoverTime" "50" -Force
Set-ItemProperty "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" -Force
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0 -Force
# Optimize power management:
powercfg /hibernate on
powercfg /h /type full
powercfg /h /size 40
powercfg /change monitor-timeout-dc 2
powercfg /change standby-timeout-dc 15
powercfg /change hibernate-timeout-dc 60
powercfg /change monitor-timeout-ac 5
powercfg /change standby-timeout-ac 60
powercfg /change hibernate-timeout-ac 120
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 99
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setactive SCHEME_CURRENT
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0 -Force
# Disable automatic Windows updates:
New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" 2 -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1 -Force
# [Optional] Create a daily scheduled task that pauses Windows updates for 35 days:
$c = 'cd HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings;$s="{0:s}Z"-f($u=[datetime]::UtcNow);$e="{0:s}Z"-f$u.AddDays(35);"Feature","Quality",""|%{$p="Pause$($_)Updates";sp . "${p}StartTime" $s;sp . ($p+("EndTime","ExpiryTime")[!$_]) $e}'
$enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($c))
$settings = New-ScheduledTaskSettingsSet -Priority 10 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask "PauseWindowsUpdate" -Action (New-ScheduledTaskAction powershell "-w h -nop -enc $enc") -Trigger (New-ScheduledTaskTrigger -Daily -At (Get-Date)) -Settings $settings -User "SYSTEM" -Force | Out-Null
iex $c
```

## Install Apps

```powershell
# Install the essentials:
winget install --silent `
	Microsoft.WindowsTerminal `
	Microsoft.PowerShell `
	OpenJS.NodeJS `
	7zip.7zip `
	Git.Git `
	ggml.llamacpp `
	Microsoft.VisualStudioCode `
	REALiX.HWiNFO `
	Stremio.Stremio `
	Brave.Brave
powershell -c "irm bun.sh/install.ps1 | iex"
npm install -g @opencode/cli bun
# Update everything:
winget update --all --silent --accept-source-agreements --accept-package-agreements --force --include-unknown
```

## Maintenance & Diagnostics

```powershell
# Free disk space:
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
# Restart the Windows Update service:
Restart-Service wuauserv -Force
# Reset the battery usage log:
Stop-Service DPS -Force -EA 0
Remove-Item "C:\Windows\System32\sru\SRUDB.dat" -Force -EA 0
Remove-Item "C:\Windows\System32\sru\*.log" -Force -EA 0
Start-Service DPS -EA 0
# Trim process working sets (cosmetic; Windows reclaims memory automatically):
Add-Type -MemberDefinition '[DllImport("psapi.dll")] public static extern int EmptyWorkingSet(IntPtr h);' -Name "Mem" -Namespace "Win32"
Get-Process | ForEach-Object { [Win32.Mem]::EmptyWorkingSet($_.Handle) } *>$null
# Export all drivers to C:\Drivers:
Export-WindowsDriver -Online -Destination "C:\Drivers"
# Install all drivers from C:\Drivers:
pnputil /add-driver "C:\Drivers\*.inf" /subdirs /install
pnputil /scan-devices
# Enable PowerShell autocomplete:
New-Item -ItemType File -Path $PROFILE -Force | Out-Null
@'
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
'@ | Add-Content -Path $PROFILE
# Show battery charging rate in watts:
Get-CimInstance -Namespace root/wmi -ClassName BatteryStatus | % { ($_.ChargeRate - $_.DischargeRate) / 1000 }
# Show battery usage, degradation, and consumption:
powercfg /batteryreport; .\battery-report.html
# Show sleep study:
powercfg /sleepstudy; .\sleepstudy-report.html
# Show general power efficiency report:
powercfg /energy /duration 30; .\energy-report.html
# Show what's preventing sleep:
powercfg /requests
# List devices that can wake the PC:
powercfg -devicequery wake_armed
# Show available sleep states:
powercfg /a
# Block a process from preventing sleep (edit the name):
powercfg -requestsoverride PROCESS "process_name.exe" SYSTEM
# Block a driver from preventing sleep (edit the name):
powercfg -requestsoverride DRIVER "driver_name" SYSTEM
```

## Git Aliases

```powershell
# List all aliases:
git config --global alias.alias "config --get-regexp alias"
# Stage all and commit with a default message ("update"):
git config --global alias.save '!f() { git add -A && git commit -m "${*:-update}"; }; f'
# Stage all and amend the last commit:
git config --global alias.amend '!git add -A && git commit --amend --no-edit'
# Show history with short stats:
git config --global alias.view "log --reverse --oneline --shortstat"
# Undo ALL uncommitted changes:
git config --global alias.undo '!git reset --hard HEAD && git clean -fd'
# Hard reset to the previous commit (discards local changes):
git config --global alias.revert '!git reset --hard HEAD~1'
# Logging in to GitHub and sets the username/email:
git config --global alias.login '!f() { git config --global credential.helper manager; u=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n "s/^username=//p"); git config --global user.name "$u"; [ "$1" ] && git config --global user.email "$1"; echo "Logged as $u"; }; f'
# Add a remote if it doesn't exist, and push to remote:
git config --global alias.send '!f() { git remote add origin "https://github.com/$(git config user.name)/${PWD##*/}.git" 2>/dev/null; git push -f -u origin HEAD; }; f'
# Remove all aliases:
git config --global --remove-section alias
```

## System Image Backup & Restore

> **Note:** Requires WinPE, a USB installer, or another Windows install. Won't run on the active OS.

```powershell
# Capture the C: drive as D:\WindowsBackup.wim:
dism /Capture-Image /ImageFile:D:\WindowsBackup.wim /CaptureDir:C:\ /Name:"WindowsBackup"
# WARNING: The commands below WIPE C:! Run only from WinPE.
# Format C: (NTFS, quick):
format C: /fs:ntfs /q /y
# Restore the image to C::
dism /Apply-Image /ImageFile:D:\WindowsBackup.wim /Index:1 /ApplyDir:C:\
# Rebuild the boot config:
bcdboot C:\Windows
```
