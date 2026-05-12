#!/bin/bash
# release-lock.sh — Release feature lock and log event
# Usage: bash .claude/hooks/release-lock.sh <feature_dir> <session_id>
set -e

FEATURE_DIR="$1"
SESSION_ID="$2"
LOCK_FILE="${FEATURE_DIR}/.agent-lock"

if [ -z "$FEATURE_DIR" ] || [ -z "$SESSION_ID" ]; then
  echo "ERROR: Usage: release-lock.sh <feature_dir> <session_id>"
  exit 1
fi

if [ ! -f "$LOCK_FILE" ]; then
  echo "NO_LOCK: No lock file found"
  exit 0
fi

EXISTING_SESSION=$(python3 -c "
import json
try: print(json.load(open('$LOCK_FILE')).get('session', ''))
except: print('')
" 2>/dev/null)

if [ "$EXISTING_SESSION" = "$SESSION_ID" ]; then
  rm -f "$LOCK_FILE"
  echo "LOCK_RELEASED"
else
  echo "LOCK_MISMATCH: Lock belongs to session ${EXISTING_SESSION}, not ${SESSION_ID}"
  exit 1
fi
