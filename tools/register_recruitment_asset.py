#!/usr/bin/env python3
"""Register ONE real recruitment asset with byte hash; never mark art owner-approved.

Example:
 python3 tools/register_recruitment_asset.py --root . --id portrait_featured \
   --path Art/RecruitmentRecovery/portraits/alex_master.png \
   --origin-kind generated_original \
   --rights-basis 'Original generated image; usage terms reviewed 2026-10-28'
"""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path
from xml.etree import ElementTree
from recruitment_quality_gate import (GateError, actual_sha256, png_size, resolve_safe)


def register(root: Path, asset_id: str, relative: str, origin: str,
             rights: str, source_url: str | None, candidate_id: str | None,
             replace: bool) -> dict:
    manifest_path = root / 'Art/RecruitmentRecovery/ASSET_MANIFEST.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    entries = [a for a in manifest['assets'] if a['id'] == asset_id]
    if len(entries) != 1:
        raise GateError(f'Exact planned ID required: {asset_id!r}')
    entry = entries[0]
    if entry['status'] != 'planned' and not replace:
        raise GateError('Asset already registered; use --replace only after explicit change review')
    path = resolve_safe(root, relative)
    if not path.is_file():
        raise GateError(f'Actual file not found: {relative}')
    if path.suffix.lower() not in ('.png', '.svg'):
        raise GateError('Only PNG sources and SVG control/material sources supported; convert other formats to PNG before intake')
    if path.suffix.lower() == '.svg' and entry['type'] not in ('controls', 'material'):
        raise GateError('Portraits and target art must be genuine PNG image files, not procedural vector studies')
    if len(rights.strip()) < 8:
        raise GateError('Rights/creation basis must be concrete')
    if origin == 'licensed_third_party' and (not source_url or not source_url.startswith('https://')):
        raise GateError('Third-party source must have official HTTPS origin URL')
    if entry['type'] == 'portrait':
        candidate_id = candidate_id or entry.get('candidate_id')
        expected_id = {'portrait_featured': 'alex', 'portrait_contrast': 'nia_griffiths'}[asset_id]
        if candidate_id != expected_id:
            raise GateError(f'Portrait {asset_id} must retain catalogue identity {expected_id!r}')
    if path.suffix.lower() == '.png':
        width, height = png_size(path)
        if width < 64 or height < 64:
            raise GateError(f'Image source too small at {width}x{height}')
        if entry['type'] == 'portrait' and min(width, height) < 1024:
            raise GateError(f'Portrait master requires >=1024 px on both axes; got {width}x{height}')
    else:
        try:
            svg = ElementTree.parse(path).getroot()
            if not svg.tag.endswith('svg'):
                raise ValueError('Not a valid SVG root')
        except (ElementTree.ParseError, ValueError) as exc:
            raise GateError(f'Invalid SVG control/material: {exc}')
        width, height = None, None
    entry.update(path=relative, sha256=actual_sha256(path), origin_kind=origin,
                 source_url=source_url, rights_basis=rights, status='ready',
                 width=width, height=height)
    if candidate_id:
        entry['candidate_id'] = candidate_id
    if entry['type'] == 'design_target':
        expectation = (1280, 720) if asset_id == 'desktop_art_target' else (390, 844)
        if (width, height) != expectation:
            raise GateError(f'{asset_id} must be {expectation}; got {(width, height)}')
    # Atomic replace to avoid half-written manifest if execution fails.
    data = json.dumps(manifest, indent=2, ensure_ascii=False) + '\n'
    temp = manifest_path.with_suffix('.json.tmp')
    temp.write_text(data, encoding='utf-8')
    temp.replace(manifest_path)
    return entry


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', default='.')
    parser.add_argument('--id', required=True)
    parser.add_argument('--path', required=True)
    parser.add_argument('--origin-kind', choices=('generated_original','owned_original','licensed_third_party'), required=True)
    parser.add_argument('--rights-basis', required=True)
    parser.add_argument('--source-url')
    parser.add_argument('--candidate-id')
    parser.add_argument('--replace', action='store_true')
    args = parser.parse_args(argv)
    try:
        asset = register(Path(args.root).resolve(), args.id, args.path, args.origin_kind,
                         args.rights_basis, args.source_url, args.candidate_id, args.replace)
    except (GateError, OSError, ValueError, KeyError) as e:
        print(f'ASSET INTAKE BLOCKED: {e}', file=sys.stderr)
        return 1
    print(f'ASSET REGISTERED (not approved): {asset["id"]} {asset["path"]} SHA256 {asset["sha256"]}')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
