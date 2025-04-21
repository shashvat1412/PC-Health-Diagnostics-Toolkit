# Drive Health Check Script
# Checks the health status of all drives using SMART data
# Usage: Run in PowerShell with administrator privileges

# Create output folder if it doesn't exist
$outputPath = "$env:USERPROFILE\Documents\PC-Diagnostics"
if (!(Test-Path -Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

$reportFile = "$outputPath\drive-health-report.txt"

# Clear previous report if exists
if (Test-Path $reportFile) {
    Remove-Item $reportFile
}

# Report generation timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"DRIVE HEALTH REPORT" | Out-File -FilePath $reportFile
"Generated: $timestamp" | Out-File -FilePath $reportFile -Append
"=======================================" | Out-File -FilePath $reportFile -Append

# Get physical disk information
$physicalDisks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, Size

# Get SMART status using WMI
$smartData = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus | Select-Object InstanceName, PredictFailure, Reason

# Get disk volumes
$volumes = Get-Volume | Where-Object { $_.DriveLetter } | Select-Object DriveLetter, FileSystemLabel, FileSystem, DriveType, Size, SizeRemaining

# Output physical disk information
"PHYSICAL DISK INFORMATION" | Out-File -FilePath $reportFile -Append
"-------------------------" | Out-File -FilePath $reportFile -Append
foreach ($disk in $physicalDisks) {
    "Name: $($disk.FriendlyName)" | Out-File -FilePath $reportFile -Append
    "Type: $($disk.MediaType)" | Out-File -FilePath $reportFile -Append
    "Health Status: $($disk.HealthStatus)" | Out-File -FilePath $reportFile -Append
    "Operational Status: $($disk.OperationalStatus)" | Out-File -FilePath $reportFile -Append
    "Size: $([math]::Round($disk.Size / 1GB, 2)) GB" | Out-File -FilePath $reportFile -Append
    "---------------------------------" | Out-File -FilePath $reportFile -Append
}

# Output SMART status if available
"SMART STATUS" | Out-File -FilePath $reportFile -Append
"------------" | Out-File -FilePath $reportFile -Append
if ($smartData) {
    foreach ($item in $smartData) {
        "Drive: $($item.InstanceName)" | Out-File -FilePath $reportFile -Append
        if ($item.PredictFailure) {
            "Failure Predicted: YES - ATTENTION REQUIRED" | Out-File -FilePath $reportFile -Append
            "Reason: $($item.Reason)" | Out-File -FilePath $reportFile -Append
        } else {
            "Failure Predicted: No" | Out-File -FilePath $reportFile -Append
        }
        "---------------------------------" | Out-File -FilePath $reportFile -Append
    }
} else {
    "SMART data could not be retrieved. This may require third-party tools." | Out-File -FilePath $reportFile -Append
}

# Output volume information
"VOLUME INFORMATION" | Out-File -FilePath $reportFile -Append
"------------------" | Out-File -FilePath $reportFile -Append
foreach ($vol in $volumes) {
    $freePercent = [math]::Round(($vol.SizeRemaining / $vol.Size) * 100, 2)
    "Drive Letter: $($vol.DriveLetter)" | Out-File -FilePath $reportFile -Append
    "Label: $($vol.FileSystemLabel)" | Out-File -FilePath $reportFile -Append
    "File System: $($vol.FileSystem)" | Out-File -FilePath $reportFile -Append
    "Total Size: $([math]::Round($vol.Size / 1GB, 2)) GB" | Out-File -FilePath $reportFile -Append
    "Free Space: $([math]::Round($vol.SizeRemaining / 1GB, 2)) GB ($freePercent%)" | Out-File -FilePath $reportFile -Append
    "---------------------------------" | Out-File -FilePath $reportFile -Append
}

# Additional disk information using WMI
"DETAILED DISK INFORMATION" | Out-File -FilePath $reportFile -Append
"------------------------" | Out-File -FilePath $reportFile -Append
$disks = Get-WmiObject Win32_DiskDrive
foreach ($disk in $disks) {
    "Model: $($disk.Model)" | Out-File -FilePath $reportFile -Append
    "Interface: $($disk.InterfaceType)" | Out-File -FilePath $reportFile -Append
    "Serial Number: $($disk.SerialNumber)" | Out-File -FilePath $reportFile -Append
    "Size: $([math]::Round($disk.Size / 1GB, 2)) GB" | Out-File -FilePath $reportFile -Append
    "Partitions: $($disk.Partitions)" | Out-File -FilePath $reportFile -Append
    "Status: $($disk.Status)" | Out-File -FilePath $reportFile -Append
    "---------------------------------" | Out-File -FilePath $reportFile -Append
}

Write-Host "Drive health check complete! Report saved to: $reportFile" -ForegroundColor Green