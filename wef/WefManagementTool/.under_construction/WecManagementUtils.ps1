<#
    Remove-AllWecSubscriptions
    This functions iterates over all configured subscriptions and then
    deletes each one of them. It depends on the `wecutil.exe` program.
#>
function Remove-AllWecSubscriptions {
    $subscriptions = $(& wecutil.exe es);

    foreach ($subscription in $subscriptions) {
        $(& wecutil.exe ds $subscription)
    };

    Echo "All subscriptions have been removed";
}


<#
.SYNOPSIS
    Unregisters and deletes a custom event manifest and its associated DLL from the system.

.DESCRIPTION
    This function stops the Windows Event Collector (Wecsvc) service, unregisters the custom event manifest 
    using `wevtutil.exe`, deletes the manifest and its associated DLL, and restarts the service.

.PARAMETER EventManifestFileName
    The file name (without extension) of the event manifest to remove (e.g., 'CustomEventChannels').

.PARAMETER EventManifestDir
    The directory path where the manifest and DLL files are located. Defaults to 'C:\Windows\System32\'.

.EXAMPLE
    Remove-CustomLogs -EventManifestFileName "CustomEventChannels" -Verbose

.EXAMPLE
    Remove-CustomLogs -EventManifestFileName "MyManifest" -EventManifestDir "D:\Manifests" -Verbose

.LINK
    https://github.com/Security-Experts-Community/wef-guidance/blob/main/New-WECManifest.ps1
 
.LINK
    https://learn.microsoft.com/en-us/archive/blogs/russellt/creating-custom-windows-event-forwarding-logs
#>
function Remove-CustomLogs {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param(
        [Parameter(Mandatory = $true,
                   HelpMessage = "Event Manifest File Name (no extension).")]
        [Alias("FileName")]
        [string]
        $EventManifestFileName,

        [Parameter(Mandatory = $false,
                   HelpMessage = "Directory where the manifest and DLL are located.")]
        [ValidateScript({ Test-Path -Path $_ })]
        [Alias("Dir")]
        [string]
        $EventManifestDir = "C:\Windows\System32\",

        [Parameter(Mandatory = $false,
                   HelpMessage = "Automatically remove DLL and MAN files.")]
        [Alias("Remove")]
        [switch]
        $RemoveFiles
    )

    # Ensure directory path ends with backslash
    if (-not $EventManifestDir.EndsWith("\")) {
        $EventManifestDir += "\"
    }

    $ManifestDll = "${EventManifestDir}${EventManifestFileName}.dll"
    $ManifestMan = "${EventManifestDir}${EventManifestFileName}.man"

    try {
        Write-Verbose "Stopping the Windows Event Collector service..."
        Stop-Service -Name Wecsvc -Force -ErrorAction Stop

        if (Test-Path $ManifestMan) {
            if ($PSCmdlet.ShouldProcess($ManifestMan, "Unregister event manifest")) {
                Write-Verbose "Unregistering the event manifest: $ManifestMan"
                wevtutil um "$ManifestMan"

                if ($RemoveFiles) { Remove-Item -Path $ManifestMan -Force }
                
            }
        } else {
            Write-Warning "Manifest file not found: $ManifestMan"
        }

        if (Test-Path $ManifestDll) {
            if ($PSCmdlet.ShouldProcess($ManifestDll, "Removing DLL")) {
                Write-Verbose "Removing associated DLL: $ManifestDll"
                
                if ($RemoveFiles) { Remove-Item -Path $ManifestDll -Force }
            }
        } else {
            Write-Verbose "DLL not found at: $ManifestDll"
        }

        Write-Verbose "Restarting the Windows Event Collector service..."
        Start-Service -Name Wecsvc -ErrorAction Stop
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

