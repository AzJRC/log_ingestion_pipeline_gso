
using namespace system.collections.generic

$SUPPORTED_SCHEMA_VERSION = 1.0
$SUPPORTED_EVENT_SCHEMA_VERSION = 1.0

function Build-MetadataQuery {
    param(
        [string]$RootDatabase = (Join-Path -Path $PSScriptRoot -ChildPath '..\QueriesDB' | Resolve-Path)
    )

    $XmlQueryFiles = Get-ChildItem -Path $RootDatabase -Recurse -Filter "*.query.xml" -File

    foreach ($XmlQueryFile in $XmlQueryFiles) {
        $RawXmlLines = Get-Content $XmlQueryFile.FullName

        # 1. Parse comment block metadata
        $Meta = Parse-QueryMetadata -Lines $RawXmlLines

        # 2. Parse <Query> elements
        [xml]$Xml = $RawXmlLines -join "`n"
        $QueryElements = Parse-QueryXmlElements -Xml $Xml

        # 3. Compose final metadata object
        $JsonObject = [ordered]@{
            MetaSchemaVersion = $Meta.MetaSchemaVersion
            QueryName         = $Meta.QueryName
            QueryIntent       = @{ Primary = $Meta.Primary; Secondary = $Meta.Secondary }
            Platform          = $Meta.Platform
            SecurityProfile   = $Meta.SecurityProfile
            Authors           = $Meta.Authors
            References        = $Meta.References
            Tags              = $Meta.Tags
            RequiresAudit     = $Meta.RequiresAudit
            RequiredSettings  = $Meta.RequiredSettings
            Description       = $Meta.Description
            QueryElements     = $QueryElements
        }

        # 4. Write META.JSON
        $OutputJsonPath = $XmlQueryFile.FullName -replace "query.xml", "meta.json"
        $JsonObject | ConvertTo-Json -Depth 10 | Out-File $OutputJsonPath -Encoding UTF8
    }
}

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Utilities\Get-MicrosoftQueryElementSchema.ps1')
# class QueryTypeElement {}
# class QueryElement {}
# class QueryListElement {}

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Utilities\Get-WMTQueryMetadataSchema.ps1')
# class QueryMetadataSchema {}
function Parse-QueryMetadata {
    param(
        [list]$Lines
    )

    $Lines | ForEach-Object {
        
    }
}