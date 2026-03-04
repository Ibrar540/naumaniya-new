# Test AI Backend Connection - Quick Guide

## Quick Test Steps

### Step 1: Run Flutter App with Console
```bash
cd your_project_directory
flutter run -d windows
```

### Step 2: Open AI Assistant
1. Launch the app
2. Navigate to AI Assistant screen
3. Keep console window visible

### Step 3: Send Test Query
Type in chat: `Total income of masjid in 2025`

### Step 4: Check Console Output

#### ✅ Success Output
```
🔵 AI Backend Request:
   URL: https://naumaniya-new.vercel.app/ai-query
   Message: Total income of masjid in 2025
   Language: English
🟢 AI Backend Response:
   Status Code: 200
   Headers: {content-type: application/json, ...}
   Body Length: 245 bytes
✅ JSON parsed successfully
   Success: true
   Intent: total
   Module: masjid
   Type: income
✅ Response formatted successfully
```

**Result**: You should see the financial data in the chat

#### ❌ Network Error
```
🔵 AI Backend Request:
   URL: https://naumaniya-new.vercel.app/ai-query
   Message: Total income of masjid in 2025
   Language: English
❌ HTTP Client Exception: SocketException: Failed host lookup
```

**Fix**: Check internet connection

#### ❌ Timeout Error
```
🔵 AI Backend Request:
   URL: https://naumaniya-new.vercel.app/ai-query
   Message: Total income of masjid in 2025
   Language: English
❌ Request timeout after 30 seconds
```

**Fix**: Wait 1 minute and try again (Vercel cold start)

#### ❌ 404 Error
```
🟢 AI Backend Response:
   Status Code: 404
❌ Endpoint not found (404)
```

**Fix**: Verify backend URL is correct

#### ❌ 500 Error
```
🟢 AI Backend Response:
   Status Code: 500
❌ Server error (500)
```

**Fix**: Check Vercel logs, verify DATABASE_URL is set

## Test Queries

### English Queries
```
Total income of masjid in 2025
Madrasa expenditure 2024
Financial summary of masjid 2025
Net balance of masjid in 2025
Compare income of 2024 and 2025
```

### Urdu Queries
```
مسجد کی کل آمدنی 2025
مدرسہ کا خرچ 2024
مسجد کا خلاصہ 2025
```

## Verify Backend Directly

### PowerShell Test
```powershell
$body = @{
    message = "Total income of masjid in 2025"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://naumaniya-new.vercel.app/ai-query" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

Expected output:
```json
{
  "success": true,
  "intent": "total",
  "module": "masjid",
  "type": "income",
  "year": 2025,
  "result": 150000,
  "message": "Total Income of Masjid in 2025 is 150,000 PKR."
}
```

### curl Test
```bash
curl -X POST https://naumaniya-new.vercel.app/ai-query \
  -H "Content-Type: application/json" \
  -d '{"message":"Total income of masjid in 2025"}'
```

## Troubleshooting Checklist

- [ ] Internet connection working?
- [ ] Backend URL correct: `https://naumaniya-new.vercel.app/ai-query`
- [ ] Backend responds to PowerShell/curl test?
- [ ] Firewall not blocking Flutter app?
- [ ] Console shows debug logs?
- [ ] Status code is 200?
- [ ] JSON parsing successful?

## Common Issues

### Issue: Always shows "Could not connect"
**Before Fix**: Generic error, no details
**After Fix**: Specific error with details in console

**Action**: Check console logs for actual error

### Issue: Works in PowerShell, not in Flutter
**Cause**: HTTP client configuration or certificate issue
**Action**: Check console for specific error

### Issue: First request fails, second works
**Cause**: Vercel cold start (normal behavior)
**Action**: Wait 1 minute after first failure, try again

### Issue: Timeout on every request
**Cause**: Network too slow or backend issue
**Action**: 
1. Test internet speed
2. Check Vercel status
3. Increase timeout if needed

## Success Indicators

✅ Console shows "🟢 AI Backend Response"
✅ Status code is 200
✅ "✅ JSON parsed successfully" appears
✅ "✅ Response formatted successfully" appears
✅ Chat shows formatted financial data
✅ No error messages in console

## Next Steps After Success

1. Test with different queries
2. Test in Urdu
3. Test error cases (invalid queries)
4. Test with no internet (should show network error)
5. Monitor performance over time

## Need Help?

If still having issues after following this guide:

1. Copy full console output
2. Copy exact error message from chat
3. Verify backend works with PowerShell test
4. Check Vercel deployment logs
5. Verify DATABASE_URL environment variable is set

## Status
✅ Enhanced error handling implemented
✅ Debug logging added
✅ Ready for testing
