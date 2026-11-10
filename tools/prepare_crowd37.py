#!/usr/bin/env python3
"""Acquire/prepare the four owner-approved crowd sources, outside public Git.

fetch uses only registered original URLs and records source hashes. A proxy
denial is a blocker, never a reason to change routes. prepare is offline;
default preparation refuses incomplete source banks before creating output.
--allow-partial is explicit source QA, never release clearance.
"""
import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'docs/audio/CROWD37_SOURCES.json'
PREFIX = 'res://experiments/playable_flightcase/audio/crowd37/'
CREDIT_PATH = ROOT / 'experiments/playable_flightcase/audio/crowd37_credits.txt'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def catalog():
    return json.loads(CATALOG.read_text())['sources']


def fetch(output):
    output.mkdir(parents=True, exist_ok=False)
    receipt = {'sources': {}}
    for identity, row in catalog().items():
        target = output / (identity + '.mp3')
        # Default proxy/CA settings, no custom proxy, no unregistered mirrors.
        with urlopen(row['preview_url'], timeout=25) as response:
            if response.geturl() != row['preview_url']:
                raise ValueError('Unexpected source redirect: ' + identity)
            data = response.read(8 * 1024 * 1024 + 1)
        if len(data) > 8 * 1024 * 1024:
            raise ValueError('Unexpected source size')
        target.write_bytes(data)
        digest = sha(target)
        if row['source_sha256'] and digest != row['source_sha256']:
            raise ValueError('Pinned source changed: ' + identity)
        receipt['sources'][identity] = {'url': row['preview_url'], 'sha256': digest}
        (output / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')


def levels(path, seconds):
    pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-nostdin', '-i', str(path),
                                   '-t', str(seconds), '-f', 'f32le', '-acodec', 'pcm_f32le', '-'])
    samples = array('f'); samples.frombytes(pcm)
    if sys.byteorder != 'little':
        samples.byteswap()
    if not samples or any(not math.isfinite(value) for value in samples):
        raise ValueError('Invalid decoded source')
    peak = max(abs(value) for value in samples)
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    if rms <= 0 or peak <= 0:
        raise ValueError('Silent source')
    return 20 * math.log10(rms), 20 * math.log10(peak)


def prepare(sources, output, allow_partial=False):
    rows = catalog()
    receipt_path = sources / 'receipt.json'
    receipt = json.loads(receipt_path.read_text()) if receipt_path.exists() else {'sources': {}}
    missing = [identity for identity in rows if not (sources / (identity + '.mp3')).is_file()]
    if missing and not allow_partial:
        raise ValueError('Incomplete approved bank: ' + ', '.join(missing))
    verified = {}
    for identity, row in rows.items():
        if identity in missing:
            continue
        path = sources / (identity + '.mp3')
        digest = sha(path)
        pin = row['source_sha256']
        record = receipt['sources'].get(identity, {})
        if not pin and record.get('url') == row['preview_url']:
            pin = record.get('sha256')
        if not pin or digest != pin:
            raise ValueError('Unbound or changed source: ' + identity)
        probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries',
            'format=duration:stream=codec_type,sample_rate,channels', '-of', 'json', str(path)]))
        streams = probe['streams']
        if len(streams) != 1 or streams[0]['codec_type'] != 'audio':
            raise ValueError('Expected one audio stream')
        duration = min(row['duration_seconds'], float(probe['format']['duration']) - 0.08)
        mean, peak = levels(path, duration)
        gain = min(6.0, -24.0 - mean, -3.0 - peak)
        verified[identity] = (path, duration, gain, streams[0])
    if not verified:
        raise ValueError('No approved audio available')
    output.mkdir(parents=True, exist_ok=False)
    manifest = {'schema_version': 1, 'content_version': 'crowd37',
                'authority': 'owner_approved_table_20261110',
                'complete': not missing, 'missing_sources': missing,
                'owner_source_listening_accepted': True, 'derivative_mix_listening_verified': False,
                'boo_approved': False, 'effects': {}}
    for identity, (path, duration, gain, stream) in verified.items():
        row = rows[identity]; cue = row['cue']; target = output / (cue + '.ogg')
        rate = int(stream['sample_rate'])
        subprocess.run(['ffmpeg', '-v', 'error', '-nostdin', '-n', '-i', str(path), '-t', str(duration),
            '-vn', '-ar', str(rate), '-ac', '2', '-af',
            f'volume={gain:.6f}dB,afade=t=in:d=0.04,afade=t=out:st={duration-0.15}:d=0.15',
            '-c:a', 'libvorbis', '-q:a', '5', '-map_metadata', '-1', str(target)], check=True)
        manifest['effects'][cue] = {
            'path': PREFIX + target.name, 'sha256': sha(target),
            'source_id': identity, 'source_sha256': sha(path), 'source_page': row['source_page'],
            'source_url': row['preview_url'], 'creator': row['creator'], 'title': row['title'],
            'license': row['license'], 'license_url': row['license_url'],
            'owner_source_listening_accepted': True, 'integration_review_accepted': True,
            'authority': 'owner_approved_table_20261110',
            'source_type': 'approved source MP3, not original WAV master',
            'source_start_seconds': 0, 'duration_seconds': duration, 'sample_rate': rate,
            'gain_db': round(gain, 6), 'modifications': 'Excerpt, level adjustment, fades and Vorbis encoding',
        }
        if row['license'] == 'CC-BY-4.0':
            manifest['effects'][cue]['attribution_path'] = 'res://' + CREDIT_PATH.relative_to(ROOT).as_posix()
            manifest['effects'][cue]['attribution_sha256'] = sha(CREDIT_PATH)
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return manifest


if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest='command', required=True)
    acquire = sub.add_parser('fetch'); acquire.add_argument('--output', type=Path, required=True)
    make = sub.add_parser('prepare'); make.add_argument('--sources', type=Path, required=True)
    make.add_argument('--output', type=Path, required=True)
    make.add_argument('--allow-partial', action='store_true')
    args = p.parse_args()
    if args.command == 'fetch':
        fetch(args.output)
    else:
        print(json.dumps(prepare(args.sources, args.output, args.allow_partial), indent=2))
