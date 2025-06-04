<#
.SYNOPSIS
    Generates a Windows Event Manifest (.man) file for one or more custom event providers and their associated channels.

.DESCRIPTION
    The Write-WecEventManifest function assists in the creation of valid ETW-compliant Windows Event Manifest files. 
    It supports interactive and automatic modes, allowing the user to define provider metadata, event channel paths, 
    and symbol naming conventions. This manifest can be later imported using wevtutil or compiled with the Message Compiler (mc.exe).

    The function supports optional parameters for output path and associated resource DLL, and loads helper routines from an external script.

.PARAMETER CustomEventsMAN
    Specifies the full path for the manifest output file. Defaults to 'CustomEventChannels.man' in the current script directory.

.PARAMETER CustomEventsDLL
    Specifies the resource/message DLL path used in the manifest. Defaults to 'System32\[BaseName].dll' derived from the manifest filename.

.PARAMETER EnableAutoMode
    Enables automatic naming of GUIDs and symbols. When enabled, GUIDs are auto-generated and channel/provider symbols are derived from names.

.EXAMPLE
    Write-WecEventManifest

    Launches the interactive manifest builder with automatic mode enabled by default.

.EXAMPLE
    Write-WecEventManifest -Man "C:\Manifests\MyLog.man" -Dll "C:\Windows\System32\MyLog.dll" -Auto $false
    
    Creates a manifest file named 'MyLog.man' that points to a DLL with the same name in the System32 folder with manual input for symbols and GUIDs.

.NOTES
    Author: Alejandro Rodriguez
    Created: June 03, 2025
    Version: 1.0
    Requires: PowerShell 5.1 or later

.NOTES
    Manifest XML writer logic adapted from the project `wef-guidance` made by `t0x01` and `Anton Kutepov`. See RELATED LINKS.

.LINK
    https://github.com/Security-Experts-Community/wef-guidance/blob/main/New-WECManifest.ps1

#>
function Write-WecEventManifest {
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            HelpMessage = "Manifest Document output file.")]
        [Alias("Man")]
        [string]
        $CustomEventsMAN = "$PSScriptRoot\CustomEventChannels.man",

        [Parameter(Mandatory = $false,
            Position = 0,
            HelpMessage = "The Resource and Message DLL that will be referenced in the manifest.")]
        [Alias("Dll")]
        [string]
        $CustomEventsDLL = "C:\Windows\System32\$([System.IO.Path]::GetFileNameWithoutExtension($CustomEventsMAN)).dll",
    
        # 'Auto' mode ensures consistency between the Provider-related values and the Channel-related values.
        # It also auto-configures GUID values using the `New-Guid` CMDlet.
        [Parameter(Mandatory = $false,
            Position = 0,
            HelpMessage = "Enabling Automatic Mode helps write Manifest Documents more easy.")]
        [Alias("Auto")]
        [bool]
        $EnableAutoMode = $true
    )
   
    $UtilsPath = "$PSScriptRoot\Write-WecEventManifest_utils.ps1"
    if (-Not (Test-Path $UtilsPath)) {
        throw "Required utility script not found: $UtilsPath"
    }
    . $UtilsPath

    # Create-Manifest writes the initial schema of the Manifest File.
    # It's the starting point of any Event Manifest Document.
    $XmlWriter = Write-ManifestTemplate -OutputPath $CustomEventsMAN
    
    Write-Host "WEC Manifest Creator Tool started"
    
    # Loop for Provider configuration. 
    # A WEC Manifest can have various providers configured.
    while ($true) {
        $ProviderName = Read-Host "Event Provider Name"

        if ($EnableAutoMode) {
            $ProviderGuid = New-Guid

            $ProviderPrefix = Read-Host "Provider Symbol Prefix"
            $ProviderSymbol = Convert-ToSymbol $ProviderName $ProviderPrefix

            if ($ProviderSymbol.Length -gt 60) {
                $ProviderSymbol = Read-Host "The Provider Symbol $ProviderSymbol is too long - Modify"
            }
        }
        else {
            $ProviderGuid = Read-Host "Event Provider Guid"
            $ProviderSymbol = Read-Host "Event Provider Symbol"
        }

        $ProviderData = @{
            ProviderSymbol = $ProviderSymbol
            ProviderName   = $ProviderName
            ProviderGuid   = $ProviderGuid  
        }

        Write-ManifestProvider -xmlWriter $XmlWriter -ProviderData $ProviderData -CustomEventsDLL $CustomEventsDLL
        Write-Host "Provider has been successfully added to the Manifest Document"
        
        # Loop for Channel configuration.
        # An Event Provider can have various (maximum 21) channels configured.
        while ($true) {

            if ($EnableAutoMode) {
                $ChannelName = $ProviderName + '/' + $(Read-Host "Event Channel log stream")
                
                $ChannelPrefix = $ProviderPrefix
                $ChannelSymbol = Convert-ToSymbol $ChannelName $ChannelPrefix
                
                if ($ChannelSymbol.Length -gt 60) {
                    $ChannelSymbol = Read-Host "The Channel Symbol $ChannelSymbol is too long - Modify"
                }
            }
            else {
                $ChannelName = Read-Host "Event Channel Name"
                $ChannelSymbol = Read-Host "Event Channel Symbol"
            }

            $ChannelData = @{
                ChannelSymbol = $ChannelSymbol
                ChannelName   = $ChannelName
            }

            Write-ManifestChannel -xmlwriter $XmlWriter -ChannelData $ChannelData
            Write-Host "Channel has been successfully added to the Provider $($ProviderData.ProviderName)"

            $EndChannelLoop = Read-Host "Create a new channel? [Y/n]"
            if ($EndChannelLoop -eq 'n') { break }
        }

        Write-ManifestProviderEnd -xmlWriter $XmlWriter
        
        Write-Host "Provider $($ProviderData.ProviderName) has been successfully closed"
        $EndProviderLoop = Read-Host "Create a new provider? [Y/n]"
        if ($EndProviderLoop -eq 'n') { break }
    }

    Write-ManifestEnd -xmlWriter $XmlWriter
    Write-Host "Event Manifest has been written successfully"
}

# 
# Utility functions
#

function Convert-ToSymbol($inputName, $prefix = "") {
    $symbol = $inputName.ToUpper() -replace '[^A-Z0-9]', '_'
    if ($prefix -ne "") {
        return "${prefix}_$symbol"
    }
    return $symbol
}

function Write-ManifestTemplate {
    param (
        [string]$OutputPath
    )

    $XmlWriter = New-Object System.XMl.XmlTextWriter($OutputPath, $null)
        
    # XML Writer Settings
    $xmlWriter.Formatting = "Indented"
    $xmlWriter.Indentation = "4"

    # Write the XML Decleration
    $xmlWriter.WriteStartDocument()

    # Create Instrumentation Manifest
    $xmlWriter.WriteStartElement("instrumentationManifest")
    $xmlWriter.WriteAttributeString("xsi:schemaLocation", "http://schemas.microsoft.com/win/2004/08/events eventman.xsd")
    $xmlWriter.WriteAttributeString("xmlns", "http://schemas.microsoft.com/win/2004/08/events")
    $xmlWriter.WriteAttributeString("xmlns:win", "http://manifests.microsoft.com/win/2004/08/windows/events")
    $xmlWriter.WriteAttributeString("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    $xmlWriter.WriteAttributeString("xmlns:xs", "http://www.w3.org/2001/XMLSchema")
    $xmlWriter.WriteAttributeString("xmlns:trace", "http://schemas.microsoft.com/win/2004/08/events/trace")

    # Create Instrumentation, Events and Provider Elements
    $xmlWriter.WriteStartElement("instrumentation")
    $xmlWriter.WriteStartElement("events")

    return $xmlWriter
}

function Write-ManifestProvider {
    param (
        $xmlWriter,
        $CustomEventsDLL,
        $ProviderData
    )

    $xmlWriter.WriteStartElement("provider")
    $xmlWriter.WriteAttributeString("name", $ProviderData.ProviderName)
    $xmlWriter.WriteAttributeString("guid", $ProviderData.ProviderGuid)
    $xmlWriter.WriteAttributeString("symbol", $ProviderData.ProviderSymbol)
    $xmlWriter.WriteAttributeString("resourceFileName", $CustomEventsDLL)
    $xmlWriter.WriteAttributeString("messageFileName", $CustomEventsDLL)
    $xmlWriter.WriteAttributeString("parameterFileName", $CustomEventsDLL)
    $xmlWriter.WriteStartElement("channels")
}

function Write-ManifestChannel {
    param (
        $xmlwriter,
        $ChannelData
    )

    $xmlWriter.WriteStartElement("channel")	
    $xmlWriter.WriteAttributeString("name", $ChannelData.ChannelName)
    $xmlWriter.WriteAttributeString("chid", ($ChannelData.ChannelName).Replace(' ', ''))
    $xmlWriter.WriteAttributeString("symbol", $ChannelData.ChannelSymbol)
    $xmlWriter.WriteAttributeString("type", "Admin")
    $xmlWriter.WriteAttributeString("enabled", "false")
    $xmlWriter.WriteEndElement() # Closing channel
}

function Write-ManifestProviderEnd {
    param ($xmlWriter)

    $xmlWriter.WriteEndElement() # Closing channels
    $xmlWriter.WriteEndElement() # Closing provider
}

function Write-ManifestEnd {
    param ($xmlWriter)

    $xmlWriter.WriteEndElement() # </events>
    $xmlWriter.WriteEndElement() # </instrumentation>
    $xmlWriter.WriteEndElement() # </instrumentationManifest>
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Finalize
    $xmlWriter.Flush()
    $xmlWriter.Close()
}