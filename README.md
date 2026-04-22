# Notion Menu Bar Tracker 🌈

A fun, colorful macOS menu bar app that shows your Notion todo progress with a rainbow progress bar!

## Features

- 🌈 **Colorful Progress Bar**: Visual rainbow bar that fills up as you complete tasks
- 🔄 **Auto-refresh**: Polls Notion every 60 seconds to stay up-to-date
- 📊 **Live Counter**: Shows completed/total tasks (e.g., "7/10")
- 🎨 **Always Visible**: Lives in your menu bar so you always see your progress

## Setup

### 1. Create a Notion Integration

1. Go to https://www.notion.so/my-integrations
2. Click "New integration"
3. Give it a name (e.g., "Menu Bar Tracker")
4. Copy the "Internal Integration Token" (starts with `secret_`)

### 2. Share Your Database with the Integration

1. Open your Notion todo database
2. Click the "..." menu in the top right
3. Click "Add connections"
4. Select your integration

### 3. Get Your Database ID

Your database ID is in the URL when viewing the database:
```
https://notion.so/workspace/DATABASE_ID?v=...
```

### 4. Set Environment Variables

Create a file at `~/.notion_menu_bar_config`:

```bash
export NOTION_API_KEY="secret_your_integration_token_here"
export NOTION_DATABASE_ID="your_database_id_here"
```

Then source it in your shell config (~/.zshrc or ~/.bashrc):

```bash
# Notion Menu Bar Tracker
[ -f ~/.notion_menu_bar_config ] && source ~/.notion_menu_bar_config
```

### 5. Build and Run

```bash
cd ~/Desktop/scripts/NotionMenuBarTracker
swift build -c release
./.build/release/NotionMenuBarTracker
```

## Database Requirements

Your Notion database should have:
- Multiple pages/items (these are your todos)
- A checkbox property (any name works - the app looks for checkbox properties)

## Customization

Edit `Sources/main.swift` to customize:
- `updateIntervalSeconds`: How often to poll Notion (default: 60 seconds)
- `generateColorfulProgressBar()`: Change the progress bar appearance
- Colors: Modify the `colors` array for different rainbow patterns

## How It Works

The progress bar shows:
- 🟥🟧🟨🟩🟦🟪 = Filled blocks (completed tasks) with rainbow gradient
- ⬜ = Empty blocks (remaining tasks)

Example: `🟥🟧🟨🟩🟦🟪🟪⬜⬜⬜ 7/10` means 7 out of 10 tasks done!

## Troubleshooting

**"❌ Error" appears in menu bar:**
- Check your NOTION_API_KEY is correct
- Verify your NOTION_DATABASE_ID is correct
- Make sure the integration has access to the database
- Check Console.app for detailed error messages

**No progress shown (0/0):**
- The database might be empty
- The integration might not have permission to read the database

## License

MIT - Do whatever you want with it!
