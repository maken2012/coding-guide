#!/bin/bash
# pre-spec-check.sh — Pre-spec validation + stale lock cleanup
set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPECIFY_DIR="$PROJECT_ROOT/.specify"

# Check .specify directory exists
if [ ! -d "$SPECIFY_DIR" ]; then
  echo "ERROR: .specify/ directory not found. Run install.sh first."
  exit 1
fi

# Check constitution.md exists
if [ ! -f "$SPECIFY_DIR/constitution.md" ]; then
  echo "ERROR: constitution.md not found."
  exit 1
fi

# Check templates directory exists
if [ ! -d "$SPECIFY_DIR/templates" ]; then
  echo "ERROR: templates/ directory not found."
  exit 1
fi

# Check and create registry.jsonl if missing
SPECS_DIR="$SPECIFY_DIR/specs"
mkdir -p "$SPECS_DIR"
if [ ! -f "$SPECS_DIR/registry.jsonl" ]; then
  touch "$SPECS_DIR/registry.jsonl"
fi

# Clean up stale locks (expired > 60 minutes)
NOW=$(python3 -c "import time; print(int(time.time()))" 2>/dev/null || echo "0")
for lock in "$SPECS_DIR"/20*/.agent-lock; do
  [ -f "$lock" ] || continue
  EXPIRES=$(python3 -c "
import json,sys
try:
    d=json.load(open('$lock'))
    from datetime import datetime
    exp=datetime.fromisoformat(d.get('expires_at','2000-01-01')).timestamp()
    print(int(exp))
except: print(0)
" 2>/dev/null || echo "0")
  if [ "$NOW" -gt "$EXPIRES" ] && [ "$EXPIRES" -gt 0 ]; then
    rm -f "$lock"
    echo "CLEANED: stale lock removed from $(dirname $lock)"
  fi
done

echo "OK: Pre-spec validation passed"
