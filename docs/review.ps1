# ThoughtForge Review - Read review-prompt.md, send to CC1
# Usage: .\review.ps1

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
if (-not (Test-Path "review-prompt.md")) {
    Write-Host "ERROR: review-prompt.md not found." -ForegroundColor Red
    exit 1
}

Send-Notify "[REVIEW] Running CC1 review..."
$result = Get-Content "review-prompt.md" -Raw -Encoding UTF8 | claude -p - --dangerously-skip-permissions --output-format text
$result | Set-Content -Path "results.md" -Encoding UTF8

# Git commit
git add results.md
git commit -m "Review iteration - results.md"
git push

Send-Notify "[REVIEW] $result"