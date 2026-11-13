#!/usr/bin/env python3
"""Read bounded continuation context and check its consistency; never advance review cursors.

This complements improvement_gate.py. It does not replace preflight/history checks,
native verification, actual image inspection, or owner acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

from improvement_gate import GateError, ensure, read_json, safe_path

DOCS = 'docs/continuous_improvement'
CURRENT = f'{DOCS}/CURRENT.json'
STATE = 'docs/asset_base/STATE.json'
LOCK = 'docs/asset_base/CONTROL_SPRINT_LOCK.json'
START = 'docs/handover/START_HERE.md'
LIMITS = {CURRENT: 8192, STATE: 4096, LOCK: 4096, START: 6144}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def cursor(raw: bytes, reviewed: dict) -> int:
    size = reviewed.get('bytes')
    ensure(type(size) is int and 0 < size <= len(raw), 'Invalid issue cursor length')
    ensure(raw[:size].endswith(b'\n'), 'Issue cursor splits an event')
    ensure(sha(raw[:size]) == reviewed.get('sha256'), 'Issue cursor/history hash mismatch')
    return size


def validate(root: Path) -> dict:
    for path, maximum in LIMITS.items():
        p = safe_path(root, path)
        ensure(p.is_file() and p.stat().st_size <= maximum,
               f'Current context missing or oversized: {path} (limit {maximum} bytes)')
    current, state, lock = (read_json(root / p) for p in (CURRENT, STATE, LOCK))
    ensure(current.get('context_schema_version') == 1, 'Unsupported compact context schema')
    session_path = current.get('session')
    session = read_json(safe_path(root, session_path))
    sid = session.get('id')
    ensure(session_path == f'{DOCS}/sessions/{sid}.json', 'Session path does not match its ID')
    ensure(current.get('active_session') == sid, 'CURRENT session ID disagrees with session path')
    for name, record in (('STATE', state), ('LOCK', lock)):
        ensure(record.get('session') == sid and record.get('session_path') == session_path,
               f'{name} points to a different session')
        ensure(record.get('canonical_current') == CURRENT, f'{name} lacks canonical current pointer')
        ensure(record.get('branch') == current.get('branch'), f'{name} branch differs')
    ensure(session.get('status') in ('active', 'closed'), 'Session status must be active or closed')
    for name, record in (('CURRENT', current), ('STATE', state), ('LOCK', lock)):
        ensure(record.get('status') == session['status'], f'{name} status disagrees with session')
        ensure('writer' in record, f'{name} must explicitly record its writer')
        ensure(record.get('owner_approved') == session.get('owner_approved'), f'{name} approval differs')
    expected_writer = session.get('writer', {}).get('owner') if session['status'] == 'active' else None
    if session['status'] == 'active':
        ensure(bool(expected_writer), 'Active session needs an identified writer')
    else:
        ensure(session.get('writer', {}).get('status') == 'released', 'Closed session must release writer')
    ensure(all(r['writer'] == expected_writer for r in (current, state, lock)), 'Writer records disagree')
    action = session.get('next_action') if session['status'] == 'active' else session.get('closeout', {}).get('next_action')
    ensure(isinstance(action, str) and bool(action.strip()), 'Session needs one next action')
    ensure(current.get('next_action') == action and state.get('next_single_action') == action
           and lock.get('next_single_action') == action, 'Next-action records disagree')
    start = (root / START).read_text()
    for marker in (f'<!-- session: {sid} -->', f'<!-- status: {session["status"]} -->'):
        ensure(marker in start, 'Start-here session/status is stale')
    ensure(action in start, 'Start-here next action is stale')
    manifest_path = current.get('history_manifest')
    ensure(state.get('history_manifest') == manifest_path and lock.get('history_manifest') == manifest_path,
           'History pointers disagree')
    manifest = read_json(safe_path(root, manifest_path))
    entries = manifest.get('files')
    ensure(isinstance(entries, list) and bool(entries), 'History manifest is empty')
    archived = set()
    for entry in entries:
        p = safe_path(root, entry['archive'])
        ensure(p.is_file(), 'Archived history is missing: ' + entry['archive'])
        raw = p.read_bytes()
        ensure(len(raw) == entry['bytes'] and sha(raw) == entry['sha256'],
               'Archived history changed: ' + entry['archive'])
        archived.add(entry['original'])
    ensure(set(LIMITS).issubset(archived), 'Current records must retain their original history')
    issue_raw = (root / DOCS / 'ISSUES.jsonl').read_bytes()
    cursor(issue_raw, manifest['preserved_issue_prefix'])
    return {'context_check': 'pass', 'session': sid, 'status': session['status'],
            'writer': expected_writer, 'current_bytes': sum((root / p).stat().st_size for p in LIMITS),
            'archive_files_verified': len(entries), 'next_action': action}


def start(root: Path) -> dict:
    validate(root)
    current = read_json(root / CURRENT)
    session = read_json(safe_path(root, current['session']))
    return {'branch': current['branch'], 'session': current['session'], 'status': current['status'],
            'scope': current['scope'], 'writer': current['writer'], 'source': current['source'],
            'owner_approved': current['owner_approved'], 'next_action': current['next_action'],
            'roadmap': current['roadmap'], 'queue': current['queue'],
            'lesson_ids': session['lesson_ids'], 'reviewed_issue_cursor': session['issue_log_review'],
            'commands': ['python3 tools/project_context.py lessons --ids <relevant BM IDs>',
                         'python3 tools/project_context.py issues',
                         'python3 tools/project_context.py check',
                         f'python3 tools/improvement_gate.py check --session {current["session"]}'],
            'history': current['history_manifest'],
            'note': 'Only current context is printed. Read relevant lessons and new issue events; commands never mark them reviewed.'}


def lessons(root: Path, ids: list[str], full: bool = False) -> str:
    source = (root / DOCS / 'LESSONS.md').read_text()
    selected = []
    for lesson_id in ids:
        ensure(re.fullmatch(r'BM-\d{2,}', lesson_id) is not None, 'Invalid lesson ID')
        match = re.search(r'^### ' + re.escape(lesson_id) + r'\s*\n(.*?)(?=^## |^### |\Z)',
                          source, flags=re.M | re.S)
        ensure(match is not None, 'Lesson not found: ' + lesson_id)
        body = match.group(1).strip()
        if not full:
            body = '\n'.join(line for line in body.splitlines() if line.startswith('**'))
        selected.append('### ' + lesson_id + '\n' + body)
    if full:
        # Later dated clarifications live outside the original BM blocks.
        # Include each relevant section once, even when its heading names
        # several selected lessons. Keep exact IDs (BM-22 is not BM-220).
        wanted = set(ids)
        for match in re.finditer(r'^## ([^\n]+)\n(.*?)(?=^## |\Z)', source, flags=re.M | re.S):
            heading_ids = set(re.findall(r'\bBM-\d{2,}\b', match.group(1)))
            if wanted & heading_ids:
                selected.append(match.group(0).strip())
    return '\n\n'.join(selected) + '\n'


def issues(root: Path, session_path: str | None = None, limit: int = 20,
           after: dict | None = None) -> dict:
    ensure(type(limit) is int and 1 <= limit <= 50, 'Issue limit must be 1–50')
    if session_path is None:
        session_path = read_json(root / CURRENT)['session']
    session = read_json(safe_path(root, session_path))
    raw = (root / DOCS / 'ISSUES.jsonl').read_bytes()
    size = cursor(raw, after if after is not None else session['issue_log_review'])
    ensure(raw.endswith(b'\n'), 'Issue log has an incomplete final event')
    lines = raw[size:].splitlines(keepends=True)
    page = lines[:limit]
    end = size + sum(map(len, page))
    return {'events': [json.loads(line) for line in page], 'has_more': len(lines) > limit,
            'read_cursor': {'bytes': end, 'sha256': sha(raw[:end])},
            'reviewed_cursor_unchanged': True,
            'note': 'Read all events before explicitly updating the session review. Continue with --after-bytes/--after-sha256 from read_cursor; do not skip events.'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('start')
    sub.add_parser('check')
    p = sub.add_parser('lessons'); p.add_argument('--ids', nargs='+', required=True); p.add_argument('--full', action='store_true')
    p = sub.add_parser('issues'); p.add_argument('--since-session'); p.add_argument('--limit', type=int, default=20)
    p.add_argument('--after-bytes', type=int); p.add_argument('--after-sha256')
    args = parser.parse_args()
    try:
        if args.command == 'lessons':
            print(lessons(args.root, args.ids, args.full), end='')
        else:
            after = None
            if args.command == 'issues':
                ensure((args.after_bytes is None) == (args.after_sha256 is None), 'Both explicit cursor fields are required')
                if args.after_bytes is not None:
                    after = {'bytes': args.after_bytes, 'sha256': args.after_sha256}
            value = start(args.root) if args.command == 'start' else validate(args.root) if args.command == 'check' else issues(args.root, args.since_session, args.limit, after)
            print(json.dumps(value, ensure_ascii=False, indent=2))
    except (GateError, OSError, ValueError, KeyError) as exc:
        print('PROJECT CONTEXT FAILED: ' + str(exc)); return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
