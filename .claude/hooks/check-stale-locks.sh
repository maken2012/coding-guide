#!/bin/bash
# check-stale-locks.sh — Find and report/remove expired locks
# Usage: bash .claude/hooks/check-stale-locks.sh [specs_dir]
set -e

SPECS_DIR="${1:-.specify/specs}"
FOUND=0

for lock in "$SPECS_DIR"/20*/.agent-lock; do
  [ -f "$lock" ] || continue
  
  IS_EXPIRED=$(python3 -c "
import json
from datetime import datetime
try:
    d = json.load(open('$lock'))
    exp = datetime.fromisoformat(d.get('expires_at', '2000-01-01'))
    print('expired' if datetime.now() > exp else 'active')
except: print('expired')
" 2>/dev/null)

  if [ "$IS_EXPIRED" = "expired" ]; then
    FEATURE=$(basename "$(dirname "$lock")")
    echo "STALE: ${FEATURE} (expired lock removed)"
    rm -f "$lock"
    FOUND=$((FOUND + 1))
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo "OK: No stale locks found"
fi
