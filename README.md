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

Build:
```bash
cd ~/Desktop/scripts/NotionMenuBarTracker
swift build -c release
```

Run with the helper script:
```bash
./run.sh
```

Or manually:
```bash
source ~/.notion_menu_bar_config
./.build/release/NotionMenuBarTracker &
```

### 6. Set Up Auto-Start (Optional)

Create a LaunchAgent that runs at login:

```bash
cat > ~/Library/LaunchAgents/com.notion.menubar.tracker.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.notion.menubar.tracker</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/Desktop/scripts/NotionMenuBarTracker/.build/release/NotionMenuBarTracker</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>NOTION_API_KEY</key>
        <string>YOUR_API_KEY_HERE</string>
        <key>NOTION_DATABASE_ID</key>
        <string>YOUR_DATABASE_ID_HERE</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/notion-dog-bone-out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/notion-dog-bone-err.log</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.notion.menubar.tracker.plist
```

Replace `YOUR_USERNAME`, `YOUR_API_KEY_HERE`, and `YOUR_DATABASE_ID_HERE` with your values.

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

**App isn't showing in menu bar:**
- The app is likely running (check logs with `tail -f /tmp/notion-dog-bone.log`)
- Menu bar display is a known macOS limitation with simple executables
- Verify it's working by checking the logs - you should see updates every 5 seconds

**API errors in logs:**
- Check your NOTION_API_KEY is correct
- Verify your NOTION_DATABASE_ID is correct
- Make sure the integration has access to the database
- Notion may rate-limit - app handles this gracefully by keeping the last good value

**No progress shown (0/0):**
- The database might be empty
- The integration might not have permission to read the database
- Check logs for API errors

## License

MIT - Do whatever you want with it!
