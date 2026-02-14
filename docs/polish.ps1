# ThoughtForge Polish Loop — Ralph-style two-agent loop (PowerShell)
# CC1 reviews → CC2 implements → repeat until converged
#
# Usage: .\polish.ps1                  (milestones only)
#        .\polish.ps1 -Verbose         (ping every iteration + retries)
# Stop:  Ctrl+C or wait for convergence / max iterations

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# ── Config ──────────────────────────────────────────────
$MAX_ITERATIONS   = 25
$STALL_THRESHOLD  = 3          # stop after N passes with no improvement
$TELEGRAM_TOKEN   = "7998768592:AAHxlbOZPm0b_Vf5ipuTu3BRr6LudeItIO8"
$TELEGRAM_CHAT_ID = "7897824652"
$VERBOSE_NOTIFY   = $Verbose.IsPresent
$REVIEW_PROMPT    = "project-plan-review-prompt.md"
$STATE_DIR        = "state"
$FINDINGS_FILE    = "$STATE_DIR\findings.md"
$LOG_FILE         = "$STATE_DIR\polish-log.jsonl"
$CONVERGENCE_FILE = "$STATE_DIR\convergence.json"

# ── Setup ───────────────────────────────────────────────
if (-not (Test-Path $STATE_DIR)) { New-Item -ItemType Directory -Path $STATE_DIR | Out-Null }

$iteration  = 0
$stallCount = 0
$prevTotal  = 999999

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

    # Extract JSON from ```json ... ``` block
    if ($content -match '(?s)```json\s*(\{[^}]+\})\s*```') {
        $jsonStr = $Matches[1]
        try {
            $parsed = $jsonStr | ConvertFrom-Json
            # Validate all three fields exist and are numbers
            if ($null -ne $parsed.critical -and $null -ne $parsed.major -and $null -ne $parsed.minor) {
                return @{
                    critical = [int]$parsed.critical
                    major    = [int]$parsed.major
                    minor    = [int]$parsed.minor
                }
            }
        } catch {}
    }

    # Fallback: try line-by-line regex (covers old format or slight variations)
    $c = $null; $m = $null; $n = $null
    foreach ($line in ($content -split "`n")) {
        if ($line -match '(?i)["\s]*critical["\s:]*(\d+)') { $c = [int]$Matches[1] }
        if ($line -match '(?i)["\s]*major["\s:]*(\d+)')    { $m = [int]$Matches[1] }
        if ($line -match '(?i)["\s]*minor["\s:]*(\d+)')    { $n = [int]$Matches[1] }
    }

    if ($null -ne $c -and $null -ne $m -and $null -ne $n) {
        return @{ critical = $c; major = $m; minor = $n }
    }

    return $null  # parse failed
}

# ── Preflight ───────────────────────────────────────────
if (-not (Test-Path $REVIEW_PROMPT)) {
    Write-Host "❌ Missing $REVIEW_PROMPT in project root" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Claude Code CLI not found" -ForegroundColor Red
    exit 1
}

$gitCheck = git rev-parse --is-inside-work-tree 2>$null
if ($gitCheck -ne "true") {
    Write-Host "❌ Not a git repo. Run: git init; git add -A; git commit -m 'baseline'" -ForegroundColor Red
    exit 1
}

Write-Host "════════════════════════════════════════════════════"
Write-Host "  ThoughtForge Polish Loop"
Write-Host "  Max iterations:   $MAX_ITERATIONS"
Write-Host "  Review prompt:    $REVIEW_PROMPT"
Write-Host "  Stall threshold:  $STALL_THRESHOLD consecutive passes"
Write-Host "════════════════════════════════════════════════════"
Send-Notify "🔄 Polish loop started (max $MAX_ITERATIONS iterations)"

# ── Main Loop ───────────────────────────────────────────
while ($iteration -lt $MAX_ITERATIONS) {
    $iteration++
    Write-Host ""
    Write-Host "── Iteration $iteration/$MAX_ITERATIONS ──────────────────────" -ForegroundColor Cyan

    # ── CC1: Review ──
    Write-Host "[CC1] Reviewing..." -ForegroundColor Yellow
    $reviewInput = Get-Content $REVIEW_PROMPT -Raw

    $convergenceBlock = @'
```json
{"critical": 0, "major": 0, "minor": 0}
```
'@
    $prompt = @"
$reviewInput

Read all project files and apply your review.

MANDATORY — at the very end of your response, output a JSON convergence block with your severity counts. Use this exact format (replace 0s with your actual counts):

$convergenceBlock

This block MUST appear at the end. Do NOT omit it. Do NOT change the format. The numbers must reflect your actual findings.
"@

    claude -p $prompt --output-format text 2>$null | Set-Content -Path $FINDINGS_FILE

    # ── Parse convergence ──
    $counts = Get-Counts $FINDINGS_FILE

    # ── Parse failure: retry once ──
    if ($null -eq $counts) {
        if ($VERBOSE_NOTIFY) { Send-Notify "⚠ Iteration $iteration — parse retry triggered. CC1 didn't output valid counts." }
        Write-Host "[CC1] ⚠ Parse failed. Retrying count extraction..." -ForegroundColor Yellow
        $retryPrompt = @"
Read the file state/findings.md which contains a review you just wrote. Count the findings by severity. Output ONLY this JSON block and nothing else:

$convergenceBlock

Replace the 0s with the actual counts of [Critical], [Major], and [Minor] findings in the review.
"@
        $retryResult = claude -p $retryPrompt --output-format text 2>$null
        $retryResult | Set-Content -Path "$STATE_DIR\counts-retry.txt"

        # Try to parse the retry
        if ($retryResult -match '(?s)\{.*?"critical".*?\}') {
            try {
                $parsed = ($Matches[0] | ConvertFrom-Json)
                if ($null -ne $parsed.critical -and $null -ne $parsed.major -and $null -ne $parsed.minor) {
                    $counts = @{
                        critical = [int]$parsed.critical
                        major    = [int]$parsed.major
                        minor    = [int]$parsed.minor
                    }
                }
            } catch {}
        }
    }

    # ── Still no counts: halt ──
    if ($null -eq $counts) {
        Write-Log "PARSE_FAILED" -1 -1 -1
        git add -A 2>$null
        git commit -m "polish: iteration $iteration - PARSE FAILED" --allow-empty -q 2>$null
        Send-Notify "❌ Polish HALTED at iteration $iteration — could not parse CC1 severity counts. Check $FINDINGS_FILE"
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  ❌ PARSE FAILED at iteration $iteration" -ForegroundColor Red
        Write-Host "  CC1 output did not contain parseable counts." -ForegroundColor Red
        Write-Host "  Check $FINDINGS_FILE and retry manually." -ForegroundColor Red
        Write-Host "════════════════════════════════════════════════════" -ForegroundColor Red
        exit 1
    }

    $critical = $counts.critical
    $major    = $counts.major
    $minor    = $counts.minor
    $total    = $critical + $major + $minor

    Write-Host "[CC1] Found: critical=$critical major=$major minor=$minor (total=$total)"

    # ── Check convergence ──
    if ($critical -eq 0 -and $major -lt 3 -and $minor -lt 5) {
        Write-Log "CONVERGED" $critical $major $minor
        git add -A 2>$null
        git commit -m "polish: iteration $iteration - CONVERGED" --allow-empty -q 2>$null
        Send-Notify "✅ Polish CONVERGED at iteration $iteration (critical:$critical major:$major minor:$minor)"
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host "  ✅ CONVERGED at iteration $iteration" -ForegroundColor Green
        Write-Host "  Critical: $critical | Major: $major | Minor: $minor" -ForegroundColor Green
        Write-Host "════════════════════════════════════════════════════" -ForegroundColor Green
        exit 0
    }

    # ── Check stall ──
    if ($total -ge $prevTotal) {
        $stallCount++
    } else {
        $stallCount = 0
    }

    if ($stallCount -ge $STALL_THRESHOLD) {
        Write-Log "STALLED" $critical $major $minor
        git add -A 2>$null
        git commit -m "polish: iteration $iteration - STALLED" --allow-empty -q 2>$null
        Send-Notify "⚠️ Polish STALLED at iteration $iteration - no improvement for $STALL_THRESHOLD passes (critical:$critical major:$major minor:$minor)"
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "  ⚠️ STALLED at iteration $iteration" -ForegroundColor Yellow
        Write-Host "  No improvement for $STALL_THRESHOLD consecutive passes" -ForegroundColor Yellow
        Write-Host "  Critical: $critical | Major: $major | Minor: $minor" -ForegroundColor Yellow
        Write-Host "  Review $FINDINGS_FILE for remaining issues" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════" -ForegroundColor Yellow
        exit 1
    }

    $prevTotal = $total

    # ── CC2: Implement fixes ──
    Write-Host "[CC2] Implementing fixes..." -ForegroundColor Yellow
    $findings = Get-Content $FINDINGS_FILE -Raw

    $commitMsg = "polish: iteration $iteration fixes"
    $coderPrompt = @"
You are an implementation agent. Apply every change from the review below to the project files. Be precise. Do not skip anything. After applying all changes, git add and commit with message "$commitMsg".

--- REVIEW FINDINGS ---
$findings
"@

    claude -p $coderPrompt --output-format text 2>$null | Out-Null

    # ── Git commit (backup in case CC2 didn't) ──
    git add -A 2>$null
    git commit -m "polish: iteration $iteration" --allow-empty -q 2>$null

    Write-Log "CONTINUE" $critical $major $minor
    if ($VERBOSE_NOTIFY) { Send-Notify "🔁 Iteration $iteration complete — critical:$critical major:$major minor:$minor" }
    Write-Host "[OK] Iteration $iteration complete. Looping..." -ForegroundColor Green
}

# ── Max iterations reached ──
Write-Log "MAX_ITERATIONS" $critical $major $minor
Send-Notify "⏰ Polish hit max iterations ($MAX_ITERATIONS). Review needed. (critical:$critical major:$major minor:$minor)"
Write-Host ""
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host "  ⏰ MAX ITERATIONS ($MAX_ITERATIONS) reached" -ForegroundColor Red
Write-Host "  Critical: $critical | Major: $major | Minor: $minor" -ForegroundColor Red
Write-Host "  Review $FINDINGS_FILE for remaining issues" -ForegroundColor Red
Write-Host "════════════════════════════════════════════════════" -ForegroundColor Red
exit 1
