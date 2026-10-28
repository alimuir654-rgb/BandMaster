#!/usr/bin/env python3
"""Optional diff guard: prevent recruitment sprint from editing live gameplay/saves.

Usage (after unzip and first commit):
 python3 tools/recruitment_scope_guard.py --root . --base <known-good-sprint-commit>

Only checks DIFF scope against the user-provided base; not a full repo audit.
"""
import argparse
import subprocess
import sys
from pathlib import Path

ROOT_EXACT = {'AGENTS.md','README_IMPORT.md'}
PREFIXES = (
    '.agents/recruitment/', '.agents/skills/recruitment-screen-recovery/',
    'docs/recruitment_recovery/', 'Art/RecruitmentRecovery/',
    'Art/UI/RecruitmentV4/', 'docs/visual-proofs/',
    'tools/recruitment_', 'tests/test_recruitment_',
    '.github/workflows/recruitment-recovery-',
)
NATIVE_EXACT = {
    'poc/ldtd_recruitment_v4.gd', 'poc/ldtd_recruitment_v4.tscn',
    'poc/ldtd_editorial_native_handoff.gd', 'poc/ldtd_editorial_native_handoff.tscn',
    'tests/capture_ldtd_recruitment_v4.gd', 'tests/ldtd_recruitment_v4_tests.gd',
    'tests/capture_ldtd_editorial_native_handoff.gd',
    'tests/ldtd_editorial_native_handoff_tests.gd',
    'tools/check_v4_visual_contract.py',
    '.github/workflows/ldtd-recruitment-v4-art.yml',
    '.github/workflows/ldtd-editorial-native-handoff.yml',
}

def allowed(path):
    return path in ROOT_EXACT or path in NATIVE_EXACT or path.startswith(PREFIXES)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', default='.')
    parser.add_argument('--base', required=True, help='Explicit baseline SHA/ref; never compare entire old PR by accident')
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    cmd = ['git','-C',str(root),'diff','--name-only','--no-renames',f'{args.base}..HEAD']
    result = subprocess.run(cmd, text=True, capture_output=True)
    if result.returncode:
        print('SCOPE CHECK BLOCKED: ' + result.stderr.strip(), file=sys.stderr)
        return 1
    files = [v for v in result.stdout.splitlines() if v.strip()]
    forbidden = [p for p in files if not allowed(p)]
    if forbidden:
        print('SCOPE P0 BLOCKED: unrelated code files changed: ' + ', '.join(forbidden), file=sys.stderr)
        return 1
    print(f'SCOPE PASS: {len(files)} file(s) changed within the one-screen programme (not art approval)')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
