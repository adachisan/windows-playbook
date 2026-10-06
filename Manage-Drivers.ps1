param(
	[ArgumentCompleter({ 'save', 'load', 'prune' })][string]$Action,
	[ArgumentCompleter({ Get-ChildItem -LiteralPath $PWD.Path -Filter *.zip -File -Recurse -EA 0 | ForEach-Object FullName })][string]$Zip = "$PWD\Drivers.zip",
	[switch]$y
)

function Step ([string]$Message, [scriptblock]$Script, [bool]$Throw = $true) {
	Write-Host -NoNewline ">>> $Message... " -ForegroundColor Cyan
	try { & $Script; Write-Host "OK!" -ForegroundColor Green }
	catch { Write-Host "FAILED!" -ForegroundColor Red; if ($Throw) { throw } }
}

function Confirm-Removal ($Title, $Items, $Question) {
	if (!$Items -or $y) { return $Items }
	Write-Host $Title -ForegroundColor Yellow
	$Items | Format-Table Driver, ProviderName, Size -AutoSize | Out-Host
	if ((Read-Host $Question) -match '^[Yy]') { $Items }
}

function Invoke-DriverPipeline {
	$Fatal = $Action -ne 'save'
	if (!$Fatal) { $ExportJob = Step "Starting export" { Start-Job { Export-WindowsDriver -Online -Destination $using:Temp } } }
	$Drivers = Step "Reading drivers" { Get-WindowsDriver -Online } -Throw $Fatal
	Step "Measuring sizes" { $Drivers | ForEach-Object { $_ | Add-Member NoteProperty Size ((Get-ChildItem (Split-Path $_.OriginalFileName) -Recurse -File | Measure-Object Length -Sum).Sum / 1MB) } } -Throw $Fatal
	$Display = @($Drivers | Where-Object { $_.ClassName -eq 'Display' })
	$Duplicates = $Drivers | Group-Object { "$($_.ProviderName)_$(Split-Path $_.OriginalFileName -Leaf)" } | Where-Object Count -gt 1
	$Legacy = @($Duplicates | ForEach-Object { $_.Group | Sort-Object Date, { [version]$_.Version } | Select-Object -SkipLast 1 })
	if (!$Fatal) {
		$Targets += Confirm-Removal "Display drivers:" $Display "Ignore Display drivers? (Y/N)"
		$Targets += Confirm-Removal "Legacy drivers:" $Legacy "Ignore legacy drivers? (Y/N)"
		Step "Waiting for export" { $ExportJob | Wait-Job > $null; if ($ExportJob.State -eq 'Failed') { throw }; $ExportJob | Remove-Job -Force }
		if ($Targets.Count) { Step "Stripping" { $Targets | Sort-Object Driver -Unique | ForEach-Object { Remove-Item (Join-Path $Temp (Split-Path (Split-Path $_.OriginalFileName) -Leaf)) -Recurse -Force -EA 0 } } -Throw $Fatal }
	}
	else { Confirm-Removal "Remove legacy drivers:" $Legacy "Remove legacy drivers? (Y/N)" | ForEach-Object { pnputil /delete-driver $_.Driver /uninstall } }
}

function Select-ZipFile {
	$Zips = @(Get-ChildItem -LiteralPath $PWD.Path -Filter *.zip -File -Recurse -EA 0); if (!$Zips.Count) { return Read-Host "File [$Zip]" }
	$i = 0; $Zips | ForEach-Object { Write-Host ("{0}) {1}" -f (++$i), $_.FullName) }
	$Pick = Read-Host "Pick a number or a path, Enter = [$Zip]"
	if ($Pick -match '^\d+$' -and [int]$Pick -ge 1 -and [int]$Pick -le $Zips.Count) { $Zips[[int]$Pick - 1].FullName } else { $Pick }
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
	Start-Process wt "powershell -noexit -ep bypass -f `"$PSCommandPath`"" -Verb RunAs; exit
}
$Temp = "$env:TEMP\Drivers_Backup_$([guid]::NewGuid().Guid)"
mkdir $Temp -Force > $null
if (!$PSBoundParameters.ContainsKey('Action')) { $Action = (Read-Host "Action [save/load/prune]").Trim() }
if (!$y -and !$PSBoundParameters.ContainsKey('Zip') -and $Action -in 'save', 'load') { $Path = Select-ZipFile; if ($Path) { $Zip = $Path } }
if ($Action -in 'save', 'load' -and $Zip -notlike '*.zip') { throw "The file must be a .zip" }

try {
	switch ($Action) {
		"save" { Invoke-DriverPipeline; Step "Compressing drivers" { Compress-Archive -Path "$Temp\*" -DestinationPath $Zip -Force } }
		"load" {
			if (!(Test-Path $Zip)) { throw "File '$Zip' not found!" }
			Step "Extracting drivers" { Expand-Archive -Path $Zip -DestinationPath $Temp -Force }
			Step "Installing drivers" { pnputil /add-driver "$Temp\*.inf" /subdirs /install | Where-Object { $_ -match 'Fail' } }
			Step "Refreshing devices" { pnputil /scan-devices > $null } 
		}
		"prune" { Invoke-DriverPipeline; Step "Refreshing devices" { pnputil /scan-devices > $null } }
		default { "save -> Backup drivers to Zip", "load -> Restore drivers from Zip", "prune -> Remove old drivers" | ForEach-Object { Write-Host $_ -ForegroundColor Yellow } }
	} 
}
finally { Remove-Item $Temp -Recurse -Force -EA 0 }
