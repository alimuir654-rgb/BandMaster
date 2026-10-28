#!/usr/bin/env python3
"""Validate recruitment recovery planning, source provenance and evidence stage.

Stdlib-only. Does NOT judge aesthetic quality or authenticate human approval.
Usage: python3 tools/recruitment_quality_gate.py --root . --stage prep
       python3 tools/recruitment_quality_gate.py --root . --stage art
       python3 tools/recruitment_quality_gate.py --root . --stage native
       python3 tools/recruitment_quality_gate.py --root . --stage owner
       python3 tools/recruitment_quality_gate.py --root . --package-only
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import struct
import zlib
import subprocess
import sys
from pathlib import Path

REQUIRED_PACK = [
    'AGENTS.md', 'README_IMPORT.md',
    '.agents/recruitment/README.md',
    '.agents/recruitment/SPRINT_CONTROLLER.md',
    '.agents/recruitment/ART_DIRECTOR.md',
    '.agents/recruitment/ASSET_PRODUCER.md',
    '.agents/recruitment/GODOT_INTEGRATOR.md',
    '.agents/recruitment/VISUAL_QA.md',
    '.agents/skills/recruitment-screen-recovery/SKILL.md',
    'docs/recruitment_recovery/00_SINGLE_SOURCE_OF_TRUTH.md',
    'docs/recruitment_recovery/01_VISUAL_TARGET.md',
    'docs/recruitment_recovery/02_ART_AND_ASSET_BIBLE.md',
    'docs/recruitment_recovery/03_ACCEPTANCE_RUBRIC.md',
    'docs/recruitment_recovery/04_SPRINT_PLAYBOOK.md',
    'docs/recruitment_recovery/05_SPRINT_LEDGER.md',
    'docs/recruitment_recovery/06_OWNER_REVIEW_PACKET_TEMPLATE.md',
    'docs/recruitment_recovery/07_ART_PROMPT_AND_SHOT_LIST.md',
    'docs/recruitment_recovery/08_RESEARCH_AND_ASSET_SHORTLIST.md',
    'docs/recruitment_recovery/09_NEXT_RUN_BRIEF.md',
    'docs/recruitment_recovery/RECOVERY_STATE.json',
    'Art/RecruitmentRecovery/ASSET_MANIFEST.json',
    'tools/recruitment_quality_gate.py',
    'tools/register_recruitment_asset.py',
    'tools/recruitment_scope_guard.py',
    'tests/test_recruitment_quality_gate.py',
    '.github/workflows/recruitment-recovery-plan.yml',
]
REQUIRED_REPOSITORY = [
    'project.godot', 'docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md',
    'docs/RECRUITMENT_REFERENCE_LOCK.md',
    'Scripts/recruitment_catalogue_v3.gd',
]
REQUIRED_ASSETS = {
    'portrait_featured', 'portrait_contrast', 'desktop_art_target',
    'phone_art_target', 'case_layer', 'paper_layer',
    'role_tab_idle', 'role_tab_hover', 'role_tab_pressed', 'role_tab_selected', 'role_tab_disabled',
}
VALID_ASSET_STATUS = {'planned', 'ready', 'approved'}
SHA256_RE = re.compile(r'^[a-f0-9]{64}$')
EXPECTED_REFERENCE = '278998d5c7875557aab95ac6d225026481a29fddd23537a7c94ac99765caa223'
STAGES = ('prep', 'art', 'native', 'owner')

class GateError(ValueError):
    """Expected contract failure, safe to show in CI."""


def resolve_safe(root: Path, relative: str) -> Path:
    """Never allow a source manifest path to escape the repository tree."""
    if not isinstance(relative, str) or not relative or '\\' in relative:
        raise GateError(f'Unsafe/empty path: {relative!r}')
    rel = Path(relative)
    if rel.is_absolute() or '..' in rel.parts or rel.parts[0] in ('.', ''):
        raise GateError(f'Unsafe asset path: {relative!r}')
    root = root.resolve()
    path = (root / rel).resolve()
    if not path.is_relative_to(root):
        raise GateError(f'Path resolves outside repository: {relative!r}')
    return path


def load_json(root: Path, path: str):
    return json.loads(resolve_safe(root, path).read_text(encoding='utf-8'))


def actual_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def png_size(path: Path):
    """Read physical PNG dimensions, validate chunk CRC, IDs and compressed data.

    This verifies image integrity, not its visual source or whether it came from Godot.
    """
    data = path.read_bytes()
    if len(data) < 45 or data[:8] != b'\x89PNG\r\n\x1a\n':
        raise GateError(f'Expected actual PNG bytes: {path}')
    pos = 8
    dimensions = None
    idat = bytearray()
    seen_end = False
    while pos < len(data):
        if pos + 12 > len(data):
            raise GateError(f'Truncated PNG chunk: {path}')
        length = struct.unpack('>I', data[pos:pos+4])[0]
        tag = data[pos+4:pos+8]
        stop = pos + 12 + length
        if stop > len(data):
            raise GateError(f'Truncated PNG chunk body: {path}')
        payload = data[pos+8:pos+8+length]
        expected_crc = struct.unpack('>I', data[pos+8+length:stop])[0]
        if zlib.crc32(tag + payload) & 0xffffffff != expected_crc:
            raise GateError(f'PNG CRC mismatch: {path}')
        if tag == b'IHDR':
            if dimensions is not None or length != 13 or pos != 8:
                raise GateError(f'Invalid PNG IHDR: {path}')
            dimensions = struct.unpack('>II', payload[:8])
            if not all(0 < d <= 32768 for d in dimensions):
                raise GateError(f'Invalid PNG dimensions: {path}')
        if tag == b'IDAT':
            idat.extend(payload)
            if len(idat) > 40_000_000:
                raise GateError(f'Excessive compressed PNG image: {path}')
        if tag == b'IEND':
            if length != 0 or stop != len(data):
                raise GateError(f'Invalid PNG end: {path}')
            seen_end = True
            break
        pos = stop
    if dimensions is None or not idat or not seen_end:
        raise GateError(f'PNG missing essential image data: {path}')
    try:
        decompressor = zlib.decompressobj()
        decompressor.decompress(bytes(idat), 128_000_000)
        if not decompressor.eof or decompressor.unconsumed_tail:
            raise ValueError('incomplete or oversize image stream')
    except (zlib.error, ValueError) as exc:
        raise GateError(f'Invalid PNG compressed pixels: {path}: {exc}') from exc
    return dimensions


def verify_source(root: Path, asset: dict) -> None:
    """Require real files and exact provenance when marked ready/approved."""
    aid = asset['id']
    path = asset.get('path')
    sha = asset.get('sha256')
    if not path or not isinstance(sha, str) or not SHA256_RE.fullmatch(sha):
        raise GateError(f'{aid}: source path and SHA256 are required')
    real = resolve_safe(root, path)
    if not real.is_file():
        raise GateError(f'{aid}: source file missing: {path}')
    if actual_sha256(real) != sha:
        raise GateError(f'{aid}: source SHA256 mismatch: {path}')
    if asset.get('origin_kind') not in {'generated_original', 'owned_original', 'licensed_third_party'}:
        raise GateError(f'{aid}: origin_kind missing/invalid')
    if not isinstance(asset.get('rights_basis'), str) or len(asset['rights_basis'].strip()) < 8:
        raise GateError(f'{aid}: actual rights basis required')
    if asset.get('origin_kind') == 'licensed_third_party' and not asset.get('source_url'):
        raise GateError(f'{aid}: third-party source URL required')
    if asset['type'] == 'portrait':
        if not asset.get('candidate_id'):
            raise GateError(f'{aid}: immutable candidate ID required')
        if not path.lower().endswith('.png'):
            raise GateError(f'{aid}: portrait master must be an independently usable PNG')
        w, h = png_size(real)
        if min(w, h) < 1024:
            raise GateError(f'{aid}: full-resolution portrait master requires >=1024 px on both axes, got {w}x{h}')
        if (w, h) != (asset.get('width'), asset.get('height')):
            raise GateError(f'{aid}: registered portrait size does not match actual PNG source')
    if asset['type'] == 'design_target':
        if not path.lower().endswith('.png'):
            raise GateError(f'{aid}: use real PNG output for physical-size evidence')
        w, h = png_size(real)
        if (w, h) != (asset.get('width'), asset.get('height')):
            raise GateError(f'{aid}: target PNG dimensions {(w, h)} disagree with manifest')


def verify_portrait_pair(by_id: dict) -> None:
    """The source-art gate cannot accept misnamed or duplicated masters."""
    expected = {'portrait_featured': 'alex', 'portrait_contrast': 'nia_griffiths'}
    for aid, candidate_id in expected.items():
        if by_id[aid].get('candidate_id') != candidate_id:
            raise GateError(f'{aid}: expected canonical candidate ID {candidate_id!r}')
    first, second = (by_id[k] for k in expected)
    if first.get('sha256') and first.get('sha256') == second.get('sha256'):
        raise GateError('Portrait masters cannot share source bytes/SHA256 across two identities')


def check_basic(root: Path, package_only: bool) -> tuple[dict, dict]:
    missing = [p for p in REQUIRED_PACK if not (root / p).is_file()]
    if not package_only:
        missing.extend(p for p in REQUIRED_REPOSITORY if not (root / p).is_file())
    if missing:
        raise GateError('Missing required source(s): ' + ', '.join(missing))
    agents = (root / 'AGENTS.md').read_text(encoding='utf-8')
    for term in ('RECRUITMENT QUALITY RECOVERY', 'STOP-THE-LINE VISUAL QUALITY',
                 'ART_DIRECTION_PRODUCTION_CONTRACT_V4.md', 'owner_approved'):
        if term not in agents:
            raise GateError(f'Root AGENTS.md missing mandatory directive: {term}')
    if not package_only and (root / '.git').exists():
        branch = subprocess.run(['git', '-C', str(root), 'branch', '--show-current'],
                                text=True, capture_output=True, check=False)
        if branch.returncode == 0 and branch.stdout.strip() in ('main', 'master'):
            raise GateError('Refusing to validate recovery changes on main/master; use a feature branch')
    state = load_json(root, 'docs/recruitment_recovery/RECOVERY_STATE.json')
    manifest = load_json(root, 'Art/RecruitmentRecovery/ASSET_MANIFEST.json')
    if state.get('schema_version') != 1 or state.get('mission') != 'one_recruitment_screen_only':
        raise GateError('RECOVERY_STATE must keep one-screen mission / schema=1')
    if state.get('current_stage') not in STAGES:
        raise GateError('current_stage must be one of ' + ', '.join(STAGES))
    if state.get('internal_art_review') not in {'blocked', 'provisional_pass'}:
        raise GateError('Invalid internal_art_review; it is not owner approval')
    if state.get('reference', {}).get('sha256') != EXPECTED_REFERENCE:
        raise GateError('Owner-approved reference SHA has changed without explicit review')
    ref = state['reference']
    if ref.get('binary_in_repository_verified'):
        if not ref.get('file'):
            raise GateError('Reference binary verification requires exact file path')
        p = resolve_safe(root, ref['file'])
        if not p.is_file() or actual_sha256(p) != EXPECTED_REFERENCE:
            raise GateError('Owner reference binary absent or exact SHA mismatch')
    if type(state.get('owner_approved')) is not bool:
        raise GateError('owner_approved must be Boolean and human asserted')
    if state.get('owner_approved') and not state.get('owner_approval_evidence'):
        raise GateError('No owner approval evidence: cannot mark owner_approved=true')
    if manifest.get('schema_version') != 1 or not isinstance(manifest.get('assets'), list):
        raise GateError('Invalid ASSET_MANIFEST schema')
    by_id = {}
    for a in manifest['assets']:
        if not isinstance(a, dict) or not isinstance(a.get('id'), str):
            raise GateError('Manifest contains missing asset id')
        if a['id'] in by_id:
            raise GateError(f'Duplicate asset ID: {a["id"]}')
        by_id[a['id']] = a
        if a.get('status') not in VALID_ASSET_STATUS:
            raise GateError(f'{a["id"]}: invalid asset status')
        if a['status'] in {'ready', 'approved'}:
            verify_source(root, a)
        elif a.get('path') or a.get('sha256'):
            raise GateError(f'{a["id"]}: planned asset cannot claim a source; switch status to ready after verifying')
    if not REQUIRED_ASSETS <= set(by_id):
        raise GateError('Asset manifest lacks: ' + ', '.join(sorted(REQUIRED_ASSETS - set(by_id))))
    verify_portrait_pair(by_id)
    if (state.get('owner_approved') or state.get('internal_art_review') == 'provisional_pass') and state.get('known_art_p0'):
        raise GateError('Art approval/provisional approval cannot coexist with unresolved P0s')
    return state, by_id


def verify_stage(root: Path, stage: str, state: dict, assets: dict) -> None:
    if stage == 'prep':
        return
    for aid in ('portrait_featured', 'portrait_contrast', 'desktop_art_target', 'phone_art_target'):
        if assets[aid]['status'] not in ('ready', 'approved'):
            raise GateError(f'Art gate BLOCKED: {aid} is {assets[aid]["status"]}')
    if assets['portrait_featured'].get('candidate_id') == assets['portrait_contrast'].get('candidate_id'):
        raise GateError('Portrait candidate identities must be different')
    art = state['milestones']['art_target']
    if state.get('internal_art_review') != 'provisional_pass' or art.get('status') != 'provisional_pass' or not art.get('evidence'):
        raise GateError('Art gate BLOCKED: needs documented visual provisional pass and actual target evidence')
    if stage == 'art':
        return
    for aid in ('case_layer', 'paper_layer',
                'role_tab_idle', 'role_tab_hover', 'role_tab_pressed',
                'role_tab_selected', 'role_tab_disabled'):
        if assets[aid]['status'] not in ('ready', 'approved'):
            raise GateError(f'Native gate BLOCKED: {aid} source not ready')
    for milestone in ('source_layers', 'godot_native', 'visual_qa'):
        node = state['milestones'][milestone]
        if node.get('status') != 'pass' or not node.get('evidence'):
            raise GateError(f'Native gate BLOCKED: {milestone} lacks PASS and traceable evidence')
    if not isinstance(state.get('native_ci_url'), str) or not state['native_ci_url'].startswith(
            'https://github.com/alimuir654-rgb/BandMaster/actions/runs/'):
        raise GateError('Native gate BLOCKED: actual Godot CI run URL required')
    screenshots = state.get('native_screenshots', {})
    for dims, wh in (('390x844', (390, 844)), ('1280x720', (1280, 720))):
        relative = screenshots.get(dims)
        if not relative:
            raise GateError(f'Native gate BLOCKED: {dims} actual local screenshot missing')
        image = resolve_safe(root, relative)
        if not image.is_file() or png_size(image) != wh:
            raise GateError(f'Native gate BLOCKED: {dims} native PNG absent/wrong size')
    if stage == 'native':
        return
    if state.get('owner_approved') is not True:
        raise GateError('Owner gate BLOCKED: only the real human owner may approve the actual native proof')
    evidence = state.get('owner_approval_evidence')
    if not isinstance(evidence, str) or not evidence.startswith('https://github.com/alimuir654-rgb/BandMaster/'):
        raise GateError('Owner gate BLOCKED: concrete GitHub PR/decision evidence URL required')
    # Structural check ONLY. It does NOT authenticate the person who approved.


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', default='.', help='Repository or unpacked ZIP root')
    parser.add_argument('--stage', choices=STAGES, default='prep')
    parser.add_argument('--package-only', action='store_true', help='Validate pack structure before repo import')
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    try:
        state, assets = check_basic(root, args.package_only)
        verify_stage(root, args.stage, state, assets)
    except (GateError, OSError, ValueError, KeyError, TypeError) as e:
        print(f'RECRUITMENT {args.stage.upper()} GATE BLOCKED: {e}', file=sys.stderr)
        return 1
    print(f'RECRUITMENT {args.stage.upper()} CONTRACT PASS — structure/evidence only; automated checks do NOT certify art or owner approval')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
