# ThoughtForge Review - Run CC1 review, write results.md + results-applyprompttext.md
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

$reviewPrompt = @"
Read project-plan-review-prompt.md and follow the instructions. Review these files:
- thoughtforge-requirements-brief.md
- thoughtforge-design-specification.md
- thoughtforge-build-spec.md
- thoughtforge-execution-plan.md
"@

$output = $reviewPrompt | claude -p - --output-format text

# Write full review for auditing
$output | Set-Content -Path "results.md" -Encoding UTF8
$fullSize = (Get-Item "results.md").Length
Send-Notify "[REVIEW] results.md written ($fullSize bytes)"

# Extract Consolidated Coder Prompt section
$marker = "Consolidated Coder Prompt"
$idx = $output.IndexOf($marker)
if ($idx -ge 0) {
    $coderPrompt = $output.Substring($idx)
    $coderPrompt | Set-Content -Path "results-applyprompttext.md" -Encoding UTF8
    $promptSize = (Get-Item "results-applyprompttext.md").Length
    Send-Notify "[REVIEW] results-applyprompttext.md written ($promptSize bytes)"
} else {
    Send-Notify "[REVIEW] WARNING: Could not find '$marker' in output. results-applyprompttext.md not created."
}

# Git commit
git add results.md results-applyprompttext.md
git commit -m "Review iteration - results.md ($fullSize bytes)"
git push

Send-Notify "[REVIEW] Done."