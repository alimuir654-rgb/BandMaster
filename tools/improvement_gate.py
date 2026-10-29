#!/usr/bin/env python3
"""Validate the mandatory work preflight and append-only improvement log.

Standard library only. This checks evidence records, not artistic merit.
"""
from __future__ import annotations
import argparse
import fnmatch
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

DOCS = 'docs/continuous_improvement'
REQUIRED_DOCS = (f'{DOCS}/LESSONS.md', f'{DOCS}/CHECK_BEFORE_WORK.md')
HEX = re.compile(r'^[0-9a-f]{64}$')

class GateError(ValueError):
    """A required, verifiable work contract was not satisfied."""

def ensure(condition: bool, message: str) -> None:
    if not condition:
        raise GateError(message)

def safe_path(root: Path, relative: str) -> Path:
    ensure(isinstance(relative, str) and bool(relative), 'Missing relative path')
    p = PurePosixPath(relative)
    ensure(not p.is_absolute() and '..' not in p.parts and '\\' not in relative,
           f'Unsafe path: {relative}')
    target = (root / relative).resolve()
    ensure(target.is_relative_to(root.resolve()), f'Path escapes repository: {relative}')
    return target

def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        raise GateError(f'Cannot read JSON {path}: {exc}') from exc
    ensure(isinstance(data, dict), f'Expected object: {path}')
    return data

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def issue_events(root: Path) -> tuple[bytes, list[dict[str, Any]]]:
    path = root / DOCS / 'ISSUES.jsonl'
    try:
        raw = path.read_bytes()
    except OSError as exc:
        raise GateError(f'Missing issue log: {exc}') from exc
    ensure(bool(raw) and raw.endswith(b'\n'), 'Issue log must be nonempty newline-terminated JSONL')
    events: list[dict[str, Any]] = []
    seen: set[str] = set()
    for number, line in enumerate(raw.splitlines(), 1):
        try:
            event = json.loads(line)
        except ValueError as exc:
            raise GateError(f'Invalid issue event at line {number}') from exc
        ensure(isinstance(event, dict), f'Issue line {number} is not an object')
        key = event.get('event_id') or f"{event.get('event')}:{event.get('id')}"
        ensure(isinstance(key, str) and key not in seen, f'Duplicate issue event: {key}')
        ensure(event.get('event') in {'lesson_recorded','new_issue','recurrence','verified_resolution','review'},
               f'Unknown issue event: {key}')
        ensure(re.fullmatch(r'BM-\d{2,}', str(event.get('id',''))) is not None, f'Invalid lesson ID: {key}')
        ensure(bool(event.get('observation')), f'Missing observation: {key}')
        seen.add(key); events.append(event)
    return raw, events

def git(root: Path, *arguments: str) -> str:
    result = subprocess.run(['git', '-C', str(root), *arguments], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    ensure(result.returncode == 0, 'Git check failed: ' + result.stderr.strip())
    return result.stdout

def check(root: Path, session_path: str, before: str | None = None,
          require_prior_record: bool = False) -> dict[str, Any]:
    session = read_json(safe_path(root, session_path))
    ensure(session.get('schema_version') == 1, 'Unsupported session schema')
    ensure(session.get('status') in {'active','closed'}, 'Session must be active or closed')
    ensure(session.get('owner_approved') is False, 'This gate does not confer owner approval')
    for field in ['id','owner_request','baseline_sha','dominant_issue','hypothesis','stop_condition']:
        ensure(isinstance(session.get(field), str) and bool(session[field].strip()), f'Missing {field}')
    ensure(re.fullmatch(r'[0-9a-f]{40}',session['baseline_sha']) is not None,'Invalid baseline SHA')
    reviewed = session.get('reviewed_documents', {})
    ensure(isinstance(reviewed, dict), 'reviewed_documents must be an object')
    for name in REQUIRED_DOCS:
        p = safe_path(root, name)
        ensure(p.is_file(), f'Missing required document: {name}')
        ensure(reviewed.get(name) == digest(p.read_bytes()), f'Stale/unread policy: {name}')
    raw, events = issue_events(root)
    prefix = session.get('issue_log_review', {})
    size = prefix.get('bytes', -1)
    ensure(isinstance(size, int) and not isinstance(size, bool) and 0 < size <= len(raw), 'Invalid reviewed issue prefix')
    ensure(raw[:size].endswith(b'\n'), 'Reviewed issue prefix ends inside an event')
    ensure(prefix.get('sha256') == digest(raw[:size]), 'Reviewed issue history was rewritten or hash is stale')
    ensure(size == len(raw) or session.get('status') == 'closed', 'New issue events need review before continuing')
    ids = {e['id'] for e in events}
    selected = session.get('lesson_ids')
    ensure(isinstance(selected, list) and bool(selected) and all(i in ids for i in selected), 'Missing/unknown lesson IDs')
    ensure(session['dominant_issue'] in selected, 'Dominant issue must be among reviewed lessons')
    target = session.get('target', {})
    ensure(isinstance(target,dict) and HEX.fullmatch(str(target.get('original_sha256',''))) is not None,
           'Target original SHA256 is required')
    ensure(bool(target.get('locator')) and target.get('pixels_inspected') is True,
           'Target must have an explicit locator and recorded pixel inspection')
    ensure(bool(session.get('controlled_comparison')), 'Missing controlled comparison contract')
    paths = session.get('allowed_paths')
    ensure(isinstance(paths,list) and bool(paths), 'No scoped paths')
    for pattern in paths:
        ensure(isinstance(pattern,str) and pattern not in {'*','**','**/*'}, 'Unbounded path scope is forbidden')
        safe_path(root,pattern)
    ensure(isinstance(session.get('validation_commands'),list) and bool(session['validation_commands']), 'No validation commands')
    if before is not None:
        ensure(re.fullmatch(r'[0-9a-f]{40}',before) is not None, 'Invalid before SHA')
        names = git(root,'diff','--name-only',before,'HEAD').splitlines()
        for name in names:
            ensure(any(fnmatch.fnmatchcase(name,p) for p in paths),f'Unscoped change: {name}')
        old = subprocess.run(['git','-C',str(root),'show',before+':'+DOCS+'/ISSUES.jsonl'],
                             stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=False)
        if old.returncode == 0:
            ensure(raw.startswith(old.stdout),'Issue log is append-only; previous events changed')
        if require_prior_record:
            old_session = git(root,'show',before+':'+session_path)
            previous = json.loads(old_session)
            ensure(previous.get('id')==session['id'] and previous.get('status')=='active',
                   'Implementation requires an already committed active preflight')
    if session['status']=='closed':
        close = session.get('closeout',{})
        for key in ['tested_sha','evidence','visual_verdict','next_action','new_issue_review']:
            ensure(bool(close.get(key)),f'Closeout missing {key}')
        ensure(close['visual_verdict'] in ['hold','partial','internal_pass'], 'Invalid visual verdict')
    return {'session':session['id'],'status':session['status'],'lessons_reviewed':len(selected),
            'issue_events':len(events),'record_gate':'pass','artistic_approval':False}

def append_event(root: Path, source: Path) -> None:
    raw, events = issue_events(root)
    event = read_json(source)
    for key in ['event_id','id','event','observation','expected','evidence','severity','cause_confidence','prevention','verification','recorded_at','owner_role','affected_paths','next_action']:
        ensure(bool(event.get(key)), f'New event missing {key}')
    ensure(event['event'] in ['new_issue','recurrence','verified_resolution','review'],'Invalid append event type')
    ensure(event['severity'] in ['P0','P1','P2'],'Invalid severity')
    ensure(event['cause_confidence'] in ['observed','inferred','unknown'],'Invalid cause confidence')
    ensure(event['event_id'] not in {x.get('event_id') for x in events},'Duplicate event_id')
    ensure(re.fullmatch(r'BM-\d{2,}',str(event['id'])) is not None,'Invalid ID')
    known={x['id'] for x in events}
    ensure(event['id'] in known or event['event']=='new_issue','Unknown recurrence/resolution ID')
    if event['event']=='new_issue':ensure(event['id'] not in known,'Use recurrence for an existing ID')
    encoded=(json.dumps(event,ensure_ascii=False,separators=(',',':'))+'\n').encode('utf-8')
    path=root/DOCS/'ISSUES.jsonl'
    ensure(path.read_bytes()==raw,'Issue log changed during append; reconcile writer first')
    with path.open('ab') as stream:stream.write(encoded)

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path.cwd())
    sub=parser.add_subparsers(dest='command',required=True)
    p=sub.add_parser('check');p.add_argument('--session',required=True)
    p.add_argument('--before');p.add_argument('--require-prior-record',action='store_true')
    p=sub.add_parser('append');p.add_argument('--event',type=Path,required=True)
    args=parser.parse_args()
    try:
        if args.command=='check':
            print(json.dumps(check(args.root,args.session,args.before,args.require_prior_record),indent=2))
        else:append_event(args.root,args.event);print('Issue event appended. Refresh the active session review before continuing.')
    except (GateError,OSError,ValueError) as exc:
        print('IMPROVEMENT GATE FAILED: '+str(exc),file=sys.stderr);return 1
    return 0
if __name__=='__main__':raise SystemExit(main())
