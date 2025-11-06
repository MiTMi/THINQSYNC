# AI Features Guide - ThinqSync

## Overview
ThinqSync now includes AI-powered text processing features using the Deepseek R1 API. This integration allows you to enhance, summarize, expand, and fix text directly within your notes using simple slash commands.

## Setup

### 1. Get Your Deepseek API Key
- Visit [Deepseek's website](https://www.deepseek.com) to create an account and obtain your API key
- Keep your API key secure

### 2. Configure the API Key
You can configure your API key in two ways:

**Option 1: Via Menubar**
1. Click the ThinqSync icon in your menubar
2. Select "AI Settings"
3. Enter your Deepseek API key
4. Click "Save"

**Option 2: Via Note Window**
1. Open any note
2. Click the three-dot menu (•••) in the title bar
3. Select "AI Settings"
4. Enter your Deepseek API key
5. Click "Save"

## Available AI Features

### 1. AI: Improve Writing
**Slash command:** `/ai improve` or `/ai`
- Enhances clarity, style, and flow of your text
- Maintains original meaning and tone
- Perfect for polishing drafts

### 2. AI: Summarize
**Slash command:** `/ai summ`
- Creates concise summaries of your text
- Captures key points
- Ideal for long notes or meeting notes

### 3. AI: Expand
**Slash command:** `/ai exp`
- Adds more detail and context to brief text
- Elaborates on ideas
- Great for developing initial thoughts

### 4. AI: Fix Grammar
**Slash command:** `/ai fix` or `/ai gram`
- Corrects grammatical errors
- Fixes spelling mistakes
- Improves punctuation
- Preserves original meaning and style

## How to Use

### Basic Usage
1. In any note, type `/` to open the slash command menu
2. Start typing an AI command (e.g., "ai improve")
3. Select the desired AI feature from the menu
4. The AI will process your text and replace it with the result

### With Selected Text
1. Select the text you want to process
2. Type `/` and choose an AI command
3. Only the selected text will be processed

### With All Text
1. Don't select any text
2. Type `/` and choose an AI command
3. All text in the note will be processed

## Features

### Visual Feedback
- **Processing Indicator:** A progress spinner appears at the bottom of the note window while AI is processing
- **Error Alerts:** Clear error messages if something goes wrong (e.g., no API key, network issues)
- **Status Indicator:** The AI Settings window shows whether AI features are enabled or disabled

### Security
- API keys are stored securely in UserDefaults
- Sensitive information is displayed in a SecureField
- Easy to clear/remove API key anytime

## Architecture

### Files Created
1. **DeepseekAIService.swift** - Service class handling all API communication
   - Located: `thinqsync/Services/`
   - Manages API key storage
   - Handles all four AI operations
   - Provides error handling

2. **AISettingsView.swift** - Settings interface for API key configuration
   - Located: `thinqsync/Views/`
   - Clean, modern UI
   - Shows feature list
   - Status indicators

### Files Modified
1. **SlashCommandMenu.swift** - Added 4 new AI commands to the enum
2. **RichTextEditorWithSlashMenu.swift** - Added AI command execution logic
3. **NoteWindow.swift** - Added AI Settings option to three-dot menu
4. **GettingStartedView.swift** - Changed Settings button to open AI Settings

## API Details

### Deepseek API Configuration
- **Endpoint:** `https://api.deepseek.com/v1/chat/completions`
- **Model:** `deepseek-chat`
- **Temperature:** 0.7
- **Max Tokens:** 2000

### Error Handling
The service handles various error conditions:
- No API key configured
- Empty text selection
- Network errors
- Invalid API responses
- API-specific errors with detailed messages

## Tips

1. **API Key Security:** Never share your API key or commit it to version control
2. **Text Selection:** Select text for targeted processing, or leave unselected to process entire note
3. **Undo:** Use Cmd+Z if you don't like the AI result
4. **Multiple Operations:** You can chain multiple AI operations (e.g., expand then improve)
5. **Network:** AI features require an active internet connection

## Troubleshooting

### "No API key configured"
- Go to AI Settings and enter your Deepseek API key
- Make sure to click "Save"

### "Invalid response from AI service"
- Check your internet connection
- Verify your API key is correct
- Try again in a few moments

### AI is slow
- Processing time depends on text length and API response time
- Longer texts take more time to process
- The progress indicator shows processing is active

### Menu not showing AI commands
- Make sure you're typing `/` in a note window
- Try typing more of the command (e.g., "ai im" for improve)
- Commands are searchable by title and description

## Development Notes

### Testing AI Integration
1. Configure a valid Deepseek API key
2. Create a test note with sample text
3. Try each AI command:
   - `/ai improve` - Test with poorly written text
   - `/ai summ` - Test with a long paragraph
   - `/ai exp` - Test with a brief sentence
   - `/ai fix` - Test with text containing errors

### Future Enhancements
Potential improvements for future versions:
- Custom AI prompts
- Multiple AI provider support (OpenAI, Anthropic, etc.)
- AI-powered note organization
- Smart tagging and categorization
- Note templates with AI assistance
- Keyboard shortcuts for AI commands
- AI command history
- Batch processing multiple notes

## Technical Implementation

### State Management
- Uses `@StateObject` for AI service singleton
- `@Published` properties for real-time UI updates
- Async/await for API calls

### UI/UX Patterns
- Non-blocking UI during processing
- Clear visual feedback
- Graceful error handling
- Consistent with app's design language

### Code Quality
- Proper error handling with custom error types
- Type-safe API operations
- Clean separation of concerns
- Well-documented code

---

**Built with:** Swift, SwiftUI, AppKit
**AI Provider:** Deepseek R1
**Version:** 1.0
**Date:** November 2025
