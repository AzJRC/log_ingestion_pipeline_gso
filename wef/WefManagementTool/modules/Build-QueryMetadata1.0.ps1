
using namespace system.collections.generic


# Build-MetadataQuery follows the QUERY.XML propietary schema META-1.0
function Build-MetadataQuery {
    param(
        [string]$RootDatabase = (Join-Path -Path $PSScriptRoot -ChildPath '..\QueriesDB' | Resolve-Path)
    )

    $XmlQueryFiles = Get-ChildItem -Path $RootDatabase -Recurse -Filter "*.query.xml" -File

    foreach ($XmlQueryFile in $XmlQueryFiles) {
        $RawXmlLines = Get-Content $XmlQueryFile.FullName

        # 1. Parse comment block metadata
        $Meta = Parse-CommentBlockMetadata -Lines $RawXmlLines
        $EvtMeta = Parse-CommentBlockEventMetadata -Lines $RawXmlLines  # [Unused]

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

Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Utilities\Get-QuerySchemaElements.ps1')
# class QueryTypeElement {}
# class QueryElement {}
# class QUeryListElement {}



class QueryEventMetadata {
    static [string] $SCHEMA_EVT_VERSION = 1.0

    # [TODO]
}

class QueryMetaIntent {

    hidden [ValidateNotNullOrEmpty()][string]$Primary   # Unique, mandatory
    hidden [list[string]]$Secondary                     # Non-unique, optional

    [void] SetIntent([string]$PrimaryIntent, [list[string]]$SecondaryIntent) {
        $this.Primary = $PrimaryIntent
        if ($SecondaryIntent.Count -gt 0) { $this.Secondary = $SecondaryIntent }
    }
}

class QueryMetadata {
    static [string] $SCHEMA_META_VERSION = 1.0

    # Mandatory fields
    [ValidateNotNullOrEmpty()][string]$QueryName
    [ValidateNotNullOrEmpty()][QueryMetaIntent]$Intent

}

function Parse-CommentBlockMetadata {
    param(
        [list]$Lines
    )

    $Lines | ForEach-Object {
        
    }
}