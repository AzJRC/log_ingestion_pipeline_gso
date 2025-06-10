using namespace system.collections.generic

class QueryTypeElement {
    [ValidateNotNullOrEmpty()][string]$Type             # select | suppress
    [ValidateNotNullOrEmpty()][string]$Channel          # Event channel, like Security or Microsoft-Windows-SMBServer/Security
    [ValidateNotNullOrEmpty()][string]$XPath            # XPath expression, like *[System[(EventID=4624)]]

    QueryTypeElement($Type, $Channel, $XPath) {
        $this.Type = $Type 
        $this.Channel = $Channel
        $this.XPath = $XPath
    }
}

class QueryElement {
    [int]$QueryId
    $QueryTypeElements = [list[object]]::new()

    QueryElement($QueryId) {
        $this.QueryId = $QueryId
    }

    [int] AddQueryTypeElement($QueryTypeElement) {
        try { $this.QueryTypeElements.Add($QueryTypeElement) } catch { return 1 }
        return 0
    }
}

class QueryListElement {
    $QueryElements = [list[object]]::new()

    [int] AddQueryElement($QueryElement) {
        try { $this.QueryElements.Add($QueryElement) } catch { return 1 }
        return 0
    }

    [list[object]] InspectQueryElements() {
        return $this.QueryElements
    }

    [object] GetLastQueryElement() {
        return $this.QueryElements[-1]
    }

    [int] WriteQueryListElement($OutputPath) {
        return (Write-QueryListXmlFile -QueryList $this.QueryElements -OutputPath $OutputPath)
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
        i
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

        Write-Host ""   # BlankLine

        Write-HostMenu -Message "Select an option:"
        Write-HostMenuOption -OptionNumber 1 -Message "Add new QueryElement"
        Write-HostMenuOption -OptionNumber 2 -Message "Inspect QueryList"
        Write-HostMenuOption -OptionNumber 3 -Message "Write QueryList XML File"
        Write-HostMenuOption -OptionNumber 4 -Message "Exit"

        Write-Host ""   # BlankLine

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
                        $QueryTypeElementCount += $QueryList.GetLastQueryElement().Length - 1 
                    }
                }
                else {
                    $QueryList.AddQueryElement($NewQueryElement)
                    # [BUG?] I don't know why, but I need to substract one from the list length to get the correct result.
                    $QueryTypeElementCount += $QueryList.GetLastQueryElement().Length - 1 
                }
                $QueryElementCount += 1
                Write-HostMessage -success -Message "QueryElement added successfully"
            }
            2 {
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
            3 {
                $QueryList.WriteQueryListElement($OutputPath)
                $XmlFileWritten = $true
            }
            4 {
                if (-not $XmlFileWritten) {
                    Write-HostMessage -warning -Message "You haven't write the QueryList XML File"
                    Read-HostInput -Message "Are you sure you want to exit? [ y / N ]"
                    if ($ImportQuery.ToUpper() -ne "Y") {
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
    Write-Host ""   # BlankLine
    while ($true) {
        
        if ($LocalQueryTypeCount -gt 0) {
            $FinishQuery = Read-HostInput -Message "Type 'q' to finish the QueryElement" -Prompt ":" -AllowString
            if ($FinishQuery.ToUpper() -eq "Q") {
                return $QueryElement
            }
        }
        Write-Host ""   # BlankLine

        # Optionally, Import query
        $ImportQuery = Read-HostInput -Message "Do you want to import an existing query? [ Y / n ]" -Prompt ":" -AllowString
        if ($ImportQuery.ToUpper() -ne "N") {
            # [TODO] Import Existing Queries from local file database
            # $ImportedQueries = Import-QueryElements

            return 1
        }
        Write-Host ""   # BlankLine

        # Obtain QueryType
        while ($true) {
            $QueryType = (Read-HostInput -Message "What Query Type? [ SELECT(1) / SUPRESS(2) ]" -Prompt ":" -AllowString).ToUpper()
            $QueryType = if ($QueryType -in @('1', 'SELECT')) { 'Select' } 
            elseif ($QueryType -in @('2', 'SUPPRESS')) { 'Suppress' }
            else {
                Write-HostMessage -err "Invalid option"
                continue
            }
            break
        }
        Write-Host ""   # BlankLine

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
        Write-Host ""   # BlankLine

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
        Write-Host ""   # BlankLine

        # Query review
        Write-HostMessage -Message "Query review: $QueryType $Channel $XPathQuery"
        $NewQueryTypeElement = [QueryTypeElement]::new($QueryType, $Channel, $XPathQuery)
        if ($QueryElement.AddQueryTypeElement($NewQueryTypeElement) -eq 1) {
            Write-HostMessage -err "There was a problem adding the QueryType element"
        }
        $LocalQueryTypeCount += 1
    }
}