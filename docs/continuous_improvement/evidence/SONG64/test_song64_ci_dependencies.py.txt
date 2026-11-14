"""Regression checks for CI selection, never gameplay or Godot execution."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('ci_guard', ROOT / 'tools/song64_ci_dependencies.py')
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)

class TriggerCoverage(unittest.TestCase):
    def test_actual_model_closure_is_triggered(self):
        report = guard.audit(ROOT)
        self.assertIn('experiments/playable_flightcase/finance_policy.gd', report['model_inputs'])
        self.assertIn('tools/song59_verify.py', report['python_inputs'])

    def test_omitted_transitive_gameplay_and_runner_dependencies_refuse(self):
        text = (ROOT / guard.WORKFLOW).read_text()
        for path in ['experiments/playable_flightcase/rehearsal_intent.gd',
                     'experiments/playable_flightcase/finance_policy.gd',
                     'Data/CharacterCast/approved_cast_2026-10-29.json',
                     'tools/song59_verify.py', 'tools/song55_verify.py']:
            with self.subTest(path=path):
                changed = text.replace('      - ' + path + '\n', '')
                self.assertNotEqual(changed, text)
                with self.assertRaisesRegex(ValueError, 'Untriggered'):
                    guard.audit(ROOT, changed)

    def test_docs_art_and_workflow_scope_are_not_broad(self):
        report = guard.audit(ROOT)
        self.assertNotIn('docs/continuous_improvement/CURRENT.json', report['push_paths'])
        self.assertNotIn('Art/Backgrounds/shared/band.webp', report['push_paths'])
        self.assertTrue(all('*' not in p for p in report['push_paths']))

    def test_recursive_cycles_json_and_local_python_imports(self):
        with tempfile.TemporaryDirectory(prefix='song64-guard-') as work:
            r = Path(work)
            (r/'root.gd').write_text('extends "res://next.gd"\nvar x="res://data.json"\n')
            (r/'next.gd').write_text('extends "res://root.gd"\n')
            (r/'data.json').write_text('{"ref":"res://next.gd"}')
            self.assertEqual(guard.model_inputs(r, ['root.gd']), {'root.gd','next.gd','data.json'})
            (r/'runner.py').write_text('import helper\nimport pathlib\n')
            (r/'helper.py').write_text('from runner import anything\n')
            self.assertEqual(guard.python_inputs(r, {'runner.py'}), {'runner.py','helper.py'})

    def test_unsafe_or_unreviewed_trigger_syntax_refuses(self):
        for value in ['**/*.gd', '!excluded.gd', '../outside.gd', 'same.gd\n      - same.gd']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                guard.push_paths('on:\n  push:\n    paths:\n      - '+value+'\npermissions:\n')
        with self.assertRaises(ValueError):
            guard.push_paths('on:\n  push:\n    paths:\n      - "unterminated\n')

    def test_pull_request_paths_do_not_count_as_push_coverage(self):
        text = 'on:\n  push:\n    paths-ignore:\n      - critical.gd\n  pull_request:\n    paths:\n      - critical.gd\npermissions:\n  contents: read\n'
        with self.assertRaises(ValueError):
            guard.push_paths(text)
        outside = 'on:\n  pull_request:\n    paths:\n      - critical.gd\njobs:\n  push:\n    paths:\n      - critical.gd\n'
        with self.assertRaises(ValueError):
            guard.push_paths(outside)

    def test_missing_root_and_escape_refuse(self):
        with tempfile.TemporaryDirectory(prefix='song64-guard-') as work:
            with self.assertRaises(ValueError): guard.model_inputs(Path(work), ['missing.gd'])
            with self.assertRaises(ValueError): guard.model_inputs(Path(work), ['../outside.gd'])

if __name__ == '__main__':
    unittest.main()
