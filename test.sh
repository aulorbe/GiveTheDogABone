#!/bin/bash
# Basic functionality tests for Give The Dog a Bone

set -e

echo "🧪 Testing Give The Dog a Bone..."
echo ""

# Test 1: Can we build?
echo "Test 1: Building..."
swift build -c release > /dev/null 2>&1
echo "✅ Build succeeds"

# Test 2: Check environment variables
echo "Test 2: Checking environment..."
if [ -z "$NOTION_API_KEY" ]; then
    echo "⚠️  NOTION_API_KEY not set"
else
    echo "✅ NOTION_API_KEY is set"
fi

if [ -z "$NOTION_DATABASE_ID" ]; then
    echo "⚠️  NOTION_DATABASE_ID not set"
else
    echo "✅ NOTION_DATABASE_ID is set"
fi

# Test 3: Can the binary run?
echo "Test 3: Checking binary..."
if [ -f ".build/release/NotionMenuBarTracker" ]; then
    echo "✅ Binary exists"
else
    echo "❌ Binary not found"
    exit 1
fi

# Test 4: Test Notion API connection (if credentials exist)
if [ -n "$NOTION_API_KEY" ] && [ -n "$NOTION_DATABASE_ID" ]; then
    echo "Test 4: Testing Notion API..."
    RESPONSE=$(curl -s -X POST "https://api.notion.com/v1/databases/$NOTION_DATABASE_ID/query" \
      -H "Authorization: Bearer $NOTION_API_KEY" \
      -H "Notion-Version: 2022-06-28" \
      -H "Content-Type: application/json")

    if echo "$RESPONSE" | jq -e '.results' > /dev/null 2>&1; then
        TASK_COUNT=$(echo "$RESPONSE" | jq '.results | length')
        echo "✅ Notion API works ($TASK_COUNT tasks found)"
    else
        echo "❌ Notion API error"
        echo "$RESPONSE" | jq '.'
        exit 1
    fi
fi

echo ""
echo "🎉 All tests passed!"
