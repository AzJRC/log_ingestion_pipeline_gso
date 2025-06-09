# Windows Sysmon deployment

Installing Windows Sysmon in distributed environments (Windows domains) can be somewhat tricky, specially when we care about security risks. In this documentation file you'll find information on how to deploy Widows Sysmon in a secure manner.

Special thanks to `arkoperator` (Carlos Perez) from `TrustedSec LLC.` in his  project [`SysmonCommunityGuide`](github.com/trustedsec/SysmonCommunityGuide/tree/master) as one of the best resources of information regarding Windows Sysmon.

## Install Windows Sysmon in a Windows Domain with a StartUp Script

To install Windows Sysmon in a Windows Domain follow the steps outlined next:

1. Create a shared folder with `read/execute` permissions for the users and workstations you are considering for this installation. You can name the folder `SysmonArchives` or something similar.
    - If using a DC, you can go to the `shares` tab in the Server Manager and right-click to create a shared folder using the Wizard.
    - You can also create a folder and right-click on `properties` to configure the sharing options.
    - For security reasons, make sure that normal users cannot modify or add any file to the remote share.

![Network Share](/media/servermanager_shares_sysmonarchive.png)

2. In the shared folder, you will save the Windows Sysmon version you are planning to use, often the [latest release](https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon). Ideally, you will also save any other previous version.
    - Save every Sysmon version in a folder with the following suggested naming convention: `SysmonV<VERSION>`. For example, the current versions while I am writing this document is 15.15; thus, the folder name will be `SysmonV15.15`.
    - Within each Sysmon folder store the Sysmon executable for that version. You don't need to keep all three executables (Only the one you need per your environment needs, nor the EULA file).

![Sysmon Archive Folder Structure](/media/sysmonarchive_folder.png)

3. In the root of the SysmonArchive folder you must save the [following script](./../sysmon-installer.ps1):

```PowerShell
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
```

4. Create a GPO with the suggested name `Install and Configure Windows Sysmon` (The steps to distribute the configuration of Sysmon are defined [here](#distribute-sysmon-configuration-securely))
    - If you have another naming convetion for your GPOs, feel free to make the changes.

5. In the GPO editor, go to `Computer Configuration > Policies > Windows Settings > Scripts > Startup` and create a startup script.
    - Make sure to configure the script in the PowerShell tab.
    - Make sure you configure the network path and not the local path. A network path begins with two backslashes (`\\`). E.g.: `\\hostname.subdomain.domain.tld\SysmonArchive\sysmon-installer.ps1`

![Configure GPO Startup Script](/media/startup_script_sysmoninstaller.png)

6. Finally, you can manually apply the GPO by running the command `gpupdate` or wait around 30 minutes (default time to wait until GPOs are automatically evaluated and applied). Keep in mind that the script will only run on startup, so you'll need to restart the workstations to install Sysmon.

### Can I set up a schedule task instead of a startup script?

Yes, you can. However, you'll need to configure the Execution Policy settings and sign the PowerShell script.

Ideally, in enterprise environments you'll sign the PowerShell script with a certificate issued by your internal PKI, but for testing you can also search for self-signed PowerShell Scripts. Anyway, this process is out-of-scope of this repository.

Another, not really good option is to set the Execution Policy to `Bypass` in the whole domain, but that's pretty dangerous. Altough the Execution Policy isn't an actual security measure nor security control, allowing any script to run in your domain without warning messages is a bad practice. However, if you plan to make a quick installation for once, this could be a quick and simple option.

### Can I use Desired Configuration State (DSC) to install (and configure) Sysmon?

Yes. I'll add documentation about this soon.

## Distribute Sysmon Configuration securely

Often, people will include the Sysmon XML configuration file in a shared folder and use a similar script like the one showed in earlier sections to push and run that configuration in every Sysmon instance within a computer domain.

Altough this works in terms of operation, there are various security risks when doing so, but the most important is having the configuration file in a shared folder. This is basically exfiltration of sensitive data, and any client, user, and adversary will be able to read that information (hiding the share is not going to work either).

Fortunately, there is a clever and paradogically not-intricate way to push Sysmon configuration to every workstation in a Windows Domain without the need to share the XML file with everybody. You only need to have Windows Sysmon installed and configured in one machine (Ideally your DC).

1. Create a GPO. If you followed the steps in the section to [Install Windows Sysmon with a StartUp script](#install-windows-sysmon-in-a-windows-domain-with-a-startup-script), you may already have the `Install and Configure Windows Sysmon` GPO.

2. Go to `Preferences > Windows Settings > Registry` and right-click to `New > Registry Wizard`.
    - Select the computer that has Windows Sysmon already configured (likely the local computer).
    - Traverse the registry up to this location: `Computer\HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\SysmonDrv\Parameters`
    - Click the `Parameters` key and the keys under it, including `Rules`,`Options`,`HashingAlgorithm`,`DnsLookup`,`ConfigHash`,`CheckRevocation`.

![](/media/sysmon_distributeconfig_registry.png)

3. Finally, you can apply the GPOs manually using the command `gpupdate` or wait until the GPO is applied automatically. Additionally, registry keys are applied automatically on GPO evaluation; thefore, there is no need to restart the workstations.