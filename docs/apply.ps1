# ThoughtForge Apply - Build apply-prompt.md from results-applyprompttext.md, send to CC3
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
if (-not (Test-Path "results-applyprompttext.md")) {
    Write-Host "ERROR: results-applyprompttext.md not found. Run review.ps1 first." -ForegroundColor Red
    exit 1
}

Send-Notify "[APPLY] Writing apply-prompt.md..."

$coderPrompt = Get-Content "results-applyprompttext.md" -Raw
$applyPrompt = @"
You MUST directly edit the files on disk. Do NOT describe or summarize changes. Do NOT explain what you would do. Open each file, make the edits, and save.

Read the coder prompt below. Apply every change to the correct file:
- thoughtforge-requirements-brief.md
- thoughtforge-design-specification.md
- thoughtforge-build-spec.md
- thoughtforge-execution-plan.md

Save each file after editing. After all files are edited and saved, run:
git add -A
git commit -m "Apply review findings from results.md"
git push

When finished, output ONLY a single line in this format: Applied: X critical, Y major, Z minor. Do not output anything else.

--- CODER PROMPT ---
$coderPrompt
"@

$applyPrompt | Set-Content -Path "apply-prompt.md" -Encoding UTF8
$size = (Get-Item "apply-prompt.md").Length
Send-Notify "[APPLY] apply-prompt.md written ($size bytes)"

Send-Notify "[APPLY] Applying fixes..."
$result = claude -p (Get-Content "apply-prompt.md" -Raw) --output-format text
Write-Host $result

Send-Notify "[APPLY] $result"