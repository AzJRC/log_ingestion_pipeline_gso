
using namespace system.collections.generic

# <channel name="$CHANN_NAME" chid="$CHANN_NAME_CHID" symbol="CHANN_NAME_SYMBOL" 
#   type="%TYPE(Admin)" enabled="$STATUS(false)" 
# />
class ChannelElement {
    [ValidateNotNullOrEmpty()][string]$ChannelName
    [ValidateNotNullOrEmpty()][string]$ChannelChidName
    [ValidateNotNullOrEmpty()][string]$ChannelSymbolName
    [ValidateNotNullOrEmpty()][string]$ChannelType
    [ValidateNotNullOrEmpty()][string]$ChannelStatus

    # >-- ChannelElement Constructor --<
    ChannelElement($ChannelName, $ChannelChidName = $null, $ChannelSymbolName = $null, $ChannelType = 'Admin', $ChannelStatus = 'false') {
        $this.ChannelName = $ChannelName
        $this.ChannelType = $ChannelType
        $this.ChannelStatus = $ChannelStatus
        $this.ChannelChidName = if ( $null -eq $ChannelChidName ) { $this.DeriveChannelChidName($ChannelName) } else { $ChannelChidName }
        $this.ChannelSymbolName = if ( $null -eq $ChannelSymbolName ) { $this.DeriveChannelSymbolName($ChannelName) } else { $ChannelSymbolName }
    }

    # Pseudo-Private methods
    hidden [string] DeriveChannelChidName($ChannelName) {
        # The chid parameter in the Manifest does not allow spaces
        return $ChannelName.Replace(' ', '')
    }


    hidden [string] DeriveChannelSymbolName($ProviderName) {
        $HostName = [System.Net.Dns]::GetHostName()
        $SymbolName = ("$HostName $ProviderName").ToUpper() -replace '[^A-Z0-9]', '_'
        return $SymbolName
    }
}

# <provider name="$PROV_NAME" guid="{$GUID}" symbol="$PROV_NAME_SYMBOL" 
#   resourceFileName="C:\Windows\System32\{OUTPUT_DLL}.dll" 
#   messageFileName="C:\Windows\System32\{OUTPUT_DLL}.dll" parameterFileName="C:\Windows\System32\{OUTPUT_DLL}.dll"
# > ... </provider>
class ProviderElement {
    static [string] $DLL_PARENT_PATH = 'C:\Windows\System32'
    static [string] $DLL_FILENAME = 'CustomEventChannels'

    # Fundamental properties of the <Provider> element
    [ValidateNotNullOrEmpty()][string]$ProviderName
    [ValidateNotNullOrEmpty()][string]$ProviderGUID
    [ValidateNotNullOrEmpty()][string]$ProviderSymbolName
    hidden [ValidateNotNullOrEmpty()][string]$ResourceFileName
    hidden [ValidateNotNullOrEmpty()][string]$MessageFileName
    hidden [ValidateNotNullOrEmpty()][string]$ParameterFileName

    # Content of the <Provider> element
    $Channels = [list[ChannelElement]]::new()

    # >-- Constructor --<
    ProviderElement ($ProviderName, $ProviderGUID = $null, $ProviderSymbolName = $null, $DllOutputPath = $null) {
        $this.ProviderName = $ProviderName
        $this.ProviderGUID = if ($null -eq $ProviderGUID) { "{$((New-Guid).Guid)}" } else { "{$ProviderGuid}" }
        $this.ProviderSymbolName = if ( $null -eq $ProviderSymbolName) { $this.DeriveProviderSymbolName($ProviderName) } else { $ProviderSymbolName }
        $this.ResourceFileName = if ($null -eq $DllOutputPath) { $this.GetDllPath() } else { $DllOutputPath }
        $this.MessageFileName = if ($null -eq $DllOutputPath) { $this.GetDllPath() } else { $DllOutputPath }
        $this.ParameterFileName = if ($null -eq $DllOutputPath) { $this.GetDllPath() } else { $DllOutputPath }
    }

    hidden [string] DeriveProviderSymbolName($ProviderName) {
        $HostName = [System.Net.Dns]::GetHostName()
        $SymbolName = ("$HostName $ProviderName").ToUpper() -replace '[^A-Z0-9]', '_'
        return $SymbolName
    }

    hidden [string] GetDllPath() {
        $Path = [ProviderElement]::DLL_PARENT_PATH
        $Filename = [ProviderElement]::DLL_FILENAME + ".dll"

        # Detect if running on Linux (For WSL)
        $System = [System.Environment]::OSVersion.Platform

        if ($System -eq 'Win32NT') {
            # Use Join-Path normally on Windows
            $DllPath = Join-Path -Path $Path -ChildPath $Filename
        } else {
            # Just build the string manually (avoid Join-Path)
            $Path = $Path.TrimEnd('\', '/')
            $DllPath = "$Path\$Filename"
        }

        return $DllPath
    }

}

# Load dependencies
$CommonUtilities = "$PSScriptRoot/Utilities/CommonUtilities.ps1"
if (Test-Path $CommonUtilities) { . $CommonUtilities } else { Write-HostMessage -err -Message "Missing dependency: [CommonUtilities.ps1]"; return 1 }

# ======== Main ========
function Write-EventManifestFile {
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            HelpMessage = "Manifest file output path.")]
        [Alias("Man")]
        [string]
        $ManifestFileOutputPath
    )

    if (-not $ManifestFileOutputPath) {
        $BasePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
        $ResolvedBasePath = [System.IO.Path]::GetFullPath($BasePath)
        $FileName = ([ProviderElement]::DLL_FILENAME) + ".man"
        $ManifestFileOutputPath = Join-Path -Path $ResolvedBasePath -ChildPath "Files\$FileName"
    }

    # Create $OutputPath if not exists
    if (-not (Test-Path $ManifestFileOutputPath)) {
        Write-HostMessage -alert -Message "OutputPath does not exist. Creating it..."
        New-Item -Path $ManifestFileOutputPath -Force > $null
    }

    # Initialize list of providers
    $Providers = [list[ProviderElement]]::new()

    # Accounting variables
    $ManifestFileWritten = $false

    # Configuration
    $AutomaticMode = $true  # You should not disable this, although you can.

    if ($AutomaticMode) { Write-HostMessage -Message "Automatic mode enabled" }

    # Main Loop Control
    $ContinueLoop = $true
    while ($ContinueLoop) {
        Write-HostTitle -Message "Event Manifest Writer"

        Write-HostMenu -Message "Select an option:"
        Write-HostMenuOption -OptionNumber 1 -Message "Add new provider"
        Write-HostMenuOption -OptionNumber 2 -Message "Generate manifest file based on a template"
        Write-HostMenuOption -OptionNumber 3 -Message "Inspect providers"
        Write-HostMenuOption -OptionNumber 4 -Message "Write manifest file"
        Write-HostMenuOption -OptionNumber 5 -Message "Exit"

        Write-BlankLine

        $Option = Read-HostInput -Message "Enter option number" -Prompt ">"
        switch ($Option) {
            1 {
                # Add new provider
                $NewProvider = Get-NewProvider
                $Providers.add($NewProvider)
                Write-HostMessage -success -Message "Provider added successfully"
            }
            2 {
                # [TODO] Generate manifest based on template
                Write-HostMessage -warning -Message "[TODO] functionality in progress"
            }
            3 {
                # [TODO] Inspect providers
                Write-HostMessage -warning -Message "[TODO] functionality in progress"
            }
            4 {
                # Write manifest file
                Write-InstrumentationManifestXmlFile -OutputPath $ManifestFileOutputPath -Providers $Providers
                $ManifestFileWritten = $true
                Write-HostMessage -success -Message "Manifest file written."
            }
            5 {
                if (-not $ManifestFileWritten) {
                    Write-HostMessage -warning -Message "You haven't written the manifest file"
                    $Exit = Read-HostInput -Message "Are you sure you want to exit? [ y / N ]" -AllowString
                    if ($Exit.ToUpper() -ne "Y") {
                        break  # Stay in loop
                    }
                }
                $ContinueLoop = $false  # Exit loop cleanly
            }
            default {
                Write-HostMessage -err "Invalid option"
            }
        }
    }

    # After loop, Export CSV if Manifest was written
    if ($ManifestFileWritten) {
        Export-ProvidersChannelsCsv -OutputPath $ManifestFileOutputPath -Providers $Providers
    }

    return
}

function Get-NewProvider {

    Write-HostMessage -Message "Recommended provider name structure: WEC-[Domain/NonDomain]-[Clients/Servers/Controllers/Other]"
    Write-HostMessage -Message "E.g. WEC-Domain-Clients"
    Write-HostMessage -Message "E.g. WEC-NonDomain-Servers"

    Write-BlankLine

    if ($AutomaticMode) { Write-HostMessage "Your computer's hostname will be prepended to the symbolic name of your provider." }
    $ProviderName = Read-HostInput -Message "Provider name" -AllowString

    if ($AutomaticMode) {
        $NewProvider = [ProviderElement]::new($ProviderName, $null, $null, $null)
    }
    else {
        # [TODO] Request remaining parameters too
        # $NewProvider = [ProviderElement]::new($ProviderName, $ProviderGUID, $ProviderSymbolName, $DllOutputPath)
    }

    if (-not ($ChannelListTemplates.Count -eq 0) -and $AutomaticMode) {
        $StoreChannelsTemplate = Read-HostInput -Message "Do you want to import one of your channel templates? [ Y / n ]" -AllowString
        if ($StoreChannelsTemplate.ToUpper() -ne "N") {
            $TemplateId = Read-HostInput -Message "Enter the Template Identifier" -AllowString
            $ChannelsToImport = $ChannelListTemplates[$TemplateId]
            foreach ($Channel in $ChannelsToImport) {
                # Adjust $Channels.ChannelName by prepend the currrent $Provider.ProviderName to the channel stream
                $Parts = $Channel.ChannelName -split '/'
                $AdjustedChannelName = "$($NewProvider.ProviderName)/$($Parts[1])"
                $NewChannel = [ChannelElement]::new($AdjustedChannelName, $null, $null, 'Admin', 'false')
                $NewProvider.Channels.Add($NewChannel)
            }
            Write-HostMessage -Message "Template has been imported."
            $MoreChannels = Read-HostInput -Message "Do you want to add more channels? [ y / N ]" -AllowString
            if ($MoreChannels.ToUpper() -ne "Y") {
                return $NewProvider
            }
        }
    }
    
    Set-ProviderChannels -Provider $NewProvider
    return $NewProvider
}

$ChannelListTemplates = [ordered] @{}

function Set-ProviderChannels {
    param([ProviderElement]$Provider)

    Write-HostTitle -Message "$($Provider.ProviderName) channel configuration"

    if ( $AutomaticMode ) { Write-HostMessage "Your provider's name will be prepended to the channel stream." }

    while ($true) {
        if ( $AutomaticMode ) {
            Write-HostMessage -Message "[$($Provider.ProviderName)/{ChannelStream}]"
            $ChannelStream = Read-HostInput -Message "Add a new ChannelStream [Or nothing to exit]" -AllowString

            Write-BlankLine

            if ($ChannelStream -eq "") { break }

            $ChannelName = $Provider.ProviderName + "/" + $ChannelStream
            $NewChannel = [ChannelElement]::new($ChannelName, $null, $null, 'Admin', 'false')
        }
        else {
            # [TODO] Request remaining parameters too
            # $NewChannel = [ChannelElement]::new($ChannelName, $ChannelSymbolName, $ChannelType, $ChannelStatus)
        }
        $Provider.Channels.Add($NewChannel)
    }

    if ( $AutomaticMode ) {
        $StoreChannelsTemplate = Read-HostInput -Message "Do you want to store your channels as a template? [ Y / n ]" -AllowString
        if ($StoreChannelsTemplate.ToUpper() -ne "N") {
            $TemplateId = Read-HostInput -Message "Template Identifier" -AllowString
            $ChannelListTemplates.Add($TemplateId, $Provider.Channels)
            Write-HostMessage -Message "Template has been saved. You can import it when you create another provider"
        }
    }

    return
}

function Write-InstrumentationManifestXmlFile {
    param(
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [Parameter(Mandatory = $true)][list[ProviderElement]]$Providers
    )

    if (-not (Test-Path $OutputPath)) {
        Write-HostMessage -err "Invalid OutputPath. Maybe the path does not exists."
        return 1
    }

    $settings = New-Object System.Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.Encoding = [System.Text.Encoding]::UTF8

    $xmlWriter = [System.Xml.XmlWriter]::Create($OutputPath, $settings)

    $xmlWriter.WriteStartDocument()

    # Begin Instrumentation Manifest
    $xmlWriter.WriteStartElement("instrumentationManifest", "http://schemas.microsoft.com/win/2004/08/events")

    $xmlWriter.WriteAttributeString("xmlns", "xs", $null, "http://www.w3.org/2001/XMLSchema")
    $xmlWriter.WriteAttributeString("xmlns", "xsi", $null, "http://www.w3.org/2001/XMLSchema-instance")
    $xmlWriter.WriteAttributeString("xmlns", "win", $null, "http://manifests.microsoft.com/win/2004/08/windows/events")
    $xmlWriter.WriteAttributeString("xmlns", "trace", $null, "http://schemas.microsoft.com/win/2004/08/events/trace")
    $xmlWriter.WriteAttributeString("xsi", "schemaLocation", "http://www.w3.org/2001/XMLSchema-instance", "http://schemas.microsoft.com/win/2004/08/events eventman.xsd")

    # Create Instrumentation, Events and Provider Elements
    $xmlWriter.WriteStartElement("instrumentation")
    $xmlWriter.WriteStartElement("events")
    
    foreach ($Provider in $Providers) {
        # Add Providers
        $xmlWriter.WriteStartElement("provider")
        $xmlWriter.WriteAttributeString("name", $Provider.ProviderName)
        $xmlWriter.WriteAttributeString("guid", $Provider.ProviderGUID)
        $xmlWriter.WriteAttributeString("symbol", $Provider.ProviderSymbolName)
        $xmlWriter.WriteAttributeString("resourceFileName", $Provider.ResourceFileName)
        $xmlWriter.WriteAttributeString("messageFileName", $Provider.MessageFileName)
        $xmlWriter.WriteAttributeString("parameterFileName", $Provider.ParameterFileName)

        $xmlWriter.WriteStartElement("channels")
        foreach ($Channel in $Provider.Channels) {
            # Add Channels
            $xmlWriter.WriteStartElement("channel")
            $xmlWriter.WriteAttributeString("name", $Channel.ChannelName)
            $xmlWriter.WriteAttributeString("chid", $Channel.ChannelChidName)
            $xmlWriter.WriteAttributeString("symbol", $Channel.ChannelSymbolName)
            $xmlWriter.WriteAttributeString("type", $Channel.ChannelType)
            $xmlWriter.WriteAttributeString("enabled", $Channel.ChannelStatus)
            $xmlWriter.WriteEndElement()    # </channel>
            
        }
        $xmlWriter.WriteEndElement()    # </channels>
        
        $xmlWriter.WriteEndElement()    # </provider>
    }

    $XmlWriter.WriteEndElement()    # </events>
    $XmlWriter.WriteEndElement()    # </instrumentation>
    $xmlWriter.WriteEndElement()    # </instrumentationManifest>
    $xmlWriter.WriteEndDocument()

    $xmlWriter.Flush()
    $xmlWriter.Close()

    Write-HostMessage -success -Message "Instrumentation Manifest successfully written to:"
    Write-HostMessage -success -Message "$OutputPath"

    Write-BlankLine
    return
}

function Export-ProvidersChannelsCsv {
    param(
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [Parameter(Mandatory = $true)][list[ProviderElement]]$Providers
    )

    Write-HostMessage -Message "Exporting Providers and Channels summary to CSV..."

    $SummaryList = foreach ($Provider in $Providers) {
        foreach ($Channel in $Provider.Channels) {
            [PSCustomObject]@{
                Provider       = $Provider.ProviderName
                ProviderSymbol = $Provider.ProviderSymbolName
                Channel        = $Channel.ChannelName
                ChannelSymbol  = $Channel.ChannelSymbolName
            }
        }
    }

    $CsvOutputPath = Join-Path -Path (Split-Path -Path $OutputPath -Parent) -ChildPath "ProvidersChannelsSummary.csv"
    $SummaryList | Export-Csv -Path $CsvOutputPath -Encoding UTF8 -NoTypeInformation

    Write-HostMessage -success -Message "CSV summary exported to: $CsvOutputPath"
}

# Run main
Write-EventManifestFile