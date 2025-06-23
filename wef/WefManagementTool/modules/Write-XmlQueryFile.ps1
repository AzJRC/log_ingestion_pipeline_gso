using namespace system.collections.generic
class QueryTypeElement {
    static [string] $QUERY_TYPE_SUPPRESS = 'Suppress'
    static [string] $QUERY_TYPE_SELECT = 'Select'

    [ValidateNotNullOrEmpty()][string]$Type             # select | suppress
    [ValidateNotNullOrEmpty()][string]$Channel          # Event channel, like Security or Microsoft-Windows-SMBServer/Security
    [ValidateNotNullOrEmpty()][string]$XPath            # XPath expression, like *[System[(EventID=4624)]]
    [list[int]]$Events

    QueryTypeElement($Type, $Channel, $XPath) {
        $this.Type = $Type 
        $this.Channel = $Channel
        $this.XPath = $XPath
        $this.Events = $this.ParseXPathEvents($XPath)
    }

    [list[int]] ParseXPathEvents($XPath) {
        $EventList = [list[int]]::new()

        if (-not ($XPath -match 'EventID')) {
            return $EventList
        }
        
        $SingleEventRegex = 'EventID\s?=\s?(\d+)'
        $RangeEventRegex = 'EventID\s?&gt;=\s(\d+)\sand\sEventID\s?&lt;=\s?(\d+)'

        $SingleEventMatches = [regex]::Matches($XPath, $SingleEventRegex)
        foreach ($MatchGroup in $SingleEventMatches) {
            $EventList.Add([int]$MatchGroup.Groups[1].Value)
        }

        $RangeEventMatches = [regex]::Matches($XPath, $RangeEventRegex)
        foreach ($MatchGroup in $RangeEventMatches) {
            $EventRangeLowerBound = [int]$MatchGroup.Groups[1].Value
            $EventRangeHigherBound = [int]$MatchGroup.Groups[2].Value
            foreach ($i in $EventRangeLowerBound..$EventRangeHigherBound) {
                $EventList.Add($i)
            }
        }
        return $EventList
    }
}

class QueryElement {
    [int]$QueryId
    $SelectQueryElements = [list[QueryTypeElement]]::new()
    $SuppressQueryElements = [list[QueryTypeElement]]::new()

    QueryElement($QueryId) {
        $this.QueryId = $QueryId
    }

    [void] AddQueryTypeElement([QueryTypeElement]$QueryTypeElement) {
        if ($QueryTypeElement.Type -eq [QueryTypeElement]::QUERY_TYPE_SELECT) {
            $this.SelectQueryElements.Add($QueryTypeElement)
        }
        elseif ($QueryTypeElement.Type -eq [QueryTypeElement]::QUERY_TYPE_SUPPRESS) {
            $this.SuppressQueryElements.Add($QueryTypeElement)
        }
        else {
            throw "Invalid Type: $($QueryTypeElement.Type)"
        }
    }

    [list[QueryTypeElement]] GetQueryTypeElements() {
        return ($this.SelectQueryElements + $this.SuppressQueryElements)
    }

    [list[QueryTypeElement]] GetSelectQueryTypeElements() {
        return ($this.SelectQueryElements)
    }

    [list[QueryTypeElement]] GetSupressQueryTypeElements() {
        return ($this.SuppressQueryElements)
    }
}

class QueryListElement {
    $QueryElements = [list[QueryElement]]::new()

    [void] AddQueryElement($QueryElement) {
        $this.QueryElements.Add($QueryElement)
    }

    [list[QueryElement]] GetQueryElements() {
        return $this.QueryElements
    }

    [QueryElement] GetLastQueryElement() {
        return $this.QueryElements[-1]
    }

    [void] WriteQueryListElement($OutputPath) {
        Write-QueryListXmlFile -QueryList $this.QueryElements -OutputPath $OutputPath
    }

    [int] GetQueryTypeElementCount() {
        $count = 0
        Foreach ($QueryElement in $this.QueryElements) {    
            $count += $QueryElement.GetQueryTypeElementCount().Count
        }
        return $count
    }
}

# Helper global variables
$AvailableChannels = $(wevtutil.exe el) # List of Windows Event Logs

# Load dependencies
$CommonUtilities = "$PSScriptRoot/Utilities/CommonUtilities.ps1"
if (Test-Path $CommonUtilities) { . $CommonUtilities } else { Write-HostMessage -err -Message "Missing dependency: [CommonUtilities.ps1]"; return 1 }

<#
.SYNOPSIS
[TODO]

.DESCRIPTION
[TODO]
#>
function Write-XmlQueryFile {
    param(
        [string]$OutputPath = "$PSScriptRoot\..\Files\SubscriptionEventXmlQuery.xml"
    )

    # Create $OutputPath if not exists
    if (-not (Test-Path $OutputPath)) {
        Write-HostMessage -alert -Message "OutputPath does not exist. Creating it..."
        New-Item -Path $OutputPath -Force > $null
    }

    # Initialize QueryElementList
    $QueryList = [QueryListElement]::new()

    # AccountingVariables
    $XmlFileWritten = $false
    

    while ($true) {

        $QueryTypeElementCount = 0
        foreach ($QueryElement in $QueryList.QueryElements) {
            $QueryTypeElementCount = $QueryElement.SelectQueryElements.Count + $QueryElement.SuppressQueryElements.Count
        }

        Write-HostTitle -Message "Event XML Writer Module"
        Write-HostMessage -Message "QueryElementCount: [$($QueryList.QueryElements.Count)]"
        Write-HostMessage -Message "QueryTypeElementCount: [$QueryTypeElementCount]"

        Write-BlankLine

        Write-HostMenu -Message "Select an option:"
        Write-HostMenuOption -OptionNumber 1 -Message "Add new QueryElement"
        Write-HostMenuOption -OptionNumber 2 -Message "Import QueryElement"
        Write-HostMenuOption -OptionNumber 3 -Message "Inspect QueryList"
        Write-HostMenuOption -OptionNumber 4 -Message "Write QueryList XML File"
        Write-HostMenuOption -OptionNumber 5 -Message "Exit"

        Write-BlankLine

        $Option = Read-HostInput -Message "Enter option number" -Prompt ">"
        Switch ($Option) {
            1 {    
                try {
                    $NewQueryElement = [QueryElement]::new($QueryElementId)
                    Write-NewQueryElement -QueryElementId ($QueryList.QueryElements.Count + 1) -QueryElement $NewQueryElement
                }
                catch { 
                    Write-HostMessage -err -Message "Failed to create new QueryElement"
                    Write-Host $_
                    break
                }
                # treat $NewQueryElement as a collection; user may import various query elements
                foreach ($QueryElement in @($NewQueryElement)) {
                    $QueryList.AddQueryElement($QueryElement)
                }

                Write-HostMessage -success -Message "QueryElement added successfully"
                break
            }
            2 {
                # [TODO]
                # Import QueryElement -> <Query> block
                # Queries can be categorized by the intent of the event:
                #   System events, Network events, Security & Auditing events, Applications and Services events, and Identity & Access events
                # Queries can also be subcategorized. E.g. Network -> SMB, System -> Registry change, or Identity and Acess -> User authentication
                # Query blocks are also tagged with author name. E.g. 
                $NewQueryElement = [QueryElement]::new($QueryElementId)
                Search-QueryElementIdentifier -QueryElementId ($QueryList.QueryElements.Count + 1) -QueryElement $NewQueryElement
                Write-HostMessage -success -Message "QueryElement added successfully"
                break
            }
            3 {
                # [TODO]
                # Broken functionality after refactoring classes
                Write-HostMessage -warning -Message "[TODO] Broken Functionality"
                $QueryList.GetQueryElements() | ForEach-Object {
                    Write-HostMessage -Message "QueryElement ID: $($_.QueryId)"
                    $_.QueryTypeElements | ForEach-Object {
                        Write-HostMessage -NoSymbol -Message "Type: $($_.Type) - Channel: $($_.Channel) - XPath: $($_.XPath)" 
                    }
                }
            }
            4 {
                $QueryList.WriteQueryListElement($OutputPath)
                $XmlFileWritten = $true
            }
            5 {
                if (-not $XmlFileWritten) {
                    Write-HostMessage -warning -Message "You haven't write the QueryList XML File"
                    $Exit = Read-HostInput -Message "Are you sure you want to exit? [ y / N ]" -AllowString
                    if ($Exit.ToUpper() -ne "Y") {
                        break
                    }
                }
                return
            }
            default { Write-HostMessage -err "Invalid option" }
        }
    }
}

function Write-NewQueryElement {
    param(
        [int]$QueryElementId,
        [QueryElement]$QueryElement
    )

    $LocalQueryTypeCount = 0

    # QueryElementLoop
    Write-HostTitle -Message "QueryElement #$QueryElementId"
    while ($true) {
        
        if ($LocalQueryTypeCount -gt 0) {
            $FinishQuery = Read-HostInput -Message "Type 'q' to finish the QueryElement" -Prompt ":" -AllowString
            if ($FinishQuery.ToUpper() -eq "Q") {
                
                # Run Query Optimization/Normalization
                Write-HostMessage -Message "Attempting QueryElement Normalization..."
                try {
                    [QueryElement]$NormalizedQueryElement = Get-NormalizedQueryElement -QueryElement $QueryElement
                }
                catch {
                    Write-HostMessage -warning -Message "Normalization unsuccessuful"
                    return $QueryElement
                }
                $QueryElement.SelectQueryElements = $NormalizedQueryElement.SelectQueryElements
                $QueryElement.SuppressQueryElements = $NormalizedQueryElement.SuppressQueryElements
                return
            }
            Write-BlankLine   
        }
        

        # [TODO] Optionally, Import query
        # User can import Suppress/Select unique queries like in the option Import Query (block) asked before
        # The difference is that there is more selectivity of which Suppress/Select queries to include
        # User can search for queries in the same way as before
        # $ImportQuery = Read-HostInput -Message "Do you want to import an existing query or queries? [ Y / n ]" -Prompt ":" -AllowString
        # if ($ImportQuery.ToUpper() -ne "N") {
        #     [TODO]
        # }
        # Write-BlankLine   

        # Obtain QueryType
        while ($true) {
            $QueryType = (Read-HostInput -Message "What Query Type? [ SELECT(1) / SUPPRESS(2) ]" -Prompt ":" -AllowString).ToUpper()
            $QueryType = if ($QueryType -in @('1', 'SELECT')) { [QueryTypeElement]::QUERY_TYPE_SELECT } 
            elseif ($QueryType -in @('2', 'SUPPRESS')) { $[QueryTypeElement]::QUERY_TYPE_SUPPRESS }
            else {
                Write-HostMessage -err "Invalid option"
                continue
            }
            break
        }
        Write-BlankLine   

        # Obtain QueryType XPath
        while ($true) {
            $XPathQuery = (Read-HostInput -Message "Query XPath Expression" -Prompt ":" -AllowString)
        
            # Normalize Xpath syntax
            $XPathQuery = $XPathQuery -replace '(?i)eventid', 'EventID'
            $XPathQuery = $XPathQuery.Replace('>=', '&gt;=')     # *[System[(EventID >= 4624)]] -> *[System[(EventID &gt;= 4624)]]
            $XPathQuery = $XPathQuery.Replace('<=', '&lt;=')     # *[System[(EventID <= 4624)]] -> *[System[(EventID &lt;= 4624)]]
            # $XPathQuery = $XPathQuery.Replace('&', 'and')      # *[System[(EventID > 4624 & EventID < 4625)]] -> *[System[(EventID gt;= 4624 and EventID lt;= 4625)]]
            # $XPathQuery = $XPathQuery.Replace('||', 'or')      # *[System[(EventID = 4624 || EventID = 4625)]] -> *[System[(EventID = 4624 or EventID = 4625)]]
        
            # Run partial validations of the XPath expression syntax
            # (https://learn.microsoft.com/en-us/windows/win32/wes/consuming-events)
            $XPathValidSyntax = $false
            if ($XPathQuery -match '^\*.*$') { $XPathValidSyntax = $true }  # All valid selector paths start with * (or "Event")
            # [TODO] Each XPath that you specify is limited to 32 expressions

            # [TODO] Test the Xpath expression
            # Wrap Xpath query and run test...
            $XPathValidTest = $true

            if ((-not $XPathValidSyntax) -or (-not $XPathValidTest)) {
                Write-HostMessage -err -Message "XPath Expression didn't pass all partial tests"
                continue
            }

            break
        }
        Write-BlankLine   

        # Obtain channel

        # [TODO] Try to infeer channel from XPath
        # ...

        Write-HostMessage -warning -Message "Attempt to infer channel based on XPath expression was not successful."
        Write-HostMessage -Message "You can type `"!KW:{Keyword}`" to search for matching Event Channels"
        while ($true) {      
            $Channel = (Read-HostInput -Message ("Event Channel") -Prompt ":" -AllowString)
        
            #Search for event channel by {Keyword} if !KW:{Keyword} (or !KW:Keyword) is present in the input
            $Match = ($Channel -match '^!KW:{(?<keyword>\w+)}$') -or ($Channel -match '^!KW:(?<keyword>\w+)$')
            if ($Match) {
                $matchesFound = $false
                $AvailableChannels | ForEach-Object {
                    if ($_ -like "*$($Matches.keyword)*" ) {
                        Write-Host " - $_" -ForegroundColor Gray
                        $matchesFound = $true
                    }
                }
                if (-not $matchesFound) {
                    Write-HostMessage -warning -Message "No matching channels found."
                }
                continue
            }

            # Validate channel
            if ($AvailableChannels -contains $Channel) {
                break
            }

            # If no valid channel, notify.
            Write-HostMessage -warning -Message "Unknown channel"
            $useUnknownChannel = (Read-HostInput -Message ("Do you want to use it anyway? [y/N]") -Prompt ":" -AllowString)
            if ($useUnknownChannel.ToUpper() -ne "Y") {
                continue
            }
            break
        }
        Write-BlankLine 

        # Query review
        
        $NewQueryTypeElement = [QueryTypeElement]::new($QueryType, $Channel, $XPathQuery)
        Write-HostMessage -Message "QueryType Element Quick Review: [ Type: $QueryType ] [ Channel: $Channel ] [ XPath: $XPathQuery ]"
        $QueryElement.AddQueryTypeElement($NewQueryTypeElement)
        $LocalQueryTypeCount += 1
    }
}


# === [ Still under development ] ===
function Get-NormalizedQueryElement {
    param(
        [QueryElement]$QueryElement
    )

    # QueryElements with one QueryType Element do not require normalization/optimization
    if ($QueryElement.GetQueryTypeElements().Count -le 1) { return $QueryElement }

    # Normalization: XPath pre-sorting steps
    #   First, sort by Channel Path (Alphabetically)
    #   Second, sort by Event ID (Numerically)
    #
    #   Before:
    #   <Query>
    #       <Select Path="Application">*[System[(EventID=5615)]]</Select>
    #       <Suppress Path="Security">*[System[(EventID=4625)]]</Suppress>
    #       <Select Path="Security">*[System[(EventID=4624)]]</Select>
    #       <Select Path="Application">*[System[(EventID=5617)]]</Select>
    #   </Query>
    #
    #   After:
    #   <Query>
    #       <Select Path="Application">*[System[(EventID=5615)]]</Select>
    #       <Select Path="Application">*[System[(EventID=5617)]]</Select> 
    #       <Select Path="Security">*[System[(EventID=4624)]]</Select>
    #       <Suppress Path="Security">*[System[(EventID=4625)]]</Suppress>
    #   </Query>

    $QueryElement.SelectQueryElements = $QueryElement.SelectQueryElements | Sort-Object -Property Channel, Events
    $FilteredSelectQueryTypeElements = @()

    # Normalization: De-duplication of QueryType Elements and EventIDs
    $QueryTypeElementHashes = @{}
    $CoveredEventIDs = New-Object 'System.Collections.Generic.HashSet[int]'

    foreach ($QueryTypeElement in $QueryElement.SelectQueryElements) {

        # QueryTypeElement-level de-duplication: skip duplicated QueryType Elements
        $hashKey = "$($QueryTypeElement.Type)|$($QueryTypeElement.Channel)|$($QueryTypeElement.XPath)"
        if ($QueryTypeElementHashes.ContainsKey($hashKey)) {
            continue  # Duplicate QueryType Element, skip
        }
        $QueryTypeElementHashes[$hashKey] = $true

        # EventID-level de-duplication: ensure the same EventID is not queried twice
        $IsCovered = $false
        foreach ($EventID in $QueryTypeElement.Events) {
            if ($CoveredEventIDs.Contains($EventID)) {
                $IsCovered = $true
                break
            }
        }
        if ($IsCovered) {
            continue  # Skip this QueryType Element, as some of its EventIDs are already covered
        }

        # Keep this QueryType Element
        $FilteredSelectQueryTypeElements += $QueryTypeElement
        foreach ($EventID in $QueryTypeElement.Events) {
            $CoveredEventIDs.Add($EventID) | Out-Null
        }
    }

    $QueryElement.SelectQueryElements = $FilteredSelectQueryTypeElements

    # Optimization: XPath Selector QueryType Element Compression
    #   Minimize the number of QueryType Elements by analyzing the content of the Query
    #   If there are standalone <Select> elements that query subsequent EventIDs, merge them.
    #
    #   Before:
    #   <Query>
    #       <Select Path="Security">*[System[(EventID=4624)]]</Select>
    #       <Select Path="Security">*[System[(EventID=4625)]]</Select>
    #   </Query>
    #
    #   After:
    #   <Query>
    #       <Select Path="Security">*[System[(EventID gt;= 4624 and EventID lt;= 4625)]]</Select>
    #   </Query>
    #
    #   [TODO?] Extend compression to XPath Suppress QueryType Elements?

    $NewQueryElement = [QueryElement]::new($QueryElement.QueryId)
    $QueryTypeElementCount = $QueryElement.GetSelectQueryTypeElements().Count
    $IsLastQueryTypeElementAdded = $false
    $LeftPointer = 0
    $RightPointer = $LeftPointer + 1

    while ($true) {

        $LeftQueryTypeElement = $QueryElement.GetSelectQueryTypeElements()[$LeftPointer]
        $LeftEventID = [int](($LeftQueryTypeElement.XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value)

        # End of list
        if ($RightPointer -ge $QueryTypeElementCount) { break }

        $RightQueryTypeElement = $QueryElement.GetSelectQueryTypeElements()[$RightPointer]
        $RightEventID = [int](($RightQueryTypeElement.XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value)

        $ConsecutiveCount = 1
        if (-not (($LeftEventID + $ConsecutiveCount) -eq $RightEventID) -or ($LeftQueryTypeElement.Channel -ne $RightQueryTypeElement.Channel)) {
            # If subsequence test fails, add current element and continue
            [void]$NewQueryElement.AddQueryTypeElement($LeftQueryTypeElement)
            $LeftPointer = $RightPointer
            $RightPointer += 1
            continue
        }

        while ((($LeftEventID + $ConsecutiveCount) -eq $RightEventID) -and ($LeftQueryTypeElement.Channel -eq $RightQueryTypeElement.Channel)) {
            $RightPointer += if ($RightPointer -ge $QueryTypeElementCount - 1) { 0 } else { 1 }
            $RightQueryTypeElement = $QueryElement.GetQueryTypeElements()[$RightPointer]
            $RightEventID = [int](($RightQueryTypeElement.XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value)
            $ConsecutiveCount += 1
        }

        # Generate the compressed ranged query
        $CompressedXPath = "*[System[(EventID &gt;= $($LeftEventID) and EventID &lt;= $($LeftEventID + $ConsecutiveCount - 1))]]"

        if (($LeftPointer + $ConsecutiveCount) -eq $QueryTypeElementCount) { $IsLastQueryTypeElementAdded = $true }

        $CompressedQueryTypeElement = [QueryTypeElement]::new($LeftQueryTypeElement.Type, $LeftQueryTypeElement.Channel, $CompressedXPath)
        [void]$NewQueryElement.AddQueryTypeElement($CompressedQueryTypeElement)
        $LeftPointer = $RightPointer
        $RightPointer += 1
    }

    if (-not ($IsLastQueryTypeElementAdded)) {
        $LeftQueryTypeElement = $QueryElement.GetSelectQueryTypeElements()[$LeftPointer]
        $CompressedQueryTypeElement = [QueryTypeElement]::new($LeftQueryTypeElement.Type, $LeftQueryTypeElement.Channel, $LeftQueryTypeElement.XPath)
        [void]$NewQueryElement.AddQueryTypeElement($CompressedQueryTypeElement)
    }

    return $NewQueryElement
}

function Write-QueryListXmlFile {
    # Write QueryList XML File - (https://learn.microsoft.com/en-us/windows/win32/wes/queryschema-schema)
    param(
        [Parameter(Mandatory = $true)][list[object]]$QueryList,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    if (-not (Test-Path $OutputPath)) {
        Write-HostMessage -err -Message "Invalid OutputPath. Maybe the path does not exists."
        return 1
    }

    Write-HostMessage -Message "Writing QueryList XML file" 

    $XmlWriter = New-Object System.XMl.XmlTextWriter($OutputPath, $null)
    $XmlWriter.Formatting = "Indented"
    $XmlWriter.Indentation = 4

    $XmlWriter.WriteStartDocument()
    $XmlWriter.WriteStartElement("QueryList")

    foreach ($QueryElement in $QueryList) {
        $XmlWriter.WriteStartElement("Query")
        $XmlWriter.WriteAttributeString("Id", $QueryElement.QueryId.ToString())

        foreach ($QueryTypeElement in $QueryElement.QueryTypeElements) {
            $XmlWriter.WriteStartElement($QueryTypeElement.Type)
            $XmlWriter.WriteAttributeString("Path", $QueryTypeElement.Channel)
            $XmlWriter.WriteString($QueryTypeElement.XPath)
            $XmlWriter.WriteEndElement()  # Close Select or Suppress element
        }

        $XmlWriter.WriteEndElement()  # Close Query element
    }

    $XmlWriter.WriteEndElement()  # Close QueryList element
    $XmlWriter.WriteEndDocument()
    $XmlWriter.Flush()
    $XmlWriter.Close()

    Write-HostMessage -success -Message "QueryList successfully written to: $OutputPath"
    return
}

function Search-QueryElementIdentifier {

    # This function should return a unique identifier of a QueryElement stored in the
    # project folder named QueriesDB/
    # This unique identifier is used to query the appropiate file under QueriesDB/ 
    # that contains the XML QueryElement <Query>.
    #
    # A user can search for a QueryElement either by
    #   - By intent: What's the overall goal of the query
    #   - By author: Who wrote the query
    #   - By events: What event or events are in the query
    #   - By provider: What provider or providers are in the query
    #   - *By technique: What Att&ck technique does the query is useful for detection
    #
    #   E.g., the following query can be found either by providing any of the following keywords based on the query method
    #   - Intent: Network, IP, IPv6
    #   - Author: Security-Experts-Community (GitHub profile name), wef-guidance (GitHub repo), t0x01 (GitHub Author), or aw350m33d[Anton Kutepov] (GitHub Author)
    #   - Events: 50086 (Notice that Queries with * are not matched, nor the asterisk can be used to search for queries with it)
    #   - Provider: Microsoft-Windows-Dhcp-Client/Operational (or just Microsoft-Windows-Dhcp-Client), and Microsoft-Windows-Dhcpv6-Client/Operational (or just Microsoft-Windows-Dhcpv6-Client)
    #   - Technque: T1046 (Network Service Discovery), or T1557.002 (Adversary-in-the-Middle: ARP Cache Poisoning)
    #
    #   <Query Id="0">
    #       <!-- (50086) IP conflict detection complete on interface [interface] for IP [IP] -->
    #       <Select Path="Microsoft-Windows-Dhcp-Client/Operational">*[System[(EventID=50086)]]</Select>
    #       <Select Path="Microsoft-Windows-Dhcpv6-Client/Operational">*</Select>
    #   </Query>
    #
    # * Querying by technique can be very subjective.
    #   Frequent review of this kind of tagging is important
    
    param(
        [int]$QueryElementId,
        [QueryElement]$QueryElement
    )

    # Search parameters
    [list[string]]$QueryIntents = [List[string]]::new()
    [List[int]]$Events = [List[int]]::new()
    [List[string]]$Providers = [List[string]]::new()
    [List[string]]$Channels = [List[string]]::new()
    [List[string]]$Authors = [List[string]]::new()
    [List[string]]$Techniques = [List[string]]::new()
    [List[string]]$Tags = [List[string]]::new()

    # Ask user for matching keywords
    while ($true) {
        $RawKeywords = Read-HostInput -Message "Search for query element ['h' for help, 't' for tag list]" -Prompt ":" -AllowString
        if ($RawKeywords.ToUpper() -eq 'H') {

            Write-HostMessage -Message "Search for query elements by specifying matching values from the meta.json query files"

            Write-BlankLine

            Write-HostMessage -Message "Use !I:{Intent} to search by intent. E.g. '!I:ia' (Identity and Access), '!I:User Account management'"
            Write-HostMessage -Message "Use !A:{Author} to search by author. E.g. '!A:AzJRC', '!A:WefManagementTool'"
            Write-HostMessage -Message "Use !E:{Events} to search by event IDs. E.g. '!E:4624', '!E:4624,4625', '!E:4624-4630,4632"
            Write-HostMessage -Message "Use !P:{Providers} to search by providers. E.g. '!P:Microsoft-Windows-WMI-Activity'"
            Write-HostMessage -Message "Use !C:{Channels} to search by channels. E.g. '!C:Security'"
            Write-HostMessage -Message "Use !T:{Techniques} to search by Att&ck Techniques. E.g. '!T:T1047'"
            Write-HostMessage -Message "Use !TA:{Tags} to search by tags. E.g. '!TA:Lateral Movement, Scripting'"

            Write-BlankLine

            Write-HostMessage -Message "Indidual search operations are OR-ed."
            Write-HostMessage -Message "All search operations are AND-ed"
            Write-HostMessage -Message "String-based search operations are case-insensitive"
            Write-HostMessage -Message "Intent, Providers, and Channels will match substrings. E.g. '!I:User Account' will match the subintent 'User Account Management'"

            Write-BlankLine

            continue
        }
        elseif ($RawKeywords.ToUpper() -eq 'T') {
            # [TODO] Print available tags

            continue
        }

        # Parse keywords
        # E.g. !I:IA !T:T1047
        # E.g. !A:AzJRC
        # E.g. !TA:Scripting, Lateral Movement, DLL
        # E.g. !I:Account Management !A:WefManagementTool !E:4000-5000 !T:T1059

        $KeywordRegex = '!(?<Keyword>I|A|E|P|C|T|TA):(?<Value>[a-zA-Z0-9-\s,]+)(?:\s|$)'
        $KeywordMatches = [regex]::Matches($RawKeywords, $KeywordRegex)
        
        foreach ($KeywordMatch in $KeywordMatches) {
            $Keyword = ($KeywordMatch.Groups["Keyword"].Value).ToUpper()
            $Values = (($KeywordMatch.Groups["Value"].Value) -split ',' | ForEach-Object { $_.Trim() })
            

            switch ($Keyword) {
                'I' { 
                    # Normalize QueryIntent value
                    $Values = $Values | ForEach-Object {
                        switch ($_) {
                            'as' { 'application_and_services' }
                            'ia' { 'identity_and_access' }
                            'sa' { 'security_and_auditing' }
                            'n' { 'network' }
                            's' { 'system' }
                            Default { $_ }
                        }
                    }
                    foreach ($Value in $Values) { $QueryIntents.Add( ($Value.ToLower() -replace ('[ ]+', '_')) ) }
                    break
                }
                'A' {
                    # No preprocessing required
                    foreach ($Value in $Values) { $Authors.Add($Value) }
                    break
                }
                'E' {
                    foreach ($Value in $Values) {
                        if ($Value -match "^(\d+)-(\d+)$") {
                            # It's a range like "1000-1005"
                            $LowerBound = [int]$Matches[1]
                            $UpperBound = [int]$Matches[2]

                            if ($LowerBound -le $UpperBound) {
                                $Range = $LowerBound..$UpperBound
                                foreach ($EventId in $Range) {
                                    $Events.Add($EventId)
                                }
                            }
                        }
                        else {
                            # Try parse as single integer
                            [int]$IntValue = 0
                            $Success = [int32]::TryParse($Value, [ref]$IntValue)
                            if ($Success) {
                                $Events.Add($IntValue)
                            }
                        }
                    }
                    break
                }
                'P' {
                    # No preprocessing required
                    foreach ($Value in $Values) { $Providers.Add($Value) }
                    break
                }
                'C' {
                    # No preprocessing required
                    foreach ($Value in $Values) { $Channels.Add($Value) }
                    break
                }
                'T' {
                    # Validate Att&ck technique format T[Number]
                    foreach ($Value in $Values) {
                        if ($Value -match '^T\d+$') {
                            $Techniques.Add($Value) 
                        }
                    }
                    break
                }
                'TA' {
                    # No preprocessing required
                    foreach ($Value in $Values) { 
                        $Tags.Add(($Value.ToLower() -replace ('[ ]+', '_')))
                    }
                    break
                }
                default { continue }    # Skip
            }
        }

        break
    }

    $QueryMatches = @()
    $MetaFiles = Get-ChildItem -Path $Root -Recurse -Filter "*.meta.json" -File
    foreach ($MetaFile in $MetaFiles) {
        $Meta = Get-Content $MetaFile.FullName | ConvertFrom-Json
        $Match = $true

        if ($QueryIntents.Length -gt 0 -and -not ($QueryIntents -contains $Meta.QueryIntent.Intent -or $QueryIntents -contains $Meta.QueryIntent.SubIntent)) { $Match = $false }
        if ($Events.Length -gt 0 -and -not ($Meta.Events | Where-Object { [int]$_ -in $Events })) { $Match = $false }
        if ($Providers.Length -gt 0 -and -not ($Meta.Providers | Where-Object { $Providers -contains $_ })) { $Match = $false }
        if ($Channels.Length -gt 0 -and -not ($Meta.Channels | Where-Object { $Channels -contains $_ })) { $Match = $false }
        if ($Authors.Length -gt 0 -and -not ($Meta.QueryAuthors.AuthorName -like "*$($Authors | ForEach-Object ( $_ ))*" -or $Meta.QueryAuthors.AuthorAlias -like "*$($Authors | ForEach-Object ( $_ ))*" -or $Meta.QueryAuthors.AuthorProject -like "*$($Authors | ForEach-Object ( $_ ))*")) { $Match = $false }
        if ($Techniques.Length -gt 0 -and -not ($Meta.AttackMappings | Where-Object { $_ -in $Techniques })) { $Match = $false }
        if ($Tags.Length -gt 0 -and -not ($Meta.Tags | Where-Object { $_ -in $Tags })) { $Match = $false }

        if ($Match) {
            $QueryMatches += $MetaFile.FullName -replace '\.meta\.json$', '.query.xml'
        }
    }

    return $QueryMatches
}

# Call Main
Write-XmlQueryFile