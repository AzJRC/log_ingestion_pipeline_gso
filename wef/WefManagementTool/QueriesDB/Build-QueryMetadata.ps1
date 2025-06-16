using namespace system.collections.generic

<#
AuthorSchema
{
    "name": "author_name",                  # Real person name
    "alias": "author_alias",                # Usernames, aliases, known/common reference names
    "project": "author's_project_name"      # Author's project where he orginally published the query
}

MetadataSchema
{
    "name": "query_name",                                               # descriptive name      
    "description": "query_description",                                 # query description
    "intent": "{Intent} > {SubIntent} > {SubSubIntent}",                # Allowed values for {Category} are n, s, as, ia, sa (and long versions too)
    "events": [1,2,3,4,...],                                            # Events found in the query selectors
    "providers": ["query_provider_1", "query_provider_2", ...],         # Providers found in the query selectors
    "channels": ["query_channel_1", "query_channel_2", ...],            # Channels found in the query selectors
    "authors": [AuthorSchema_1, ...],                                   # Query author
    "attack_mappings": ["technique_id_1", "technique_id_2", ...],       # Query mappings to Mitre Att&ck techniques (and subtechniques)
    "tags": ["tag_1", "tag_2", "tag_3", ...]                            # Related terms to the query's intent
}#>

class QueryAuthor {
    [ValidateNotNullOrEmpty()][string]$AuthorName
    [ValidateNotNullOrEmpty()][string]$AuthorAlias
    [ValidateNotNullOrEmpty()][string]$AuthorProject

    QueryAuthor($AuthorName, $AuthorAlias, $AuthorProject) {
        $this.AuthorName = $AuthorName
        $this.AuthorAlias = $AuthorAlias
        $this.AuthorProject = $AuthorProject
    }
}

class QueryIntent {
    
    [ValidateNotNullOrEmpty()][string]$Intent
    [string]$SubIntent
    [string]$SubSubIntent

    QueryIntent ($Intent, $SubIntent = "", $SubSubIntent = "") {
        $this.Intent = $Intent                  # Any of: Network, System, Application and Services, Identity and Access, Security and Auditing 
        $this.SubIntent = $SubIntent            # E.g. If intent is Network, a SubIntent could be SMB
        $this.SubSubIntent = $SubSubIntent      # E.g. if SubIntent is DCHP, a SubSubIntent could be SMB Client, or File Sharing
    }
}

class QueryMetadata {
    
    [ValidateNotNullOrEmpty()]
    [string]$QueryName
    [QueryIntent]$QueryIntent

    # Optional properties
    # [string]$QueryDescription
    [list[int]]$Events
    [list[string]]$Providers
    [list[string]]$Channels
    [list[QueryAuthor]]$QueryAuthors
    [list[string]]$Tags

    QueryMetadata(
        [string]$QueryName, 
        [QueryIntent]$QueryIntent, 
        # [string]$QueryDescription = "", 
        [list[int]]$Events = [list[int]]::new(), 
        [list[string]]$Providers = [list[string]]::new(), 
        [list[string]]$Channels = [list[string]]::new(), 
        [list[QueryAuthor]]$QueryAuthors = [list[QueryAuthor]]::new(), 
        [list[string]]$Tags = [list[string]]::new()
    ) {
        $this.QueryName = $QueryName
        $this.QueryIntent = $QueryIntent
        # $this.QueryDescription = $QueryDescription
        $this.Events = $Events
        $this.Providers = $Providers
        $this.Channels = $Channels
        $this.QueryAuthors = $QueryAuthors
        $this.Tags = $Tags
    }

}


function Build-MetadataQuery {
    param(
        [Parameter(Mandatory = $false)]
        [string]
        [Alias("Path")]
        $XmlQueryFilePath,

        [Parameter(Mandatory = $false)]
        [string]
        [Alias("Root")]
        $RootDatabase = "$PSScriptRoot\..\QueriesDB"
    )

    # [TODO] If $XmlQueryFilePath is provided, Build only that file.
    

    # If not $XmlQueryFilePath, search for any {base_name}.query.xml without corresponding {base_name}.meta.json.
    # Then, build the .meta.json files for those xml queries.
    # All XML queries are assumed to be located in $RootDatabase

    $XmlQueryFiles = Get-ChildItem -Path $RootDatabase -Recurse -Filter "*.query.xml" -File

    foreach ($XmlQueryFile in $XmlQueryFiles) {

        # Remove .query.xml from the filename (Asummes filename structures {basename}.query.xml)
        $QueryBasename = ($XmlQueryFile.Name -split '.', 0, "SimpleMatch")[0]

        $RawXmlFile = Get-Content -Path $XmlQueryFile.FullName
        [xml]$xml = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n$RawXmlFile"

        $EventList = [list[int]]::new()
        $Channels = [list[string]]::new()
        $Providers = [list[string]]::new()

        # Extract Channel and EventIDs from EACH Selector QueryType element
        foreach ($SelectItem in $xml.Query.Select) {

            # Extract-EventsFromXpathExpression deals with the operations of adding one or many events
            # from each Xpath expression
            $XPathExpression = $SelectItem.'#text'.Trim() -replace ('[ ]+', ' ')
            Extract-EventsFromXpathExpresion -XpathExpression $XPathExpression -EventList $EventList

            # Only one channel per selector; therefore we use Add()
            $Channels.Add($SelectItem.Attributes["Path"].Value)
        }

        # De-duplicate $EventIds and $Channels
        # [TODO]
        # ...

        # Extract Provider from Channel if applicable 
        Extract-ProvidersFromChannels -Channels $Channels -Providers $Providers

        #Extract comment-block information: QueryName, QueryIntent, Author(s), Attack Mapping, and Tags
        $Metadata = [PSCustomObject]@{
            QueryName   = $null
            QueryIntent = $null
            Authors     = @()
            Attack      = @()
            Tags        = @()
        }

        $InCommentBlock = $false
        foreach ($Line in $RawXmlFile) {
            if $(-not ($InCommentBlock) -and ($Line -like "*<!--*")) { $InCommentBlock = $true; continue }
            if $($InCommentBlock -and ($Line -like "*-->*")) { $InCommentBlock = $true; continue }
            if (-not ($InCommentBlock)) { continue }

            $Key, $Value = ($Line -split ':').Trim()

            # Keys always just one word (UpperCammelCase like QueryName or QueryIntent)   
            switch ($Key.ToLower()) {
                'queryname' { $Metadata.QueryName = $Value }
                'queryintent' { $Metadata.QueryIntent = Parse-RawQueryName -RawQueryName $Value }
                'author' { $Metadata.Author = Parse-RawAuthor -RawAuthor $Value }
                'attack' { $Metadata.Attack += $Value }
                'tag' { $Metadata.Tags += $Value }
            }
        }
    }
}


$SINGLE_EVENT_REGEX = '[\s(]?EventID=(?<EventId>\d+)[\s)]?'
function Extract-EventsFromXpathExpresion {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $XpathExpression,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [list[int]]
        $EventList
    )

    # Extract Event Ids from XPath Expression
    $matches = [regex]::Matches($XpathExpression, $SINGLE_EVENT_REGEX)
    foreach ($match in $matches) {
        $eventIdStr = $match.Groups["EventId"].Value
        if ([int]::TryParse($eventIdStr, [ref]$null)) {
            $EventList.Add([int]$eventIdStr)
        }
    }

    return
}

function Extract-ProvidersFromChannels {
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [list[string]]
        $Channels,

        [Parameter(Mandatory = $true)]
        [list[string]]
        [AllowEmptyCollection()]
        $Providers
    )

    Foreach ($Channel in $Channels) {
        $Provider = ($Channel -split '/')[0]    # Assumes a structure {provider_name}/{channel_stream_name}
        if ($Provider -ne $Channel) { $Providers.Add($Provider) } 
    }

    return
}

function Parse-RawQueryIntent {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RawQueryIntent
    )
    # QueryIntent: Identity and Access > SubIntent[Optional] > SubSubIntent[Optional]
    # [TODO]

}

function Parse-RawAuthor {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RawAuthor
    )

    # Author: John Doe, JohnDoe123, WefManagementTool
    $AuthorParts = $RawQueryName -split ',' | ForEach-Object { $_.Trim() }

    # Ensure the array has exactly 3 elements
    while ($AuthorParts.Count -lt 3) {
        $AuthorParts += ""
    }

    $Name = $AuthorParts[0]
    $Alias = $AuthorParts[1]
    $Project = $AuthorParts[2]

    # [TODO] What happen if all authorship data isn't provided?

    try {
        return [QueryAuthor]::new($Name, $Alias, $Project)
    }
    catch {
        Write-Error "Failed to create QueryAuthor object. Check input format. Input: '$RawQueryName'"
        return $null
    }
}

# Run Main
Build-MetadataQuery