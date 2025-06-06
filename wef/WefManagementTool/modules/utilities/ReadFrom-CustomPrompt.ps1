
function ReadFrom-CustomPrompt {
    param(
        [char]$Prompt = '>',
        [string]$PromptText = ""      
    )

    # Prompt line
    Write-Host (" " * $LeftMenuOptionsPadding + $PromptText + $Prompt + " ") -ForegroundColor Cyan -NoNewLine

    # Read, trim, validate, and return a clean integer
    $input = $Host.UI.ReadLine().Trim()
    return $input
}