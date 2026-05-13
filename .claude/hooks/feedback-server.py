#!/usr/bin/env python3
"""feedback-server.py — Lightweight HTTP server for SDD feedback bridge.

Provides REST API for feedback submission and static file serving for specs.
Uses only Python standard library (http.server, sqlite3, json, re, os, datetime).

Usage:
    python3 feedback-server.py [--port PORT] [--root PROJECT_ROOT]
"""

import argparse
import glob
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
        CREATE TABLE IF NOT EXISTS sync_log (
            file_path TEXT PRIMARY KEY,
            file_mtime TEXT,
            sync_status TEXT DEFAULT 'pending',
            synced_at TEXT,
            error TEXT
        );
    """)
    conn.commit()


def now_str():
    """Current local time as 'YYYY-MM-DD HH:MM:SS'."""
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')

# ---------------------------------------------------------------------------
# Sync: filesystem → SQLite
# ---------------------------------------------------------------------------

def _get_mtime(filepath):
    try:
        return str(os.path.getmtime(filepath))
    except OSError:
        return None


def _is_synced(conn, rel_path, mtime):
    """Check if file was already synced with current mtime."""
    row = conn.execute(
        'SELECT sync_status, file_mtime FROM sync_log WHERE file_path = ?',
        (rel_path,)
    ).fetchone()
    return row is not None and row['sync_status'] == 'synced' and row['file_mtime'] == mtime


def _mark_synced(conn, rel_path, mtime, now):
    conn.execute(
        'INSERT INTO sync_log (file_path, file_mtime, sync_status, synced_at) '
        'VALUES (?, ?, ?, ?) '
        'ON CONFLICT(file_path) DO UPDATE SET file_mtime=excluded.file_mtime, '
        'sync_status=excluded.sync_status, synced_at=excluded.synced_at, error=NULL',
        (rel_path, mtime, 'synced', now)
    )


def _mark_failed(conn, rel_path, mtime, now, error):
    conn.execute(
        'INSERT INTO sync_log (file_path, file_mtime, sync_status, synced_at, error) '
        'VALUES (?, ?, ?, ?, ?) '
        'ON CONFLICT(file_path) DO UPDATE SET file_mtime=excluded.file_mtime, '
        'sync_status=excluded.sync_status, synced_at=excluded.synced_at, error=excluded.error',
        (rel_path, mtime, 'failed', now, error)
    )


def _process_feature_state(conn, filepath, now):
    """Parse and upsert a single .feature-state.json."""
    with open(filepath, 'r', encoding='utf-8') as f:
        state = json.load(f)

    fid = state.get('id', '')
    if not VALID_FEATURE_ID.match(fid):
        return 0

    name = state.get('name', fid)
    pipeline = state.get('pipeline', {})
    closed_at = state.get('closed_at')

    current_phase = ''
    overall_status = 'draft'
    if closed_at:
        overall_status = 'closed'
    for phase_name in ('spec', 'detail', 'design', 'plan', 'implement', 'review'):
        phase_info = pipeline.get(phase_name, {})
        if not phase_info:
            continue
        status = phase_info.get('status', 'not_started')
        if status in ('in_progress', 'pending_review'):
            current_phase = phase_name
            if not closed_at:
                overall_status = status if status != 'in_progress' else 'implementing'
        elif status == 'approved':
            current_phase = phase_name
            if not closed_at:
                overall_status = 'approved'
        elif status == 'rejected':
            current_phase = phase_name
            if not closed_at:
                overall_status = 'rejected'

    conn.execute(
        'INSERT INTO features (id, name, current_phase, status, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET name=excluded.name, current_phase=excluded.current_phase, '
        'status=excluded.status, updated_at=excluded.updated_at',
        (fid, name, current_phase, overall_status, now, now)
    )

    phase_count = 0
    for phase_name in ('spec', 'detail', 'design', 'plan', 'implement', 'review'):
        phase_info = pipeline.get(phase_name, {})
        if not phase_info:
            continue
        ps = phase_info.get('status', 'not_started')
        if ps == 'not_started':
            continue
        artifact = phase_info.get('artifact', '')
        conn.execute(
            'INSERT INTO phases (feature_id, phase, status, artifact_path, updated_at) '
            'VALUES (?, ?, ?, ?, ?) '
            'ON CONFLICT(feature_id, phase) DO UPDATE SET status=excluded.status, '
            'artifact_path=excluded.artifact_path, updated_at=excluded.updated_at',
            (fid, phase_name, ps, artifact, now)
        )
        phase_count += 1

    return phase_count


def _process_feedback_file(conn, filepath, now):
    """Parse and upsert a single .feedback.json."""
    with open(filepath, 'r', encoding='utf-8') as f:
        fb = json.load(f)

    fid = fb.get('feature', '')
    phase = fb.get('phase', '')
    if not fid or not phase:
        return

    decisions = fb.get('decisions', {})
    if decisions:
        conn.execute('DELETE FROM decisions WHERE feature_id = ? AND phase = ?', (fid, phase))
        if isinstance(decisions, dict):
            for k, v in decisions.items():
                conn.execute(
                    'INSERT INTO decisions (feature_id, phase, decision_key, decision_value, created_at) '
                    'VALUES (?, ?, ?, ?, ?)',
                    (fid, phase, str(k), json.dumps(v, ensure_ascii=False) if not isinstance(v, str) else v, now)
                )
        elif isinstance(decisions, list):
            for d in decisions:
                if isinstance(d, dict):
                    sel = d.get('selected')
                    if sel:
                        conn.execute(
                            'INSERT INTO decisions (feature_id, phase, decision_key, decision_value, created_at) '
                            'VALUES (?, ?, ?, ?, ?)',
                            (fid, phase, d.get('id', '?'), str(sel), now)
                        )

    review = fb.get('review', {})
    if review.get('verdict'):
        existing = conn.execute(
            'SELECT id FROM timeline WHERE feature_id = ? AND event_type LIKE ?',
            (fid, '%' + review['verdict'])
        ).fetchone()
        if not existing:
            conn.execute(
                'INSERT INTO timeline (feature_id, event_type, description, created_at) VALUES (?, ?, ?, ?)',
                (fid, 'phase_' + review['verdict'], f'{fid} {phase} {review["verdict"]}', now)
            )


def sync_from_filesystem(specs_root):
    """Sync only new/changed/failed files to SQLite. Skip already-synced ones.

    Per-file tracking via sync_log table:
    - Already synced with same mtime → skip
    - New / changed mtime / previously failed → process
    - Success → mark synced
    - Failure → mark failed (will be retried next call)
    """
    state_files = glob.glob(os.path.join(specs_root, '*', '.feature-state.json'))
    feedback_files = glob.glob(os.path.join(specs_root, '*', '*.feedback.json'))

    if not state_files and not feedback_files:
        return {'ok': True, 'scanned': 0, 'skipped': 0, 'synced': 0, 'failed': 0, 'details': []}

    result = {'ok': True, 'scanned': 0, 'skipped': 0, 'synced': 0, 'failed': 0, 'details': []}
    conn = get_db(specs_root)
    try:
        now = now_str()

        for filepath in state_files + feedback_files:
            rel = os.path.relpath(filepath, specs_root)
            mtime = _get_mtime(filepath)
            result['scanned'] += 1

            # Skip if already synced with same mtime
            if mtime and _is_synced(conn, rel, mtime):
                result['skipped'] += 1
                result['details'].append({'file': rel, 'action': 'skipped'})
                continue

            # Process the file
            try:
                if filepath.endswith('.feature-state.json'):
                    _process_feature_state(conn, filepath, now)
                elif filepath.endswith('.feedback.json'):
                    _process_feedback_file(conn, filepath, now)

                if mtime:
                    _mark_synced(conn, rel, mtime, now)
                result['synced'] += 1
                result['details'].append({'file': rel, 'action': 'synced'})
            except Exception as e:
                if mtime:
                    _mark_failed(conn, rel, mtime, now, str(e))
                result['failed'] += 1
                result['details'].append({'file': rel, 'action': 'failed', 'error': str(e)})

        conn.commit()
    finally:
        conn.close()
    return result

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
        """Return the templates directory path.

        Supports two layouts:
        - Installed: .specify/templates/ (no locale subdirectory)
        - Source dev: .specify/zh/templates/ or .specify/en/templates/
        """
        project_root = os.path.dirname(os.path.dirname(self.specs_root))
        direct = os.path.join(project_root, '.specify', 'templates')
        if os.path.isdir(direct):
            return direct
        for lang in ('zh', 'en'):
            d = os.path.join(project_root, '.specify', lang, 'templates')
            if os.path.isdir(d):
                return d
        return None

    # ---- routing ----------------------------------------------------------

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip('/') or '/'

        if path == '/':
            self._serve_template('dashboard.html')
            return
        if path == '/timeline':
            self._serve_template('timeline.html')
            return
        if path.startswith('/specs/'):
            rel = path[len('/specs/'):]
            self._serve_static(rel)
            return

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
        if path == '/api/sync':
            return self._api_sync()

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
        templates_dir = self._detect_lang_dir()
        if templates_dir is None:
            self._send_error_json('No language templates found', 404)
            return
        candidate = os.path.realpath(os.path.join(templates_dir, filename))
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

    def _api_sync(self):
        """Agent-triggered sync. Only processes new/changed/failed files."""
        result = sync_from_filesystem(self.specs_root)
        result['timestamp'] = now_str()
        self._send_json(result)

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

        # --- sandbox path ---
        rel_dir = os.path.join(feature_id)
        safe_dir = self._sandbox_path(rel_dir)
        if safe_dir is None:
            self._send_error_json('Invalid feature path')
            return

        os.makedirs(safe_dir, exist_ok=True)

        filename = f'{phase}.feedback.json'
        target_path = os.path.join(safe_dir, filename)

        real_root = os.path.realpath(self.specs_root)
        if not os.path.realpath(target_path).startswith(real_root + os.sep):
            self._send_error_json('Path traversal denied', 403)
            return

        if not re.match(r'^[a-z]+\.feedback\.json$', filename):
            self._send_error_json('Invalid feedback filename')
            return

        # --- build feedback JSON ---
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
                'timestamp': now,
            },
            'created_at': now,
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
            conn.execute("""
                INSERT INTO features (id, name, current_phase, status, created_at, updated_at)
                VALUES (?, ?, ?, 'active', ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    current_phase = excluded.current_phase,
                    status = excluded.status,
                    updated_at = excluded.updated_at
            """, (feature_id, feature_id, phase, now, now))

            conn.execute("""
                INSERT INTO phases (feature_id, phase, status, artifact_path, updated_at)
                VALUES (?, ?, 'reviewed', ?, ?)
                ON CONFLICT(feature_id, phase) DO UPDATE SET
                    status = excluded.status,
                    artifact_path = excluded.artifact_path,
                    updated_at = excluded.updated_at
            """, (feature_id, phase, f'{phase}.html', now))

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

            event_type = f'phase_{verdict}'
            description = f'{feature_id} {phase} {verdict}'
            conn.execute(
                'INSERT INTO timeline (feature_id, event_type, description, created_at) VALUES (?, ?, ?, ?)',
                (feature_id, event_type, description, now)
            )

            # Mark feedback file as synced in sync_log
            rel_feedback = os.path.relpath(target_path, self.specs_root)
            mtime = _get_mtime(target_path)
            if mtime:
                _mark_synced(conn, rel_feedback, mtime, now)

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

    if args.root:
        abs_root = os.path.abspath(args.root)
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
