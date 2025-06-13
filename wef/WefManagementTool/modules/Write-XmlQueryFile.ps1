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
    $SelectQueryElements = [list[object]]::new()
    $SuppressQueryElements = [list[object]]::new()

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

    [list[object]] GetQueryTypeElements() {
        return ($this.SelectQueryElements + $this.SuppressQueryElements)
    }

    [list[object]] GetSelectQueryTypeElements() {
        return ($this.SelectQueryElements)
    }

    [list[object]] GetSupressQueryTypeElements() {
        return ($this.SuppressQueryElements)
    }
}

class QueryListElement {
    $QueryElements = [list[object]]::new()

    [void] AddQueryElement($QueryElement) {
        $this.QueryElements.Add($QueryElement)
    }

    [list[object]] GetQueryElements() {
        return $this.QueryElements
    }

    [object] GetLastQueryElement() {
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

# Helper variables
$WriteHostTitlePadding = " " * 3
$WriteHostMenuPadding = " " * 3
$WriteHostOptionPadding = " " * 6
$WriteHostMessagePadding = " " * 3

# Helper functions
function Write-HostTitle {
    param ([string]$Message)
    Write-Host ( "`n" + $WriteHostTitlePadding + "[ " + $Message + " ]" + "`n") -ForegroundColor Cyan
}

function Write-HostMenu {
    param ([string]$Message)
    Write-Host ($WriteHostMenuPadding + $Message) -ForegroundColor Cyan
}

function Write-HostMenuOption {
    param (
        [string]$Message,
        [int]$OptionNumber
    )
    Write-Host $WriteHostOptionPadding -NoNewline
    if ($OptionNumber -is [int]) { Write-Host "[$OptionNumber] " -ForegroundColor Cyan -NoNewline }
    Write-Host $Message -ForegroundColor Gray
}

# Utility variables
$AvailableChannels = $(wevtutil.exe el)

# Utility functions
function Write-HostMessage {
    param (
        [string]$Message,
        [switch]$warning,
        [switch]$err,
        [switch]$success,
        [switch]$NoSymbol
    )
    if ($err) { Write-Host ($WriteHostMessagePadding + $(if (-not $NoSymbol) { "[-] " }) + $Message) -ForegroundColor Red; return $null }
    if ($warning) { Write-Host ($WriteHostMessagePadding + $(if (-not $NoSymbol) { "[!] " }) + $Message) -ForegroundColor Yellow; return $null }
    if ($success) { Write-Host ($WriteHostMessagePadding + $(if (-not $NoSymbol) { "[+] " }) + $Message) -ForegroundColor Green; return $null }
    Write-Host ($WriteHostMessagePadding + $(if (-not $NoSymbol) { "[*] " }) + $Message) -ForegroundColor Gray
}

function Read-HostInput {
    param (
        [string]$Prompt,
        [string]$Message,
        [switch]$AllowString
    )
    Write-Host ($Message + " " + $Prompt + " ") -ForegroundColor Cyan -NoNewline
    $UserInput = $Host.UI.ReadLine()
    if ($AllowString) { return $UserInput }
    if ($UserInput -match "^[\d\.]+$") { return $UserInput }
    return $null
}

function Write-BlankLine { Write-Host "" }

# Write QueryList XML File - (https://learn.microsoft.com/en-us/windows/win32/wes/queryschema-schema)
function Write-QueryListXmlFile {
    param(
        [Parameter(Mandatory = $true)][list[object]]$QueryList,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    if (-not (Test-Path $OutputPath)) {
        Write-Error "[-] Invalid OutputPath. Maybe the path does not exists."
        return 1
    }

    Write-Host "[+] Writing QueryList to XML file" -ForegroundColor Cyan

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

    Write-HostMessage -success -Message "XML successfully written to: $OutputPath"
}

function Write-XmlQueryFile {
    param(
        [string]$OutputPath = "$PSScriptRoot\..\Files\SubscriptionEventXmlQuery.xml"
    )

    # Create $OutputPath if not exists
    if (-not (Test-Path $OutputPath)) {
        Write-HostMessage -alert -Message "OutputPath does not exist. Creating it..."
        New-Item -Path $OutputPath -Force > $null
    }

    # Initialize QueryListElement
    $QueryList = [QueryListElement]::new()

    # AccountingVariables
    $XmlFileWritten = $false
    $QueryElementCount = $QueryList.QueryElements.Count
    $QueryTypeElementCount = $QueryList.GetQueryTypeElementCount()

    while ($true) {
        Write-HostTitle -Message "Event XML Writer Module"
        Write-HostMessage -Message "QueryElementCount: [$QueryElementCount]"
        Write-HostMessage -Message "QueryTypeElementCount: [$QueryTypeElementCount]" # [TODO] Broken after refactoring classes

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
                    $NewQueryElement = Write-NewQueryElement -QueryElementId ($QueryTypeElementCount + 1) 
                }
                catch { 
                    Write-HostMessage -err -Message "Failed to create new QueryElement"
                    Write-Host $_
                    break
                }
                if ($NewQueryElement -is [list[object]]) {
                    foreach ($QueryElement in $NewQueryElement) {
                        $QueryList.AddQueryElement($QueryElement)
                        # [BUG?] I don't know why, but I need to substract one from the list length to get the correct result.
                        $QueryTypeElementCount += $QueryList.GetLastQueryElement().QueryTypeElements.Count
                    }
                }
                else {
                    $QueryList.AddQueryElement($NewQueryElement)
                    # [BUG?] I don't know why, but I need to substract one from the list length to get the correct result.
                    $QueryTypeElementCount += $QueryList.GetLastQueryElement().QueryTypeElements.Count
                }
                $QueryElementCount += 1
                Write-HostMessage -success -Message "QueryElement added successfully"
            }
            2 {
                # [TODO]
                # Import QueryElement -> <Query> block
                # Queries can be categorized by the intent of the event:
                #   System events, Network events, Security & Auditing events, Applications and Services events, and Identity & Access events
                # Queries can also be subcategorized. E.g. Network -> SMB, System -> Registry change, or Identity and Acess -> User authentication
                # Query blocks are also tagged with author name. E.g. 


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
                return 0
            }
            default {
                Write-HostMessage -err "Invalid option"
            }
        }
    }
}

function Write-NewQueryElement {
    param($QueryElementId)

    $QueryElement = [QueryElement]::new($QueryElementId)
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
                    $NormalizedQueryElement = Get-NormalizedQueryElement -QueryElement $QueryElement
                }
                catch {
                    Write-HostMessage -warning -Message "Normalization unsuccessuful"
                    return $QueryElement
                }
                return $NormalizedQueryElement
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
            $XPathQuery = $XPathQuery.Replace('>', 'gt;=')     # *[System[(EventID > 4624)]] -> *[System[(EventID gt;= 4624)]]
            $XPathQuery = $XPathQuery.Replace('<', 'lt;=')     # *[System[(EventID < 4624)]] -> *[System[(EventID lt;= 4624)]]
            $XPathQuery = $XPathQuery.Replace('&', 'and')      # *[System[(EventID > 4624 & EventID < 4625)]] -> *[System[(EventID gt;= 4624 and EventID lt;= 4625)]]
            $XPathQuery = $XPathQuery.Replace('||', 'or')      # *[System[(EventID = 4624 || EventID = 4625)]] -> *[System[(EventID = 4624 or EventID = 4625)]]
        
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
        if ($QueryElement.AddQueryTypeElement($NewQueryTypeElement) -eq 1) {
            Write-HostMessage -err "There was a problem adding the QueryType element"
        }
        $LocalQueryTypeCount += 1
    }
}

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

function Test-QueryNormalization {
    param(
        [int[]]$EventIDs,
        [string[]]$Channels,
        [string[]]$Types
    )

    $qe = [QueryElement]::new(0)
    for ($i = 0; $i -lt $EventIDs.Length; $i++) {
        $newQte = [QueryTypeElement]::new($($Types[$i]), $($Channels[$i]), "*[System[(EventID=$($EventIDs[$i]))]]")
        $qe.AddQueryTypeElement($newQte)
    }

    $nqe = Get-NormalizedQueryElement($qe)

    Write-Host "After Normalization:"
    $nqe.GetQueryTypeElements() | Format-Table
}


# Call Main
Write-XmlQueryFile