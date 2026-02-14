# ThoughtForge Review - Run CC1 review, write results.md
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
if (-not (Test-Path "project-plan-review-prompt.md")) {
    Write-Host "ERROR: project-plan-review-prompt.md not found." -ForegroundColor Red
    exit 1
}

Send-Notify "[REVIEW] Running CC1 review..."
claude -p "Read project-plan-review-prompt.md for your instructions. Review these four files: thoughtforge-requirements-brief.md, thoughtforge-design-specification.md, thoughtforge-build-spec.md, thoughtforge-execution-plan.md. Output your complete review with all findings, severity tags, and the consolidated coder prompt." --output-format text | Set-Content -Path "results.md"
$size = (Get-Item "results.md").Length
Send-Notify "[REVIEW] Done. results.md written ($size bytes)"

