<#
.SYNOPSIS
    Sysmon Installation and Upgrade Script (GPO-compatible).

.DESCRIPTION
    This PowerShell script automates the installation or upgrade of Sysmon (System Monitor) on Windows endpoints.
    
    It compares the installed driver version with the desired version and installs or upgrades Sysmon accordingly.
    Designed to be used with GPO startup scripts or automated deployment processes.
    
    The script references a network share for the Sysmon binary.

.VERSION
    0.1

.AUTHOR
    Modified by Alejandro Rodriguez.
    Original script authored by Carlos Perez from TrustedSec LLC (https://www.trustedsec.com), under the MIT License.

.LICENSE
    MIT License (https://opensource.org/licenses/MIT)
    Copyright (c) TrustedSec LLC

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

.NOTES
    Tested with Sysmon version 15.15.
    Ensure the share path is accessible and the script is executed with administrative privileges.
    Without proper execution policy handling you may find issues trying to run this script from the UNC path.
    Alternatively, you can set up a startup script with a GPO policy under Policies > Windows Settings > Scripts.
#>

# CONFIGURE PARAMETERS

$DriverName = '<DRV_NAME>'         # Default Driver Name is `SysmonDrv.sys`
$ExecutableName = '<EXEC_name>'    # Default Executable Name is `Sysmon.exe`
$CurrentVersion = '<SYSMON_VER>'   # You can get the Sysmon Version by running the command `Sysmon.exe -c`
$WindowsDomain = '<WIN_DOMAIN>'    # E.g. hostname.subdomain.domain.tld
$SharedFolder = 'WindowsArchive'   # Change if necessary

# DO NOT MODIFY BELOW THIS LINE (Unless necessary)

# Get Sysmon Path
$SysmonPath = "\\$($WindowsDomain)\$($SharedFolder)\SysmonV$($CurrentVersion)\$($ExecutableName)"

# Check if the driver if present
$Present = Test-Path -Path "C:\Windows\$($DriverName)" -PathType Leaf

if ($Present) {
    Write-Host -Object "[+] Sysmon was found." -ForegroundColor Green
    # Check if the version on host is the approved one.
    $HostVersion = (Get-Item "C:\Windows\$($DriverName)").VersionInfo.FileVersion
    if ($CurrentVersion -eq $HostVersion) {
        Write-Host -Object "[+] Sysmon is current approved version." -ForegroundColor Green
    } else {
        # Execute upgrade process.
        Write-Host -Object "[-] Sysmon needs upgrade." -ForegroundColor Red
        Start-Process -FilePath $SysmonPath -ArgumentList '-u' -WindowStyle Hidden
        Start-Process -FilePath $SysmonPath -ArgumentList '-accepteula','-i' -WindowStyle Hidden
    }
} else {
    Write-Host -Object "[+] Installing Windows SysmonV$($CurrentVersion)" -ForegroundColor Green
    Start-Process -FilePath $SysmonPath -ArgumentList '-accepteula','-i' -WindowStyle Hidden
}