# Write-WecEventManifest_Utils.ps1

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