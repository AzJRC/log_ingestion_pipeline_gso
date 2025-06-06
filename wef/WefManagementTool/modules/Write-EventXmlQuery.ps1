
function Write-EventXmlQuery {
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            HelpMessage = "Path where to save the XML query file.")]
        [Alias("Path")]
        [string]
        $OutputPath = "$PSScriptRoot\..\Files\SubscriptionEventXmlQuery.xml"
    )

    # Import Utilities
    $utilitiesPath = Join-Path $PSScriptRoot 'Utilities'
    Get-ChildItem "$utilitiesPath\*.ps1" | ForEach-Object {
        . $_.FullName
    }

    Write-MessageInBox -Msg "Event XML Query Creator Tool" -Color Cyan

    # Start XmlWriter
    $XmlWriter = New-Object System.XMl.XmlTextWriter($OutputPath, $null)
        
    # XML Writer Settings
    $xmlWriter.Formatting = "Indented"
    $xmlWriter.Indentation = "4"

    # Begin XML Query file with <Querylist> tag
    $xmlWriter.WriteStartDocument()
    $xmlWriter.WriteStartElement("QueryList")

    # Helper variables
    $QueryObjectCount = 0  # Also represents the current Query Object ID
    $QueryItemCount = 0

    $ContinueObjectMenuLoop = $true
    while ($ContinueObjectMenuLoop) {
     
        Write-CustomMenu -MenuTitle "[Query Object Menu]" -MenuOptions @("Add a new query object", "Inspect current query objects [TODO]", "Finish Query") -PreMenuText "Select an option:"
        
        try {
            $Option = [int](ReadFrom-CustomPrompt)
            # Write-Host "Selected Option: [$Option]" -ForegroundColor DarkGray   # Use to debug 
        }
        catch {
            Write-Host "Invalid input" -ForegroundColor Red
            continue
        }

        

        switch ($Option) {
            1 {
                $QueryItemCount += Write-QueryObject $QueryObjectCount $QueryItemCount
                $QueryObjectCount += 1
                continue 
            }
            2 { 
                Write-Host "Option not yet ready [TODO]" -ForegroundColor Red; break 
            }
            3 { $ContinueObjectMenuLoop = $false; break }
            default { Write-Warning "Invalid option"; break }
        }
    }
    
    # Finish XML Query file 
    $xmlWriter.WriteEndElement()
    $xmlWriter.Finalize
    $xmlWriter.Flush()
    $xmlWriter.Close()

    Write-Host "Event XML query file has been succesfully created." -ForegroundColor Cyan
}

<#
XML Event Query Structure:

<QueryList>
    <Query Id="$QueryId" Path="$Channel">
        <Select Path="$Channel">*[System[(EventID=$EventId)]]</Select>
        <Select Path="$Channel">*[System[(EventID &gt;=$EventId and EventID &lt;=$EventId)]]</Select>
        <Suppress Path="$Channel">*[EventData[Data[@Name="$EventDataKey"]="$EventDataValue"]]</Suppress>
    </Query>
</QueryList>

$QueryId                 An iterable value
$Channel            The channel where the query will search for events that matches the Select and Supress statements within the Query block.
                    Usually, the $Channel in the <Query> tag will be the same in the <Select> and <Supress> tags within it.
$EventId            A number that uniquely identifies the event of interest.
$EventDataKey       The Key within the <EventData> block in some Windows Events
$EventDataValue     The value associated with a $EventDataKey within the <EventData> block in some Windows Events.

Notes:
- We call any Select/Supress tag a query item. 
- According to user reports, WECs break when you exceed 22 query items in total (i.e., in the whole XMLQuery, not per Query block).
- Therefore, changing from individual EventIDs to ranges (e.g., 5000-5005) is recommended, as it reduces item query count.
- This limitation is not formally documented.
#>  

function Write-QueryObject {
    param(
        [Parameter(Mandatory = $true)][int]$QueryId,
        [Parameter(Mandatory = $true)][int]$QueryItemCount
    )

    # Request Channel
    $Channel = Get-Channel


    # Open QueryObject tag
    $xmlWriter.WriteStartElement("Query")
    $xmlWriter.WriteAttributeString("Id", $QueryId)
    $xmlWriter.WriteAttributeString("Path", $Channel)

    while ($true) {
        Write-Host "Writing new query item" -ForegroundColor Cyan

        $Supress = (Read-Host "Add a supress query item? [y/N]") -match '^[yY]$'
        Write-QueryItem -Channel $Channel -Supress $Supress
        $LocalQueryItemCount += 1
        
        $NewQuery = Read-Host "Do you want to add another query item (LocalQueryCount: $LocalQueryItemCount)? [Y/n]"
        if ($NewQuery.ToUpper() -eq 'N') { break }
    }

    # Close QueryObject tag
    $xmlWriter.WriteEndElement()

    return $LocalQueryItemCount
}
function Write-QueryItem {
    param(
        [string]$Channel,
        [bool]$Supress
    )

    # Open QueryItem tag
    if ($Supress) {
        $xmlWriter.WriteStartElement("Supress")
    }
    else {
        $xmlWriter.WriteStartElement("Select")
    } 
    $xmlWriter.WriteAttributeString("Path", $Channel)

    Write-XPathQuery

    # Close QueryItem tag
    $xmlWriter.WriteEndElement()
}

function Write-XPathQuery {
    $XPathQuery = "*[System[(EventID=1234)]]"
    $xmlWriter.WriteString($XPathQuery)
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

    while ($true) {
        Write-CustomMenu -MenuOptions @(
            "[Submenu] Network Logs", # Option 1
            "[Submenu] Remote Management Logs", # Option 2
            "[Submenu] System Activity", # Option 3
            "[Submenu] Software and Updates", # Option 4
            "[Submenu] Tasks and Services", # Option 5
            "[Submenu] User and Group Management", # Option 6
            "[Submenu] System Security", # Option 7
            "[Submenu] Image and External Devices", # Option 8
            "[Submenu] Powershell", # Option 9
            "[Submenu] Authentication", # Option 10
            "[Submenu] Windows Server Roles", # Option 11
            "[Submenu] Windows Server Active Directory")    # Option 12
    
        try {
            $MenuOption = [int](ReadFrom-CustomPrompt)
        }
        catch {
            Write-Host "Invalid input" -ForegroundColor Red
            continue
        }

        switch ($MenuOption) {
            1 { Write-WindowsNetworkLogMenuOption }
            2 { Write-WindowsRemoteManagementMenuOption }
            3 { Write-WindowsSystemActivtityMenuOption }
            4 { Write-WindowsSoftwareUpdatesMenuOption }
            5 { Write-WindowsTaskServicesMenuOption }
            6 { Write-WindowsUserManagementMenuOption }
            7 { Write-WindowsSystemSecurityMenuOption }
            8 { Write-WindowsImagesAndDevicesMenuOption }
            9 { Write-WindowsPowershellMenuOption }
            10 { Write-WindowsAuthenticationMenuOption }
            11 { Write-WindowsServerMenuOption }
            12 { Write-WindowsActiveDirectoryMenuOption }
            default { break }
        }
    }
}

