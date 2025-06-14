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