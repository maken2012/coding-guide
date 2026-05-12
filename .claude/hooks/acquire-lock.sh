#!/bin/bash
# acquire-lock.sh — Atomic feature lock acquisition
# Usage: bash .claude/hooks/acquire-lock.sh <feature_dir> <session_id> [timeout_minutes]
set -e

FEATURE_DIR="$1"
SESSION_ID="$2"
TIMEOUT_MIN="${3:-60}"
LOCK_FILE="${FEATURE_DIR}/.agent-lock"

if [ -z "$FEATURE_DIR" ] || [ -z "$SESSION_ID" ]; then
  echo "ERROR: Usage: acquire-lock.sh <feature_dir> <session_id> [timeout_minutes]"
  exit 1
fi

# Check if lock exists
if [ -f "$LOCK_FILE" ]; then
  EXISTING_SESSION=$(python3 -c "
import json
try:
    d = json.load(open('$LOCK_FILE'))
    print(d.get('session', ''))
except: print('')
" 2>/dev/null)

  # If same session, just renew
  if [ "$EXISTING_SESSION" = "$SESSION_ID" ]; then
    python3 -c "
import json
from datetime import datetime, timedelta
d = json.load(open('$LOCK_FILE'))
d['expires_at'] = (datetime.now() + timedelta(minutes=$TIMEOUT_MIN)).isoformat()
with open('$LOCK_FILE', 'w') as f: json.dump(d, f, indent=2)
print('LOCK_RENEWED')
" 2>/dev/null
    exit 0
  fi

  # Check if expired
  IS_EXPIRED=$(python3 -c "
import json
from datetime import datetime
try:
    d = json.load(open('$LOCK_FILE'))
    exp = datetime.fromisoformat(d.get('expires_at', '2000-01-01'))
    print('expired' if datetime.now() > exp else 'active')
except: print('expired')
" 2>/dev/null)

  if [ "$IS_EXPIRED" != "expired" ]; then
    EXISTING_AGENT=$(python3 -c "
import json
try: print(json.load(open('$LOCK_FILE')).get('session', 'unknown'))
except: print('unknown')
" 2>/dev/null)
    echo "LOCKED: Feature is locked by session ${EXISTING_AGENT}"
    exit 1
  fi

  # Expired, clean up
  rm -f "$LOCK_FILE"
fi

# Atomic acquire: write temp, then rename
TMP_FILE="${LOCK_FILE}.tmp.$$"
python3 -c "
import json
from datetime import datetime, timedelta
lock = {
    'session': '$SESSION_ID',
    'claimed_at': datetime.now().isoformat(),
    'expires_at': (datetime.now() + timedelta(minutes=$TIMEOUT_MIN)).isoformat()
}
with open('$TMP_FILE', 'w') as f: json.dump(lock, f, indent=2)
" 2>/dev/null

mv "$TMP_FILE" "$LOCK_FILE"

# Verify we won the race
WINNER=$(python3 -c "
import json
try: print(json.load(open('$LOCK_FILE')).get('session', ''))
except: print('')
" 2>/dev/null)

if [ "$WINNER" = "$SESSION_ID" ]; then
  echo "LOCK_ACQUIRED"
else
  rm -f "$TMP_FILE"
  echo "LOCK_LOST: Another agent won the race"
  exit 1
fi
