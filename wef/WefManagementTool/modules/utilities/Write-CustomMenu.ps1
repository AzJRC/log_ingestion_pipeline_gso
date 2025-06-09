
function Write-CustomMenu {
    param(
        [Parameter(Mandatory = $true)][string[]]$MenuOptions,
        [string]$MenuTitle = "",
        [Hashtable]$MenuTitleFlags = @{'SpaceTop' = 1; 'NoTop' = $true; 'NoRightSide' = $true; 'NoLeftSide' = $true; 'Color' = 'Cyan' },
        [Hashtable]$MenuItemStyle = @{'ForegroundColor' = 'White' },
        [string]$PreMenuText,
        [string]$PostMenuText
        
    )
    if (-not (Get-Command Write-MessageInBox -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot\Write-HostMessageInBox.ps1"
    }

    #Helper Variable
    $LongestOptionLength = ($MenuOptions | Sort-Object length -desc | Select-Object -first 1).Length
    $SuggestedHLineLength = [int]($LongestOptionLength / 4)

    #Menu Settings
    $LeftMenuOptionsPadding = 3
    $InnerMenuOptionsPadding = 3

    $MenuTitlePadding = $LeftMenuOptionsPadding + [int](($LongestOption - $MenuTitle.Length + $InnerMenuOptionsPadding) / 2) + $SuggestedHLineLength

    #Menu Title
    if ($MenuTitle.Length -gt 0) {
        Write-HostMessageInBox -Msg $MenuTitle @MenuTitleFlags -LeftBoxPadding $MenuTitlePadding -InnerPadding $SuggestedHLineLength
        Write-Host "`n"
    }

    #Optional text between title and options
    if ($PreMenuText) { Write-Host $PreMenuText -ForegroundColor Cyan; Write-Host "`n" }
    
    # Options loop
    $OptionId = 1
    foreach ($MenuOption in $MenuOptions) {
        $optionPreface = ((" " * $LeftMenuOptionsPadding) + "[$OptionId]" + (" " * $InnerMenuOptionsPadding))
        
        Write-Host $optionPreface -ForegroundColor Cyan -NoNewline
        Write-Host $MenuOption @MenuItemStyle

        $OptionId += 1
    }
    Write-Host "`n"

    #Optional text after menu
    if ($PostMenuText) { Write-Host $PostMenuText -ForegroundColor Cyan; Write-Host "`n" }
}