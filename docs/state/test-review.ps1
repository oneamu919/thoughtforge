# Test - Read prompt file, send to CC1, output to results.md
# Usage: .\test-review.ps1
$output = Get-Content "review-prompt.md" -Raw -Encoding UTF8 | claude -p - --output-format text
$output | Set-Content -Path "results.md" -Encoding UTF8
#Write-Output $output
Write-Host "`nresults.md written ($((Get-Item 'results.md').Length) bytes)"