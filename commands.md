## Useful links

https://www.microsoft.com/en-us/software-download/windows11

https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewiso

https://schneegans.de/windows/unattend-generator/

https://github.com/pbatard/rufus/releases

## System Setup & Policies

```powershell
# Allow local scripts without a signature prompt:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
# Activate Windows/Office (MAS):
irm https://get.activated.win | iex
# Launch Chris Titus Windows Utility (debloat, drivers, tweaks):
irm https://christitus.com/windev | iex
```

## Performance Tweaks

```powershell
# Disable MPO (prevents GPU driver stuttering/flickering):
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5 -Type DWord -Force
# Disable the telemetry service (DiagTrack):
Stop-Service DiagTrack -Force; Set-Service DiagTrack -StartupType Disabled
# Optimize Windows Defender (10% CPU load limit & 1-day log purge)
Set-MpPreference -ScanAvgCPULoadFactor 10 -ScanPurgeItemsAfterDelay 1
# Enable memory compression:
Enable-MMAgent -MemoryCompression
# Set the pagefile size to 8GB (Sweet spot):
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "PagingFiles" "C:\pagefile.sys 8192 8192" -Type MultiString -Force
# Disable Delivery Optimization P2P uploads (prevents Windows using your bandwidth)
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0 -Type DWord -Force
# Sets external DNS and MTU for best performance and availability:
Get-NetAdapter -Physical | Set-DnsClientServerAddress -ServerAddresses ('9.9.9.9', '8.8.8.8')
Get-NetAdapter -Physical | Set-NetIPInterface -AddressFamily IPv4 -NlMtuBytes 1400
Clear-DnsClientCache
```

## Driver Backup & Restore

```powershell
# Export all drivers to C:\Drivers:
Export-WindowsDriver -Online -Destination "C:\Drivers"
# Install all drivers from C:\Drivers:
pnputil /add-driver "C:\Drivers\*.inf" /subdirs /install
# Scan for new devices:
pnputil /scan-devices
```

## Software Installation (Winget)

```powershell
# Install the essentials:
winget install --silent `
	Microsoft.VCRedist.2015+.x64 `
	Microsoft.VCRedist.2015+.x86 `
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
# Install Bun:
powershell -c "irm bun.sh/install.ps1 | iex"
# Install the OpenCode AI CLI:
npm install -g @opencode/cli
# Update everything:
winget update --all --silent --accept-source-agreements --accept-package-agreements --force --include-unknown
```

## PowerShell Autocomplete (Add to $PROFILE)

```powershell
# Create $PROFILE if it doesn't exist:
if (!(Test-Path -Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
# Append the config to $PROFILE:
@'
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
'@ | Add-Content -Path $PROFILE
```

## Windows Cleanup & Maintenance

```powershell
# Free disk space (WinSxS cleanup):
Dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
# Restart the Windows Update service (fixes stuck updates):
Restart-Service wuauserv -Force
# Block Microsoft Store from silently auto-installing suggested apps
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" "AutoDownload" 2 -Type DWord -Force
# Disable automatic updates and reboots:
New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" 2 -Type DWord -Force
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1 -Type DWord -Force
# [Optional] Creates a scheduled task that runs every day and pauses Windows updates for 35 days:
$c = 'cd HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings;$s="{0:s}Z"-f($u=[datetime]::UtcNow);$e="{0:s}Z"-f$u.AddDays(35);"Feature","Quality",""|%{$p="Pause$($_)Updates";sp . "${p}StartTime" $s;sp . ($p+("EndTime","ExpiryTime")[!$_]) $e}'
$enc = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($c))
$settings = New-ScheduledTaskSettingsSet -Priority 10 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask "PauseWindowsUpdate" -Action (New-ScheduledTaskAction powershell "-w h -nop -enc $enc") -Trigger (New-ScheduledTaskTrigger -Daily -At (Get-Date)) -Settings $settings -User "SYSTEM" -Force | Out-Null
iex $c
# Trim process working sets to release active memory:
Add-Type -MemberDefinition '[DllImport("psapi.dll")] public static extern int EmptyWorkingSet(IntPtr h);' -Name "Mem" -Namespace "Win32"
Get-Process | ForEach-Object { [Win32.Mem]::EmptyWorkingSet($_.Handle) } *>$null
```

## System Imaging - WIM Backup/Restore

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
# Discard ALL uncommitted changes (staged, tracked, and untracked files):
git config --global alias.discard '!git reset --hard HEAD && git clean -fd'
# Force back to the previous commit:
git config --global alias.revert '!git reset --hard HEAD~1'
# Logging in to GitHub and sets the username/email:
git config --global alias.login '!f() { git config --global credential.helper manager; u=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | sed -n "s/^username=//p"); git config --global user.name "$u"; [ "$1" ] && git config --global user.email "$1"; echo "Logged as $u"; }; f'
# Add a remote if it doesn't exist, and push to remote:
git config --global alias.send '!f() { git remote add origin "https://github.com/$(git config user.name)/${PWD##*/}.git" 2>/dev/null; git push -f -u origin HEAD; }; f'
# Remove all aliases:
git config --global --remove-section alias
```

## Power Management

```powershell
# Show battery chargding rate in watts:
Get-CimInstance -Namespace root/wmi -ClassName BatteryStatus | % { ($_.ChargeRate - $_.DischargeRate) / 1000 }
# Show battery usage, degradation, and consumption:
powercfg /batteryreport; .\battery-report.html
# Show sleep study:
powercfg /sleepstudy; .\sleepstudy-report.html
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
# Enable full hibernation and reduce file size to 40% RAM:
powercfg /hibernate on
powercfg /h /type full
powercfg /h /size 40
# Disable fast startup (that can cause battery auto-discharge):
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0 -Type DWord -Force
# Battery (DC): Screen 2m, Sleep 15m, Hibernate 60m:
powercfg /change monitor-timeout-dc 2
powercfg /change standby-timeout-dc 15
powercfg /change hibernate-timeout-dc 60
# Plugged in (AC): Screen 5m, Sleep 60m, Hibernate 120m:
powercfg /change monitor-timeout-ac 5
powercfg /change standby-timeout-ac 60
powercfg /change hibernate-timeout-ac 120
# Lid close: Sleep for both on (1):
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 1
# Power button: Hibernate on both (2):
powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2
# Energy Saver: Always on battery (100%), Off on AC (0%):
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100
powercfg /setacvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 0
# CPU min state: 0% on both:
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 0
# CPU max state: 99% on DC (disables Turbo Boost), 100% on AC:
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 99
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
# Disable hybrid sleep:
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
# Apply changes:
powercfg /setactive SCHEME_CURRENT
```

## Lock Screen & Desktop

```powershell
# Disable the lock screen password:
powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
powercfg /SETACTIVE SCHEME_CURRENT
# Remove the lock screen delay:
Set-ItemProperty "HKCU:\Control Panel\Desktop" "DelayLockInterval" -1 -Type DWord -Force
# Disable the lock screen entirely:
New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force | Out-Null
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "NoLockScreen" 1 -Type DWord -Force
```
