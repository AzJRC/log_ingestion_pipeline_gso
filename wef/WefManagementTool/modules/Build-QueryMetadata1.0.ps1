
using namespace system.collections.generic

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Utilities\Get-MicrosoftQueryElementSchema.ps1')
# class QueryTypeElement {}
# class QueryElement {}
# class QueryListElement {}

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Utilities\Get-WMTQueryMetadataSchema.ps1')
# enum MetaSchemaIntentFields
# enum MetaSchemaAuthorFields
# enum MetaSchemaFields
# class QueryMetadataSchema {}

function Build-QueryMetadata {
    param(
        [string]$RootDatabase = (Join-Path -Path $PSScriptRoot -ChildPath '..\QueriesDB' | Resolve-Path)
    )

    $queryXmlFiles = Get-ChildItem -Path $RootDatabase -Recurse -Filter "*.query.xml" -File
    foreach ($queryXmlFile in $queryXmlFiles) {
        $RawQueryXmlLines = Get-Content $queryXmlFile.FullName
        [xml]$QueryXml = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n$RawQueryXmlLines"

        # 0. Validate Schema Version
        $validQueryXml = $false
        $match = $RawQueryXmlLines | Where-Object {
            # The cryptic script ($_ -split ':', 2)[1].Trim() is the value '1.0' in the string 'MetaSchemaVersion: 1.0'
            $_ -match 'MetaSchemaVersion' -and (($_ -split ':', 2)[1].Trim() -eq [QueryMetadataSchema]::SCHEMA_META_VERSION)
        } | Select-Object -First 1
        if ($match) { $validQueryXml = $true }

        if (-not $validQueryXml) {
            throw "[-] Invalid QueryXmlFile MetaSchemaVersion. Supported version is: $([QueryMetadataSchema]::SCHEMA_META_VERSION)"
        }

        # 1. Parse <Query> elements
        $QueryElements = Parse-QueryXmlElements -Xml $QueryXml

        # 2. Parse comment block metadata
        $Meta = Parse-QueryMetadata -Lines $RawQueryXmlLines
        $Meta.ToString()

        # 3. Write META.JSON
        continue    # [Stop] Temporary 
        $OutputJsonPath = $queryXmlFile.FullName -replace "query.xml", "meta.json"
        $JsonObject | ConvertTo-Json -Depth 5 | Out-File $OutputJsonPath -Encoding UTF8
    }
}

function Parse-QueryXmlElements {
    [OutputType([list[QueryElement]])]
    param(
        [xml]$Xml
    )


    $xmlQueryElementList = $Xml.GetElementsByTagName([QuerySchemaTagNames]::Query.ToString())
    ForEach ($xmlQueryElement in $xmlQueryElementList) {
        
        $xmlQueryTypeElementList = (
            $xmlQueryElement.GetElementsByTagName([QuerySchemaTagNames]::Select.ToString()) + 
            $xmlQueryElement.GetElementsByTagName([QuerySchemaTagNames]::Suppress.ToString())
        )

        $rawPathAttribute = $xmlQueryElement.Attributes["Path"].Value

        ForEach ($xmlQueryType in $xmlQueryTypeElementList) {
            $rawQueryType = $xmlQueryType.Name
            $rawXpathQuery = $xmlQueryType.InnerXml
        }

    }

    return $queryElementList
}

function Parse-QueryMetadata {
    [OutputType([QueryMetadataSchema])]
    param(
        [list[string]]$Lines
    )

    $QueryMetadata = [QueryMetadataSchema]::new()

    $Lines | ForEach-Object {
        $currLine = $_

    }

    return $QueryMetadata
}

function Extract-ProvidersFromChannels {
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [list[string]]
        $Channels
    )
    $Providers = [list[string]]::new()
    Foreach ($Channel in $Channels) {
        $Provider = ($Channel -split '/')[0]    # Assumes a structure {provider_name}/{channel_stream_name}
        if ($Provider -ne $Channel) { $Providers.Add($Provider) } 
    }
    return $Providers 
}
