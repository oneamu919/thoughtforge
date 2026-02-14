# ThoughtForge Polish Loop - two-agent loop (PowerShell)
# CC1 reviews, CC2 implements, repeat until converged
#
# Usage: .\polish.ps1                  (milestones only)
#        .\polish.ps1 -Verbose         (ping every iteration + retries)
# Stop:  Ctrl+C or wait for convergence / max iterations

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# -- Config --
$MAX_ITERATIONS   = 25
$STALL_THRESHOLD  = 3
$TELEGRAM_TOKEN   = "7998768592:AAHxlbOZPm0b_Vf5ipuTu3BRr6LudeItIO8"
$TELEGRAM_CHAT_ID = "7897824652"
$VERBOSE_NOTIFY   = $Verbose.IsPresent
$REVIEW_PROMPT    = "project-plan-review-prompt.md"
$STATE_DIR        = "state"
$FINDINGS_FILE    = "$STATE_DIR\findings.md"
$LOG_FILE         = "$STATE_DIR\polish-log.jsonl"
$CONVERGENCE_FILE = "$STATE_DIR\convergence.json"

# -- Setup --
if (-not (Test-Path $STATE_DIR)) { New-Item -ItemType Directory -Path $STATE_DIR | Out-Null }

$iteration  = 0
$stallCount = 0
$prevTotal  = 999999

function Run-Git {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { git @args 2>&1 | Out-Null } catch {}
    $ErrorActionPreference = $prev
}

function Send-Notify($message) {
    if ($TELEGRAM_TOKEN -ne "" -and $TELEGRAM_CHAT_ID -ne "") {
        $uri = "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage"
        try {
            Invoke-RestMethod -Uri $uri -Method Post -Body @{
                chat_id = $TELEGRAM_CHAT_ID
                text    = $message
            } -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Host $message
}

function Write-Log($verdict, $critical, $major, $minor) {
    $entry = @{
        iteration = $iteration
        critical  = $critical
        major     = $major
        minor     = $minor
        verdict   = $verdict
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json -Compress
    Add-Content -Path $LOG_FILE -Value $entry
    $entry | Set-Content -Path $CONVERGENCE_FILE
}

function Get-Counts($file) {
    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $null }

    # Count severity tags directly from CC1 output
    $c = ([regex]::Matches($content, '\[Critical\]', 'IgnoreCase')).Count
    $m = ([regex]::Matches($content, '\[Major\]', 'IgnoreCase')).Count
    $n = ([regex]::Matches($content, '\[Minor\]', 'IgnoreCase')).Count

    return @{ critical = $c; major = $m; minor = $n }
}

# -- Preflight --
if (-not (Test-Path $REVIEW_PROMPT)) {
    Write-Host "ERROR: Missing $REVIEW_PROMPT in project root" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Claude Code CLI not found" -ForegroundColor Red
    exit 1
}

$gitCheck = git rev-parse --is-inside-work-tree 2>$null
if ($gitCheck -ne "true") {
    Write-Host "ERROR: Not a git repo. Run: git init; git add -A; git commit -m baseline" -ForegroundColor Red
    exit 1
}

Write-Host "========================================================"
Write-Host "  ThoughtForge Polish Loop"
Write-Host "  Max iterations:   $MAX_ITERATIONS"
Write-Host "  Review prompt:    $REVIEW_PROMPT"
Write-Host "  Stall threshold:  $STALL_THRESHOLD consecutive passes"
Write-Host "  Verbose notify:   $VERBOSE_NOTIFY"
Write-Host "========================================================"
Send-Notify "[STARTED] Polish loop started (max $MAX_ITERATIONS iterations)"

# -- Main Loop --
while ($iteration -lt $MAX_ITERATIONS) {
    $iteration++
    Write-Host ""
    Write-Host "-- Iteration $iteration/$MAX_ITERATIONS --" -ForegroundColor Cyan

    # -- CC1: Review --
    Write-Host "[CC1] Reviewing..." -ForegroundColor Yellow
    $reviewInput = Get-Content $REVIEW_PROMPT -Raw

    $prompt = @"
$reviewInput

Read all project files and apply your review.
"@

    claude -p $prompt --output-format text 2>$null | Set-Content -Path $FINDINGS_FILE

    # -- Parse convergence --
    $counts = Get-Counts $FINDINGS_FILE

    # -- No findings at all: halt --
    if ($null -eq $counts) {
        Write-Log "NO_OUTPUT" -1 -1 -1
        Run-Git add -A
        Run-Git commit -m "polish: iteration $iteration - NO OUTPUT" --allow-empty -q
        Send-Notify "[NO OUTPUT] Polish HALTED at iteration $iteration - CC1 produced no output. Check $FINDINGS_FILE"
        Write-Host ""
        Write-Host "========================================================"  -ForegroundColor Red
        Write-Host "  NO OUTPUT at iteration $iteration" -ForegroundColor Red
        Write-Host "  CC1 produced no findings file." -ForegroundColor Red
        Write-Host "========================================================"  -ForegroundColor Red
        exit 1
    }

    $critical = $counts.critical
    $major    = $counts.major
    $minor    = $counts.minor
    $total    = $critical + $major + $minor

    Write-Host "[CC1] Found: critical=$critical major=$major minor=$minor (total=$total)"

    # -- Check convergence --
    if ($critical -eq 0 -and $major -lt 3 -and $minor -lt 5) {
        Write-Log "CONVERGED" $critical $major $minor
        Run-Git add -A
        Run-Git commit -m "polish: iteration $iteration - CONVERGED" --allow-empty -q
        Send-Notify "[CONVERGED] Polish converged at iteration $iteration (critical:$critical major:$major minor:$minor)"
        Write-Host ""
        Write-Host "========================================================"  -ForegroundColor Green
        Write-Host "  CONVERGED at iteration $iteration" -ForegroundColor Green
        Write-Host "  Critical: $critical | Major: $major | Minor: $minor" -ForegroundColor Green
        Write-Host "========================================================"  -ForegroundColor Green
        exit 0
    }

    # -- Check stall --
    if ($total -ge $prevTotal) {
        $stallCount++
    } else {
        $stallCount = 0
    }

    if ($stallCount -ge $STALL_THRESHOLD) {
        Write-Log "STALLED" $critical $major $minor
        Run-Git add -A
        Run-Git commit -m "polish: iteration $iteration - STALLED" --allow-empty -q
        Send-Notify "[STALLED] Polish stalled at iteration $iteration - no improvement for $STALL_THRESHOLD passes (critical:$critical major:$major minor:$minor)"
        Write-Host ""
        Write-Host "========================================================"  -ForegroundColor Yellow
        Write-Host "  STALLED at iteration $iteration" -ForegroundColor Yellow
        Write-Host "  No improvement for $STALL_THRESHOLD consecutive passes" -ForegroundColor Yellow
        Write-Host "  Critical: $critical | Major: $major | Minor: $minor" -ForegroundColor Yellow
        Write-Host "  Review $FINDINGS_FILE for remaining issues" -ForegroundColor Yellow
        Write-Host "========================================================"  -ForegroundColor Yellow
        exit 1
    }

    $prevTotal = $total

    # -- CC2: Implement fixes --
    Write-Host "[CC2] Implementing fixes..." -ForegroundColor Yellow
    $findings = Get-Content $FINDINGS_FILE -Raw

    $commitMsg = "polish: iteration $iteration fixes"
    $coderPrompt = @"
You are an implementation agent. Apply every change from the review below to the project files. Be precise. Do not skip anything. After applying all changes, git add and commit with message: $commitMsg

--- REVIEW FINDINGS ---
$findings
"@

    claude -p $coderPrompt --output-format text 2>$null | Out-Null

    # -- Git commit backup --
    Run-Git add -A
    Run-Git commit -m "polish: iteration $iteration" --allow-empty -q

    Write-Log "CONTINUE" $critical $major $minor
    if ($VERBOSE_NOTIFY) {
        Send-Notify "[ITERATION $iteration] Complete - critical:$critical major:$major minor:$minor"
    }
    Write-Host "[OK] Iteration $iteration complete. Looping..." -ForegroundColor Green
}

# -- Max iterations reached --
Write-Log "MAX_ITERATIONS" $critical $major $minor
Send-Notify "[MAX ITERATIONS] Polish hit max iterations ($MAX_ITERATIONS). Review needed. (critical:$critical major:$major minor:$minor)"
Write-Host ""
Write-Host "========================================================"  -ForegroundColor Red
Write-Host "  MAX ITERATIONS ($MAX_ITERATIONS) reached" -ForegroundColor Red
Write-Host "  Critical: $critical | Major: $major | Minor: $minor" -ForegroundColor Red
Write-Host "  Review $FINDINGS_FILE for remaining issues" -ForegroundColor Red
Write-Host "========================================================"  -ForegroundColor Red
exit 1