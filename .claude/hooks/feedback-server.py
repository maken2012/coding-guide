#!/usr/bin/env python3
"""feedback-server.py — Lightweight HTTP server for SDD feedback bridge.

Provides REST API for feedback submission and static file serving for specs.
Uses only Python standard library (http.server, sqlite3, json, re, os, datetime).

Usage:
    python3 feedback-server.py [--port PORT] [--root PROJECT_ROOT]
"""

import argparse
import json
import mimetypes
import os
import re
import signal
import sqlite3
import sys
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VALID_FEATURE_ID = re.compile(r'^\d{8}-\d{3}-[a-zA-Z0-9_-]+$')
VALID_PHASES = ('spec', 'detail', 'design', 'plan', 'implement', 'review')
VALID_VERDICTS = ('approved', 'rejected')
MAX_PAYLOAD = 1 * 1024 * 1024  # 1 MB

DB_NAME = 'sdd.db'

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def get_db(specs_root):
    """Return (conn, cursor) for the SQLite database inside specs_root."""
    db_path = os.path.join(specs_root, DB_NAME)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute('PRAGMA journal_mode=WAL')
    conn.execute('PRAGMA foreign_keys=ON')
    _init_schema(conn)
    return conn


def _init_schema(conn):
    """Create tables if they don't exist."""
    conn.executescript("""
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
    """)
    conn.commit()


def now_str():
    """Current local time as 'YYYY-MM-DD HH:MM:SS'."""
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')

# ---------------------------------------------------------------------------
# SPECS_ROOT auto-detection
# ---------------------------------------------------------------------------

def detect_specs_root(start_dir=None):
    """Walk up from *start_dir* looking for .specify/specs/."""
    d = os.path.abspath(start_dir or os.getcwd())
    while True:
        candidate = os.path.join(d, '.specify', 'specs')
        if os.path.isdir(candidate):
            return candidate
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent

# ---------------------------------------------------------------------------
# Request handler
# ---------------------------------------------------------------------------

class FeedbackHandler(BaseHTTPRequestHandler):
    """Handles API and static file requests for the SDD feedback system."""

    specs_root = ''   # set once at server start

    # ---- helpers ----------------------------------------------------------

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_error_json(self, message, status=400):
        self._send_json({'error': message}, status)

    def _read_body(self):
        length = int(self.headers.get('Content-Length', 0))
        if length > MAX_PAYLOAD:
            return None, 'Payload exceeds 1 MB limit'
        raw = self.rfile.read(length)
        try:
            return json.loads(raw), None
        except (json.JSONDecodeError, ValueError):
            return None, 'Invalid JSON'

    def _sandbox_path(self, relative):
        """Resolve *relative* inside specs_root, reject path traversal."""
        real_root = os.path.realpath(self.specs_root)
        target = os.path.realpath(os.path.join(self.specs_root, relative))
        if not target.startswith(real_root + os.sep) and target != real_root:
            return None
        return target

    def _detect_lang_dir(self):
        """Return the language-specific templates dir (zh or en)."""
        project_root = os.path.dirname(os.path.dirname(self.specs_root))
        for lang in ('zh', 'en'):
            d = os.path.join(project_root, '.specify', lang, 'templates')
            if os.path.isdir(d):
                return os.path.dirname(d)  # .specify/{lang}
        return None

    # ---- routing ----------------------------------------------------------

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip('/') or '/'

        # Dashboard page
        if path == '/':
            self._serve_template('dashboard.html')
            return

        # Timeline page
        if path == '/timeline':
            self._serve_template('timeline.html')
            return

        # Static files under /specs/
        if path.startswith('/specs/'):
            rel = path[len('/specs/'):]
            self._serve_static(rel)
            return

        # API routes
        if path == '/api/features':
            return self._api_features()
        if path.startswith('/api/phases/'):
            fid = path[len('/api/phases/'):]
            return self._api_phases(fid)
        if path.startswith('/api/decisions/'):
            fid = path[len('/api/decisions/'):]
            return self._api_decisions(fid)
        if path == '/api/timeline':
            qs = parse_qs(parsed.query)
            return self._api_timeline(qs)

        self._send_error_json('Not found', 404)

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip('/')

        if path == '/api/feedback':
            return self._api_feedback()

        self._send_error_json('Not found', 404)

    # ---- static serving ---------------------------------------------------

    def _serve_static(self, relative_path):
        safe = self._sandbox_path(relative_path)
        if safe is None:
            self._send_error_json('Forbidden: path traversal', 403)
            return
        if not os.path.isfile(safe):
            self._send_error_json('Not found', 404)
            return
        mime, _ = mimetypes.guess_type(safe)
        if mime is None:
            mime = 'application/octet-stream'
        try:
            with open(safe, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', mime)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except OSError as exc:
            self._send_error_json(str(exc), 500)

    def _serve_template(self, filename):
        """Serve a template file (dashboard.html, timeline.html, etc.) from language-specific templates directory."""
        lang_dir = self._detect_lang_dir()
        if lang_dir is None:
            self._send_error_json('No language templates found', 404)
            return
        for lang in ('zh', 'en'):
            candidate = os.path.join(
                os.path.dirname(lang_dir), '.specify', lang, 'templates', filename
            )
            candidate = os.path.realpath(candidate)
            if os.path.isfile(candidate):
                self._serve_absolute(candidate)
                return
        self._send_error_json(filename + ' not found', 404)

    def _serve_absolute(self, filepath):
        mime, _ = mimetypes.guess_type(filepath)
        if mime is None:
            mime = 'text/html'
        try:
            with open(filepath, 'rb') as f:
                data = f.read()
            self.send_response(200)
            self.send_header('Content-Type', mime)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except OSError as exc:
            self._send_error_json(str(exc), 500)

    # ---- API handlers -----------------------------------------------------

    def _api_features(self):
        conn = get_db(self.specs_root)
        try:
            rows = conn.execute('SELECT * FROM features ORDER BY created_at DESC').fetchall()
            self._send_json([dict(r) for r in rows])
        finally:
            conn.close()

    def _api_phases(self, feature_id):
        if not VALID_FEATURE_ID.match(feature_id):
            self._send_error_json('Invalid feature_id')
            return
        conn = get_db(self.specs_root)
        try:
            rows = conn.execute(
                'SELECT * FROM phases WHERE feature_id = ? ORDER BY phase',
                (feature_id,)
            ).fetchall()
            self._send_json([dict(r) for r in rows])
        finally:
            conn.close()

    def _api_decisions(self, feature_id):
        if not VALID_FEATURE_ID.match(feature_id):
            self._send_error_json('Invalid feature_id')
            return
        conn = get_db(self.specs_root)
        try:
            rows = conn.execute(
                'SELECT phase, decision_key, decision_value FROM decisions WHERE feature_id = ? ORDER BY id',
                (feature_id,)
            ).fetchall()
            grouped = {}
            for r in rows:
                phase = r['phase']
                grouped.setdefault(phase, []).append({
                    'key': r['decision_key'],
                    'value': r['decision_value'],
                })
            self._send_json(grouped)
        finally:
            conn.close()

    def _api_timeline(self, qs):
        limit = qs.get('limit', [None])[0]
        page = qs.get('page', ['1'])[0]
        per_page = qs.get('per_page', ['50'])[0]
        feature_id = qs.get('feature_id', [None])[0]

        try:
            page = int(page)
            per_page = int(per_page)
        except ValueError:
            self._send_error_json('Invalid page or per_page')
            return

        conn = get_db(self.specs_root)
        try:
            where_clause = ''
            params = []
            if feature_id:
                where_clause = 'WHERE feature_id = ?'
                params.append(feature_id)

            total = conn.execute(
                f'SELECT COUNT(*) FROM timeline {where_clause}', params
            ).fetchone()[0]

            if limit is not None:
                try:
                    limit_val = int(limit)
                    rows = conn.execute(
                        f'SELECT * FROM timeline {where_clause} ORDER BY id DESC LIMIT ?',
                        params + [limit_val]
                    ).fetchall()
                except ValueError:
                    self._send_error_json('Invalid limit')
                    return
            else:
                offset = (page - 1) * per_page
                rows = conn.execute(
                    f'SELECT * FROM timeline {where_clause} ORDER BY id DESC LIMIT ? OFFSET ?',
                    params + [per_page, offset]
                ).fetchall()

            items = [dict(r) for r in rows]
            self._send_json({
                'items': items,
                'total': total,
                'page': page,
                'per_page': per_page,
            })
        finally:
            conn.close()

    def _api_feedback(self):
        body, err = self._read_body()
        if err:
            self._send_error_json(err)
            return

        # --- validate fields ---
        feature_id = body.get('feature_id', '')
        if not VALID_FEATURE_ID.match(feature_id):
            self._send_error_json('Invalid feature_id')
            return

        phase = body.get('phase', '')
        if phase not in VALID_PHASES:
            self._send_error_json('Invalid phase')
            return

        verdict = body.get('verdict', '')
        if verdict not in VALID_VERDICTS:
            self._send_error_json('Invalid verdict')
            return

        feedback_text = body.get('feedback', '')
        decisions = body.get('decisions', {})
        timestamp = body.get('timestamp', '') or now_str()

        # --- sandbox path for feedback JSON ---
        rel_dir = os.path.join(feature_id)
        safe_dir = self._sandbox_path(rel_dir)
        if safe_dir is None:
            self._send_error_json('Invalid feature path')
            return

        # Ensure the feature directory exists
        os.makedirs(safe_dir, exist_ok=True)

        filename = f'{phase}.feedback.json'
        target_path = os.path.join(safe_dir, filename)

        # Verify the resolved target is still inside sandbox
        real_root = os.path.realpath(self.specs_root)
        if not os.path.realpath(target_path).startswith(real_root + os.sep):
            self._send_error_json('Path traversal denied', 403)
            return

        # Only allow writing {phase}.feedback.json files
        if not re.match(r'^[a-z]+\.feedback\.json$', filename):
            self._send_error_json('Invalid feedback filename')
            return

        # --- build feedback JSON (agent-compatible) ---
        now = now_str()
        feedback_obj = {
            'artifact': f'{phase}.html',
            'feature': feature_id,
            'phase': phase,
            'status': 'reviewed',
            'decisions': decisions if isinstance(decisions, dict) else {},
            'review': {
                'verdict': verdict,
                'feedback': feedback_text,
                'timestamp': timestamp,
            },
            'created_at': timestamp,
            'updated_at': now,
        }

        # --- write JSON file ---
        try:
            with open(target_path, 'w', encoding='utf-8') as f:
                json.dump(feedback_obj, f, ensure_ascii=False, indent=2)
        except OSError as exc:
            self._send_error_json(f'Write failed: {exc}', 500)
            return

        # --- write to SQLite ---
        conn = get_db(self.specs_root)
        try:
            # Upsert features
            conn.execute("""
                INSERT INTO features (id, name, current_phase, status, created_at, updated_at)
                VALUES (?, ?, ?, 'active', ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    current_phase = excluded.current_phase,
                    status = excluded.status,
                    updated_at = excluded.updated_at
            """, (feature_id, feature_id, phase, timestamp, now))

            # Upsert phases
            conn.execute("""
                INSERT INTO phases (feature_id, phase, status, artifact_path, updated_at)
                VALUES (?, ?, 'reviewed', ?, ?)
                ON CONFLICT(feature_id, phase) DO UPDATE SET
                    status = excluded.status,
                    artifact_path = excluded.artifact_path,
                    updated_at = excluded.updated_at
            """, (feature_id, phase, f'{phase}.html', now))

            # Delete old decisions for this feature+phase, then insert new ones
            conn.execute(
                'DELETE FROM decisions WHERE feature_id = ? AND phase = ?',
                (feature_id, phase)
            )
            if isinstance(decisions, dict):
                for key, value in decisions.items():
                    conn.execute(
                        'INSERT INTO decisions (feature_id, phase, decision_key, decision_value, created_at) VALUES (?, ?, ?, ?, ?)',
                        (feature_id, phase, str(key), str(value), now)
                    )

            # Insert timeline event
            event_type = f'phase_{verdict}'
            description = f'{feature_id} {phase} {verdict}'
            conn.execute(
                'INSERT INTO timeline (feature_id, event_type, description, created_at) VALUES (?, ?, ?, ?)',
                (feature_id, event_type, description, now)
            )

            conn.commit()
        except sqlite3.Error as exc:
            conn.rollback()
            self._send_error_json(f'Database error: {exc}', 500)
            return
        finally:
            conn.close()

        self._send_json({'ok': True})

    # ---- logging ----------------------------------------------------------

    def log_message(self, format, *args):
        sys.stderr.write('[feedback-server] %s - %s\n' %
                         (self.log_date_time_string(), format % args))

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description='SDD Feedback Server')
    parser.add_argument('--port', type=int, default=8421, help='Port to listen on (default: 8421)')
    parser.add_argument('--root', type=str, default=None, help='Project root directory')
    args = parser.parse_args()

    # Resolve specs_root
    if args.root:
        abs_root = os.path.abspath(args.root)
        # If user passed the specs dir directly, use it; otherwise append .specify/specs
        if os.path.isdir(abs_root) and abs_root.endswith(os.sep + 'specs'):
            specs_root = abs_root
        else:
            specs_root = os.path.join(abs_root, '.specify', 'specs')
    else:
        specs_root = detect_specs_root()

    if not specs_root or not os.path.isdir(specs_root):
        print(f'ERROR: .specify/specs/ not found', file=sys.stderr)
        print('Run from project root or specify --root /path/to/project', file=sys.stderr)
        sys.exit(1)

    FeedbackHandler.specs_root = specs_root
    os.makedirs(specs_root, exist_ok=True)

    server = HTTPServer(('127.0.0.1', args.port), FeedbackHandler)

    def shutdown(sig, frame):
        print('\nShutting down...')
        server.server_close()
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    print(f'SDD Feedback Server')
    print(f'  URL:        http://127.0.0.1:{args.port}')
    print(f'  Specs root: {specs_root}')
    print(f'  Database:   {os.path.join(specs_root, DB_NAME)}')
    print(f'  Ctrl+C to stop')
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
