"""Continuity regressions: stale pointers, lost history, bloated reads and unsafe cursors."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import project_context as context
from improvement_gate import GateError


class ContextTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.session_path = context.DOCS + '/sessions/SAMPLE.json'
        self.issue_path = self.root / context.DOCS / 'ISSUES.jsonl'
        self.issue_path.parent.mkdir(parents=True)
        self.issue_path.write_bytes(b'{"event_id":"old","observation":"ARCHIVED_HISTORY"}\n')
        prefix = {'bytes': self.issue_path.stat().st_size, 'sha256': context.sha(self.issue_path.read_bytes())}
        manifest_path = 'docs/handover/archive/sample/MANIFEST.json'
        entries = []
        for name in context.LIMITS:
            archived = 'docs/handover/archive/sample/' + Path(name).name
            raw = ('ARCHIVED_HISTORY:' + name).encode()
            p = self.root / archived; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(raw)
            entries.append({'original': name, 'archive': archived, 'bytes': len(raw), 'sha256': context.sha(raw)})
        self.write(manifest_path, {'files': entries, 'preserved_issue_prefix': prefix})
        action = 'Inspect the current native result and close SAMPLE.'
        self.write(self.session_path, {'id': 'SAMPLE', 'status': 'active', 'owner_approved': False,
                   'writer': {'owner': 'root-SAMPLE', 'status': 'active'}, 'next_action': action,
                   'lesson_ids': ['BM-43'], 'issue_log_review': prefix})
        current = {'context_schema_version': 1, 'session': self.session_path, 'active_session': 'SAMPLE',
                   'branch': 'feature/test', 'status': 'active', 'writer': 'root-SAMPLE', 'owner_approved': False,
                   'scope': 'One bounded result', 'next_action': action, 'source': {'verification': 'pending'},
                   'roadmap': 'docs/roadmap.md', 'queue': 'docs/queue.md', 'history_manifest': manifest_path}
        self.write(context.CURRENT, current)
        for name in (context.STATE, context.LOCK):
            self.write(name, {'session': 'SAMPLE', 'session_path': self.session_path, 'canonical_current': context.CURRENT,
                       'branch': current['branch'], 'status': 'active', 'writer': 'root-SAMPLE', 'owner_approved': False,
                       'next_single_action': action, 'history_manifest': manifest_path})
        (self.root / context.START).write_text(f'# Start\n<!-- session: SAMPLE -->\n<!-- status: active -->\n{action}\n')

    def write(self, path, value):
        p = self.root / path; p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(value, ensure_ascii=False) + '\n')

    def change(self, path, **updates):
        value = json.loads((self.root / path).read_text()); value.update(updates); self.write(path, value)

    def test_compact_context_and_bounded_start(self):
        self.assertEqual(context.validate(self.root)['context_check'], 'pass')
        output = json.dumps(context.start(self.root))
        self.assertNotIn('ARCHIVED_HISTORY', output)
        self.assertLess(len(output), 4000)

    def test_stale_session_status_and_branch_are_rejected(self):
        for path, updates in [(context.CURRENT, {'active_session': 'OLD'}),
                              (context.STATE, {'session_path': 'docs/old.json'}),
                              (context.LOCK, {'status': 'closed'}),
                              (context.STATE, {'branch': 'main'})]:
            original = (self.root / path).read_bytes()
            with self.subTest(path=path, updates=updates):
                self.change(path, **updates)
                with self.assertRaises(GateError): context.validate(self.root)
            (self.root / path).write_bytes(original)

    def test_writer_mismatch_and_missing_writer_are_rejected(self):
        original = (self.root / context.LOCK).read_bytes()
        self.change(context.LOCK, writer=None)
        with self.assertRaisesRegex(GateError, 'Writer'): context.validate(self.root)
        (self.root / context.LOCK).write_bytes(original)
        value = json.loads(original); del value['writer']; self.write(context.LOCK, value)
        with self.assertRaisesRegex(GateError, 'explicitly'): context.validate(self.root)

    def test_next_action_and_start_page_cannot_lag(self):
        original = (self.root / context.STATE).read_bytes()
        self.change(context.STATE, next_single_action='Skip to the old roadmap task')
        with self.assertRaisesRegex(GateError, 'Next-action'): context.validate(self.root)
        (self.root / context.STATE).write_bytes(original)
        (self.root / context.START).write_text('An old handover')
        with self.assertRaisesRegex(GateError, 'Start-here'): context.validate(self.root)

    def test_closed_session_requires_released_consistent_writer(self):
        action = 'Review the completed result.'
        self.change(self.session_path, status='closed', writer={'owner': 'root-SAMPLE', 'status': 'released'},
                    closeout={'next_action': action})
        self.change(context.CURRENT, status='closed', writer=None, next_action=action)
        for name in (context.STATE, context.LOCK):
            self.change(name, status='closed', writer=None, next_single_action=action)
        (self.root / context.START).write_text(f'<!-- session: SAMPLE -->\n<!-- status: closed -->\n{action}')
        self.assertIsNone(context.validate(self.root)['writer'])
        self.change(context.LOCK, writer='root-SAMPLE')
        with self.assertRaisesRegex(GateError, 'Writer'): context.validate(self.root)

    def test_history_cannot_be_embedded_back_in_current(self):
        self.change(context.CURRENT, old_runs=['old run ' * 2000])
        with self.assertRaisesRegex(GateError, 'oversized'): context.validate(self.root)

    def test_missing_or_changed_archive_is_rejected(self):
        path = self.root / 'docs/handover/archive/sample/STATE.json'
        original = path.read_bytes(); path.unlink()
        with self.assertRaisesRegex(GateError, 'missing'): context.validate(self.root)
        path.write_bytes(original + b'changed')
        with self.assertRaisesRegex(GateError, 'changed'): context.validate(self.root)

    def test_issue_delta_is_unicode_safe_paginated_and_read_only(self):
        for event in [{'event_id': 'new1', 'text': 'écho'}, {'event_id': 'new2', 'text': '保存'}]:
            with self.issue_path.open('ab') as f: f.write((json.dumps(event, ensure_ascii=False) + '\n').encode())
        before = (self.root / self.session_path).read_bytes()
        first = context.issues(self.root, limit=1)
        self.assertTrue(first['has_more']); self.assertEqual(first['events'][0]['event_id'], 'new1')
        second = context.issues(self.root, limit=1, after=first['read_cursor'])
        self.assertFalse(second['has_more']); self.assertEqual(second['events'][0]['event_id'], 'new2')
        self.assertEqual(before, (self.root / self.session_path).read_bytes())
        self.assertEqual(len(context.issues(self.root)['events']), 2)

    def test_rewritten_history_or_split_cursor_is_rejected(self):
        raw = self.issue_path.read_bytes()
        with self.assertRaisesRegex(GateError, 'splits'): context.cursor(raw, {'bytes': 4, 'sha256': context.sha(raw[:4])})
        self.issue_path.write_bytes(raw.replace(b'old', b'bad', 1))
        with self.assertRaisesRegex(GateError, 'hash mismatch'): context.issues(self.root)
        with self.assertRaisesRegex(GateError, 'hash mismatch'): context.validate(self.root)

    def test_relevant_lessons_can_expand_without_loading_other_lessons(self):
        (self.root / context.DOCS / 'LESSONS.md').write_text('### BM-43\n**Prevent:** Keep current state small.\n\nDetailed extension.\n\n### BM-44\n**Prevent:** Unrelated.\n')
        short = context.lessons(self.root, ['BM-43'])
        self.assertIn('Keep current state small', short)
        self.assertNotIn('Detailed extension', short); self.assertNotIn('Unrelated', short)
        self.assertIn('Detailed extension', context.lessons(self.root, ['BM-43'], full=True))

    def test_full_lessons_include_dated_shared_clarifications_once(self):
        (self.root / context.DOCS / 'LESSONS.md').write_text(
            '### BM-22\n**Prevent:** Layout.\n### BM-32\n**Prevent:** Input.\n'
            '## 2 November scrolling — BM-22, BM-32 and BM-33\nLater real-world correction.\n'
            '## 3 November unrelated — BM-220\nNot the same ID.\n')
        full = context.lessons(self.root, ['BM-22', 'BM-32'], full=True)
        self.assertEqual(full.count('Later real-world correction'), 1)
        self.assertNotIn('Not the same ID', full)
        self.assertNotIn('Later real-world correction', context.lessons(self.root, ['BM-22']))


if __name__ == '__main__':
    unittest.main()
