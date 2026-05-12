#!/bin/bash
# post-task-verify.sh — Validate .feature-state.json and feedback files
set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SPECIFY_DIR="$PROJECT_ROOT/.specify"
SPECS_DIR="$SPECIFY_DIR/specs"

# Validate all .feature-state.json files
for state_file in "$SPECS_DIR"/20*/.feature-state.json; do
  [ -f "$state_file" ] || continue
  python3 -c "import json; json.load(open('$state_file'))" 2>/dev/null || {
    echo "WARNING: $(basename $(dirname $state_file))/.feature-state.json has invalid JSON"
  }
done

# Validate feedback files in all feature directories
for feat_dir in "$SPECS_DIR"/20*/; do
  [ -d "$feat_dir" ] || continue
  for fb in "$feat_dir"*.feedback.json "$feat_dir"design/*.feedback.json; do
    [ -f "$fb" ] || continue
    python3 -c "import json; json.load(open('$fb'))" 2>/dev/null || {
      echo "WARNING: $(basename $fb) has invalid JSON"
    }
  done
done

# Validate registry.jsonl (each line should be valid JSON)
if [ -f "$SPECS_DIR/registry.jsonl" ]; then
  INVALID=$(python3 -c "
import json, sys
bad = 0
for i, line in enumerate(open('$SPECS_DIR/registry.jsonl'), 1):
    line = line.strip()
    if line:
        try: json.loads(line)
        except: bad += 1
if bad > 0: print(f'{bad} invalid lines in registry.jsonl')
" 2>/dev/null || echo "validation error")
  if [ -n "$INVALID" ]; then
    echo "WARNING: $INVALID"
  fi
fi

echo "OK: Output file validation complete"
