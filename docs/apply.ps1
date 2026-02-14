# ThoughtForge Apply - Read apply-prompt.md, send to CC3
# Usage: .\apply.ps1

# -- Load .env --
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^(.+?)=(.+)$") { Set-Item "env:$($matches[1])" $matches[2] }
    }
}

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
if (-not (Test-Path "apply-prompt.md")) {
    Write-Host "ERROR: apply-prompt.md not found." -ForegroundColor Red
    exit 1
}

Send-Notify "[APPLY] Applying fixes..."
$result = Get-Content "apply-prompt.md" -Raw -Encoding UTF8 | claude -p - --dangerously-skip-permissions --output-format text

if ($LASTEXITCODE -ne 0) {
    Send-Notify "[APPLY] Claude failed with exit code $LASTEXITCODE"
    exit 1
}

Write-Host $result

# Git commit
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "Apply review findings"
    git push
} else {
    Write-Host "No changes to commit, skipping."
}

Send-Notify "[APPLY] $result"
