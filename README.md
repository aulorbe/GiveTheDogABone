# Give The Dog a Bone 🐕🦴

A fun, adorable macOS menu bar app that shows your Notion todo progress. Your goal: give the dog its bone! As you tick things off your todo list, the bone gets closer to the pup. Complete everything and see 🎉!

## Features

- 🐕 **Give The Dog a Bone**: Watch the bone (🦴) get closer to the dog (🐕) as you complete tasks
- 🎉 **Celebration**: When all done, the menu bar shows 🎉
- 🔄 **Auto-refresh**: Polls Notion every 5 seconds to stay up-to-date
- 📊 **Live Counter**: Shows completed/total tasks (e.g., "3/7")
- 🎨 **Always Visible**: Lives in your menu bar so you always see your progress
- 🖱️ **Click to Refresh**: Click the menu bar for instant refresh (⌘R) or to quit (⌘Q)
- 🚀 **Auto-start**: Can automatically start when you log in
- 🛡️ **Stable**: Handles API errors gracefully, keeps last good value

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

### 6. Set Up Auto-Start (Optional)

To make the app start automatically when you log in, create a LaunchAgent:

```bash
# The app needs your environment variables to be set in your shell config first
# Then add to Login Items via System Settings > General > Login Items
# Or use launchd (see launchd documentation)
```

## Testing

Run the test script:

```bash
source ~/.notion_menu_bar_config  # Load your credentials
./test.sh
```

## Development

- Logs are written to `/tmp/notion-dog-bone.log` for debugging
- 5-second polling interval (configurable in `NotionConfig`)
- Gracefully handles Notion API rate limiting and errors

## Database Requirements

Your Notion database should have:
- Multiple pages/items (these are your todos)
- A checkbox property (any name works - the app looks for checkbox properties)

## How It Works

The menu bar shows your progress in giving the dog its bone:
- **Start**: 🐕━━━━━🦴 (many tasks remaining - bone is far away!)
- **Progress**: 🐕━━🦴 (you're getting closer to giving the dog its bone!)
- **Complete**: 🐕🦴 (all done - you gave the dog its bone! 🎆)

Each dash (━) represents an uncompleted task. As you check off todos, you're giving the dog its bone - the dashes disappear and the bone gets closer!

Example: `🐕━━━🦴 3/7` means 3 completed, 4 remaining (4 more tasks until the dog gets its bone!)

## Customization

Edit `Sources/main.swift` to customize:
- `updateIntervalSeconds`: How often to poll Notion (default: 5 seconds)
- `generateColorfulProgressBar()`: Change the dog/bone to other emojis
- Try different characters for the body segments (━, ─, ~, etc.)

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
