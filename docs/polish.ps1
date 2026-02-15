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

# -- UTF-8 Encoding --
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$TELEGRAM_TOKEN   = $env:TELEGRAM_TOKEN
$TELEGRAM_CHAT_ID = $env:TELEGRAM_CHAT_ID
$COUNTER_FILE     = "reviewcount.txt"
$STATUS_FILE      = "polish-status.md"
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

function Format-Duration($ts) {
    return "{0}m {1:D2}s" -f [int][math]::Floor($ts.TotalMinutes), $ts.Seconds
}

function Parse-Counts($text) {
    $c = 0; $ma = 0; $mi = 0
    if ($text -match 'Critical:\s*(\d+)') { $c  = [int]$matches[1] }
    if ($text -match 'Major:\s*(\d+)')    { $ma = [int]$matches[1] }
    if ($text -match 'Minor:\s*(\d+)')    { $mi = [int]$matches[1] }
    return @{ Critical = $c; Major = $ma; Minor = $mi }
}

function Write-Status {
    $status = "# Polish Status`n"
    if ($script:converged) {
        $status += "CONVERGED at iteration $($script:count)/$MaxIterations`n"
    } elseif ($script:hitMax) {
        $status += "MAX ITERATIONS reached at $($script:count)/$MaxIterations`n"
    } else {
        $status += "Running: iteration $($script:count)/$MaxIterations`n"
    }
    $status += "`n## Progress`n"
    foreach ($entry in $script:iterationLog) {
        $status += "$entry`n"
    }
    $totalTime = $script:totalReview + $script:totalCheck + $script:totalApply
    $status += "`n## Totals`n"
    $status += "Elapsed: $(Format-Duration $totalTime) (Review: $(Format-Duration $script:totalReview), Check: $(Format-Duration $script:totalCheck), Apply: $(Format-Duration $script:totalApply))`n"
    $status | Set-Content -Path $STATUS_FILE -Encoding UTF8
}

# -- Timing accumulators --
$totalReview = [TimeSpan]::Zero
$totalCheck  = [TimeSpan]::Zero
$totalApply  = [TimeSpan]::Zero
$firstCounts = $null
$lastCounts  = $null
$iterationLog = @()
$converged = $false
$hitMax = $false

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
    $t1 = Get-Date
    & "$scriptDir\review.ps1"
    if ($LASTEXITCODE -ne 0) {
        Send-Notify "[POLISH STOPPED] Review failed at iteration $count"
        exit 1
    }
    $reviewTime = (Get-Date) - $t1
    $totalReview += $reviewTime
    Send-Notify "[REVIEW] $(Format-Duration $reviewTime)"

    # -- Step 2: Check --
    $t2 = Get-Date
    & "$scriptDir\check.ps1"
    if ($LASTEXITCODE -ne 0) {
        Send-Notify "[POLISH STOPPED] Check failed at iteration $count"
        exit 1
    }
    $checkTime = (Get-Date) - $t2
    $totalCheck += $checkTime
    Send-Notify "[CHECK] $(Format-Duration $checkTime)"

    # -- Parse counts --
    $checkResult = Get-Content "resultscheck.md" -Raw
    $counts = Parse-Counts $checkResult
    if (-not $firstCounts) { $firstCounts = $counts }
    $lastCounts = $counts

    # -- Step 3: Decide --
    if ($checkResult -match 'result:\s*true') {
        # Still needs updates -- apply fixes
        $t3 = Get-Date
        & "$scriptDir\apply.ps1"
        if ($LASTEXITCODE -ne 0) {
            Send-Notify "[POLISH STOPPED] Apply failed at iteration $count"
            exit 1
        }
        $applyTime = (Get-Date) - $t3
        $totalApply += $applyTime
        Send-Notify "[APPLY] $(Format-Duration $applyTime)"

        $iterTime = $reviewTime + $checkTime + $applyTime
        $iterLine = "Iteration $count`: Critical: $($counts.Critical), Major: $($counts.Major), Minor: $($counts.Minor) ($(Format-Duration $iterTime)) (Review: $(Format-Duration $reviewTime), Check: $(Format-Duration $checkTime), Apply: $(Format-Duration $applyTime))"
        Send-Notify $iterLine
        $iterationLog += $iterLine
        Write-Status
    } else {
        # Converged
        $iterTime = $reviewTime + $checkTime
        $iterLine = "Iteration $count`: Critical: $($counts.Critical), Major: $($counts.Major), Minor: $($counts.Minor) ($(Format-Duration $iterTime)) (Review: $(Format-Duration $reviewTime), Check: $(Format-Duration $checkTime))"
        Send-Notify $iterLine
        $iterationLog += $iterLine
        $converged = $true
        Write-Status

        $totalTime = $totalReview + $totalCheck + $totalApply
        if (Test-Path $COUNTER_FILE) { Remove-Item $COUNTER_FILE }

        $summary = "[CONVERGED] Polish converged at iteration $count/$MaxIterations.`n"
        $summary += "Start:  Critical: $($firstCounts.Critical), Major: $($firstCounts.Major), Minor: $($firstCounts.Minor)`n"
        $summary += "Final:  Critical: $($counts.Critical), Major: $($counts.Major), Minor: $($counts.Minor)`n"
        $summary += "Total: $(Format-Duration $totalTime) (Review: $(Format-Duration $totalReview), Check: $(Format-Duration $totalCheck), Apply: $(Format-Duration $totalApply))"
        Send-Notify $summary

        Write-Host "========================================================"
        Write-Host "  CONVERGED at iteration $count"
        Write-Host "========================================================"
        exit 0
    }
}

# -- Max iterations --
$hitMax = $true
Write-Status

$totalTime = $totalReview + $totalCheck + $totalApply
if (Test-Path $COUNTER_FILE) { Remove-Item $COUNTER_FILE }

$summary = "[MAX ITERATIONS] Polish hit $MaxIterations iterations without converging.`n"
$summary += "Start:  Critical: $($firstCounts.Critical), Major: $($firstCounts.Major), Minor: $($firstCounts.Minor)`n"
$summary += "Final:  Critical: $($lastCounts.Critical), Major: $($lastCounts.Major), Minor: $($lastCounts.Minor)`n"
$summary += "Total: $(Format-Duration $totalTime) (Review: $(Format-Duration $totalReview), Check: $(Format-Duration $totalCheck), Apply: $(Format-Duration $totalApply))"
Send-Notify $summary

Write-Host "========================================================"
Write-Host "  MAX ITERATIONS ($MaxIterations) reached"
Write-Host "  Check results.md for remaining findings."
Write-Host "========================================================"
exit 1