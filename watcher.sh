#!/bin/bash
# GitHub Task Watcher — polls polypal-tasks repo for new tasks
# and sends them to Discord via the bridge server
#
# Install on Hostinger VPS:
#   1. Save this file to /docker/openclaw-hjh3/data/discord-bridge/watcher.sh
#   2. chmod +x /docker/openclaw-hjh3/data/discord-bridge/watcher.sh
#   3. Run: nohup /docker/openclaw-hjh3/data/discord-bridge/watcher.sh > /docker/openclaw-hjh3/data/discord-bridge/watcher.log 2>&1 &

REPO_DIR="/docker/openclaw-hjh3/data/polypal-tasks"
BRIDGE_URL="http://localhost:3456"
BRIDGE_SECRET="mancy-openclaw-2026"
GITHUB_REPO="https://github.com/unblinkr/agent-tasks.git"
POLL_INTERVAL=60

# Clone repo if not exists
if [ ! -d "$REPO_DIR" ]; then
  echo "[WATCHER] Cloning repo..."
  git clone "$GITHUB_REPO" "$REPO_DIR"
fi

echo "[WATCHER] Starting task watcher. Polling every ${POLL_INTERVAL}s..."

while true; do
  cd "$REPO_DIR"
  
  # Pull latest changes
  git pull --quiet 2>/dev/null
  
  # Check for pending tasks
  for task_file in tasks/pending/*.json; do
    # Skip if no files match the glob
    [ -e "$task_file" ] || continue
    
    echo "[WATCHER] Found task: $task_file"
    
    # Read the task
    CHANNEL=$(cat "$task_file" | python3 -c "import sys,json; print(json.load(sys.stdin)['channel'])" 2>/dev/null)
    MESSAGE=$(cat "$task_file" | python3 -c "import sys,json; print(json.load(sys.stdin)['message'])" 2>/dev/null)
    
    if [ -z "$CHANNEL" ] || [ -z "$MESSAGE" ]; then
      echo "[WATCHER] ERROR: Could not parse $task_file"
      continue
    fi
    
    echo "[WATCHER] Sending to #$CHANNEL..."
    
    # Send to Discord via bridge
    RESPONSE=$(curl -s -X POST "$BRIDGE_URL/send" \
      -H "Content-Type: application/json" \
      -H "x-bridge-secret: $BRIDGE_SECRET" \
      -d "{\"channel\":\"$CHANNEL\",\"message\":$(cat "$task_file" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)['message']))")}")
    
    echo "[WATCHER] Bridge response: $RESPONSE"
    
    # Move task to done
    FILENAME=$(basename "$task_file")
    mv "$task_file" "tasks/done/$FILENAME"
    
    # Commit the move
    git add -A
    git commit -m "Task dispatched: $FILENAME" --quiet 2>/dev/null
    git push --quiet 2>/dev/null
    
    echo "[WATCHER] Task dispatched and moved to done: $FILENAME"
    
    # Small delay between tasks
    sleep 2
  done
  
  sleep "$POLL_INTERVAL"
done
