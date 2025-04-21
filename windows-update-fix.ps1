# Windows Update Fix Script
# Repairs common Windows Update issues by resetting components and clearing cache
# Usage: Run in PowerShell with administrator privileges

# Verify running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: This script requires administrator privileges. Please restart PowerShell as an administrator." -ForegroundColor Red
    Exit 1
}

# Create log folder if it doesn't exist
$logPath = "$env:USERPROFILE\Documents\PC-Diagnostics"
if (!(Test-Path -Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath | Out-Null
}

$logFile = "$logPath\windows-update-fix.log"

# Function to log actions
function Write-Log {
    param($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $message" | Out-File -FilePath $logFile -Append
    Write-Host $message
}

# Start log
"Windows Update Fix Log - $(Get-Date)" | Out-File -FilePath $logFile
Write-Log "Starting Windows Update repair process..."

# Step 1: Stop Windows Update related services
Write-Log "Stopping Windows Update services..."
$services = @(
    "wuauserv",          # Windows Update
    "cryptSvc",          # Cryptographic Services
    "bits",              # Background Intelligent Transfer Service
    "msiserver",         # Windows Installer
    "appidsvc",          # Application Identity
    "trustedinstaller"   # Windows Modules Installer
)

foreach ($service in $services) {
    try {
        if (Get-Service $service -ErrorAction SilentlyContinue) {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Write-Log "Stopped service: $service"
        } else {
            Write-Log "Service not found: $service"
        }
    } catch {
        Write-Log "Failed to stop service $service. Error: $_"
    }
}

# Step 2: Rename the SoftwareDistribution and Catroot2 folders
Write-Log "Renaming Windows Update folders..."
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

try {
    if (Test-Path "$env:SystemRoot\SoftwareDistribution") {
        Rename-Item -Path "$env:SystemRoot\SoftwareDistribution" -NewName "SoftwareDistribution.old.$timestamp" -Force
        Write-Log "Renamed SoftwareDistribution folder"
    }
} catch {
    Write-Log "Failed to rename SoftwareDistribution folder. Error: $_"
}

try {
    if (Test-Path "$env:SystemRoot\System32\catroot2") {
        Rename-Item -Path "$env:SystemRoot\System32\catroot2" -NewName "catroot2.old.$timestamp" -Force
        Write-Log "Renamed catroot2 folder"
    }
} catch {
    Write-Log "Failed to rename catroot2 folder. Error: $_"
}

# Step 3: Clear event logs related to Windows Update
Write-Log "Clearing Windows Update event logs..."
try {
    Get-EventLog -LogName "System" -Source "Microsoft-Windows-WindowsUpdateClient" -EA SilentlyContinue | Clear-EventLog -ErrorAction SilentlyContinue
    Write-Log "Cleared Windows Update event logs"
} catch {
    Write-Log "Failed to clear event logs or no logs found. This is normal if updates have not run recently."
}

# Step 4: Reset Windows Update components using DISM
Write-Log "Resetting Windows Update components using DISM..."
try {
    $dismOutput = & dism.exe /Online /Cleanup-Image /RestoreHealth
    Write-Log "DISM restore health completed: $dismOutput"
} catch {
    Write-Log "DISM restore health encountered an error: $_"
}

# Step 5: Reset Windows Update components registration
Write-Log "Resetting Windows Update component registration..."
$registrationCommands = @(
    'regsvr32.exe /s atl.dll',
    'regsvr32.exe /s urlmon.dll',
    'regsvr32.exe /s mshtml.dll',
    'regsvr32.exe /s shdocvw.dll',
    'regsvr32.exe /s browseui.dll',
    'regsvr32.exe /s jscript.dll',
    'regsvr32.exe /s vbscript.dll',
    'regsvr32.exe /s scrrun.dll',
    'regsvr32.exe /s msxml.dll',
    'regsvr32.exe /s msxml3.dll',
    'regsvr32.exe /s msxml6.dll',
    'regsvr32.exe /s actxprxy.dll',
    'regsvr32.exe /s softpub.dll',
    'regsvr32.exe /s wintrust.dll',
    'regsvr32.exe /s dssenh.dll',
    'regsvr32.exe /s rsaenh.dll',
    'regsvr32.exe /s gpkcsp.dll',
    'regsvr32.exe /s sccbase.dll',
    'regsvr32.exe /s slbcsp.dll',
    'regsvr32.exe /s cryptdlg.dll',
    'regsvr32.exe /s oleaut32.dll',
    'regsvr32.exe /s ole32.dll',
    'regsvr32.exe /s shell32.dll',
    'regsvr32.exe /s initpki.dll',
    'regsvr32.exe /s wuapi.dll',
    'regsvr32.exe /s wuaueng.dll',
    'regsvr32.exe /s wuaueng1.dll',
    'regsvr32.exe /s wucltui.dll',
    'regsvr32.exe /s wups.dll',
    'regsvr32.exe /s wups2.dll',
    'regsvr32.exe /s wuweb.dll',
    'regsvr32.exe /s qmgr.dll',
    'regsvr32.exe /s qmgrprxy.dll',
    'regsvr32.exe /s wucltux.dll',
    'regsvr32.exe /s muweb.dll',
    'regsvr32.exe /s wuwebv.dll'
)

foreach ($cmd in $registrationCommands) {
    try {
        Invoke-Expression $cmd
        Write-Log "Executed: $cmd"
    } catch {
        Write-Log "Failed to execute: $cmd. Error: $_"
    }
}

# Step 6: Reset Windows Update registry values
Write-Log "Resetting Windows Update registry keys..."
try {
    # Reset Windows Update registry values
    $WURegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate"
    if (Test-Path $WURegistryPath) {
        $regBackupPath = "$logPath\WindowsUpdate_Registry_Backup_$timestamp.reg"
        reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" $regBackupPath /y | Out-Null
        Write-Log "Windows Update registry keys backed up to $regBackupPath"
        
        # Reset AU settings
        $AUPath = "$WURegistryPath\Auto Update"
        if (Test-Path $AUPath) {
            Set-ItemProperty -Path $AUPath -Name "AUOptions" -Value 0 -Type DWord -Force
            Write-Log "Reset AUOptions registry value"
        }
    }
} catch {
    Write-Log "Failed to reset registry keys. Error: $_"
}

# Step 7: Start Windows Update services again
Write-Log "Starting Windows Update services..."
foreach ($service in $services) {
    try {
        if (Get-Service $service -ErrorAction SilentlyContinue) {
            Start-Service -Name $service -ErrorAction SilentlyContinue
            Write-Log "Started service: $service"
        }
    } catch {
        Write-Log "Failed to start service $service. Error: $_"
    }
}

# Step 8: Run Windows Update troubleshooter
Write-Log "Running Windows Update troubleshooter..."
try {
    if ([Environment]::OSVersion.Version.Major -ge 10) {
        # Windows 10/11 has a PowerShell module for troubleshooting
        Get-TroubleshootingPack -Path "$env:SystemRoot\diagnostics\system\WindowsUpdate" | Invoke-TroubleshootingPack -Unattended
        Write-Log "Windows Update troubleshooter completed"
    } else {
        # Older versions - try running the troubleshooter executable
        if (Test-Path "$env:SystemRoot\System32\msdt.exe") {
            Start-Process "$env:SystemRoot\System32\msdt.exe" -ArgumentList "/id WindowsUpdateDiagnostic /skip force"
            Write-Log "Windows Update troubleshooter launched"
        }
    }
} catch {
    Write-Log "Failed to run Windows Update troubleshooter. Error: $_"
}

# Step 9: Final instructions
Write-Log "Windows Update repair script completed."
Write-Log "Please restart your computer and check for updates."
Write-Log "Log file saved to: $logFile"

Write-Host "`nWindows Update repair complete!" -ForegroundColor Green
Write-Host "Please restart your computer to apply all changes." -ForegroundColor Yellow
Write-Host "After restarting, check for updates by going to Settings > Update & Security > Windows Update" -ForegroundColor Yellow