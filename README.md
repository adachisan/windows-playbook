# windows-playbook

Personal collection of everything I use to set up, optimize, and maintain Windows 10/11: PowerShell scripts, a command cheat sheet, and an unattended install config.

## What's inside

- `Manage-Drivers.ps1` — Backup and restore Windows drivers.
- `useful-commands.md` — Cheat sheet of commands for setup, tweaks, drivers, apps, and maintenance.
- `autounattend.xml` — Unattended Windows 11 Pro install: bypasses hardware checks, creates the local `Admin` account, and removes bloatware.

## autounattend.xml — Unattended Windows 11 install

1. Create a Windows 11 boot USB (Rufus or Media Creation Tool).
2. Copy `autounattend.xml` to the **root** of the USB drive.
3. Boot from the USB and start setup normally. Windows reads the file automatically and installs with the preconfigured settings.

Notes:

- Only used during a clean install. Existing Windows installs are not affected.
- Bypasses the TPM, Secure Boot, and RAM checks, so it runs on unsupported hardware.
- Test on a VM or spare machine before installing on real hardware.

## PS1 Script Rules

All scripts in this repository are executed remotely in-memory via `irm <url> | iex`. When writing or modifying a `.ps1` script, follow these rules:

1. **User Input**
   - Do NOT use script parameters (`param(...)`) for core workflows.
   - Always use `Read-Host` to collect required inputs interactively. Provide a clear prompt and a fallback default.

2. **Exit and Termination**
   - NEVER use `exit` or `exit $code`. It closes the user's active PowerShell window.
   - Always use `return` to stop the script.

3. **Path Handling**
   - NEVER use `$PSScriptRoot` or `$MyInvocation.MyCommand.Path` (both are `$null` during in-memory `iex`).
   - Always use `$PWD` (or `$PWD.Path`) to resolve paths relative to the current folder.

4. **Structure**
   - Keep scripts in the repository root (no subfolders).
   - Use short, lowercase, hyphen-separated filenames (e.g., `clean-temp.ps1`, `fix-dns.ps1`).

## useful-commands.md Rules

- Keep the minimalist style: a `##` heading per topic, with all commands of a topic in a single code block for easy copy and paste.
- Label each command with a short, direct, one-line `#` comment in English.
- Use simple, direct English in every description.
- Only add commands you have tested to work on a clean Windows setup.

## Requirements

- Windows 10/11
- PowerShell 5.1+