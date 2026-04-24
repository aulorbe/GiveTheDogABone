#!/bin/bash
# Run Give The Dog a Bone menu bar app
# Make sure environment is set
source ~/.notion_menu_bar_config

# Kill any existing instances
pkill -f "NotionMenuBarTracker/.build/release" 2>/dev/null

# Run in background
cd "$(dirname "$0")"
./.build/release/NotionMenuBarTracker > /tmp/notion-dog-bone.log 2>&1 &

echo "✅ App started!"
echo "Logs: tail -f /tmp/notion-dog-bone.log"
