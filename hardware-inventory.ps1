# Hardware Inventory Script
# Creates a detailed report of all hardware components in the system
# Usage: Run in PowerShell with administrator privileges

# Create output folder if it doesn't exist
$outputPath = "$env:USERPROFILE\Documents\PC-Diagnostics"
if (!(Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$reportFile = "$outputPath\hardware-inventory-report.txt"

# Function to write section headers
function Write-SectionHeader {
    param($title)
    Write-Output "`n======== $title ========" | Out-File -FilePath $reportFile -Append
}

# Clear previous report if exists
if (Test-Path $reportFile) {
    Remove-Item $reportFile
}

# Report generation timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"PC HARDWARE INVENTORY REPORT" | Out-File -FilePath $reportFile
"Generated: $timestamp" | Out-File -FilePath $reportFile -Append
"=======================================" | Out-File -FilePath $reportFile -Append

# System information
Write-SectionHeader "SYSTEM INFORMATION"
Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory, SystemType | Format-List | Out-File -FilePath $reportFile -Append

# Operating System
Write-SectionHeader "OPERATING SYSTEM"
Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture, BuildNumber, InstallDate | Format-List | Out-File -FilePath $reportFile -Append

# Processor information
Write-SectionHeader "PROCESSOR INFORMATION"
Get-CimInstance Win32_Processor | Select-Object Name, Description, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors, L2CacheSize, L3CacheSize | Format-List | Out-File -FilePath $reportFile -Append

# Memory information
Write-SectionHeader "MEMORY INFORMATION"
Get-CimInstance Win32_PhysicalMemory | Select-Object Tag, Manufacturer, Capacity, Speed, DeviceLocator | Format-Table -AutoSize | Out-File -FilePath $reportFile -Append

# Disk information
Write-SectionHeader "DISK INFORMATION"
Get-CimInstance Win32_DiskDrive | Select-Object Model, Size, InterfaceType, Partitions, Status | Format-Table -AutoSize | Out-File -FilePath $reportFile -Append

# Partition information
Write-SectionHeader "PARTITION INFORMATION"
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, DriveType, Size, FreeSpace, @{Name="PercentFree"; Expression={"{0:P2}" -f ($_.FreeSpace/$_.Size)}} | Format-Table -AutoSize | Out-File -FilePath $reportFile -Append

# Network adapters
Write-SectionHeader "NETWORK ADAPTERS"
Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true } | Select-Object Name, AdapterType, MACAddress, Speed | Format-Table -AutoSize | Out-File -FilePath $reportFile -Append

# Graphics cards
Write-SectionHeader "GRAPHICS INFORMATION"
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, VideoModeDescription, CurrentRefreshRate, AdapterRAM | Format-Table -AutoSize | Out-File -FilePath $reportFile -Append

# Sound devices
Write-SectionHeader "SOUND DEVICES"
Get-CimInstance Win32_SoundDevice | Select-Object Name, Manufacturer | Format-Table -AutoSize | Out-File -FilePath $reportFile -Append

# BIOS information
Write-SectionHeader "BIOS INFORMATION"
Get-CimInstance Win32_BIOS | Select-Object Manufacturer, Name, SerialNumber, Version, ReleaseDate | Format-List | Out-File -FilePath $reportFile -Append

# Motherboard information
Write-SectionHeader "MOTHERBOARD INFORMATION"
Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber, Version | Format-List | Out-File -FilePath $reportFile -Append

Write-Host "Hardware inventory complete! Report saved to: $reportFile" -ForegroundColor Green