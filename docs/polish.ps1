# ThoughtForge Polish Loop
# Usage: .\polish.ps1 [-Verbose]
param(
    [switch]$Verbose,
    [int]$MaxIterations = 25
)

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

# -- Preflight --
if (-not (Test-Path "project-plan-review-prompt.md")) {
    Write-Host "ERROR: project-plan-review-prompt.md not found." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path "check-prompt.md")) {
    Write-Host "ERROR: check-prompt.md not found." -ForegroundColor Red
    exit 1
}

# -- Counter --
if (Test-Path $COUNTER_FILE) {
    $count = [int](Get-Content $COUNTER_FILE)
} else {
    $count = 0
}

Send-Notify "[STARTED] Polish loop running (max $MaxIterations iterations)"

while ($count -lt $MaxIterations) {
    $count++
    $count | Set-Content -Path $COUNTER_FILE

    # -- Step 1: CC1 Review --
    if ($Verbose) { Send-Notify "[REVIEW #$count] Running CC1 review..." }
    $reviewPrompt = Get-Content "project-plan-review-prompt.md" -Raw
    $reviewPrompt += "`n`nRead all project files and apply your review."
    claude -p $reviewPrompt --output-format text | Set-Content -Path "results.md"
    $size = (Get-Item "results.md").Length
    if ($Verbose) { Send-Notify "[REVIEW #$count] results.md written ($size bytes)" }

    # -- Step 2: CC2 Check --
    if ($Verbose) { Send-Notify "[CHECK #$count] Checking results.md..." }
    $findings = Get-Content "results.md" -Raw
    $checkPrompt = Get-Content "check-prompt.md" -Raw
    $checkPrompt += "`n`n--- REVIEW DOCUMENT ---`n$findings"
    $result = claude -p $checkPrompt --output-format text 2>$null
    if ($Verbose) { Send-Notify "[CHECK #$count] $result" }

    # -- Step 3: Decide --
    if ($result -match 'result:\s*true') {
        # Still needs updates -- apply fixes
        Send-Notify "[APPLY #$count] Applying fixes from results.md..."
        $applyPrompt = @"
Apply every change from the review below to the project files. Be precise. Do not skip anything. After applying all changes, git add, commit, and push.

--- REVIEW ---
$findings
"@
        claude -p $applyPrompt --output-format text 2>$null | Out-Null
        Send-Notify "[APPLY #$count] Done. Looping back to review."
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