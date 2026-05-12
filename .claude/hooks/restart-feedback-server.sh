#!/bin/bash
# restart-feedback-server.sh — Kill existing feedback server and start a new one

PORT=8421
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SERVER="$SCRIPT_DIR/feedback-server.py"
SPECS_DIR="$PROJECT_ROOT/.specify/specs"

# Find and kill existing server on the port
PID=$(lsof -ti :$PORT 2>/dev/null)
if [ -n "$PID" ]; then
  echo "Stopping existing server (PID: $PID)..."
  kill $PID 2>/dev/null
  sleep 1
  # Force kill if still running
  PID=$(lsof -ti :$PORT 2>/dev/null)
  if [ -n "$PID" ]; then
    kill -9 $PID 2>/dev/null
    sleep 0.5
  fi
  echo "Stopped."
fi

# Clean pycache
rm -rf "$SCRIPT_DIR/__pycache__" 2>/dev/null

# Start server
echo "Starting feedback server on port $PORT..."
python3 "$SERVER" --root "$SPECS_DIR"
