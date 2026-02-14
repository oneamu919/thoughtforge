# Pass results.md to Claude Code to check if updates are needed
$TELEGRAM_TOKEN   = "7998768592:AAHxlbOZPm0b_Vf5ipuTu3BRr6LudeItIO8"
$TELEGRAM_CHAT_ID = "7897824652"
$COUNTER_FILE     = "reviewcount.txt"

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

# -- Counter --
if (Test-Path $COUNTER_FILE) {
    $count = [int](Get-Content $COUNTER_FILE)
} else {
    $count = 0
}
$count++
$count | Set-Content -Path $COUNTER_FILE

Send-Notify "[CHECK #$count] Checking results.md..."

# -- Preflight --
if (-not (Test-Path "results.md")) {
    Write-Host "ERROR: results.md not found. Run review.ps1 first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "check-prompt.md")) {
    Write-Host "ERROR: check-prompt.md not found." -ForegroundColor Red
    exit 1
}

$findings = Get-Content "results.md" -Raw

$checkPrompt = Get-Content "check-prompt.md" -Raw
$checkPrompt += "`n`n--- REVIEW DOCUMENT ---`n$findings"

$result = claude -p $checkPrompt --output-format text 2>$null

Send-Notify "[CHECK #$count] $result"

# -- If true, apply the fixes --
if ($result -match 'result:\s*true') {
    Send-Notify "[APPLY #$count] Applying fixes from results.md..."

    $applyPrompt = @"
Apply every change from the review below to the project files. Be precise. Do not skip anything. After applying all changes, git add, commit, and push.

--- REVIEW ---
$findings
"@

    claude -p $applyPrompt --output-format text 2>$null | Out-Null
    Send-Notify "[APPLY #$count] Done. Changes applied."
} else {
    if (Test-Path $COUNTER_FILE) { Remove-Item $COUNTER_FILE }
    Send-Notify "[CHECK #$count] No updates needed. Done."
}