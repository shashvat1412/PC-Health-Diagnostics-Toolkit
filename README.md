

# PC Health & Diagnostics Toolkit

A comprehensive toolkit for diagnosing and fixing common hardware and software issues on Windows computers.

## Overview

This toolkit provides a collection of scripts for IT technicians and computer repair specialists to quickly identify and resolve common computer issues. It combines hardware diagnostics, Windows troubleshooting, and system maintenance in one easy-to-use package.

## Features

- Hardware inventory and diagnostics
- Drive health status checking
- Windows Update repair
- System cleaning and optimization
- Memory testing

## Requirements

- Windows 7/8/10/11
- PowerShell 3.0 or later
- Administrator privileges

## Installation

1. Clone or download this repository
2. Extract all files to a folder on your computer
3. Right-click on `run-diagnostics.bat` and select "Run as administrator"

## Script Descriptions

### hardware-inventory.ps1
Creates a detailed inventory of all hardware components in the system including CPU, memory, storage, network adapters, and more. This helps in identifying hardware specifications and potential compatibility issues.

### check-drive-health.ps1
Checks the health status of all drives using SMART data and provides information about potential drive failures before they occur. This allows for preventative maintenance and data backup before catastrophic drive failure.

### windows-update-fix.ps1
Repairs common Windows Update issues by resetting components and clearing the update cache. This script can resolve many common update failures without needing to reinstall Windows.

### system-cleanup.ps1
Cleans temporary files, browser caches, and Windows update cache to free up disk space. This script helps improve system performance by removing unnecessary files.

### memory-test.bat
Launches Windows Memory Diagnostic Tool with custom parameters for thorough memory testing. This helps identify faulty RAM that can cause system instability.

### run-diagnostics.bat
The main launcher script that provides a menu to run individual tools or the complete diagnostic suite.

## Usage

1. Run `run-diagnostics.bat` as administrator
2. Select the specific diagnostic tool you want to run:
   - System Information
   - Check Drive Health
   - Fix Windows Update Issues
   - Clean System and Free Up Space
   - Run Complete Diagnostic Suite

All reports are saved to `%USERPROFILE%\Documents\PC-Diagnostics\` for easy reference.

## Learning Resources

- **Days 1-2**: Learn the basics of PowerShell scripting and Windows command line tools
- **Days 3-4**: Study the scripts to understand how they diagnose and fix common Windows issues
- **Days 5-7**: Practice using the tools on test systems and customize as needed

## Customization

You can customize these scripts to fit your specific needs:
- Add additional diagnostic checks
- Modify cleanup procedures
- Adjust repair parameters for your environment

## Author

Shashvat Jain

## License

This project is released under the MIT License.
