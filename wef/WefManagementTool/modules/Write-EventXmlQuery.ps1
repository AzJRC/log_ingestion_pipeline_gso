# Define QueryType Element Object
class QueryTypeElement {
    [string]$Type  # 'Select' or 'Suppress'
    [string]$Path
    [string]$XPath

    QueryTypeElement([string]$Type, [string]$Path, [string]$XPath) {
        $this.Type = $Type
        $this.Path = $Path
        $this.XPath = $XPath
    }
}

# Define Query Object
class QueryObject {
    [int]$Id
    [System.Collections.Generic.List[QueryTypeElement]]$QueryElements

    QueryObject([int]$Id) {
        $this.Id = $Id
        $this.QueryElements = [System.Collections.Generic.List[QueryTypeElement]]::new()
    }
}

# List and store all available log channels
$AvailableChannels = $(wevtutil.exe el)

# Main Function
function Write-EventXmlQuery {
    param(
        [string]$OutputPath = "$PSScriptRoot\..\Files\SubscriptionEventXmlQuery.xml"
    )

    # Import Utilities
    $utilitiesPath = Join-Path $PSScriptRoot 'Utilities'
    Get-ChildItem "$utilitiesPath\*.ps1" | ForEach-Object {
        . $_.FullName
    }

    Write-MessageInBox -Msg "Event XML Query Creator Tool" -Color Cyan

    # Initialize QueryList as an array of QueryObject
    $QueryList = @()

    $QueryObjectCount = 0
    $QueryItemCount = 0

    $ContinueObjectMenuLoop = $true
    while ($ContinueObjectMenuLoop) {
     
        Write-CustomMenu -MenuTitle "[QueryList Menu]" -MenuOptions @(
            "Add a new Query Element", 
            "Inspect Query Elements", 
            "Finish XML Query List") -PreMenuText "Select an option:"
        $Option = Get-MenuOption 

        switch ($Option) {
            1 {
                # Create new QueryObject and add to list
                $QueryObject = New-Object QueryObject($QueryObjectCount)
                $QueryItemCount = Write-QueryObject -QueryObject $QueryObject -QueryItemCount $QueryItemCount
                $QueryList += $QueryObject
                $QueryObjectCount += 1
            }
            2 { 
                # Inspect current QueryList
                Inspect-QueryList -QueryList $QueryList
            }
            3 { 
                # Save to XML and exit
                Write-XmlQueryFile -QueryList $QueryList -OutputPath $OutputPath
                $ContinueObjectMenuLoop = $false
            }
            default { Write-Warning "Invalid option" }
        }
    }


}

# Function to handle one QueryObject
function Write-QueryObject {
    param(
        [Parameter(Mandatory = $true)][QueryObject]$QueryObject,
        [Parameter(Mandatory = $true)][int]$QueryItemCount
    )

    Write-Host "[+] Creating Query Element with Id [$($QueryObject.Id)]" -ForegroundColor Cyan

    $QueryDefaultChannel = ""
    $ContinueQueryTypeMenuLoop = $true
    while ($ContinueQueryTypeMenuLoop) {
        Write-CustomMenu -MenuTitle "[QueryType Menu]" -MenuOptions @(
            "Add a new Query Element",  
            "Choose a default channel",
            "Finish query") -PreMenuText "Select an option:"
        $Option = Get-MenuOption 

        switch ($Option) {
            1 {
                $Element = Get-QueryTypeElement -QueryDefaultChannel $QueryDefaultChannel
                if ($Element) {
                    $QueryObject.QueryElements.Add($Element)
                    $QueryItemCount += 1
                }
            }
            2 {
                $QueryDefaultChannel = Set-QueryDefaultChannel
            }
            3 {
                $ContinueQueryTypeMenuLoop = $false
            }
            default {
                Write-Warning "Invalid option"
            }
        }
    }

    return $QueryItemCount
}

# Choose default channel
function Set-QueryDefaultChannel {
    Write-Host "[+] Set the default channel for this Query object." -ForegroundColor Cyan
    $Channel = Get-Channel
    Write-Host "[+] Default channel set to: $Channel" -ForegroundColor Green
    return $Channel
}

# Create one QueryTypeElement
function Get-QueryTypeElement {
    param (
        [string]$QueryDefaultChannel = ""
    )

    $DefaultChannelText = if (![string]::IsNullOrEmpty($QueryDefaultChannel)) { " [$QueryDefaultChannel]" } else { "" }

    # Obtain QueryType
    while ($true) {
        $QueryType = [string](ReadFrom-CustomPrompt -PromptText "Query Type - SELECT(1) SUPRESS(2)" -Prompt ":")
        if (-not $QueryType.ToUpper() -in @('1', '2', 'SELECT', 'SUPRESS')) {
            Write-Warning "Invalid option"
            continue
        }
        break
    }

    # Obtain channel
    while ($true) {
        Write-Host "Type `"!MENU`" to open the Event Channel Menu. You can also type `"!KW:`{Keyword`}`" to search for matching Event Channels" -ForegroundColor Gray
        $Channel = [string](ReadFrom-CustomPrompt -PromptText ("Event Channel" + "$DefaultChannelText") -Prompt ":")
        if ($QueryType.ToUpper() -eq "`$MENU") {
            $Channel = Get-Channel
            break
        }

        # [TODO] Implement the Channel Menu with the user input !MENU
        # ...
        
        #Search for event channel by {Keyword} if !KW:{Keyword} is present in the input
        $Match = $Channel -match '^!KW:{(?<keyword>\w+)}$'
        if ($Match) {
            $AvailableChannels | ForEach-Object { 
                if ($_ -like "*$($Matches.keyword)*" ) {
                    # [TODO] Paginate output if more than 10 matches are detected
                    Write-Host " - $_"
                }
            }
            continue
        }

        #Validate event channel exists in the list provided by the command `wevtutil.exe el`
        $AvailableChannels | ForEach-Object { 
            if ($_ -eq $Channel) { 
                break
            }
        }
        Write-Warning "Unknown channel"
        $useUnknownChannel = [string](ReadFrom-CustomPrompt -PromptText ("Do you want to use it anyway? [y/N]") -Prompt " ")
        if ($useUnknownChannel.ToUpper() -ne "Y") {
            continue
        }
        
        break
    }

    # Obtain XPath
    while ($true) {
        Write-Host "[*] Type `"!TEMPLATES`" to enter the XPath Template Galery. You can search in the galery for common XPath expressions by use-case." -ForegroundColor Gray
        $XPathQuery = [string](ReadFrom-CustomPrompt -PromptText "XPath Expression" -Prompt ":")
        
        # [TODO] Validate XPath
        # ...

        # Enable EASY-MODE
        $Match = $XPathQuery -match '^!TEMPLATES$'
        if ($Match) {
            $XPathQuery = Get-XPathFromGallery
            if ($null -eq $XPathQuery) { continue }
        }

        break
    }

    # Return new QueryTypeElement
    return [QueryTypeElement]::new($Type, $Channel, $XPathQuery)
}

# Write the entire QueryList to XML file
function Write-XmlQueryFile {
    param(
        [Parameter(Mandatory = $true)][QueryObject[]]$QueryList,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    Write-Host "[+] Writing QueryList to XML file" -ForegroundColor Cyan

    $XmlWriter = New-Object System.XMl.XmlTextWriter($OutputPath, $null)
    $XmlWriter.Formatting = "Indented"
    $XmlWriter.Indentation = 4

    $XmlWriter.WriteStartDocument()
    $XmlWriter.WriteStartElement("QueryList")

    foreach ($Query in $QueryList) {
        $XmlWriter.WriteStartElement("Query")
        $XmlWriter.WriteAttributeString("Id", $Query.Id.ToString())

        foreach ($Element in $Query.QueryElements) {
            $XmlWriter.WriteStartElement($Element.Type)
            $XmlWriter.WriteAttributeString("Path", $Element.Path)
            $XmlWriter.WriteString($Element.XPath)
            $XmlWriter.WriteEndElement()  # Select or Suppress
        }

        $XmlWriter.WriteEndElement()  # Query
    }

    $XmlWriter.WriteEndElement()  # QueryList
    $XmlWriter.WriteEndDocument()
    $XmlWriter.Flush()
    $XmlWriter.Close()

    Write-Host "[+] XML successfully written to: $OutputPath" -ForegroundColor Green
}

# Inspect current QueryList
function Inspect-QueryList {
    param(
        [Parameter(Mandatory = $true)][QueryObject[]]$QueryList
    )

    Write-Host "-------- Current QueryList --------" -ForegroundColor Cyan

    foreach ($Query in $QueryList) {
        Write-Host "Query Id: $($Query.Id)" -ForegroundColor Yellow
        foreach ($Element in $Query.QueryElements) {
            Write-Host "  [$($Element.Type)] Path='$($Element.Path)' XPath='$($Element.XPath)'" -ForegroundColor Gray
        }
    }

    Read-Host "Continue? "
    Write-Host "----------------------------------" -ForegroundColor Cyan
}

function Get-MenuOption {
    try {
        $Option = [int](ReadFrom-CustomPrompt)
    }
    catch {
        Write-Host "Invalid input" -ForegroundColor Red
        return $null
    }
    return $Option
}

function Get-Channel {
    
    while ($true) {
        Write-CustomMenu -MenuOptions @(
            "Application", 
            "Security", 
            "System", 
            "Setup",
            "[Submenu] Windows OS Logs",
            "Other") -PreMenuText "Select a channel from where to read event logs:"
    
        try {
            $MenuOption = [int](ReadFrom-CustomPrompt)
        }
        catch {
            Write-Host "Invalid input" -ForegroundColor Red
            continue
        }

        switch ($MenuOption) {
            1 { return "Application" }
            2 { return "Security" }
            3 { return "System" }
            4 { return "Setup" }
            5 { return Get-WindowsOsChannels }
            6 { return ReadFrom-CustomPrompt }
            default { Write-Warning "Invalid option"; break }
        }
    }
}

function Get-WindowsOsChannels {
    Write-Host "[TODO]" -ForegroundColor red
}

Get-XPathFromGallery {

}