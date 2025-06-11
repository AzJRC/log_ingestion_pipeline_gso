using namespace system.collections.generic


class QueryTypeElement {
    static [string] $QUERY_TYPE_SUPPRESS = 'Suppress'
    static [string] $QUERY_TYPE_SELECT = 'Select'

    [ValidateNotNullOrEmpty()][string]$Type             # select | suppress
    [ValidateNotNullOrEmpty()][string]$Channel          # Event channel, like Security or Microsoft-Windows-SMBServer/Security
    [ValidateNotNullOrEmpty()][string]$XPath            # XPath expression, like *[System[(EventID=4624)]]
    [ValidateNotNullOrEmpty()][list[int]]$Events

    QueryTypeElement($Type, $Channel, $XPath) {
        $this.Type = $Type 
        $this.Channel = $Channel
        $this.XPath = $XPath
        $this.Events = $this.ParseXPathEvents($XPath)
    }

    [list[int]] ParseXPathEvents($XPath) {
        $EventList = [list[int]]::new()
        
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

    [list[object]] InspectQueryElements() {
        return $this.QueryElements
    }

    [object] GetLastQueryElement() {
        return $this.QueryElements[-1]
    }

    [void] WriteQueryListElement($OutputPath) {
        Write-QueryListXmlFile -QueryList $this.QueryElements -OutputPath $OutputPath
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
    Write-Host ($Message + $Prompt) -ForegroundColor Cyan -NoNewline
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

function Write-XmlQuery {
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
    $QueryElementCount = 0
    $QueryTypeElementCount = 0
    $XmlFileWritten = $false

    while ($true) {
        Write-HostTitle -Message "Event XML Writer Module"
        Write-HostMessage -Message "QueryElementCount: [$QueryElementCount]"
        Write-HostMessage -Message "QueryTypeElementCount: [$QueryTypeElementCount]"

        Write-BlankLine

        Write-HostMenu -Message "Select an option:"
        Write-HostMenuOption -OptionNumber 1 -Message "Add new QueryElement"
        Write-HostMenuOption -OptionNumber 2 -Message "Import QueryElement"
        Write-HostMenuOption -OptionNumber 3 -Message "Inspect QueryList"
        Write-HostMenuOption -OptionNumber 4 -Message "Write QueryList XML File"
        Write-HostMenuOption -OptionNumber 5 -Message "Exit"

        Write-BlankLine

        $Option = Read-HostInput -Prompt " > " -Message "Enter option number"
        Switch ($Option) {
            1 {    
                try {    
                    $NewQueryElement = Write-NewQueryElement -QueryElementId ($QueryElementCount + 1) 
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
                # Print query list content with format; not urgent.
                # Temporal solution...
                $QueryList.InspectQueryElements() | ForEach-Object {
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
                $NormalizedQueryElement = Get-NormalizedQueryElement -QueryElement $QueryElement

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
            $QueryType = if ($QueryType -in @('1', 'SELECT')) { $QUERY_TYPE_SELECT } 
            elseif ($QueryType -in @('2', 'SUPPRESS')) { $QUERY_TYPE_SUPPRESS }
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
        Write-HostMessage -Message "Query review: $QueryType $Channel $XPathQuery"
        $NewQueryTypeElement = [QueryTypeElement]::new($QueryType, $Channel, $XPathQuery)
        if ($QueryElement.AddQueryTypeElement($NewQueryTypeElement) -eq 1) {
            Write-HostMessage -err "There was a problem adding the QueryType element"
        }
        $LocalQueryTypeCount += 1
    }
}

function Get-NormalizedQueryElement {
    param(
        [QueryElement]$qe
    )
    # Normalization/Optimization Function

    # QueryElements with one QueryType Element does not require normalization/optimization
    if ($qe.GetQueryTypeElements().Count -le 1) { return $qe }

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

    # [TODO] Sort by channel
    $Lptr = 0
    $Rptr = $qe.GetQueryTypeElements().Count - 1
    $LptrElementChannel = $qe.GetQueryTypeElements()[$Lptr].Channel
    $RptrElementChannel = $qe.GetQueryTypeElements()[$Rptr].Channel

    # [TODO] Sort by EventID
    $Lptr = 0
    $Rptr = $qe.GetQueryTypeElements().Count - 1
    $LptrElementEventID = [int]($qe.GetQueryTypeElements()[$Lptr].XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value
    $RptrElementEventID = [int]($qe.GetQueryTypeElements()[$Rptr].XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value


    # Optimization: XPath Selector QueryType Compression
    #   Minimize the number of QueryType elements by analyzing the content of the Query
    #   E.g. If there are standalone <Select> elements that query subsequent EventIDs, merge.
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

    $NewQE = [QueryElement]::new($qe.QueryId)
    $QueryTypeCount = $qe.GetSelectQueryTypeElements().Count
    $lastQTEAdded = $false
    $Lptr = 0
    $Rptr = $Lptr + 1
    while ($true) {
        $LptrQTE = $qe.GetSelectQueryTypeElements()[$Lptr]
        $LptrEventId = [int](($LptrQTE.XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value)

        # End of list
        if ($Rptr -ge $QueryTypeCount) { break }

        $RptrQTE = $qe.GetSelectQueryTypeElements()[$Rptr]
        $RptrEventId = [int](($RptrQTE.XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value)

        $SubsequentCounter = 1
        if (-not (($LptrEventId + $SubsequentCounter) -eq $RptrEventId) -or ($LptrQTE.Channel -ne $RptrQTE.Channel)) {
            # if subsequense test fails, continue
            [void]$NewQE.AddQueryTypeElement($LptrQTE)
            $Lptr = $Rptr
            $Rptr += 1
            continue
        }

        while ((($LptrEventId + $SubsequentCounter) -eq $RptrEventId) -and ($LptrQTE.Channel -eq $RptrQTE.Channel)) {
            $Rptr += if ($Rptr -ge $QueryTypeCount - 1) { 0 } else { 1 }
            $RptrQTE = $qe.GetQueryTypeElements()[$Rptr]
            $RptrEventId = [int](($RptrQTE.XPath | Select-String -Pattern '\(EventID=(\d+)\)').Matches.Groups[1].Value)
            $SubsequentCounter += 1
        }
        #  (4624, 4625, 4626) (4630 4631 ... ) 4640 4645 
        #    |                  |
        #  $Lptr              $Rptr

        # Generate first group ranged query
        $NewQTEXPath = "*[System[(EventID &gt;= $($LptrEventId) and EventID &lt;= $($LptrEventId + $SubsequentCounter - 1))]]"
        
        if (($Lptr + $SubsequentCounter) -eq $QueryTypeCount) { $lastQTEAdded = $true }

        $NewQTE = [QueryTypeElement]::new($LptrQTE.Type, $LptrQTE.Channel, $NewQTEXPath)
        [void]$NewQE.AddQueryTypeElement($NewQTE)
        $Lptr = $Rptr
        $Rptr += 1

        #  (4624, 4625, 4626) (4630 4631 ... ) 4640
        #                        |    |
        #                     $Lptr $Rptr
    }

    if (-not ($lastQTEAdded)) {
        $LptrQTE = $qe.GetSelectQueryTypeElements()[$Lptr]
        $NewQTE = [QueryTypeElement]::new($LptrQTE.Type, $LptrQTE.Channel, $LptrQTE.XPath)
        [void]$NewQE.AddQueryTypeElement($NewQTE)
    }

    return $NewQE
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

# Test Case 1: Basic compressible range on same Channel/Type
# Test-QueryNormalization -EventIDs @(4624, 4625, 4626, 4627) -Channels @('Security', 'Security', 'Security', 'Security') -Types @('Select', 'Select', 'Select', 'Select')

# Test Case 2: Mixed Channel → should not merge across channels
# Test-QueryNormalization -EventIDs @(4624, 4625, 4626, 4627) -Channels @('Security', 'System', 'Security', 'System') -Types @('Select', 'Select', 'Select', 'Select')

# Test Case 3: Mixed Type → Select + Suppress → should not merge across types
# Test-QueryNormalization -EventIDs @(4624, 4625, 4626, 4627) -Channels @('Security', 'Security', 'Security', 'Security') -Types @('Select', 'Suppress', 'Select', 'Suppress')

# Test Case 4: Compressible group, with gap → test that gaps break merge
# Test-QueryNormalization -EventIDs @(4624, 4625, 4627, 4628) -Channels @('Security', 'Security', 'Security', 'Security') -Types @('Select', 'Select', 'Select', 'Select')

# Test Case 5: Mixed Channel + Type + out-of-order input → test sorting
# Test-QueryNormalization -EventIDs @(4628, 4624, 4626, 4625, 4627) -Channels @('System', 'Security', 'Security', 'Security', 'System') -Types @('Suppress', 'Select', 'Select', 'Select', 'Select')

# Test Case 6: Empty input → should handle cleanly
# est-QueryNormalization -EventIDs @() -Channels @() -Types @()

# Test Case 7: Single element → should remain single
# Test-QueryNormalization -EventIDs @(4624) -Channels @('Security') -Types @('Select')

# Test Case 8: Complex pattern with multiple groups, different channels/types
Test-QueryNormalization -EventIDs @(4624, 4625, 4626, 4630, 4631, 4632, 4640, 4641, 4642) `
    -Channels @('Security', 'Security', 'Security', 'System', 'Security', 'System', 'Security', 'Security', 'System') `
    -Types @('Select', 'Select', 'Select', 'Select', 'Select', 'Select', 'Select', 'Select', 'Select')

# Test Case 9: All EventIDs the same → should produce single merged output (degenerate case)
# Test-QueryNormalization -EventIDs @(4624, 4624, 4624, 4624) -Channels @('Security', 'Security', 'Security', 'Security') -Types @('Select', 'Select', 'Select', 'Select')

# Test Case 10: Large out-of-order list, mixed everything → full robustness test
# Test-QueryNormalization -EventIDs @(4627, 4624, 4630, 4625, 4640, 4626, 4631, 4632, 4628, 4629, 4641) `
#    -Channels @('Security', 'System', 'Security', 'System', 'System', 'Security', 'Security', 'System', 'System', 'Security', 'Security') `
#    -Types @('Suppress', 'Select', 'Select', 'Suppress', 'Select', 'Select', 'Select', 'Suppress', 'Select', 'Select', 'Select')