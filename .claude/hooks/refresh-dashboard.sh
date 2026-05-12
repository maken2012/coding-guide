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

# Collect feature states into a temp JSON file
STATES_FILE=$(mktemp /tmp/dashboard-states.XXXXXX.json)
echo -n "[" > "${STATES_FILE}"
FIRST=true
for dir in "${SPECS_DIR}"/20*; do
  [ -d "$dir" ] || continue
  STATE_FILE="${dir}/.feature-state.json"
  if [ -f "${STATE_FILE}" ]; then
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      echo -n "," >> "${STATES_FILE}"
    fi
    cat "${STATE_FILE}" >> "${STATES_FILE}"
  fi
done
echo "]" >> "${STATES_FILE}"

# Read registry events into a temp file
TIMELINE_FILE=$(mktemp /tmp/dashboard-timeline.XXXXXX.json)
REGISTRY="${SPECS_DIR}/registry.jsonl"
if [ -f "${REGISTRY}" ]; then
  python3 -c "
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
" < "${REGISTRY}" > "${TIMELINE_FILE}" 2>/dev/null || echo '[]' > "${TIMELINE_FILE}"
else
  echo '[]' > "${TIMELINE_FILE}"
fi

# Generate dashboard.html if template exists
if [ -f "${TEMPLATE}" ]; then
  python3 -c "
import sys, json, re

template_path = sys.argv[1]
dashboard_path = sys.argv[2]
states_path = sys.argv[3]
timeline_path = sys.argv[4]

with open(states_path, 'r') as f:
    states_raw = f.read().strip()
with open(timeline_path, 'r') as f:
    timeline_raw = f.read().strip()
with open(template_path, 'r') as f:
    html = f.read()

combined = json.dumps({
    'features': json.loads(states_raw),
    'timeline': json.loads(timeline_raw)
})

# Use string replacement instead of regex to avoid escape conflicts
marker_start = '<script type="application/json" id="dashboardState">'
marker_end = '</script>'
start_idx = html.find(marker_start)
if start_idx != -1:
    end_idx = html.find(marker_end, start_idx)
    if end_idx != -1:
        html = html[:start_idx + len(marker_start)] + combined + html[end_idx:]

with open(dashboard_path, 'w') as f:
    f.write(html)
print('Dashboard refreshed')
" "${TEMPLATE}" "${DASHBOARD}" "${STATES_FILE}" "${TIMELINE_FILE}"
else
  echo "No dashboard template found" >&2
fi

# Cleanup
rm -f "${STATES_FILE}" "${TIMELINE_FILE}"
