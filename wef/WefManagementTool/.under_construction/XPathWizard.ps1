

# EASY-MODE allows the user to use any of the following common querying patterns
# 1. Simple EventID matching in System:
#   <Select Path="$Path">*[System[(EventID=X or EventID=Y or (EventID>=A and EventID<=B))]]</Select>
#
# 2. EventID + EventData filtering
#   <Select Path="$Path">*[System[(EventID=X)]] and EventData[Data[@Name='Key'] = 'Value']</Select>
#
# 3. Complex System filter
#   <Select Path="$Path"> *[System[(EventID=X or EventID=Y) and Provider[@Name='ProviderName'] and Level=LevelValue and (Keywords = KeywordsValue)]] </Select>
function Get-XPathFromWizard {

    # Import Utilities
    $utilitiesPath = Join-Path $PSScriptRoot 'Utilities'
    Get-ChildItem "$utilitiesPath\*.ps1" | ForEach-Object {
        . $_.FullName
    }
 
    while ($true) {
        $PreMenuText = "EASY-MODE Enabled`nSelect any of the common querying templates and fill the information requested."
        Write-CustomMenu -MenuTitle "XPath builder Wizard" -PreMenuText $PreMenuText -MenuOptions @(
            'Simple EventID matching [TODO]',
            'EventID matching with Data Filtering [TODO]',
            'Complex SystemElement filtering [TODO]',
            'Use wizard',
            'NORMAL-MODE'
        )
        $Option = Get-MenuOption
        switch ($Option) {
            1 {
                # XPathStructure
                # *[System[(EventID = X or EventID = Y or (EventID &gt; A and EventID &lt; B))]]
                
                Write-Host "[*] Provide the EventID(s)." -ForegroundColor Gray
                Write-Host "    - Separate by COMMAS to make OR operations. Example: > 4624, 2625 -> EventID=4624 or EventID=4625" -ForegroundColor Gray
                Write-Host "    - Separate by SPACES to make AND operations. Example: > 4624 4625 -> (EventID=4624 and EventID=4625)" -ForegroundColor Gray
                Write-Host "    - Separate by HYPENS to make a range. Example: > 4620-4630 -> (EventID &gt;4620 and EventID &lt;4630)" -ForegroundColor Gray
                Write-Host "    - Use parenthesis to change the grouping order ()" -ForegroundColor Gray
                
                # > Examples
                # > 1, 2, (3-4, 5) : *[System[(EventID=1 or EventID=2 or ( (EventID &gt;=3 and EventID &lt;=4) or EventID=5))]]
                # > (30622, 30624) (30800, 30803-30806) : *[System[(EventID=30622 or EventID=30624) and (EventID=30800 or (EventID &gt;= 30803 and EventID &lt;= 30806))]]
                # > 30622,30624 30800,30803-30806 : *[System[(EventID=30622 or EventID=30624) and (EventID=30800 or (EventID &gt;=30803 and EventID &lt;=30806))]]
                $XPathQueryRaw = [string](ReadFrom-CustomPrompt -Prompt ">")
                

            }
            2 {
                # XPathStructure
                # *[System[(EventID=X)]] and EventData[Data[@Name='Key'] = 'Value']


            }
            3 { 
                # XPathStructure
                # *[System[(EventID=X or EventID=Y) and Provider[@Name='ProviderName'] and Level=LevelValue and (Keywords = KeywordsValue)]]


            }
            4 { return $null }
            default { Write-Warning "Invalid option"; break }
        }
    }
}