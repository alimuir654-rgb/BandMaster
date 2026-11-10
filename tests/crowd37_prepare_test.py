#!/usr/bin/env python3
"""Real source binding, missing-bank and preservation checks. No synthetic audio."""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile

spec = importlib.util.spec_from_file_location('crowd', Path(__file__).resolve().parents[1] / 'tools/prepare_crowd37.py')
crowd = importlib.util.module_from_spec(spec); spec.loader.exec_module(crowd)

if __name__ == '__main__':
    p = argparse.ArgumentParser(); p.add_argument('--sources', type=Path, required=True); args = p.parse_args()
    checks = 0
    with tempfile.TemporaryDirectory() as folder:
        root = Path(folder); sources = root / 'sources'; sources.mkdir()
        # Test an intentionally incomplete copy even after full acquisition succeeds.
        shutil.copy2(args.sources / '35748.mp3', sources / '35748.mp3')
        try:
            crowd.prepare(sources, root / 'strict')
            raise AssertionError('Incomplete bank accepted by strict preparation')
        except ValueError:
            assert not (root / 'strict').exists(); checks += 1
        result = crowd.prepare(sources, root / 'partial', allow_partial=True)
        assert result['complete'] is False and set(result['effects']) == {'cheer'}; checks += 1
        entry = result['effects']['cheer']
        assert entry['source_id'] == '35748' and entry['license'] == 'CC-BY-4.0'; checks += 1
        assert entry['attribution_sha256'] == crowd.sha(crowd.CREDIT_PATH); checks += 1
        assert entry['owner_source_listening_accepted'] is True and result['derivative_mix_listening_verified'] is False; checks += 1
        before = (root / 'partial/manifest.json').read_bytes()
        try:
            crowd.prepare(sources, root / 'partial', allow_partial=True)
            raise AssertionError('Existing output overwritten')
        except FileExistsError:
            assert (root / 'partial/manifest.json').read_bytes() == before; checks += 1
        with (sources / '35748.mp3').open('ab') as f: f.write(b'tampered')
        try:
            crowd.prepare(sources, root / 'tampered', allow_partial=True)
            raise AssertionError('Changed source accepted')
        except ValueError:
            assert not (root / 'tampered').exists(); checks += 1
    print(json.dumps({'checks': checks, 'failures': [], 'real_source': True, 'listening': False}))
