#!/bin/bash
# refresh-dashboard.sh — Aggregate .feature-state.json files into dashboard.html
# Usage: bash .claude/hooks/refresh-dashboard.sh [project_root]

set -e

PROJECT_ROOT="${1:-.}"
SPECS_DIR="${PROJECT_ROOT}/.specify/specs"
DASHBOARD="${SPECS_DIR}/dashboard.html"
TEMPLATE="${PROJECT_ROOT}/.specify/templates/dashboard.html"

if [ ! -d "${SPECS_DIR}" ]; then
  echo "No specs directory found" >&2
  exit 0
fi

# Collect feature states into JSON array
STATES="["
FIRST=true
for dir in "${SPECS_DIR}"/20*; do
  [ -d "$dir" ] || continue
  STATE_FILE="${dir}/.feature-state.json"
  if [ -f "${STATE_FILE}" ]; then
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      STATES="${STATES},"
    fi
    STATES="${STATES}$(cat "${STATE_FILE}")"
  fi
done
STATES="${STATES}]"

# Read registry events (last 100 lines)
REGISTRY="${SPECS_DIR}/registry.jsonl"
TIMELINE="[]"
if [ -f "${REGISTRY}" ]; then
  TIMELINE="$(tail -100 "${REGISTRY}" | python3 -c "
import sys, json
events = []
for line in sys.stdin:
    line = line.strip()
    if line:
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            pass
print(json.dumps(events))
" 2>/dev/null || echo '[]')"
fi

# Generate dashboard.html if template exists
if [ -f "${TEMPLATE}" ]; then
  # Read template and inject state
  python3 -c "
import sys, json, re

with open('${TEMPLATE}', 'r') as f:
    html = f.read()

# Replace embedded state
states = '${STATES}' | replace("'", \"'\")
timeline = '${TIMELINE}'

# Find and replace the dashboardState script block
pattern = r'(<script type=\"application/json\" id=\"dashboardState\">)(.*?)(</script>)'
combined = json.dumps({'features': json.loads(states), 'timeline': json.loads(timeline)})
replacement = r'\1' + combined + r'\3'
html = re.sub(pattern, replacement, html, flags=re.DOTALL)

with open('${DASHBOARD}', 'w') as f:
    f.write(html)
print('Dashboard refreshed')
" 2>/dev/null || echo "Dashboard refresh attempted"
else
  echo "No dashboard template found" >&2
fi
