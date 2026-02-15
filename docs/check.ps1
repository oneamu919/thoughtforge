# ThoughtForge Check - Read results.md, check convergence via CC2
# Usage: .\check.ps1

# -- Load .env --
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^(.+?)=(.+)$") { Set-Item "env:$($matches[1])" $matches[2] }
    }
}

# -- UTF-8 Encoding --
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$TELEGRAM_TOKEN   = $env:TELEGRAM_TOKEN
$TELEGRAM_CHAT_ID = $env:TELEGRAM_CHAT_ID

function Send-Notify($message) {
    $truncated = if ($message.Length -gt 500) { $message.Substring(0, 500) + "... [truncated]" } else { $message }
    $uri = "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"
    try {
        Invoke-RestMethod -Uri $uri -Method Post -Body @{
            chat_id = $TELEGRAM_CHAT_ID
            text    = $truncated
        } -ErrorAction SilentlyContinue
    } catch {}
    Write-Host $message
}

# -- Preflight --
if (-not (Test-Path "check-prompt.md")) {
    Write-Host "ERROR: check-prompt.md not found." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "results.md")) {
    Write-Host "ERROR: results.md not found. Run review.ps1 first." -ForegroundColor Red
    exit 1
}

# Capture apply-prompt.md timestamp before check runs
$applyPromptBefore = $null
if (Test-Path "apply-prompt.md") {
    $applyPromptBefore = (Get-Item "apply-prompt.md").LastWriteTime
}

Send-Notify "[CHECK] Checking results.md..."
$result = Get-Content "check-prompt.md" -Raw -Encoding UTF8 | claude -p - --dangerously-skip-permissions --output-format text

if ($LASTEXITCODE -ne 0) {
    Send-Notify "[CHECK] Claude failed with exit code $LASTEXITCODE"
    exit 1
}

# If still needs updates, verify apply-prompt.md was actually refreshed
if ($result -match 'result:\s*true') {
    if (-not (Test-Path "apply-prompt.md")) {
        Send-Notify "[CHECK] FAILED: apply-prompt.md not found. CC2 output: $result"
        exit 1
    }
    $applyPromptAfter = (Get-Item "apply-prompt.md").LastWriteTime
    if ($applyPromptBefore -and $applyPromptAfter -le $applyPromptBefore) {
        Send-Notify "[CHECK] FAILED: apply-prompt.md was not updated. CC2 output: $result"
        exit 1
    }
}

$result | Set-Content -Path "resultscheck.md" -Encoding UTF8

# Git commit
git add resultscheck.md
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "Check iteration - resultscheck.md"
    git push
} else {
    Write-Host "No changes to commit, skipping."
}

Send-Notify "[CHECK] $result"