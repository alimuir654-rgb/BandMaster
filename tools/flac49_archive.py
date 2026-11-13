#!/usr/bin/env python3
"""Create verified private FLAC copies of an exact owner source inventory."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
from pathlib import Path
import shutil

from punch48_compress_stems import compress, probe, sha


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    sources = json.loads(args.plan.read_text())
    assert sources and all(row['Dropbox_verified'] for row in sources)
    assert len({row['name'].casefold() for row in sources}) == len(sources)
    assert not args.output.exists(), 'Keep earlier output intact; use a fresh folder'
    assert shutil.disk_usage(args.output.parent).free > 3_000_000_000
    for row in sources:
        path = Path(row['local_path'])
        assert path.name == row['name'] and path.is_file()
        assert path.stat().st_size == row['size'] and sha(path) == row['sha256']
        streams = probe(path)
        assert len(streams) == 1 and streams[0]['codec_name'] in ['pcm_s16le', 'pcm_s24le']
    args.output.mkdir(parents=True, exist_ok=False)
    receipts = args.output / 'verification'
    receipts.mkdir()

    def one(row):
        source = Path(row['local_path'])
        target = args.output / (source.stem + '.flac')
        receipt = compress(source, target)
        decoded = probe(target)[0]
        assert decoded['codec_name'] == 'flac'
        source_depth = int(row['media'][0].get('bits_per_sample', 0))
        assert int(decoded['bits_per_raw_sample']) == source_depth
        receipt.update(source_bits=source_depth,
                       source_id=row['file_id'],
                       source_Dropbox_content_hash=row['Dropbox_content_hash'],
                       bits_preserved=True)
        sidecar = target.with_suffix('.flac.receipt.json')
        shutil.move(str(sidecar), str(receipts / sidecar.name))
        return receipt

    done = []
    with ThreadPoolExecutor(max_workers=3) as pool:
        for future in as_completed([pool.submit(one, row) for row in sources]):
            row = future.result()
            done.append(row)
            (receipts / 'progress.json').write_text(json.dumps(done, indent=2) + '\n')
            print(json.dumps({'completed': len(done), 'of': len(sources),
                              'file': row['output_name'],
                              'saved_percent': row['saved_percent']}), flush=True)
    original_bytes = sum(row['source_bytes'] for row in done)
    flac_bytes = sum(row['FLAC_bytes'] for row in done)
    manifest = {'schema_version': 1, 'format': 'FLAC', 'complete': True,
                'file_count': len(done), 'source_bytes': original_bytes,
                'FLAC_bytes': flac_bytes,
                'saved_percent': round(100*(1-flac_bytes/original_bytes), 2),
                'decoded_samples_identical': True,
                'originals_retained': True,
                'source_container_hashes_retained': True,
                'game_audio_assets_changed': False,
                'private_media': True,
                'files': sorted(done, key=lambda row: row['source_name'].casefold())}
    (args.output / 'FLAC49-verification.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert len(list(args.output.glob('*.flac'))) == len(sources)
    print(json.dumps({k: v for k, v in manifest.items() if k != 'files'}), flush=True)


if __name__ == '__main__':
    main()
