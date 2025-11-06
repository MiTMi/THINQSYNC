# OpenRouter Setup Guide for ThinqSync

## Quick Start

Your ThinqSync app is now configured to work with OpenRouter, which provides access to Deepseek R1 and other AI models.

## Setup Steps

### 1. Get Your OpenRouter API Key
1. Go to [openrouter.ai](https://openrouter.ai)
2. Sign up or log in
3. Navigate to "Keys" section
4. Create a new API key
5. Copy the key (starts with `sk-or-v1-...`)

### 2. Configure in ThinqSync

**Option A: Via Menubar**
1. Click ThinqSync menubar icon
2. Click "AI Settings"
3. Paste your OpenRouter API key
4. Select a model from the dropdown (default: `deepseek/deepseek-r1`)
5. Click "Save"

**Option B: Via Note Window**
1. Open any note
2. Click the three-dot menu (•••)
3. Select "AI Settings"
4. Paste your OpenRouter API key
5. Select a model
6. Click "Save"

## Available Models

ThinqSync supports these Deepseek models on OpenRouter:

1. **deepseek/deepseek-r1** (Default)
   - Latest Deepseek R1 model
   - Best for general text processing
   - Recommended choice

2. **deepseek/deepseek-chat**
   - Optimized for conversational tasks
   - Good for improving writing

3. **deepseek/deepseek-coder**
   - Specialized for code
   - Best if you're writing technical notes

4. **deepseek/deepseek-r1:free**
   - Free tier version
   - May have rate limits
   - Good for testing

### Which Model to Choose?

- **For most users:** Start with `deepseek/deepseek-r1`
- **If you get errors:** Try `deepseek/deepseek-r1:free`
- **For code notes:** Use `deepseek/deepseek-coder`
- **Budget conscious:** Use models with `:free` suffix

## Using AI Features

Once configured, use AI in any note:

1. Type `/` to open slash menu
2. Type `ai` to see AI commands:
   - **AI: Improve Writing** - Enhance clarity and style
   - **AI: Summarize** - Create concise summary
   - **AI: Expand** - Add detail and context
   - **AI: Fix Grammar** - Correct errors

### Tips

- **Select text** to process only that portion
- **No selection** processes the entire note
- **Processing takes 2-10 seconds** depending on text length
- **Use Cmd+Z** if you don't like the result

## Troubleshooting

### "Invalid API Key" or "API Error"

**Check these:**
1. ✅ API key is correctly copied (no spaces)
2. ✅ API key starts with `sk-or-v1-`
3. ✅ You have credits in your OpenRouter account
4. ✅ Internet connection is working

**Try:**
- Re-copy the API key from OpenRouter
- Try a different model (use the dropdown)
- Check OpenRouter dashboard for account status

### "Model Not Found" Error

**Solution:**
1. Open AI Settings
2. Try a different model from the dropdown
3. Models change on OpenRouter - try:
   - `deepseek/deepseek-r1:free` (most likely to work)
   - `deepseek/deepseek-chat`

### Slow Response

**Normal behavior:**
- First request: 5-10 seconds
- Longer text: up to 15 seconds
- Progress spinner shows it's working

**If extremely slow:**
- Check OpenRouter status
- Try `:free` version of model
- Check your internet speed

### Rate Limit Errors

**If you see rate limit messages:**
1. Wait a few minutes
2. Check OpenRouter usage limits
3. Consider upgrading OpenRouter plan
4. Use `:free` models for lower limits

## OpenRouter vs Direct Deepseek

**Why OpenRouter?**
- ✅ Single API for multiple AI models
- ✅ Often more reliable
- ✅ Better rate limits
- ✅ Pay-as-you-go pricing
- ✅ Free tier available

**Differences:**
- Endpoint: `openrouter.ai` instead of `api.deepseek.com`
- Model names: `deepseek/deepseek-r1` format
- Additional headers required (already configured)

## Pricing

OpenRouter pricing for Deepseek models (as of Nov 2025):

- **Free tier models** (`:free` suffix): Free with rate limits
- **Paid models**: ~$0.14 per 1M input tokens
- **Your costs**: Depends on usage
  - Typical note (~500 words): $0.0001-0.001
  - Heavy usage (100 notes/day): ~$0.10-1.00/day

Check current pricing at [openrouter.ai/docs/pricing](https://openrouter.ai/docs/pricing)

## Security

- ✅ API keys stored locally in UserDefaults
- ✅ Keys never logged or exposed
- ✅ Secure text field in settings
- ✅ HTTPS for all API calls
- ⚠️ Don't share your API key
- ⚠️ Don't commit keys to Git

## Testing Your Setup

1. **Open AI Settings** - Status should show "AI features enabled"
2. **Create a test note** with text like: "This is a test note with some text"
3. **Type /** and select "AI: Improve Writing"
4. **Wait for result** - should see improved text
5. **Success!** - You're all set

If it works, you're ready to use AI in all your notes!

## Support

### Check Model Availability
Visit [openrouter.ai/models](https://openrouter.ai/models) to see:
- Currently available Deepseek models
- Pricing for each model
- Model capabilities

### OpenRouter Documentation
- [OpenRouter Docs](https://openrouter.ai/docs)
- [API Reference](https://openrouter.ai/docs/api-reference)
- [Model List](https://openrouter.ai/models)

### Common Issues

**Problem:** "No API key configured"
**Solution:** Go to AI Settings and enter your OpenRouter key

**Problem:** API call fails immediately
**Solution:** Check API key format - should start with `sk-or-v1-`

**Problem:** Works sometimes, fails other times
**Solution:** OpenRouter rate limits - wait a moment and retry

**Problem:** Wrong model name
**Solution:** Use model picker in settings to try different models

## Advanced Configuration

The AI service is located in:
```
thinqsync/Services/DeepseekAIService.swift
```

### Current Settings
- **Endpoint:** `https://openrouter.ai/api/v1/chat/completions`
- **Temperature:** 0.7 (creativity level)
- **Max Tokens:** 2000 (max response length)
- **Headers:** HTTP-Referer and X-Title (required by OpenRouter)

### Model List
Edit available models in `DeepseekAIService.swift`:
```swift
static let availableModels = [
    "deepseek/deepseek-r1",
    "deepseek/deepseek-chat",
    "deepseek/deepseek-coder",
    "deepseek/deepseek-r1:free"
]
```

Add more models from OpenRouter's model list as needed.

---

**Questions?** Check the main AI_FEATURES_GUIDE.md for more details about AI features.
