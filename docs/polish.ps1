# Run CC1 review, save results, notify via Telegram
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

Send-Notify "[STARTED] Review running..."

$prompt = Get-Content "project-plan-review-prompt.md" -Raw
$prompt += "`n`nRead all project files and apply your review."
claude -p $prompt --output-format text | Set-Content -Path "results.md"

$size = (Get-Item "results.md").Length
Send-Notify "[DONE] Review complete. results.md written ($size bytes)"