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
  PY_SCRIPT=$(mktemp /tmp/dashboard-gen.XXXXXX.py)
  cat > "${PY_SCRIPT}" << 'PYEOF'
import sys, json

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

# Auto-detect language from template
is_zh = 'lang="zh' in html[:200]

raw_features = json.loads(states_raw)
raw_timeline = json.loads(timeline_raw)

# Transform features into dashboard-expected flat format
features = []
current_feature = ''
phase_order = ['spec', 'detail', 'design', 'plan', 'implement', 'review']

for feat in raw_features:
    pipeline = feat.get('pipeline', {})
    active_phase = ''
    active_status = 'draft'
    html_path = ''

    for phase in phase_order:
        p = pipeline.get(phase, {})
        s = p.get('status', 'not_started')
        if s != 'not_started':
            active_phase = phase
            active_status = s
            artifact = p.get('artifact', '')
            if artifact:
                html_path = feat.get('id', '') + '/' + artifact

    if active_status in ('in_progress',):
        status = 'implementing'
    elif active_status == 'pending_review':
        status = 'pending_review'
    elif active_status == 'approved':
        status = 'approved'
    elif active_status == 'rejected':
        status = 'rejected'
    else:
        status = 'draft'

    flat = {
        'id': feat.get('id', ''),
        'name': feat.get('name', ''),
        'status': status,
        'phase': active_phase,
        'html_path': html_path
    }
    features.append(flat)

    if not current_feature and status in ('pending_review', 'implementing'):
        current_feature = feat.get('id', '')
if not current_feature and features:
    current_feature = features[0].get('id', '')

# Transform timeline events into dashboard-expected format
timeline = []
for ev in raw_timeline:
    ts = ev.get('ts', '')
    date_part = ts[:10] if ts else ''
    event_text = ev.get('event', '')
    feat_id = ev.get('feature', '')
    phase = ev.get('phase', '')

    if is_zh:
        labels = {
            'feature_created': '创建',
            'phase_completed': (phase or '') + ' 阶段完成',
            'phase_approved': (phase or '') + ' 阶段通过',
        }
    else:
        labels = {
            'feature_created': 'created',
            'phase_completed': (phase or '') + ' completed',
            'phase_approved': (phase or '') + ' approved',
        }
    desc = labels.get(event_text, event_text)
    if feat_id:
        desc = feat_id + ' ' + desc

    timeline.append({'date': date_part, 'event': desc})

combined = json.dumps({
    'current_feature': current_feature,
    'features': features,
    'timeline': timeline
}, ensure_ascii=False)

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
PYEOF

  python3 "${PY_SCRIPT}" "${TEMPLATE}" "${DASHBOARD}" "${STATES_FILE}" "${TIMELINE_FILE}" || { echo "Dashboard refresh failed"; exit 1; }
  rm -f "${PY_SCRIPT}"
else
  echo "No dashboard template found" >&2
fi

# Cleanup
rm -f "${STATES_FILE}" "${TIMELINE_FILE}"
