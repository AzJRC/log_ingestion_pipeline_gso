<#
.SYNOPSIS
    Configures and enables custom Windows Event Collector (WEC) channels defined in a text file.

.DESCRIPTION
    This function configures logging properties (log path, size, mode) for each custom event channel 
    listed in the provided .txt file. It ensures the associated log files are created under a common 
    directory, and that the appropriate ACL permissions are applied for the LOCAL SERVICE account.

    This setup is necessary after installing a custom Event Manifest and before starting event subscriptions.

.PARAMETER ChannelsFile
    A plain text file with one custom event channel name per line. These must already exist in the Event Log.

.PARAMETER DefaultLogRootPath
    Directory where .evtx files for each custom channel will be stored. If the path doesn't exist, it will be created.

.PARAMETER DefaultLogSize
    Maximum size of each channel's log file in bytes. Default is 300MB (314572800 bytes).

.EXAMPLE
    Set-WecEventChannels

.EXAMPLE
    Set-WecEventChannels -ChannelsFile "C:\Manifests\channels.txt" -DefaultLogRootPath "D:\CustomLogs" -DefaultLogSize 157286400

.NOTES
    Author: AzJRC
    Created: June 4, 2025
    Version: 1.0
    Requires: PowerShell 5.1 or later

.NOTES
    Adapted from the project `wef-guidance` made by `t0x01` and `Anton Kutepov`. See RELATED LINKS.

.NOTES
    Tasks todo:
        1. Add 'AutoMode' flag. With 'AutoMode' disabled, users can manually set a different LogRootPath and LogSize.

.LINK
    https://github.com/Security-Experts-Community/wef-guidance/blob/main/New-WECManifest.ps1
#>
function Set-WecEventChannels {
    param(
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "A .txt file with the custom event channels (one per line) to deploy.")]
        [Alias("Channels")]
        [string]$ChannelsFile = "$PSScriptRoot\..\Files\ProvidersChannelsSummary.csv",

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Default root path for channel stream log files.")]
        [Alias("Root")]
        [string]$DefaultLogRootPath = "C:\Event Collector Logs",

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Default maximum log size in Bytes.")]
        [Alias("Size")]
        [int]$DefaultLogSize = 314572800
    )

    # Ensure the target folder exists
    if (-not (Test-Path $DefaultLogRootPath)) {
        Write-Host "Creating log root directory at: $DefaultLogRootPath" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $DefaultLogRootPath | Out-Null
    }

    # Grant LOCAL SERVICE account permission to write into the folder
    $ACE = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "LOCAL SERVICE", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $LogRootPathACL = Get-Acl -Path $DefaultLogRootPath
    $LogRootPathACL.AddAccessRule($ACE)
    Set-Acl -Path $DefaultLogRootPath -AclObject $LogRootPathACL

    # (Optional) Attempt to enable NTFS compression to save disk space
    $query = "select * from CIM_Directory where name = `"$($DefaultLogRootPath.Replace('\','\\'))`""
    Invoke-CimMethod -Query $query -MethodName Compress | Out-Null

    # Read channel list from file
    if (-not (Test-Path $ChannelsFile)) {
        throw "Channel file not found: $ChannelsFile"
    }

    # Read channel list from CSV file
    $CustomChannels = Import-Csv -Path $ChannelsFile | Select-Object -ExpandProperty Channel


    foreach ($ChannelName in $CustomChannels) {
        Write-Host "Configuring event channel: $ChannelName" -ForegroundColor Cyan

        $EventChannel = Get-WinEvent -ListLog $ChannelName -ErrorAction SilentlyContinue

        if (-not $EventChannel) {
            Write-Warning "Channel not found: '$ChannelName'. Is the manifest installed?"
            continue
        }

        # Disable channel before changing settings
        if ($EventChannel.IsEnabled) {
            $EventChannel.IsEnabled = $false
            $EventChannel.SaveChanges()
        }

        # Format log path as Windows expects (e.g. Application%4Custom.evtx)
        $LogName = ($ChannelName -replace '/', '%4') + ".evtx"
        $EventChannel.LogFilePath = Join-Path $DefaultLogRootPath $LogName

        # Set log mode and max size
        $EventChannel.LogMode = "Circular"
        $EventChannel.MaximumSizeInBytes = $DefaultLogSize
        $EventChannel.SaveChanges()

        # Re-enable channel
        $EventChannel.IsEnabled = $true
        $EventChannel.SaveChanges()
    }

    Write-Host "All channels processed." -ForegroundColor Cyan
}