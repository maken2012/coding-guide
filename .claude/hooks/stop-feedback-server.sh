#!/bin/bash
# stop-feedback-server.sh — Stop the feedback server

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.feedback-server.pid"

# Stop via PID file
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE" 2>/dev/null)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null
    sleep 1
    # Force kill if still running
    if kill -0 "$PID" 2>/dev/null; then
      kill -9 "$PID" 2>/dev/null
    fi
    echo "Feedback server stopped (PID: $PID)"
  else
    echo "Server process not found (stale PID file)"
  fi
  rm -f "$PID_FILE"
else
  # No PID file — try to find by port
  PID=$(lsof -ti :8421 2>/dev/null)
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null
    echo "Feedback server stopped (PID: $PID, found on port 8421)"
  else
    echo "No feedback server running"
  fi
fi
