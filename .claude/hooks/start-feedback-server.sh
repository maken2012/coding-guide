#!/bin/bash
# start-feedback-server.sh — Start feedback server, auto-detect port conflicts
# Called by Claude Code SessionStart hook or manually

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SERVER="$SCRIPT_DIR/feedback-server.py"
SPECS_DIR="$PROJECT_ROOT/.specify/specs"
LOG="$SCRIPT_DIR/feedback-server.log"
PID_FILE="$SCRIPT_DIR/.feedback-server.pid"

DEFAULT_PORT=8421
MAX_PORT=8431  # try up to 10 ports

# Skip if no specs directory yet
if [ ! -d "$SPECS_DIR" ]; then
  exit 0
fi

# Check if already running via PID file
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    # Process is alive — verify it's our server
    PORT=$(lsof -p "$OLD_PID" -i :8421-8431 -sTCP:LISTEN -P -n 2>/dev/null | grep -oE ':[0-9]+' | head -1 | tr -d ':')
    if [ -n "$PORT" ]; then
      echo "Feedback server already running (PID: $OLD_PID, port: $PORT)"
      exit 0
    fi
  fi
  # Stale PID file
  rm -f "$PID_FILE"
fi

# Find an available port
PORT=""
for p in $(seq $DEFAULT_PORT $MAX_PORT); do
  if ! lsof -ti :$p >/dev/null 2>&1; then
    PORT=$p
    break
  fi
done

if [ -z "$PORT" ]; then
  echo "ERROR: Ports $DEFAULT_PORT-$MAX_PORT are all in use. Free a port or edit DEFAULT_PORT in this script." >&2
  exit 1
fi

if [ "$PORT" != "$DEFAULT_PORT" ]; then
  echo "WARNING: Port $DEFAULT_PORT is in use, using port $PORT instead." >&2
fi

# Start in background
nohup python3 "$SERVER" --port "$PORT" --root "$SPECS_DIR" > "$LOG" 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > "$PID_FILE"

# Wait briefly and verify it started
sleep 1
if kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "Feedback server started (PID: $SERVER_PID, port: $PORT)"
  echo "  Dashboard: http://localhost:$PORT"
else
  echo "ERROR: Server failed to start. Check $LOG for details." >&2
  rm -f "$PID_FILE"
  exit 1
fi
