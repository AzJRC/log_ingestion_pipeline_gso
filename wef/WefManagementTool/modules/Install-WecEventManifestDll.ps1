<#
.SYNOPSIS
    Installs or updates a WEC event manifest by copying the MAN and DLL files into System32,
    and reloading the manifest via wevtutil. Temporarily disables WEF subscriptions for safety.

.DESCRIPTION
    This function is designed to deploy a Windows Event Collector (WEC) manifest configuration on the host system. 
    It performs the following operations in order:

    1. Enumerates all current Windows Event Forwarding (WEF) subscriptions using `wecutil es`.
    2. Temporarily disables each subscription to avoid conflicts during manifest update.
    3. Stops the WEC service (`wecsvc`) to release any locks on the manifest files.
    4. Unloads the existing manifest (if previously registered) using `wevtutil um`.
    5. Copies the provided .man (manifest) and .dll (compiled binary) files into `C:\Windows\System32`.
    6. Registers the new manifest using `wevtutil im`.
    7. Restarts the WEC service.
    8. Re-enables the previously disabled WEF subscriptions.

    This process ensures that the event manifest is safely reloaded without causing subscription failures or locking issues.
    It is particularly useful when distributing or updating custom event providers for use with Windows Event Forwarding.

.PARAMETER ManPath
    Path to the manifest file (.man) to be installed or updated. Defaults to a local relative path in the Files directory.

.PARAMETER DllPath
    Path to the compiled manifest DLL (.dll) file. This binary is required for the proper registration of the manifest.

.EXAMPLE
    Install-WecEventManifestDll
    Runs the command with default paths to .man and .dll files relative to the script root.

.EXAMPLE
    Install-WecEventManifestDll -ManPath "C:\MyManifests\CustomEvent.man"
    Uses a custom manifest path, keeping the default DLL path.

.NOTES
    Author: AzJRC
    Created: June 04, 2025
    Version: 1.0
    Requires: PowerShell 5.1 or later

.NOTES
    Requires administrative privileges.
    Make sure WEC service (wecsvc) is running before use.
#>

function Install-WecEventManifestDll {
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Path to the manifest document.")]
        [ValidateScript({ Test-ValidateFile $_ ".man" })]
        [string]$ManPath = "$PSScriptRoot\..\Files\CustomEventChannels.man",

        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Path to the manifest DLL binary.")]
        [ValidateScript({ Test-ValidateFile $_ ".dll" })]
        [string]$DllPath = "$PSScriptRoot\..\Files\CustomEventChannels.dll"
    )

    # Derive metadata
    $ManFilename = (Get-Item $ManPath).BaseName
    $WorkingDir = Split-Path -Path $ManPath -Parent

    Write-Host "[1/7] Enumerating active WEF subscriptions..." -ForegroundColor Cyan

    # Get WEF subscriptions using 'wecutil es' and split by newlines
    $WefSubscriptions = & wecutil.exe es | Where-Object { $_.Trim() -ne "" }

    if (-not $WefSubscriptions) {
        Write-Warning "No WEF subscriptions found or failed to enumerate."
    }

    Write-Host "[2/7] Disabling WEF subscriptions..." -ForegroundColor Cyan
    foreach ($Subscription in $WefSubscriptions) {
        Set-WefSubscriptionState -State $false -Subscription $Subscription
    }

    Write-Host "[3/7] Stopping WEC service..." -ForegroundColor Cyan
    Stop-Service -Name Wecsvc -Force -ErrorAction Stop

    Write-Host "[4/7] Unloading current manifest if present..." -ForegroundColor Cyan
    if (Test-Path "C:\Windows\System32\$ManFilename.man") {
        Start-Process -FilePath wevtutil.exe -ArgumentList @("um", "C:\Windows\System32\$ManFilename.man") -Wait -NoNewWindow
    }

    Write-Host "[5/7] Copying manifest and DLL to System32..." -ForegroundColor Cyan
    Copy-Item -Path $DllPath -Destination "C:\Windows\System32" -Force
    Copy-Item -Path $ManPath -Destination "C:\Windows\System32" -Force

    Write-Host "[6/7] Registering the new manifest..." -ForegroundColor Cyan
    Start-Process -FilePath wevtutil.exe -ArgumentList @("im", "C:\Windows\System32\$ManFilename.man") -Wait -NoNewWindow

    Write-Host "[7/7] Restarting WEC service and restoring subscriptions..." -ForegroundColor Cyan
    Start-Service -Name Wecsvc -ErrorAction Stop
    foreach ($Subscription in $WefSubscriptions) {
        Set-WefSubscriptionState -State $true -Subscription $Subscription
    }

    Write-Host "Manifest deployment complete." -ForegroundColor Cyan
}



#
# Utility functions
#

function Test-ValidateFile {
    param (
        [string]$Path,
        [string]$Extension
    )
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    if ([System.IO.Path]::GetExtension($Path) -ne $Extension) {
        throw "Invalid file extension. Expected '$Extension'."
    }
    return $true
}

function Set-WefSubscriptionState {
    param (
        [bool]$State,
        [string]$Subscription
    )
    $enabledValue = if ($State) { "true" } else { "false" }
    Start-Process -FilePath "wecutil.exe" `
        -ArgumentList @("ss", "/e:$enabledValue", $Subscription) `
        -NoNewWindow -Wait
}