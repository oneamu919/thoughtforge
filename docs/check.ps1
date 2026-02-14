# ThoughtForge Check - Read results.md, check convergence via CC2
# Usage: .\check.ps1

$TELEGRAM_TOKEN   = "7998768592:AAHxlbOZPm0b_Vf5ipuTu3BRr6LudeItIO8"
$TELEGRAM_CHAT_ID = "7897824652"

function Send-Notify($message) {
    $uri = "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Body @{
            chat_id = $TELEGRAM_CHAT_ID
            text    = $message
        } -ErrorAction SilentlyContinue
    } catch {}
    Write-Host $message
}

# -- Preflight --
if (-not (Test-Path "results.md")) {
    Write-Host "ERROR: results.md not found. Run review.ps1 first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "check-prompt.md")) {
    Write-Host "ERROR: check-prompt.md not found." -ForegroundColor Red
    exit 1
}

Send-Notify "[CHECK] Checking results.md..."
$findings = Get-Content "results.md" -Raw
$checkPrompt = Get-Content "check-prompt.md" -Raw
$checkPrompt += "`n`n--- REVIEW DOCUMENT ---`n$findings"
$result = claude -p $checkPrompt --output-format text
Send-Notify "[CHECK] $result"
