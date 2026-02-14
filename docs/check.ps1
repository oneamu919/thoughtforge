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
if (-not (Test-Path "check-prompt.md")) {
    Write-Host "ERROR: check-prompt.md not found." -ForegroundColor Red
    exit 1
}

Send-Notify "[CHECK] Checking results.md..."
$result = Get-Content "check-prompt.md" -Raw -Encoding UTF8 | claude -p - --dangerously-skip-permissions --output-format text
$result | Set-Content -Path "resultscheck.md" -Encoding UTF8

# Git commit
git add resultscheck.md
git commit -m "Check iteration - resultscheck.md"
git push

Send-Notify "[CHECK] $result"