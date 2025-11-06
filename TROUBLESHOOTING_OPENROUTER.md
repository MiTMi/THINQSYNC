# Troubleshooting OpenRouter API Errors

## "Provider returned error" - What to Try

This error usually means one of these issues:

### 1. Wrong Model Name ⚠️
**Try this first!**

1. Open AI Settings
2. Change model to **`deepseek/deepseek-chat`** (most stable)
3. Or try **`deepseek/deepseek-r1:free`** (free tier)
4. Click Save
5. Try again

The default model might not be available on your OpenRouter account.

### 2. Check API Key Format

Your OpenRouter API key should:
- ✅ Start with `sk-or-v1-`
- ✅ Be about 80-100 characters long
- ✅ Have no spaces before/after

**How to check:**
1. Go to [openrouter.ai/keys](https://openrouter.ai/keys)
2. Copy the key again (click the copy button)
3. Paste into AI Settings
4. Make sure no extra characters

### 3. Check OpenRouter Credits

1. Visit [openrouter.ai/credits](https://openrouter.ai/credits)
2. Make sure you have credits/balance
3. Free tier users: check if you hit rate limits

### 4. View Detailed Error in Console

**To see exactly what's wrong:**

1. Open your app in Xcode
2. Run the app (Cmd+R)
3. Try using an AI command
4. Check the Xcode console output

Look for lines like:
```
🔵 OpenRouter Request:
   Model: deepseek/deepseek-chat
   ...
❌ OpenRouter Error Response: { ... }
```

This will show the **exact error** from OpenRouter.

## Common Error Messages & Solutions

### "Model not found" or "Invalid model"

**Solution:** The model name is wrong or not available.

**Try these models in this order:**
1. `deepseek/deepseek-chat` ← Try this first
2. `deepseek/deepseek-r1:free`
3. `deepseek/deepseek-chat:free`

### "Insufficient credits" or "Payment required"

**Solution:** Add credits to your OpenRouter account
- Go to openrouter.ai/credits
- Add payment method or use free tier models (`:free` suffix)

### "Rate limit exceeded"

**Solution:** You're making requests too fast
- Wait 60 seconds and try again
- Use `:free` models if on free tier
- Check your rate limits on OpenRouter dashboard

### "Unauthorized" or "Invalid API key"

**Solution:** API key problem
1. Re-copy your API key from openrouter.ai/keys
2. Make sure it starts with `sk-or-v1-`
3. Delete and re-enter it in AI Settings

### "Model not supported" for your account

**Solution:** Model requires paid plan
- Try models with `:free` suffix
- Or upgrade your OpenRouter plan
- Check which models are available at openrouter.ai/models

## How to Check Console Logs

### Method 1: Run from Xcode
1. Open `thinqsync.xcodeproj` in Xcode
2. Click Run button (▶️) or press Cmd+R
3. Try using AI in a note
4. Look at bottom console panel for error messages

### Method 2: Console.app
1. Open Console.app (in /Applications/Utilities/)
2. Run ThinqSync
3. Search for "OpenRouter" in Console
4. Try AI command
5. See error details

## Model Recommendations

### Best for Most Users
```
deepseek/deepseek-chat
```
- Most stable and reliable
- Good for all text tasks
- Usually works first try

### Best for Free Tier
```
deepseek/deepseek-r1:free
```
- Free to use
- May have rate limits
- Good for testing

### Best for Code
```
deepseek/deepseek-coder
```
- Optimized for programming
- Good if writing code in notes

## Still Not Working?

### Check OpenRouter Status
1. Visit [status.openrouter.ai](https://status.openrouter.ai) or [openrouter.ai](https://openrouter.ai)
2. Check if there are any outages

### Verify Model Availability
1. Go to [openrouter.ai/models](https://openrouter.ai/models)
2. Search for "deepseek"
3. Check which models are currently active
4. Use exact model name from their list

### Test with Curl (Advanced)

Test your API key directly:

```bash
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY_HERE" \
  -d '{
    "model": "deepseek/deepseek-chat",
    "messages": [
      {"role": "user", "content": "Hello"}
    ]
  }'
```

Replace `YOUR_API_KEY_HERE` with your actual key.

**Expected result:** Should return a JSON response with AI's answer.

**If it fails:** The problem is with your OpenRouter setup, not ThinqSync.

## Error Code Reference

| Code | Meaning | Solution |
|------|---------|----------|
| 400 | Bad Request | Wrong model name or invalid parameters |
| 401 | Unauthorized | Invalid API key |
| 402 | Payment Required | Need to add credits |
| 404 | Not Found | Model doesn't exist |
| 429 | Rate Limited | Wait and try again |
| 500 | Server Error | OpenRouter is having issues |

## Quick Fixes Checklist

- [ ] Try `deepseek/deepseek-chat` model
- [ ] Verify API key starts with `sk-or-v1-`
- [ ] Check you have OpenRouter credits
- [ ] Wait 60 seconds if rate limited
- [ ] Check console logs for detailed error
- [ ] Try `:free` models
- [ ] Verify model exists on openrouter.ai/models
- [ ] Test API key with curl command

## Getting Help

If still stuck:

1. **Check Console Logs** - The error details are there
2. **OpenRouter Discord** - They have a support Discord
3. **OpenRouter Docs** - [openrouter.ai/docs](https://openrouter.ai/docs)

## Contact Info

- OpenRouter Support: Check their website for Discord link
- OpenRouter Docs: https://openrouter.ai/docs
- Model List: https://openrouter.ai/models
- API Status: Check their homepage

---

**Remember:** The console logs show the exact error. Always check those first!
