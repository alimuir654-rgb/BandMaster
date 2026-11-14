#!/usr/bin/env python3
"""Recover exact archived WAV containers from verified FLAC49 files.

No source hashes are changed. Each full reconstructed file must match its
archived original before an exclusive-create write. This is a recovery tool,
not a new audio preparation or listening-acceptance step.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess

MANIFEST_SHA256 = '387ff05261f60bc2cb0e6f9ebf05358eb3a019c0a2b5a35cd3051891a19f5b13'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def chunk(name, payload):
    return name + struct.pack('<I', len(payload)) + payload + (b'\0' if len(payload) % 2 else b'')


def decode(path, codec, fmt):
    return subprocess.check_output(['ffmpeg', '-nostdin', '-v', 'error', '-i', str(path),
                                    '-map', '0:a:0', '-c:a', codec, '-f', fmt, '-'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--flac-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    manifest = (args.flac_dir / 'FLAC49-verification.json').read_bytes()
    if sha(manifest) != MANIFEST_SHA256:
        raise ValueError('Unexpected archive verification manifest')
    catalogue = {r['output_name']: r for r in json.loads(manifest)['files']}
    sources = sorted(args.flac_dir.glob('*.flac'))
    if not sources:
        raise ValueError('No recovered FLACs supplied')
    if args.output.exists():
        raise FileExistsError('Use a fresh output directory; never overwrite prior sources')
    verified = []
    for path in sources:
        row = catalogue[path.name]
        data = path.read_bytes()
        if len(data) != row['FLAC_bytes'] or sha(data) != row['output_sha256']:
            raise ValueError('FLAC identity failed: ' + path.name)
        probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error',
            '-show_streams', '-show_format', '-of', 'json', str(path)]))
        stream = probe['streams'][0]
        if (int(stream['sample_rate']), stream['channels'], int(stream['bits_per_raw_sample'])) != (48000, 2, 16):
            raise ValueError('Unsupported original format: ' + path.name)
        pcm32 = decode(path, 'pcm_s32le', 's32le')
        if 'SHA256=' + sha(pcm32) != row['decoded_PCM_sha256']:
            raise ValueError('Archived sample identity failed: ' + path.name)
        del pcm32
        pcm = decode(path, 'pcm_s16le', 's16le')
        comment = probe['format']['tags']['comment'].encode('utf-8') + b'\0'
        info = chunk(b'LIST', b'INFO' + chunk(b'ICMT', comment) + chunk(b'ISFT', b'Lavf60.16.100\0'))
        fmt = chunk(b'fmt ', struct.pack('<HHIIHH', 1, 2, 48000, 192000, 4, 16))
        body = b'WAVE' + fmt + info + b'data' + struct.pack('<I', len(pcm)) + pcm
        wav = b'RIFF' + struct.pack('<I', len(body)) + body
        if len(wav) != row['source_bytes'] or sha(wav) != row['source_sha256']:
            raise ValueError('Original WAV container identity failed: ' + path.name)
        name = row['source_name']
        if Path(name).name != name:
            raise ValueError('Unsafe archived filename')
        verified.append((name, wav, {'source_name': name, 'bytes': len(wav),
            'sha256': sha(wav), 'FLAC_sha256': row['output_sha256'],
            'decoded_PCM_sha256': row['decoded_PCM_sha256'],
            'frames': len(pcm) // 4, 'original_bytes_identical': True}))
    args.output.mkdir(parents=True, exist_ok=False)
    for name, data, _ in verified:
        with (args.output / name).open('xb') as handle:
            handle.write(data)
    report = {'schema_version': 1, 'manifest_sha256': MANIFEST_SHA256,
              'method': 'Lossless decode; restore archived WAV metadata; require full original SHA256',
              'source_files_changed': False, 'listening_verified': False,
              'files': [r for _, _, r in verified]}
    with (args.output / 'RESTORE66-originals-verification.json').open('x') as handle:
        json.dump(report, handle, indent=2)
        handle.write('\n')
    print(json.dumps({'exact_original_WAVs': len(verified), 'bytes': sum(len(d) for _, d, _ in verified),
                      'output': str(args.output)}))


if __name__ == '__main__':
    main()
