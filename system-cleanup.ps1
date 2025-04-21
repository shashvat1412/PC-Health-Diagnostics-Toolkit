# System Cleanup Script
# Cleans temporary files, browser caches, and frees up disk space
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

$logFile = "$logPath\system-cleanup.log"

# Function to log actions and calculate space freed
function Write-Log {
    param($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $message" | Out-File -FilePath $logFile -Append
    Write-Host $message
}

function Get-FolderSize {
    param($path)
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return $size
    }
    return 0
}

function Format-Size {
    param($size)
    if ($size -gt 1GB) {
        return "$([math]::Round($size / 1GB, 2)) GB"
    } elseif ($size -gt 1MB) {
        return "$([math]::Round($size / 1MB, 2)) MB"
    } elseif ($size -gt 1KB) {
        return "$([math]::Round($size / 1KB, 2)) KB"
    } else {
        return "$size Bytes"
    }
}

function Clean-Folder {
    param($folderPath, $description)
    
    if (Test-Path $folderPath) {
        $sizeBefore = Get-FolderSize $folderPath
        
        try {
            Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { ($_.PSIsContainer -eq $false) -and ($_.LastWriteTime -lt (Get-Date).AddDays(-1)) } | 
                Remove-Item -Force -ErrorAction SilentlyContinue
                
            # Try to remove empty folders
            Get-ChildItem -Path $folderPath -Recurse -Force -ErrorAction SilentlyContinue | 
                Where-Object { $_.PSIsContainer -eq $true } | 
                Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { $_.PSIsContainer -eq $false }).Count -eq 0 } | 
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                
            $sizeAfter = Get-FolderSize $folderPath
            $freed = $sizeBefore - $sizeAfter
            
            if ($freed -gt 0) {
                Write-Log "Cleaned $description - Freed $(Format-Size $freed)"
            } else {
                Write-Log "Checked $description - No files eligible for cleanup"
            }
        }
        catch {
            Write-Log "Error cleaning $description`: $_"
        }
    }
}

# Start log
"System Cleanup Log - $(Get-Date)" | Out-File -FilePath $logFile
Write-Log "Starting system cleanup process..."

# Track total space freed
$totalFreed = 0
$totalBefore = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select-Object -ExpandProperty FreeSpace

# Step 1: Clean Windows Temp folders
Write-Log "Cleaning Windows temporary folders..."

# Windows Temp
Clean-Folder "$env:SystemRoot\Temp" "Windows Temp folder"

# User Temp folders
foreach ($userFolder in (Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
    Clean-Folder "$($userFolder.FullName)\AppData\Local\Temp" "User temp folder for $($userFolder.Name)"
}

# Step 2: Clean Windows Update cache if not done recently
$updateCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path $updateCachePath) {
    $lastCleanupFile = "$logPath\update_cache_cleaned.txt"
    $shouldClean = $true
    
    if (Test-Path $lastCleanupFile) {
        $lastCleanup = Get-Content $lastCleanupFile
        if ((Get-Date) -lt ([DateTime]::Parse($lastCleanup).AddDays(7))) {
            $shouldClean = $false
            Write-Log "Skipping Windows Update cache cleanup (cleaned within last 7 days)"
        }
    }
    
    if ($shouldClean) {
        Write-Log "Stopping Windows Update service..."
        try {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            
            $sizeBefore = Get-FolderSize $updateCachePath
            Remove-Item "$updateCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
            $sizeAfter = Get-FolderSize $updateCachePath
            $freed = $sizeBefore - $sizeAfter
            
            if ($freed -gt 0) {
                Write-Log "Cleaned Windows Update cache - Freed $(Format-Size $freed)"
            }
            
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
            Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath $lastCleanupFile
        }
        catch {
            Write-Log "Error cleaning Windows Update cache: $_"
            # Ensure service is restarted even if cleaning fails
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
    }
}

# Step 3: Clean browser caches
Write-Log "Cleaning browser caches..."

# Chrome cache for each user
foreach ($userFolder in (Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
    Clean-Folder "$($userFolder.FullName)\AppData\Local\Google\Chrome\User Data\Default\Cache" "Chrome cache for $($userFolder.Name)"
    Clean-Folder "$($userFolder.FullName)\AppData\Local\Google\Chrome\User Data\Default\Code Cache" "Chrome code cache for $($userFolder.Name)"
}

# Edge cache for each user
foreach ($userFolder in (Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
    Clean-Folder "$($userFolder.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Cache" "Edge cache for $($userFolder.Name)"
    Clean-Folder "$($userFolder.FullName)\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache" "Edge code cache for $($userFolder.Name)"
}

# Firefox cache for each user
foreach ($userFolder in (Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue)) {
    $firefoxProfiles = "$($userFolder.FullName)\AppData\Local\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxProfiles) {
        foreach ($profile in (Get-ChildItem $firefoxProfiles -Directory -ErrorAction SilentlyContinue)) {
            Clean-Folder "$($profile.FullName)\cache2" "Firefox cache for $($userFolder.Name)"
        }
    }
}

# Step 4: Empty recycle bin
Write-Log "Emptying Recycle Bin..."
try {
    $recycleBinSize = (New-Object -ComObject Shell.Application).NameSpace(10).Items() | 
        Measure-Object -Property Size -Sum | 
        Select-Object -ExpandProperty Sum
    
    if ($recycleBinSize -gt 0) {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "Emptied Recycle Bin - Freed $(Format-Size $recycleBinSize)"
    } else {
        Write-Log "Recycle Bin already empty"
    }
}
catch {
    Write-Log "Error emptying Recycle Bin: $_"
}

# Step 5: Clean WinSxS folder (Windows Component Store) for Windows 8+ systems
if ([Environment]::OSVersion.Version.Major -ge 6 -and [Environment]::OSVersion.Version.Minor -ge 2) {
    Write-Log "Cleaning Windows Component Store (WinSxS)..."
    try {
        $result = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup" -Wait -PassThru -WindowStyle Hidden
        if ($result.ExitCode -eq 0) {
            Write-Log "Windows Component Store cleanup completed successfully"
        } else {
            Write-Log "Windows Component Store cleanup failed with exit code $($result.ExitCode)"
        }
    }
    catch {
        Write-Log "Error cleaning Windows Component Store: $_"
    }
}

# Step 6: Remove old Windows Error Reports
Write-Log "Removing old Windows Error Reports..."
Clean-Folder "$env:ProgramData\Microsoft\Windows\WER\ReportArchive" "Windows Error Reporting archive"
Clean-Folder "$env:ProgramData\Microsoft\Windows\WER\ReportQueue" "Windows Error Reporting queue"

# Step 7: Clean delivery optimization files (Windows 10+)
if ([Environment]::OSVersion.Version.Major -ge 10) {
    Write-Log "Cleaning delivery optimization files..."
    Clean-Folder "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache" "Delivery Optimization cache"
}

# Step 8: Clean Windows Defender cache
Write-Log "Cleaning Windows Defender cache..."
Clean-Folder "$env:ProgramData\Microsoft\Windows Defender\Scans\History" "Windows Defender scan history"
Clean-Folder "$env:ProgramData\Microsoft\Windows Defender\Definition Updates" "Old Windows Defender definitions"

# Step 9: Run disk cleanup utility (cleanmgr) with pre-selected options
Write-Log "Running system disk cleanup utility..."
try {
    # Set up registry keys for cleanmgr
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    
    # Enable common cleanup options
    $cleanOptions = @(
        "Active Setup Temp Folders",
        "BranchCache",
        "Downloaded Program Files",
        "Internet Cache Files",
        "Old ChkDsk Files",
        "Previous Installations",
        "Recycle Bin",
        "Setup Log Files",
        "System error memory dump files",
        "System error minidump files",
        "Temporary Files",
        "Temporary Setup Files",
        "Thumbnail Cache",
        "Update Cleanup",
        "Upgrade Discarded Files",
        "Windows Defender",
        "Windows Error Reporting Archive Files",
        "Windows Error Reporting Queue Files",
        "Windows Error Reporting System Archive Files",
        "Windows Error Reporting System Queue Files",
        "Windows ESD installation files",
        "Windows Upgrade Log Files"
    )
    
    foreach ($option in $cleanOptions) {
        $optionPath = "$regPath\$option"
        if (Test-Path $optionPath) {
            Set-ItemProperty -Path $optionPath -Name "StateFlags0001" -Type DWORD -Value 2 -ErrorAction SilentlyContinue
        }
    }
    
    # Run cleanmgr with the configured options
    Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden
    Write-Log "System disk cleanup completed"
}
catch {
    Write-Log "Error running disk cleanup: $_"
}

# Calculate total space freed
$totalAfter = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" } | Select-Object -ExpandProperty FreeSpace
$totalFreed = $totalAfter - $totalBefore

# Completion summary
Write-Log "System cleanup completed! Total space freed: $(Format-Size $totalFreed)"
Write-Log "Log file saved to: $logFile"

Write-Host "`nSystem cleanup completed!" -ForegroundColor Green
Write-Host "Total space freed: $(Format-Size $totalFreed)" -ForegroundColor Cyan
Write-Host "A detailed log has been saved to: $logFile" -ForegroundColor White