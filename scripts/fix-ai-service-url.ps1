# Fix AI Chat Service URL
$filePath = "lib/services/ai_chat_service.dart"
$content = Get-Content $filePath -Raw

# Replace localhost with Vercel URL
$content = $content -replace "http://localhost:3000/ai-query", "https://naumaniya-new.vercel.app/ai-query"

# Save the file
$content | Set-Content $filePath -NoNewline

Write-Host "✅ Fixed backend URL in $filePath"
Write-Host "Changed: http://localhost:3000/ai-query"
Write-Host "To: https://naumaniya-new.vercel.app/ai-query"
