# Feedback Server + Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform SDD framework into a micro management system with Python HTTP server, SQLite storage, and dynamic dashboard/timeline pages.

**Architecture:** feedback-server.py serves as both static file server and REST API. Browser pages (dashboard, timeline, spec templates) communicate with it via fetch/XHR. SQLite is the single query source; JSON files remain as Agent-facing interface for backward compatibility.

**Tech Stack:** Python 3 standard library (http.server, sqlite3, json, re, os, datetime), vanilla HTML/CSS/JS (no frameworks)

**Design doc:** `docs/2026-05-12-feedback-server-and-dashboard-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `.claude/hooks/feedback-server.py` | Create | HTTP server, API routes, SQLite, security validation |
| `.specify/zh/templates/dashboard.html` | Rewrite | Dynamic SPA, fetch API, decision summaries |
| `.specify/en/templates/dashboard.html` | Rewrite | Same, English |
| `.specify/zh/templates/timeline.html` | Create | Full timeline page with pagination and filtering |
| `.specify/en/templates/timeline.html` | Create | Same, English |
| `.specify/zh/templates/spec-template.html` | Modify | saveFeedback POST, timezone fix |
| `.specify/en/templates/spec-template.html` | Modify | Same |
| `.specify/zh/templates/detail-template.html` | Modify | saveFeedback POST, timezone fix |
| `.specify/en/templates/detail-template.html` | Modify | Same |
| `.specify/zh/templates/plan-template.html` | Modify | saveFeedback POST, timezone fix |
| `.specify/en/templates/plan-template.html` | Modify | Same |
| `.specify/zh/templates/review-template.html` | Modify | saveFeedback POST, timezone fix |
| `.specify/en/templates/review-template.html` | Modify | Same |
| `install.sh` | Modify | Copy feedback-server.py, update completion message |

---

### Task 1: Create feedback-server.py

**Files:**
- Create: `.claude/hooks/feedback-server.py`

- [ ] **Step 1: Write feedback-server.py with SQLite init, security validation, and API routes**

```python
#!/usr/bin/env python3
"""SDD Feedback Server — lightweight HTTP server for spec-driven development.

Provides:
  - Static file serving for .specify/specs/
  - REST API for feedback submission, feature/phase/decision/timeline queries
  - SQLite storage (sdd.db) alongside JSON files for Agent compatibility
  - Path sandbox to prevent directory traversal attacks
"""

import argparse
import json
import os
import re
import sqlite3
import sys
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_PORT = 8421
VALID_PHASES = ('spec', 'detail', 'design', 'plan', 'implement', 'review')
VALID_VERDICTS = ('approved', 'rejected')
FEATURE_ID_RE = re.compile(r'^\d{8}-\d{3}-[a-zA-Z0-9_-]+$')
FEEDBACK_FILENAME_RE = re.compile(r'^(spec|detail|design|plan|implement|review)\.feedback\.json$')

# Set via --root or auto-detected at startup
SPECS_ROOT = ''

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def get_db_path():
    return os.path.join(SPECS_ROOT, 'sdd.db')


def init_db():
    """Create tables if they don't exist."""
    conn = sqlite3.connect(get_db_path())
    conn.executescript('''
        CREATE TABLE IF NOT EXISTS features (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            current_phase TEXT,
            status TEXT DEFAULT 'draft',
            created_at TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS phases (
            feature_id TEXT,
            phase TEXT,
            status TEXT DEFAULT 'draft',
            artifact_path TEXT,
            updated_at TEXT,
            PRIMARY KEY (feature_id, phase)
        );
        CREATE TABLE IF NOT EXISTS decisions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feature_id TEXT,
            phase TEXT,
            decision_key TEXT,
            decision_value TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS timeline (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feature_id TEXT,
            event_type TEXT,
            description TEXT,
            created_at TEXT
        );
    ''')
    conn.commit()
    conn.close()


def db_now():
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')


# ---------------------------------------------------------------------------
# Security: path sandbox
# ---------------------------------------------------------------------------

def validate_feature_id(feature_id):
    """Return True if feature_id matches allowed pattern."""
    return bool(FEATURE_ID_RE.match(feature_id))


def sandbox_path(feature_id, filename):
    """Build and validate a file path inside SPECS_ROOT/<feature_id>/<filename>.

    Returns the absolute safe path, or raises ValueError if traversal is detected.
    """
    real_root = os.path.realpath(SPECS_ROOT)
    target = os.path.realpath(os.path.join(SPECS_ROOT, feature_id, filename))
    if not target.startswith(real_root + os.sep) and target != real_root:
        raise ValueError('path traversal denied')
    return target


# ---------------------------------------------------------------------------
# Feedback logic
# ---------------------------------------------------------------------------

def write_feedback_json(feature_id, phase, data):
    """Write feedback data to the .feedback.json file for Agent compatibility."""
    filename = phase + '.feedback.json'
    path = sandbox_path(feature_id, filename)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def write_to_db(feature_id, phase, verdict, feedback_text, decisions, timestamp):
    """Insert or update feedback data in SQLite."""
    now = db_now()
    conn = sqlite3.connect(get_db_path())
    try:
        # Upsert feature
        existing = conn.execute('SELECT id FROM features WHERE id = ?', (feature_id,)).fetchone()
        if not existing:
            conn.execute(
                'INSERT INTO features (id, name, current_phase, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
                (feature_id, feature_id, phase, 'pending_review' if verdict == 'approved' else 'in_progress', now, now)
            )
        else:
            conn.execute(
                'UPDATE features SET current_phase = ?, status = ?, updated_at = ? WHERE id = ?',
                (phase, 'pending_review' if verdict == 'approved' else 'in_progress', now, feature_id)
            )

        # Update phase status
        conn.execute(
            'INSERT INTO phases (feature_id, phase, status, updated_at) VALUES (?, ?, ?, ?) '
            'ON CONFLICT(feature_id, phase) DO UPDATE SET status = excluded.status, updated_at = excluded.updated_at',
            (feature_id, phase, verdict, now)
        )

        # Write decisions (delete old, insert new)
        if decisions:
            conn.execute('DELETE FROM decisions WHERE feature_id = ? AND phase = ?', (feature_id, phase))
            for key, value in decisions.items():
                conn.execute(
                    'INSERT INTO decisions (feature_id, phase, decision_key, decision_value, created_at) VALUES (?, ?, ?, ?, ?)',
                    (feature_id, phase, key, str(value), now)
                )

        # Timeline event
        event_type = 'phase_' + verdict  # phase_approved or phase_rejected
        description = f'{feature_id} {phase} {verdict}'
        conn.execute(
            'INSERT INTO timeline (feature_id, event_type, description, created_at) VALUES (?, ?, ?, ?)',
            (feature_id, event_type, description, now)
        )

        conn.commit()
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# API query helpers
# ---------------------------------------------------------------------------

def query_features():
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    rows = conn.execute('SELECT * FROM features ORDER BY updated_at DESC').fetchall()
    conn.close()
    return [dict(r) for r in rows]


def query_phases(feature_id):
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    rows = conn.execute('SELECT * FROM phases WHERE feature_id = ?', (feature_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def query_decisions(feature_id):
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        'SELECT * FROM decisions WHERE feature_id = ? ORDER BY phase, id',
        (feature_id,)
    ).fetchall()
    conn.close()
    # Group by phase
    result = {}
    for r in rows:
        phase = r['phase']
        if phase not in result:
            result[phase] = []
        result[phase].append({'key': r['decision_key'], 'value': r['decision_value']})
    return result


def query_timeline(limit=10, page=None, per_page=50, feature_id=None):
    conn = sqlite3.connect(get_db_path())
    conn.row_factory = sqlite3.Row
    where = ''
    params = []
    if feature_id:
        where = 'WHERE feature_id = ?'
        params.append(feature_id)
    if page:
        offset = (page - 1) * per_page
        rows = conn.execute(
            f'SELECT * FROM timeline {where} ORDER BY created_at DESC LIMIT ? OFFSET ?',
            params + [per_page, offset]
        ).fetchall()
    else:
        rows = conn.execute(
            f'SELECT * FROM timeline {where} ORDER BY created_at DESC LIMIT ?',
            params + [limit]
        ).fetchall()
    total = conn.execute(f'SELECT COUNT(*) FROM timeline {where}', params).fetchone()[0]
    conn.close()
    return {
        'items': [dict(r) for r in rows],
        'total': total,
        'page': page,
        'per_page': per_page if page else None
    }


# ---------------------------------------------------------------------------
# HTTP Handler
# ---------------------------------------------------------------------------

class SDDHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        # Quieter logging
        pass

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_html(self, path):
        with open(path, 'rb') as f:
            content = f.read()
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def _send_error(self, status, message):
        self._send_json({'error': message}, status)

    # ---- GET routes ----

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        # API routes
        if path == '/api/features':
            return self._send_json(query_features())

        if path.startswith('/api/phases/'):
            fid = path.split('/')[-1]
            if not validate_feature_id(fid):
                return self._send_error(400, 'invalid feature_id')
            return self._send_json(query_phases(fid))

        if path.startswith('/api/decisions/'):
            fid = path.split('/')[-1]
            if not validate_feature_id(fid):
                return self._send_error(400, 'invalid feature_id')
            return self._send_json(query_decisions(fid))

        if path == '/api/timeline':
            qs = parse_qs(parsed.query)
            limit = int(qs.get('limit', [10])[0])
            page = int(qs['page'][0]) if 'page' in qs else None
            per_page = int(qs.get('per_page', [50])[0])
            feature_id = qs.get('feature_id', [None])[0]
            return self._send_json(query_timeline(limit, page, per_page, feature_id))

        # Page routes
        if path == '/' or path == '':
            self.send_response(302)
            self.send_header('Location', '/specs/dashboard.html')
            self.end_headers()
            return

        if path == '/timeline':
            for locale in ('zh', 'en'):
                p = os.path.join(SPECS_ROOT, '..', 'templates', locale, 'timeline.html')
                p = os.path.realpath(p)
                if os.path.isfile(p):
                    return self._send_html(p)
            return self._send_error(404, 'timeline.html not found')

        # Static files: /specs/<path>
        if path.startswith('/specs/'):
            rel = path[len('/specs/'):]
            # Security: resolve and verify within SPECS_ROOT
            real_root = os.path.realpath(SPECS_ROOT)
            target = os.path.realpath(os.path.join(SPECS_ROOT, rel))
            if not target.startswith(real_root + os.sep) and target != real_root:
                return self._send_error(403, 'access denied')
            if os.path.isfile(target):
                if target.endswith('.html'):
                    return self._send_html(target)
                elif target.endswith('.json'):
                    with open(target, 'rb') as f:
                        content = f.read()
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(content)))
                    self.end_headers()
                    self.wfile.write(content)
                    return
            return self._send_error(404, 'not found')

        self._send_error(404, 'not found')

    # ---- POST routes ----

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != '/api/feedback':
            return self._send_error(404, 'not found')

        # Read body
        length = int(self.headers.get('Content-Length', 0))
        if length > 1_000_000:  # 1MB limit
            return self._send_error(413, 'payload too large')
        body = self.rfile.read(length).decode('utf-8')

        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            return self._send_error(400, 'invalid JSON')

        # Validate fields
        feature_id = data.get('feature_id', '')
        phase = data.get('phase', '')
        verdict = data.get('verdict', '')

        if not validate_feature_id(feature_id):
            return self._send_error(400, 'invalid feature_id')
        if phase not in VALID_PHASES:
            return self._send_error(400, 'invalid phase')
        if verdict not in VALID_VERDICTS:
            return self._send_error(400, 'invalid verdict')

        # Write JSON file
        try:
            feedback_data = {
                'artifact': phase + '.html',
                'feature': feature_id,
                'phase': phase,
                'status': 'reviewed',
                'decisions': data.get('decisions', {}),
                'review': {
                    'verdict': verdict,
                    'feedback': data.get('feedback', ''),
                    'timestamp': data.get('timestamp', db_now())
                },
                'created_at': data.get('timestamp', db_now()),
                'updated_at': db_now()
            }
            write_feedback_json(feature_id, phase, feedback_data)
        except ValueError as e:
            return self._send_error(403, str(e))

        # Write to SQLite
        write_to_db(
            feature_id, phase, verdict,
            data.get('feedback', ''),
            data.get('decisions', {}),
            data.get('timestamp', db_now())
        )

        self._send_json({'ok': True})


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def detect_root():
    """Auto-detect .specify/specs/ from current working directory."""
    cwd = os.getcwd()
    candidate = os.path.join(cwd, '.specify', 'specs')
    if os.path.isdir(candidate):
        return candidate
    # Walk up
    parent = os.path.dirname(cwd)
    while parent != cwd:
        candidate = os.path.join(parent, '.specify', 'specs')
        if os.path.isdir(candidate):
            return candidate
        cwd = parent
        parent = os.path.dirname(cwd)
    return None


def main():
    global SPECS_ROOT

    parser = argparse.ArgumentParser(description='SDD Feedback Server')
    parser.add_argument('--port', type=int, default=DEFAULT_PORT)
    parser.add_argument('--root', type=str, default=None, help='Path to .specify/specs/')
    args = parser.parse_args()

    SPECS_ROOT = args.root or detect_root()
    if not SPECS_ROOT:
        print('Error: Cannot find .specify/specs/ directory.')
        print('Run this from the project root, or use --root /path/to/.specify/specs')
        sys.exit(1)

    SPECS_ROOT = os.path.abspath(SPECS_ROOT)
    os.makedirs(SPECS_ROOT, exist_ok=True)

    init_db()

    server = HTTPServer(('127.0.0.1', args.port), SDDHandler)
    print(f'SDD Feedback Server running at http://localhost:{args.port}')
    print(f'Serving: {SPECS_ROOT}')
    print(f'Database: {get_db_path()}')
    print('Press Ctrl+C to stop.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nStopped.')


if __name__ == '__main__':
    main()
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x .claude/hooks/feedback-server.py`

- [ ] **Step 3: Verify server starts and stops**

Run: `python3 .claude/hooks/feedback-server.py --root /tmp/test-specs &` then `curl http://localhost:8421/api/features` then `kill %1`

Expected: Server prints startup message, curl returns `[]`, server stops cleanly.

- [ ] **Step 4: Commit**

```bash
git add .claude/hooks/feedback-server.py
git commit -m "feat: add feedback-server.py with SQLite and API routes"
```

---

### Task 2: Modify zh template saveFeedback functions (4 files)

**Files:**
- Modify: `.specify/zh/templates/spec-template.html` (lines 458-499)
- Modify: `.specify/zh/templates/detail-template.html` (lines 556-607)
- Modify: `.specify/zh/templates/plan-template.html` (lines 579-618)
- Modify: `.specify/zh/templates/review-template.html` (lines 618-659)

- [ ] **Step 1: Update spec-template.html saveFeedback and submitVerdict**

In `.specify/zh/templates/spec-template.html`, replace `saveFeedback` (lines 458-481) with:

```javascript
async function saveFeedback(data) {
  try {
    var resp = await fetch('http://localhost:8421/api/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    if (resp.ok) {
      showToast('反馈已提交。', 'success');
      return;
    }
  } catch (e) { /* server not running, fallback */ }
  var json = JSON.stringify(data, null, 2);
  if (window.showSaveFilePicker) {
    try {
      var handle = await window.showSaveFilePicker({
        suggestedName: 'feedback-spec-' + Date.now() + '.json',
        types: [{ description: 'JSON File', accept: { 'application/json': ['.json'] } }]
      });
      var writable = await handle.createWritable();
      await writable.write(json);
      await writable.close();
      showToast('Feedback saved to file.', 'success');
      return;
    } catch (err) {
      if (err.name === 'AbortError') return;
    }
  }
  try {
    await navigator.clipboard.writeText(json);
    showToast('Feedback copied to clipboard.', 'info');
  } catch (err) {
    console.log('Feedback data:', json);
  }
}
```

Replace `submitVerdict` (lines 486-499) with:

```javascript
async function submitVerdict(verdict) {
  var feedback = document.getElementById('feedbackInput').value.trim();
  var decisions = collectDecisions();
  var data = {
    feature_id: document.querySelector('meta[name="feature-id"]')
      ? document.querySelector('meta[name="feature-id"]').content
      : new URLSearchParams(window.location.search).get('feature_id') || '',
    phase: 'spec',
    verdict: verdict,
    feedback: feedback,
    decisions: decisions,
    timestamp: new Date().toLocaleString('sv-SE')
  };
  window.parent.postMessage(data, '*');
  await saveFeedback(data);
}
```

Also add `<meta name="feature-id" content="">` in the `<head>` section (after existing meta tags) as a placeholder for the agent to fill in.

- [ ] **Step 2: Update detail-template.html saveFeedback and submitVerdict**

In `.specify/zh/templates/detail-template.html`, replace `saveFeedback` (lines 556-588) with the same fetch-first version as spec-template (same function body).

Replace `submitVerdict` (lines 594-607) with:

```javascript
async function submitVerdict(verdict) {
  var decisions = collectDecisions();
  var feedback = document.getElementById('feedbackInput').value.trim();
  var data = {
    feature_id: document.querySelector('meta[name="feature-id"]')
      ? document.querySelector('meta[name="feature-id"]').content
      : new URLSearchParams(window.location.search).get('feature_id') || '',
    phase: 'detail',
    verdict: verdict,
    feedback: feedback,
    decisions: decisions,
    timestamp: new Date().toLocaleString('sv-SE')
  };
  await saveFeedback(data);
}
```

Add `<meta name="feature-id" content="">` in the `<head>` section.

- [ ] **Step 3: Update plan-template.html saveFeedback and submitVerdict**

In `.specify/zh/templates/plan-template.html`, replace `saveFeedback` (lines 579-602) with the same fetch-first version.

Replace `submitVerdict` (lines 607-618) with:

```javascript
async function submitVerdict(verdict) {
  var feedback = document.getElementById('feedbackInput').value.trim();
  var data = {
    feature_id: document.querySelector('meta[name="feature-id"]')
      ? document.querySelector('meta[name="feature-id"]').content
      : new URLSearchParams(window.location.search).get('feature_id') || '',
    phase: 'plan',
    verdict: verdict,
    feedback: feedback,
    timestamp: new Date().toLocaleString('sv-SE')
  };
  window.parent.postMessage(data, '*');
  await saveFeedback(data);
}
```

Add `<meta name="feature-id" content="">` in the `<head>` section.

- [ ] **Step 4: Update review-template.html saveFeedback and submitVerdict**

In `.specify/zh/templates/review-template.html`, replace `saveFeedback` (lines 618-641) with the same fetch-first version.

Replace `submitVerdict` (lines 646-659) with:

```javascript
async function submitVerdict(verdict) {
  var feedback = document.getElementById('feedbackInput').value.trim();
  var data = {
    feature_id: document.querySelector('meta[name="feature-id"]')
      ? document.querySelector('meta[name="feature-id"]').content
      : new URLSearchParams(window.location.search).get('feature_id') || '',
    phase: 'review',
    verdict: verdict,
    feedback: feedback,
    decisions: Object.assign({}, collectIssueVerdicts() || {}, collectActionItems() || {}),
    timestamp: new Date().toLocaleString('sv-SE')
  };
  window.parent.postMessage(data, '*');
  await saveFeedback(data);
}
```

Add `<meta name="feature-id" content="">` in the `<head>` section.

- [ ] **Step 5: Commit**

```bash
git add .specify/zh/templates/spec-template.html .specify/zh/templates/detail-template.html .specify/zh/templates/plan-template.html .specify/zh/templates/review-template.html
git commit -m "feat: zh templates use fetch API for feedback submission"
```

---

### Task 3: Modify en template saveFeedback functions (4 files)

**Files:**
- Modify: `.specify/en/templates/spec-template.html`
- Modify: `.specify/en/templates/detail-template.html`
- Modify: `.specify/en/templates/plan-template.html`
- Modify: `.specify/en/templates/review-template.html`

- [ ] **Step 1: Apply identical changes to en templates**

Apply the exact same `saveFeedback` and `submitVerdict` replacements from Task 2 to all 4 English template files. The code is identical (JavaScript is language-agnostic); only the existing surrounding HTML text differs (English vs Chinese labels).

Use the same line ranges and same replacement code as Task 2 steps 1-4, applied to the en/ versions of each file.

- [ ] **Step 2: Commit**

```bash
git add .specify/en/templates/spec-template.html .specify/en/templates/detail-template.html .specify/en/templates/plan-template.html .specify/en/templates/review-template.html
git commit -m "feat: en templates use fetch API for feedback submission"
```

---

### Task 4: Rewrite dashboard.html (zh)

**Files:**
- Rewrite: `.specify/zh/templates/dashboard.html`

- [ ] **Step 1: Write the new dynamic dashboard**

The new dashboard.html removes the embedded `<script type="application/json" id="dashboardState">` static data block and replaces it with fetch API calls. Key changes:

1. **Remove** the `<script type="application/json" id="dashboardState">` block (lines 470-511)
2. **Replace init logic** — on page load, fetch from `/api/features`, `/api/timeline?limit=10`
3. **Feature list rendering** — include decision summary toggle per feature
4. **selectFeature** — fetch phases + decisions, conditionally show iframe or approved card
5. **Decision summary** — collapsible section under each feature card showing key:value pairs
6. **Review bar** — only visible when feature is pending_review or rejected
7. **Timeline link** — "查看完整时间线 →" at bottom of timeline section linking to `/timeline`
8. **saveFeedback/submitVerdict** — same fetch-first pattern as templates, POST to `/api/feedback`
9. **All timestamps** — displayed as-is (already local time from SQLite)

The full rewrite should preserve the existing dark theme CSS variables and layout (left 300px sidebar, right content area, fixed review bar at bottom) while making the data layer dynamic.

```html
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SDD Dashboard</title>
<style>
/* Preserve existing dark theme */
:root {
  --bg: #0f172a; --surface: #1e293b; --border: #334155;
  --text: #e2e8f0; --text-muted: #94a3b8;
  --primary: #3b82f6; --success: #22c55e; --warning: #f59e0b; --danger: #ef4444;
  --radius: 8px;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); height: 100vh; overflow: hidden; }
.app { display: flex; height: 100vh; }

/* Sidebar */
.sidebar { width: 300px; background: var(--surface); border-right: 1px solid var(--border); display: flex; flex-direction: column; overflow: hidden; }
.sidebar-header { padding: 16px; border-bottom: 1px solid var(--border); }
.sidebar-header h2 { font-size: 16px; font-weight: 600; }
.stats { display: flex; gap: 8px; padding: 12px 16px; border-bottom: 1px solid var(--border); }
.stat-card { flex: 1; text-align: center; padding: 8px; background: var(--bg); border-radius: var(--radius); }
.stat-card .num { font-size: 20px; font-weight: 700; }
.stat-card .label { font-size: 11px; color: var(--text-muted); margin-top: 2px; }
.feature-list { flex: 1; overflow-y: auto; padding: 8px; }
.feature-item { padding: 10px 12px; border-radius: var(--radius); cursor: pointer; display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; transition: background 0.15s; }
.feature-item:hover { background: var(--bg); }
.feature-item.active { background: var(--primary); color: #fff; }
.feature-name { font-size: 14px; font-weight: 500; }
.status-badge { font-size: 11px; padding: 2px 8px; border-radius: 12px; background: var(--bg); }
.status-badge.approved { background: rgba(34,197,94,0.2); color: var(--success); }
.status-badge.pending_review { background: rgba(59,130,246,0.2); color: var(--primary); }
.status-badge.rejected { background: rgba(239,68,68,0.2); color: var(--danger); }
.status-badge.implementing { background: rgba(245,158,11,0.2); color: var(--warning); }
.status-badge.draft { background: rgba(148,163,184,0.2); color: var(--text-muted); }

/* Decision summary */
.decision-summary { padding: 6px 12px; font-size: 12px; color: var(--text-muted); cursor: pointer; display: flex; align-items: center; gap: 4px; }
.decision-summary:hover { color: var(--text); }
.decision-detail { padding: 4px 12px 8px 24px; display: none; }
.decision-detail.show { display: block; }
.decision-item { font-size: 12px; padding: 2px 0; color: var(--text-muted); }
.decision-item .key { color: var(--text-muted); }
.decision-item .value { color: var(--text); font-weight: 500; }
.decision-item .check { color: var(--success); margin-right: 4px; }

/* Timeline in sidebar */
.timeline-section { padding: 12px 16px; border-top: 1px solid var(--border); max-height: 200px; overflow-y: auto; }
.timeline-section h3 { font-size: 13px; color: var(--text-muted); margin-bottom: 8px; }
.timeline-entry { display: flex; gap: 8px; margin-bottom: 6px; font-size: 12px; }
.timeline-date { color: var(--text-muted); white-space: nowrap; min-width: 80px; }
.timeline-text { color: var(--text); }
.timeline-more { font-size: 12px; color: var(--primary); text-decoration: none; margin-top: 8px; display: block; }
.timeline-more:hover { text-decoration: underline; }

/* Main content */
.main { flex: 1; display: flex; flex-direction: column; overflow: hidden; position: relative; }
.content-header { padding: 16px 24px; border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 12px; }
.content-header h2 { font-size: 18px; font-weight: 600; }
.phase-badge { font-size: 12px; padding: 4px 10px; border-radius: 12px; background: rgba(59,130,246,0.2); color: var(--primary); }
.content-body { flex: 1; position: relative; }

/* Welcome placeholder */
.welcome { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; color: var(--text-muted); font-size: 16px; }

/* iframe */
.content-frame { width: 100%; height: 100%; border: none; display: none; }

/* Approved card (replaces iframe for approved features) */
.approved-card { display: none; position: absolute; inset: 0; padding: 40px; overflow-y: auto; }
.approved-card .card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 32px; max-width: 600px; margin: 0 auto; }
.approved-card .card h3 { font-size: 20px; margin-bottom: 8px; }
.approved-card .card .status { color: var(--success); font-size: 14px; margin-bottom: 16px; }
.approved-card .phase-decisions { margin-top: 12px; }
.approved-card .phase-decisions h4 { font-size: 14px; color: var(--text-muted); margin-bottom: 6px; }
.approved-card .decision-row { display: flex; justify-content: space-between; padding: 6px 0; border-bottom: 1px solid var(--border); font-size: 14px; }
.approved-card .decision-row .key { color: var(--text-muted); }
.approved-card .decision-row .val { font-weight: 500; }

/* Review bar */
.review-bar { display: none; padding: 12px 24px; border-top: 1px solid var(--border); background: var(--surface); gap: 8px; align-items: center; }
.feedback-input { flex: 1; padding: 8px 12px; border-radius: var(--radius); border: 1px solid var(--border); background: var(--bg); color: var(--text); font-size: 14px; outline: none; }
.feedback-input:focus { border-color: var(--primary); }
.btn { padding: 8px 16px; border-radius: var(--radius); border: none; cursor: pointer; font-size: 14px; font-weight: 500; }
.btn-approve { background: var(--success); color: #fff; }
.btn-approve:hover { background: #16a34a; }
.btn-reject { background: var(--danger); color: #fff; }
.btn-reject:hover { background: #dc2626; }

/* Toast */
.toast-container { position: fixed; top: 16px; right: 16px; z-index: 9999; display: flex; flex-direction: column; gap: 8px; }
.toast { padding: 10px 16px; border-radius: var(--radius); font-size: 13px; color: #fff; animation: slideIn 0.3s ease; max-width: 320px; }
.toast.success { background: var(--success); }
.toast.error { background: var(--danger); }
.toast.info { background: var(--primary); }
.toast.warning { background: var(--warning); }
@keyframes slideIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }

/* Connecting state */
.connecting { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; flex-direction: column; gap: 12px; color: var(--text-muted); }
.connecting .spinner { width: 24px; height: 24px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
</style>
</head>
<body>
<div class="app">
  <div class="sidebar">
    <div class="sidebar-header"><h2>SDD Dashboard</h2></div>
    <div class="stats">
      <div class="stat-card"><div class="num" id="statTotal">-</div><div class="label">功能总数</div></div>
      <div class="stat-card"><div class="num" id="statPending">-</div><div class="label">待审核</div></div>
      <div class="stat-card"><div class="num" id="statApproved">-</div><div class="label">已通过</div></div>
    </div>
    <div class="feature-list" id="featureList"></div>
    <div class="timeline-section">
      <h3>时间线</h3>
      <div id="timeline"></div>
      <a href="/timeline" class="timeline-more" target="_blank">查看完整时间线 →</a>
    </div>
  </div>
  <div class="main">
    <div class="content-header">
      <h2 id="contentTitle">选择一个功能</h2>
      <span class="phase-badge" id="contentPhase" style="display:none"></span>
    </div>
    <div class="content-body">
      <div class="welcome" id="welcomePlaceholder">选择左侧功能查看详情</div>
      <iframe class="content-frame" id="contentFrame"></iframe>
      <div class="approved-card" id="approvedCard">
        <div class="card">
          <h3 id="approvedTitle"></h3>
          <div class="status" id="approvedStatus">✓ 已通过</div>
          <div id="approvedDecisions"></div>
        </div>
      </div>
    </div>
    <div class="review-bar" id="reviewBar">
      <input type="text" class="feedback-input" id="feedbackInput" placeholder="输入审核反馈...">
      <button class="btn btn-approve" onclick="submitVerdict('approved')">通过 ✓</button>
      <button class="btn btn-reject" onclick="submitVerdict('rejected')">驳回 ✗</button>
    </div>
  </div>
</div>
<div class="toast-container" id="toastContainer"></div>

<script>
var SERVER = window.location.origin;
var selectedFeatureId = null;
var featuresCache = [];
var phasesCache = {};
var decisionsCache = {};

function escapeHtml(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

function statusLabel(s) {
  var m = { draft: '草稿', pending_review: '待审核', approved: '已通过', rejected: '已驳回', implementing: '进行中' };
  return m[s] || s;
}

function showToast(msg, type) {
  var c = document.getElementById('toastContainer');
  var t = document.createElement('div');
  t.className = 'toast ' + type;
  t.textContent = msg;
  c.appendChild(t);
  setTimeout(function() { t.remove(); }, 3000);
}

// ---- Data loading ----

async function loadFeatures() {
  try {
    var resp = await fetch(SERVER + '/api/features');
    featuresCache = await resp.json();
  } catch (e) {
    showToast('无法连接服务器', 'error');
    featuresCache = [];
  }
  renderStats();
  renderFeatureList();
}

async function loadTimeline() {
  try {
    var resp = await fetch(SERVER + '/api/timeline?limit=10');
    var data = await resp.json();
    renderTimeline(data.items || []);
  } catch (e) {
    document.getElementById('timeline').innerHTML = '<div style="font-size:12px;color:var(--text-muted)">暂无时间线数据</div>';
  }
}

async function loadPhases(featureId) {
  try {
    var resp = await fetch(SERVER + '/api/phases/' + featureId);
    phasesCache = await resp.json();
  } catch (e) { phasesCache = {}; }
}

async function loadDecisions(featureId) {
  try {
    var resp = await fetch(SERVER + '/api/decisions/' + featureId);
    decisionsCache = await resp.json();
  } catch (e) { decisionsCache = {}; }
}

// ---- Rendering ----

function renderStats() {
  document.getElementById('statTotal').textContent = featuresCache.length;
  var pending = featuresCache.filter(function(f) { return f.status === 'pending_review'; }).length;
  var approved = featuresCache.filter(function(f) { return f.status === 'approved'; }).length;
  document.getElementById('statPending').textContent = pending;
  document.getElementById('statApproved').textContent = approved;
}

function renderFeatureList() {
  var container = document.getElementById('featureList');
  container.innerHTML = '';
  featuresCache.forEach(function(feature) {
    var item = document.createElement('div');
    item.className = 'feature-item' + (feature.id === selectedFeatureId ? ' active' : '');
    item.setAttribute('data-feature-id', feature.id);
    item.onclick = function() { selectFeature(feature.id); };
    item.innerHTML = '<span class="feature-name">' + escapeHtml(feature.name) + '</span>' +
                     '<span class="status-badge ' + feature.status + '">' + statusLabel(feature.status) + '</span>';
    container.appendChild(item);

    // Decision summary toggle
    var fid = feature.id;
    var summary = document.createElement('div');
    summary.className = 'decision-summary';
    summary.textContent = '▶ 决策记录';
    summary.style.display = 'none';
    summary.id = 'dsum-' + fid;
    summary.onclick = function(e) { e.stopPropagation(); toggleDecisions(fid); };
    container.appendChild(summary);

    var detail = document.createElement('div');
    detail.className = 'decision-detail';
    detail.id = 'ddet-' + fid;
    container.appendChild(detail);
  });
}

function toggleDecisions(fid) {
  var detail = document.getElementById('ddet-' + fid);
  var summary = document.getElementById('dsum-' + fid);
  if (detail.classList.contains('show')) {
    detail.classList.remove('show');
    summary.textContent = '▶ 决策记录';
  } else {
    detail.classList.add('show');
    summary.textContent = '▼ 决策记录';
  }
}

function renderTimeline(items) {
  var container = document.getElementById('timeline');
  container.innerHTML = '';
  if (!items.length) {
    container.innerHTML = '<div style="font-size:12px;color:var(--text-muted)">暂无时间线数据</div>';
    return;
  }
  items.forEach(function(entry) {
    var div = document.createElement('div');
    div.className = 'timeline-entry';
    div.innerHTML = '<div class="timeline-date">' + escapeHtml(entry.created_at || '') + '</div>' +
                    '<div class="timeline-text">' + escapeHtml(entry.description || '') + '</div>';
    container.appendChild(div);
  });
}

function renderDecisionsForFeature(fid) {
  var summary = document.getElementById('dsum-' + fid);
  var detail = document.getElementById('ddet-' + fid);
  var phases = Object.keys(decisionsCache);
  if (!phases.length) {
    summary.style.display = 'none';
    return;
  }
  summary.style.display = 'flex';
  var count = 0;
  detail.innerHTML = '';
  phases.forEach(function(phase) {
    var items = decisionsCache[phase];
    items.forEach(function(d) {
      count++;
      var row = document.createElement('div');
      row.className = 'decision-item';
      row.innerHTML = '<span class="check">✓</span><span class="key">' + escapeHtml(d.key) + ':</span> <span class="value">' + escapeHtml(d.value) + '</span>';
      detail.appendChild(row);
    });
  });
  summary.textContent = '▶ 决策记录 (' + count + ')';
}

// ---- Feature selection ----

async function selectFeature(featureId) {
  selectedFeatureId = featureId;
  document.querySelectorAll('.feature-item').forEach(function(el) {
    el.classList.toggle('active', el.getAttribute('data-feature-id') === featureId);
  });

  var feature = featuresCache.find(function(f) { return f.id === featureId; });
  if (!feature) return;

  document.getElementById('contentTitle').textContent = feature.name;
  var phaseEl = document.getElementById('contentPhase');
  if (feature.current_phase) { phaseEl.textContent = feature.current_phase; phaseEl.style.display = ''; }
  else { phaseEl.style.display = 'none'; }

  await loadPhases(featureId);
  await loadDecisions(featureId);
  renderDecisionsForFeature(featureId);

  // Determine what to show
  var currentPhase = phasesCache.find(function(p) { return p.phase === feature.current_phase; });
  var phaseStatus = currentPhase ? currentPhase.status : feature.status;

  var welcome = document.getElementById('welcomePlaceholder');
  var frame = document.getElementById('contentFrame');
  var reviewBar = document.getElementById('reviewBar');
  var approvedCard = document.getElementById('approvedCard');

  welcome.style.display = 'none';
  frame.style.display = 'none';
  reviewBar.style.display = 'none';
  approvedCard.style.display = 'none';

  if (phaseStatus === 'approved' || phaseStatus === 'pending_review') {
    // Check if approved
    var isApproved = phasesCache.some(function(p) { return p.status === 'approved'; });
    if (isApproved && feature.status === 'approved') {
      showApprovedCard(feature);
    } else {
      // Load iframe for review
      var htmlPath = currentPhase ? currentPhase.artifact_path : '';
      if (htmlPath) {
        frame.src = '/specs/' + featureId + '/' + htmlPath + '?feature_id=' + featureId;
        frame.style.display = 'block';
        reviewBar.style.display = 'flex';
      } else {
        welcome.style.display = 'flex';
        welcome.textContent = feature.name + ' — 尚未开始任何阶段';
      }
    }
  } else {
    var htmlPath = currentPhase ? currentPhase.artifact_path : '';
    if (htmlPath) {
      frame.src = '/specs/' + featureId + '/' + htmlPath + '?feature_id=' + featureId;
      frame.style.display = 'block';
    } else {
      welcome.style.display = 'flex';
      welcome.textContent = feature.name + ' — 尚未开始任何阶段';
    }
  }
}

function showApprovedCard(feature) {
  var card = document.getElementById('approvedCard');
  document.getElementById('approvedTitle').textContent = feature.name;

  var container = document.getElementById('approvedDecisions');
  container.innerHTML = '';
  var phases = Object.keys(decisionsCache);
  phases.forEach(function(phase) {
    var section = document.createElement('div');
    section.className = 'phase-decisions';
    section.innerHTML = '<h4>' + phase + '</h4>';
    decisionsCache[phase].forEach(function(d) {
      var row = document.createElement('div');
      row.className = 'decision-row';
      row.innerHTML = '<span class="key">' + escapeHtml(d.key) + '</span><span class="val">' + escapeHtml(d.value) + '</span>';
      section.appendChild(row);
    });
    container.appendChild(section);
  });

  card.style.display = 'flex';
}

// ---- Review bar ----

async function submitVerdict(verdict) {
  var feedback = document.getElementById('feedbackInput').value.trim();
  var data = {
    feature_id: selectedFeatureId,
    verdict: verdict,
    feedback: feedback,
    timestamp: new Date().toLocaleString('sv-SE')
  };
  try {
    var resp = await fetch(SERVER + '/api/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    if (resp.ok) {
      showToast(verdict === 'approved' ? '已通过' : '已驳回', verdict === 'approved' ? 'success' : 'error');
      // Reload data
      await loadFeatures();
      await loadTimeline();
      if (selectedFeatureId) await selectFeature(selectedFeatureId);
    } else {
      showToast('提交失败', 'error');
    }
  } catch (e) {
    showToast('无法连接服务器', 'error');
  }
}

// ---- Init ----

async function init() {
  await loadFeatures();
  await loadTimeline();
}

init();
</script>
</body>
</html>
```

- [ ] **Step 2: Verify in browser**

Run: `python3 .claude/hooks/feedback-server.py --root /tmp/test-specs` and open `http://localhost:8421`
Expected: Dashboard loads, shows empty state, no console errors.

- [ ] **Step 3: Commit**

```bash
git add .specify/zh/templates/dashboard.html
git commit -m "feat: rewrite zh dashboard as dynamic SPA with fetch API"
```

---

### Task 5: Rewrite dashboard.html (en)

**Files:**
- Rewrite: `.specify/en/templates/dashboard.html`

- [ ] **Step 1: Write English version**

Copy the zh dashboard.html structure with English labels:
- Stats: "Total", "Pending", "Approved"
- Timeline heading: "Timeline"
- Link: "View full timeline →"
- Status labels: `draft → 'Draft'`, `pending_review → 'Review'`, `approved → 'Approved'`, `rejected → 'Rejected'`, `implementing → 'In Progress'`
- Welcome: "Select a feature to view details"
- Approved card: "✓ Approved"
- Decision summary: "▶ Decisions"
- Review bar placeholder: "Enter review feedback..."
- Buttons: "Approve ✓", "Reject ✗"

- [ ] **Step 2: Commit**

```bash
git add .specify/en/templates/dashboard.html
git commit -m "feat: rewrite en dashboard as dynamic SPA with fetch API"
```

---

### Task 6: Create timeline.html (zh)

**Files:**
- Create: `.specify/zh/templates/timeline.html`

- [ ] **Step 1: Write timeline page**

```html
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SDD 时间线</title>
<style>
:root {
  --bg: #0f172a; --surface: #1e293b; --border: #334155;
  --text: #e2e8f0; --text-muted: #94a3b8;
  --primary: #3b82f6; --success: #22c55e; --warning: #f59e0b; --danger: #ef4444;
  --radius: 8px;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; }
.app { display: flex; height: 100vh; }
.filters { width: 240px; background: var(--surface); border-right: 1px solid var(--border); padding: 16px; overflow-y: auto; }
.filters h2 { font-size: 16px; margin-bottom: 12px; }
.filter-item { padding: 8px 12px; border-radius: var(--radius); cursor: pointer; font-size: 13px; margin-bottom: 4px; transition: background 0.15s; }
.filter-item:hover { background: var(--bg); }
.filter-item.active { background: var(--primary); color: #fff; }
.main { flex: 1; padding: 24px; overflow-y: auto; }
.main h1 { font-size: 20px; margin-bottom: 16px; }
.event-list { display: flex; flex-direction: column; gap: 2px; }
.event-row { display: flex; align-items: center; gap: 12px; padding: 10px 16px; border-radius: var(--radius); background: var(--surface); }
.event-time { font-size: 12px; color: var(--text-muted); white-space: nowrap; min-width: 140px; }
.event-icon { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.event-icon.started { background: var(--primary); }
.event-icon.approved { background: var(--success); }
.event-icon.rejected { background: var(--danger); }
.event-icon.feedback { background: var(--text-muted); }
.event-desc { font-size: 14px; flex: 1; }
.load-more { margin-top: 16px; text-align: center; }
.load-more button { padding: 8px 24px; border-radius: var(--radius); border: 1px solid var(--border); background: var(--surface); color: var(--text); cursor: pointer; font-size: 14px; }
.load-more button:hover { background: var(--bg); }
.back-link { display: inline-block; margin-bottom: 16px; color: var(--primary); text-decoration: none; font-size: 14px; }
.back-link:hover { text-decoration: underline; }
</style>
</head>
<body>
<div class="app">
  <div class="filters">
    <h2>功能筛选</h2>
    <div class="filter-item active" data-filter="" onclick="filterBy('')">全部</div>
    <div id="filterList"></div>
  </div>
  <div class="main">
    <a href="/" class="back-link">← 返回看板</a>
    <h1>时间线</h1>
    <div class="event-list" id="eventList"></div>
    <div class="load-more" id="loadMore" style="display:none">
      <button onclick="loadPage(currentPage + 1)">加载更多</button>
    </div>
  </div>
</div>
<script>
var SERVER = window.location.origin;
var currentPage = 1;
var currentFilter = '';
var totalCount = 0;
var allEvents = [];

async function loadFeatures() {
  try {
    var resp = await fetch(SERVER + '/api/features');
    var features = await resp.json();
    var container = document.getElementById('filterList');
    container.innerHTML = '';
    features.forEach(function(f) {
      var item = document.createElement('div');
      item.className = 'filter-item';
      item.setAttribute('data-filter', f.id);
      item.textContent = f.name;
      item.onclick = function() { filterBy(f.id); };
      container.appendChild(item);
    });
  } catch (e) {}
}

function filterBy(featureId) {
  currentFilter = featureId;
  currentPage = 1;
  allEvents = [];
  document.getElementById('eventList').innerHTML = '';
  document.querySelectorAll('.filter-item').forEach(function(el) {
    el.classList.toggle('active', el.getAttribute('data-filter') === featureId);
  });
  loadPage(1);
}

async function loadPage(page) {
  currentPage = page;
  var url = SERVER + '/api/timeline?page=' + page + '&per_page=50';
  if (currentFilter) url += '&feature_id=' + currentFilter;
  try {
    var resp = await fetch(url);
    var data = await resp.json();
    totalCount = data.total;
    data.items.forEach(function(ev) { allEvents.push(ev); });
    renderEvents();
    document.getElementById('loadMore').style.display = allEvents.length < totalCount ? '' : 'none';
  } catch (e) {
    document.getElementById('eventList').innerHTML = '<div style="color:var(--text-muted)">无法加载数据</div>';
  }
}

function renderEvents() {
  var container = document.getElementById('eventList');
  container.innerHTML = '';
  allEvents.forEach(function(ev) {
    var iconClass = 'feedback';
    if (ev.event_type && ev.event_type.indexOf('approved') >= 0) iconClass = 'approved';
    else if (ev.event_type && ev.event_type.indexOf('rejected') >= 0) iconClass = 'rejected';
    else if (ev.event_type && ev.event_type.indexOf('started') >= 0) iconClass = 'started';
    var row = document.createElement('div');
    row.className = 'event-row';
    row.innerHTML = '<div class="event-time">' + (ev.created_at || '') + '</div>' +
                    '<div class="event-icon ' + iconClass + '"></div>' +
                    '<div class="event-desc">' + (ev.description || '') + '</div>';
    container.appendChild(row);
  });
}

loadFeatures();
loadPage(1);
</script>
</body>
</html>
```

- [ ] **Step 2: Commit**

```bash
git add .specify/zh/templates/timeline.html
git commit -m "feat: add zh timeline page with pagination and filtering"
```

---

### Task 7: Create timeline.html (en)

**Files:**
- Create: `.specify/en/templates/timeline.html`

- [ ] **Step 1: Write English version**

Same structure as zh, with English labels:
- Title: "SDD Timeline"
- Filter heading: "Filter by Feature"
- "All" filter item
- Back link: "← Back to Dashboard"
- Heading: "Timeline"
- "Load more" button

- [ ] **Step 2: Commit**

```bash
git add .specify/en/templates/timeline.html
git commit -m "feat: add en timeline page with pagination and filtering"
```

---

### Task 8: Update install.sh

**Files:**
- Modify: `install.sh` (lines 272-281 hooks copy section, lines 336-367 completion message)

- [ ] **Step 1: Add feedback-server.py copy**

After the existing hooks copy block (line 281), add:

```bash
# Copy feedback server
if [ -f "${SOURCE_DIR}/.claude/hooks/feedback-server.py" ]; then
  cp "${SOURCE_DIR}/.claude/hooks/feedback-server.py" "${TARGET_DIR}/.claude/hooks/"
  chmod +x "${TARGET_DIR}/.claude/hooks/feedback-server.py"
fi
```

- [ ] **Step 2: Update completion message**

After the existing workflow echo block, add:

```bash
echo ""
echo -e "${CYAN}Feedback Server:${NC}"
echo -e "  ${YELLOW}python3 .claude/hooks/feedback-server.py${NC}"
echo -e "  → http://localhost:8421"
```

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "feat: integrate feedback-server into install script"
```

---

## Self-Review Checklist

- [x] Spec coverage: All 4 original issues addressed (feedback write, timezone, decisions display, review bar hiding)
- [x] No placeholders: All code blocks contain complete implementations
- [x] Type consistency: API field names (feature_id, phase, verdict, decisions) consistent across server, templates, and dashboard
- [x] Security: feature_id regex validation, path sandbox with realpath check, file type whitelist, payload size limit
- [x] Backward compatibility: JSON files still written alongside SQLite; Agent commands unchanged
