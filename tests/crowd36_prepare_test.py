#!/usr/bin/env python3
"""Private-input checks for source binding and fail-closed listening status."""
import argparse
import importlib.util
import json
from pathlib import Path
import tempfile

spec = importlib.util.spec_from_file_location('crowd', Path(__file__).resolve().parents[1] / 'tools/prepare_crowd36.py')
crowd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(crowd)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--applause', type=Path, required=True)
    p.add_argument('--boo', type=Path, required=True)
    args = p.parse_args()
    with tempfile.TemporaryDirectory() as folder:
        root = Path(folder)
        bad = root / 'bad.mp3'
        bad.write_bytes(b'not the pinned recording')
        try:
            crowd.prepare(bad, args.boo, root / 'bad-output')
            raise AssertionError('Changed source accepted')
        except ValueError:
            assert not (root / 'bad-output').exists()
        result = crowd.prepare(args.applause, args.boo, root / 'output')
        assert result['listening_verified'] is False
        assert result['release_status'] == 'HELD_PENDING_LISTENING_AND_FIT'
        assert set(result['effects']) == {'entrance', 'song', 'courtesy', 'cheer', 'boo'}
        for entry in result['effects'].values():
            assert entry['integration_review_accepted'] is False
            assert entry['listening_verified'] is False
            assert entry['source_sha256'] in {v[0] for v in crowd.SOURCES.values()}
            assert entry['sha256'] == crowd.sha(root / 'output' / Path(entry['path']).name)
            assert entry['duration_seconds'] <= 3.2
        before = (root / 'output/manifest.json').read_bytes()
        try:
            crowd.prepare(args.applause, args.boo, root / 'output')
            raise AssertionError('Existing output overwritten')
        except FileExistsError:
            assert (root / 'output/manifest.json').read_bytes() == before
        print(json.dumps({'source_tamper_refused_before_output': True,
                          'existing_output_preserved': True, 'real_cues_prepared': 5,
                          'unheard_manifest_held': True, 'listening': False}))
