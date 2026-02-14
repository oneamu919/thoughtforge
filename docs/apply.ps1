# ThoughtForge Apply - Pass results.md to CC3 to apply fixes
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
if (-not (Test-Path "results.md")) {
    Write-Host "ERROR: results.md not found. Run polish.ps1 first." -ForegroundColor Red
    exit 1
}

$findings = Get-Content "results.md" -Raw
$applyPrompt = @"
Apply every change from the review below to the project files. Be precise. Do not skip anything. After applying all changes, git add, commit, and push.

--- REVIEW ---
$findings
"@

Send-Notify "[APPLY] Applying fixes from results.md..."
claude -p $applyPrompt --output-format text
Send-Notify "[APPLY] Done. Changes applied."
