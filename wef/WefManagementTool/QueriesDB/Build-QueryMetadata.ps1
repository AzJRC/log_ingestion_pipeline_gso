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

# [NOTE] Program with PowerShell 7.5.1 works

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

    # Network, System, Application and Services, Security and Auditing, Identity and Access 
    static [string[]] $AllowedIntents = @('n', 's', 'as', 'sa', 'ia')   
    
    [ValidateNotNullOrEmpty()][string]$Intent
    [string]$SubIntent
    [string]$SubSubIntent

    QueryIntent ([string]$Intent, [string]$SubIntent = "", [string]$SubSubIntent = "") {
        $this.Intent = $Intent                      # Any of the $AllowedIntents 
        $this.SubIntent = $SubIntent                # E.g. If intent is Network, a SubIntent could be SMB
        $this.SubSubIntent = $SubSubIntent          # E.g. if SubIntent is DCHP, a SubSubIntent could be SMB Client, or File Sharing
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
    [list[string]]$AttackMappings
    [list[string]]$Tags

    QueryMetadata(
        [string]$QueryName, 
        [QueryIntent]$QueryIntent, 
        # [string]$QueryDescription = "",   
        [list[int]]$Events = [list[int]]::new(), 
        [list[string]]$Providers = [list[string]]::new(), 
        [list[string]]$Channels = [list[string]]::new(), 
        [list[QueryAuthor]]$QueryAuthors = [list[QueryAuthor]]::new(), 
        [list[string]]$AttackMappings = [list[string]]::new(),
        [list[string]]$Tags = [list[string]]::new()
    ) {
        $this.QueryName = $QueryName
        $this.QueryIntent = $QueryIntent
        # $this.QueryDescription = $QueryDescription
        $this.Events = $Events
        $this.Providers = $Providers
        $this.Channels = $Channels
        $this.QueryAuthors = $QueryAuthors
        $this.AttackMappings = $AttackMappings
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

    $XmlQueryFiles = Get-ChildItem -Path $RootDatabase -Recurse -Filter "*.query.xml" -File

    foreach ($XmlQueryFile in $XmlQueryFiles) {

        # Strongly typed variables
        [string]$QueryName = $null
        [QueryIntent]$QueryIntent = $null
        [List[int]]$EventList = [List[int]]::new()
        [List[string]]$Providers = [List[string]]::new()
        [List[string]]$Channels = [List[string]]::new()
        [List[QueryAuthor]]$Authors = [List[QueryAuthor]]::new()
        [List[string]]$Attack = [List[string]]::new()
        [List[string]]$Tags = [List[string]]::new()

        $RawXmlFile = Get-Content -Path $XmlQueryFile.FullName
        [xml]$xml = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n$RawXmlFile"

        # Extract Channel and EventIDs from EACH Selector QueryType element
        foreach ($SelectItem in $xml.Query.Select) {
            $XPathExpression = $SelectItem.'#text'.Trim() -replace ('[ ]+', ' ')
            $EventList = Extract-EventsFromXpathExpresion -XpathExpression $XPathExpression

            $SelectorChannelPath = $SelectItem.Attributes["Path"].Value
            $Channels.Add($SelectorChannelPath)
        }

        # Extract Provider from Channel if applicable
        if ($Channels.Count -gt 0) {
            $Providers = Extract-ProvidersFromChannels -Channels $Channels
        }

        # Extract comment-block metadata
        $InCommentBlock = $false
        foreach ($Line in $RawXmlFile) {
            if (-not ($InCommentBlock) -and ($Line -like "*<!--*")) { $InCommentBlock = $true; continue }
            if ($InCommentBlock -and ($Line -like "*-->*")) { $InCommentBlock = $true; continue }
            if (-not ($InCommentBlock)) { continue }

            $Key, $Value = ($Line -split ':').Trim()

            switch ($Key.ToLower()) {
                'queryname' { $QueryName = $Value.ToLower() -replace ('[ ]+', '_'); break }
                'queryintent' { $QueryIntent = Parse-RawQueryIntent -RawQueryIntent $Value; break }
                'author' { 
                    $authorObj = Parse-RawQueryAuthor -RawQueryAuthor $Value
                    if ($authorObj -is [QueryAuthor]) {
                        $Authors.Add($authorObj)
                    }
                    break
                }
                'attack' { $Attack.Add($Value); break }
                'tag' { $Tags.Add($Value); break }
            }
        }

        # Build the final strongly-typed QueryMetadata object
        $QueryMetadata = [QueryMetadata]::new(
            $QueryName, 
            $QueryIntent, 
            $EventList, 
            $Providers, 
            $Channels, 
            $Authors,
            $Attack,
            $Tags
        )

        # Write to JSON file
        $OutputJsonPath = $XmlQueryFile.FullName -replace ("query.xml", "meta.json")
        Write-QueryMetadataFile -QueryMetadata $QueryMetadata -OutputFile $OutputJsonPath
    }

    return
}

$SINGLE_EVENT_REGEX = '[\s(]?EventID=(?<EventId>\d+)[\s)]?'
function Extract-EventsFromXpathExpresion {
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $XpathExpression
    )

    $EventList = [list[int]]::new()

    # Extract Event Ids from XPath Expression
    $EventIdMatches = [regex]::Matches($XpathExpression, $SINGLE_EVENT_REGEX)
    foreach ($Match in $EventIdMatches) {
        $eventIdStr = $Match.Groups["EventId"].Value
        if ([int]::TryParse($eventIdStr, [ref]$null)) {
            $EventList.Add([int]$eventIdStr)
        }
    }

    return $EventList
}

function Extract-ProvidersFromChannels {
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [list[string]]
        $Channels
    )

    $Providers = [list[int]]::new()

    Foreach ($Channel in $Channels) {
        $Provider = ($Channel -split '/')[0]    # Assumes a structure {provider_name}/{channel_stream_name}
        if ($Provider -ne $Channel) { $Providers.Add($Provider) } 
    }

    return $Providers 
}


function Parse-RawQueryIntent {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RawQueryIntent
    )
    # QueryIntent: Identity and Access > SubIntent[Optional] > SubSubIntent[Optional]
    $IntentParts = $RawQueryIntent -split '>' | ForEach-Object { $_.Trim().ToLower() -replace ('[ ]+', '_') }

    # Ensure the array has exactly 3 elements (More than 3 elements are ignored)
    while ($IntentParts.Count -lt 3) {
        $IntentParts += ""
    }

    $Intent = $IntentParts[0]
    $SubIntent = $IntentParts[1]
    $SubSubIntent = $IntentParts[2]

    # Intent is mandatory
    if (-not $Intent) {
        Write-Host "[*] Intent of the query wasn't found." -ForegroundColor gray

        while ($true) {
            $IntentInput = Read-Host "Type the intent of the query (`n`, `s`, `as`, `sa`, `ia`)"
            if ($IntentInput.ToLower() -in [QueryIntent]::AllowedIntents) {
                $Intent = $IntentInput
                break
            }
            else {
                Write-Host "[!] Invalid intent. Valid options are: $([QueryIntent]::AllowedIntents -join ', ')" -ForegroundColor Yellow
            }
        }
    }

    try {
        return [QueryIntent]::new($Intent, $SubIntent, $SubSubIntent)
    }
    catch {
        Write-Error "[-] Failed to create QueryAuthor object. Check input format. Input: '$RawQueryName'"
        return $null
    }
}

function Parse-RawQueryAuthor {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $RawQueryAuthor
    )

    # Author: John Doe, JohnDoe123, WefManagementTool
    $AuthorParts = $RawQueryAuthor -split ',' | ForEach-Object { $_.Trim() }

    # Ensure the array has exactly 3 elements
    while ($AuthorParts.Count -lt 3) {
        $AuthorParts += ""
    }

    $Name = $AuthorParts[0]
    $Alias = $AuthorParts[1]
    $Project = $AuthorParts[2]

    # If no authorship data was provided default $Alias to Anonymous
    if (-not $Name -and -not $Alias -and -not $Project) {
        $Alias = "Anonymous"
        Write-Host "[*] Authorship data wasn't found. Default alias set to 'Anonymous'" -ForegroundColor gray
    }

    try {
        return [QueryAuthor]::new($Name, $Alias, $Project)
    }
    catch {
        Write-Error "Failed to create QueryAuthor object. Check input format. Input: '$RawQueryName'"
        return $null
    }
}

function Write-QueryMetadataFile {
    param (
        [Parameter(Mandatory = $true)]
        [QueryMetadata]
        $QueryMetadata,

        [Parameter(Mandatory = $true)]
        [string]
        $OutputFile
    )

    ConvertTo-Json -InputObject $QueryMetadata -Compress | Out-File $OutputFile
}

# Run Main
Build-MetadataQuery