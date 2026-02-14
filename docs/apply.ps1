# ThoughtForge Apply - Read apply-prompt.md, send to CC3
# Usage: .\apply.ps1

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
if (-not (Test-Path "apply-prompt.md")) {
    Write-Host "ERROR: apply-prompt.md not found." -ForegroundColor Red
    exit 1
}

Send-Notify "[APPLY] Applying fixes..."
$result = Get-Content "apply-prompt.md" -Raw -Encoding UTF8 | claude -p - --dangerously-skip-permissions --output-format text
Write-Host $result

# Git commit
git add -A
git commit -m "Apply review findings"
git push

Send-Notify "[APPLY] $result"