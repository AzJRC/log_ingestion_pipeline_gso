<#
.EXAMPLE
    PS > Write-HostMessageInBox -Msg "Hola Mundo"
    |==============|
    |  Hola Mundo  |
    |==============|

.EXAMPLE
    PS > Write-HostMessageInBox -Msg "Hola Mundo" -InnerSymbols + -InnerSymbolLength 3 -InnerPadding 3 -HorizontalSideSymbols @("+","+")
    |++++++++++++++++++++++|
    |      Hola Mundo      |
    |++++++++++++++++++++++|

    *$InnerSymbols, $HorizontalSideSymbols and $VerticalSideSymbols accept two sets of symbols, one per relative side. Usually you would like to use the same symbol for both.

.EXAMPLE
    PS > Write-HostMessageInBox -Msg "Test" -InnerSymbols @(">","<") -InnerSymbolLength 3 -Inn
    |==============|
    |>>>  Test  <<<|
    |==============|

.EXAMPLE
    PS > Write-HostMessageInBox -Msg "Hola Mundo" -InnerSymbols + -InnerSymbolLength 3 -InnerPadding 3 -NoTop -NoBottom -NoRightSide
    |
    |      Hola Mundo
    |

.EXAMPLE
    PS > Write-HostMessageInBox -Msg "Test" -NoLeftSide -NoRightSide -SpaceTop 2


    ======== 
      Test
    ========
#>
function Write-MessageInBox {
    param(
        [string]$Msg,
        [string]$Color,
        [bool]$ToUpper,
        [char[]]$InnerSymbols = @(" ", " "),
        [int]$InnerSymbolLength = 1,
        [int]$InnerPadding = 1,
        [char[]]$LateralSideSymbols = @("|", "|"),
        [char[]]$HorizontalSideSymbols = @("=", "="),
        [switch]$NoTop,
        [switch]$NoBottom,
        [switch]$NoLeftSide,
        [switch]$NoRightSide,
        [int]$SpaceTop = 0,
        [int]$SpaceBottom = 0,
        [int]$LeftBoxPadding = 3
    )

    # Defensive fallback
    $LeftInner = if ($InnerSymbols.Count -ge 1 -and $InnerSymbols[0]) { $InnerSymbols[0] } else { " " }
    $RightInner = if ($InnerSymbols.Count -ge 2 -and $InnerSymbols[1]) { $InnerSymbols[1] } else { " " }

    #Helper variables
    $HorizontalLength = ($InnerSymbolLength * 2) + ($InnerPadding * 2) + $Msg.Length
    $MsgCase = if ($ToUpper) { $Msg.ToUpper() } else { $Msg }
    $BottomWithoutCorners = ([string]$HorizontalSideSymbols[0] * $HorizontalLength)

    if ( $LeftBoxPadding -gt 0 ) { $LeftBoxPaddingString = " " * $LeftBoxPadding } else { "" }

    #Box parts
    $BoxTop = $LeftBoxPaddingString + $(if ($NoLeftSide) { " " } else { $LateralSideSymbols[0] }) +
    $(if ($NoTop) { " " * $HorizontalLength } else { $BottomWithoutCorners }) +
    $(if ($NoRightSide) { " " } else { $LateralSideSymbols[1] }) + "`n"

    $BoxMiddle = $LeftBoxPaddingString + $(if ($NoLeftSide) 
        { " " + (" " * $InnerSymbolLength) + (" " * $InnerPadding) } 
        else { $LateralSideSymbols[0] + ([string]$LeftInner * $InnerSymbolLength) + (" " * $InnerPadding) }) +
    $MsgCase + 
    $(if ($NoRightSide) { (" " * $InnerPadding) + (" " * $InnerSymbolLength) + " " } 
        else { (" " * $InnerPadding) + ([string]$RightInner * $InnerSymbolLength) + $LateralSideSymbols[1] }) + "`n"

    $BoxBottom = $LeftBoxPaddingString + $(if ($NoLeftSide) { " " } else { $LateralSideSymbols[0] }) +
    $(if ($NoBottom) { " " * $HorizontalLength } else { $BottomWithoutCorners }) +
    $(if ($NoRightSide) { " " } else { $LateralSideSymbols[1] })

    if (-not $Color) { $Color = "White" }

    Write-Host ("`n" * $SpaceTop + $BoxTop + $BoxMiddle + $BoxBottom + "`n" * $SpaceBottom) -ForegroundColor $Color
}