# ThoughtForge Polish Loop
# Usage: .\polish.ps1 [-MaxIterations 50]
param(
    [int]$MaxIterations = 50
)

# -- Load .env --
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^(.+?)=(.+)$") { Set-Item "env:$($matches[1])" $matches[2] }
    }
}

$TELEGRAM_TOKEN   = $env:TELEGRAM_TOKEN
$TELEGRAM_CHAT_ID = $env:TELEGRAM_CHAT_ID
$COUNTER_FILE     = "reviewcount.txt"
$scriptDir        = $PSScriptRoot

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

if (Test-Path $COUNTER_FILE) {
    $count = [int](Get-Content $COUNTER_FILE)
    Send-Notify "[RESUMED] Polish resuming from iteration $count (max $MaxIterations)"
} else {
    $count = 0
    Send-Notify "[STARTED] Polish loop running (max $MaxIterations iterations)"
}

while ($count -lt $MaxIterations) {
    $count++
    $count | Set-Content -Path $COUNTER_FILE
    Send-Notify "[ITERATION $count/$MaxIterations]"

    # -- Step 1: Review --
    & "$scriptDir\review.ps1"
    if ($LASTEXITCODE -ne 0) {
        Send-Notify "[POLISH STOPPED] Failed at iteration $count"
        exit 1
    }

    # -- Step 2: Check --
    & "$scriptDir\check.ps1"
    if ($LASTEXITCODE -ne 0) {
        Send-Notify "[POLISH STOPPED] Failed at iteration $count"
        exit 1
    }

    # -- Step 3: Decide --
    $checkResult = Get-Content "resultscheck.md" -Raw
    if ($checkResult -match 'result:\s*true') {
        # Still needs updates -- apply fixes
        & "$scriptDir\apply.ps1"
        if ($LASTEXITCODE -ne 0) {
            Send-Notify "[POLISH STOPPED] Failed at iteration $count"
            exit 1
        }
    } else {
        # Converged
        if (Test-Path $COUNTER_FILE) { Remove-Item $COUNTER_FILE }
        Send-Notify "[CONVERGED] Polish converged at iteration $count. No more updates needed."
        Write-Host "========================================================"
        Write-Host "  CONVERGED at iteration $count"
        Write-Host "========================================================"
        exit 0
    }
}

# -- Max iterations --
if (Test-Path $COUNTER_FILE) { Remove-Item $COUNTER_FILE }
Send-Notify "[MAX ITERATIONS] Polish hit $MaxIterations iterations without converging."
Write-Host "========================================================"
Write-Host "  MAX ITERATIONS ($MaxIterations) reached"
Write-Host "  Check results.md for remaining findings."
Write-Host "========================================================"