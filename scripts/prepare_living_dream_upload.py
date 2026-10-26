#!/usr/bin/env python3
"""Convert owner-supplied AVIF/JPEG/PNG/WebP scene photos into offline Godot crops.

This prepares review candidates, not a legal or human visual approval.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError

SCENES = {
    'spark': 'songwriting', 'vibe': 'songwriting', 'jam': 'songwriting',
    'songsheet': 'songwriting', 'load_van': 'showday', 'on_road': 'showday',
    'venue_arrival': 'showday', 'soundcheck': 'showday',
    'backstage': 'showday', 'showtime': 'showday',
    'formation': 'world', 'home': 'world', 'gear': 'world',
    'band_life': 'world', 'promoter': 'world', 'scrapbook': 'world',
}
EXTENSIONS = {'.avif', '.jpg', '.jpeg', '.png', '.webp'}
SIZES = {'wide': (1600, 900), 'portrait': (900, 1400)}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def convert(incoming: Path, output: Path, register: Path | None = None,
            strict_provenance: bool = False):
    metadata = {}
    if register is not None and register.is_file():
        with register.open(newline='', encoding='utf-8-sig') as stream:
            for row in csv.DictReader(stream):
                metadata[Path(row.get('filename', '')).stem] = row
    entries = []
    found = set()
    for source in sorted(incoming.rglob('*')):
        if not source.is_file() or source.suffix.lower() not in EXTENSIONS:
            continue
        slot = source.stem
        if slot not in SCENES:
            raise ValueError(f'Unrecognised scene name: {source.name}')
        if source.parent.name != SCENES[slot]:
            raise ValueError(f'Wrong scene folder for {source.name}: expected {SCENES[slot]}')
        if slot in found:
            raise ValueError(f'Duplicate scene slot: {slot}')
        found.add(slot)
        record = metadata.get(slot, {})
        url = record.get('actual_source_url', '').strip()
        photographer = record.get('photographer', '').strip()
        rights = record.get('license_or_rights_notes', '').strip()
        if strict_provenance and (not url or not photographer or not rights):
            raise ValueError(f'Missing original photo source/photographer/rights: {slot}')
        data = source.read_bytes()
        if len(data) > 45_000_000:
            raise ValueError(f'Photo too large: {source.name}')
        try:
            with Image.open(source) as check:
                check.verify()
            with Image.open(source) as raw:
                image = ImageOps.exif_transpose(raw).convert('RGB')
        except (OSError, UnidentifiedImageError) as exc:
            raise ValueError(f'Invalid image {source.name}: {exc}') from exc
        if min(image.size) < 800:
            raise ValueError(f'Photo resolution below 800px short edge: {source.name} {image.size}')
        produced = []
        output.mkdir(parents=True, exist_ok=True)
        for variant, dimensions in SIZES.items():
            destination = output / f'{slot}_{variant}.webp'
            crop = ImageOps.fit(image, dimensions, method=Image.Resampling.LANCZOS)
            crop.save(destination, format='WEBP', quality=85, method=6)
            with Image.open(destination) as checked:
                if checked.format != 'WEBP' or checked.size != dimensions:
                    raise ValueError(f'Corrupt converted output: {destination}')
            produced.append({'file': destination.name, 'sha256': sha(destination.read_bytes()),
                             'width': dimensions[0], 'height': dimensions[1]})
        entries.append({'slot': slot, 'input_filename': source.name, 'input_sha256': sha(data),
                        'original_dimensions': list(image.size), 'source_url': url,
                        'photographer': photographer, 'rights_notes': rights,
                        'provenance_complete': bool(url and photographer and rights),
                        'human_visual_approval': False, 'outputs': produced})
    if not entries:
        raise ValueError('No photos found: populate incoming/songwriting, incoming/showday or incoming/world')
    audit = output / 'owner_upload_audit.json'
    audit.write_text(json.dumps(entries, indent=2) + '\n', encoding='utf-8')
    return entries


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--incoming', type=Path, default=Path('Art/Photography/incoming'))
    parser.add_argument('--output', type=Path, default=Path('Art/Photography/approved'))
    parser.add_argument('--register', type=Path, default=Path('scene_asset_register.csv'))
    parser.add_argument('--strict-provenance', action='store_true')
    args = parser.parse_args()
    results = convert(args.incoming, args.output, args.register, args.strict_provenance)
    print(f'PREPARED {len(results)} PHOTO SLOTS; human clearance and viewport review still required')
