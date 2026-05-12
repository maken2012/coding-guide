#!/bin/bash
# start-feedback-server.sh — Start feedback server in background if not running
# Called by Claude Code SessionStart hook

PORT=8421
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SERVER="$SCRIPT_DIR/feedback-server.py"
SPECS_DIR="$PROJECT_ROOT/.specify/specs"
LOG="$SCRIPT_DIR/feedback-server.log"

# Skip if no specs directory yet (project not initialized)
if [ ! -d "$SPECS_DIR" ]; then
  exit 0
fi

# Check if already running
PID=$(lsof -ti :$PORT 2>/dev/null)
if [ -n "$PID" ]; then
  exit 0
fi

# Start in background
nohup python3 "$SERVER" --root "$SPECS_DIR" > "$LOG" 2>&1 &
echo "Feedback server started on port $PORT (PID: $!)"
