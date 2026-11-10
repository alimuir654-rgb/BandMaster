#!/usr/bin/env python3
"""Lossless private WAV-to-FLAC transfer copies; verify decoded samples exactly."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def probe(path):
    return json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-select_streams', 'a', '-show_streams',
        '-of', 'json', str(path)]))['streams']


def pcm_hash(path):
    return subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(path), '-map', '0:a:0',
        '-c:a', 'pcm_s32le', '-f', 'hash', '-hash', 'sha256', '-'], text=True).strip()


def compress(source, output):
    if source.resolve() == output.resolve() or output.exists():
        raise FileExistsError(output)
    original = probe(source)
    if len(original) != 1 or original[0]['codec_name'] not in ('pcm_s16le', 'pcm_s24le'):
        raise ValueError('Only one PCM16/PCM24 WAV stream is supported; no float/down-conversion')
    output.parent.mkdir(parents=True, exist_ok=True)
    original_sha = sha(source)
    subprocess.run(['ffmpeg', '-v', 'error', '-n', '-i', str(source),
                    '-map', '0:a:0', '-map_metadata', '0', '-c:a', 'flac',
                    '-compression_level', '8', str(output)], check=True)
    result = probe(output)
    for field in ['sample_rate', 'channels']:
        assert result[0][field] == original[0][field], field
    before_pcm, after_pcm = pcm_hash(source), pcm_hash(output)
    assert before_pcm == after_pcm, 'Decoded samples differ; retain the WAV and hold this transfer'
    assert sha(source) == original_sha, 'Source changed'
    receipt = {'source_name': source.name, 'source_sha256': original_sha,
               'output_name': output.name, 'output_sha256': sha(output),
               'source_bytes': source.stat().st_size, 'FLAC_bytes': output.stat().st_size,
               'saved_percent': round(100*(1-output.stat().st_size/source.stat().st_size), 2),
               'decoded_PCM_sha256': before_pcm, 'decoded_samples_identical': True,
               'source_retained': True, 'rate': original[0]['sample_rate'],
               'channels': original[0]['channels'],
               'processing': 'Lossless encoding only; no resampling, trimming, normalising or pitch change'}
    sidecar = output.with_suffix('.flac.receipt.json')
    with sidecar.open('x') as stream:
        json.dump(receipt, stream, indent=2); stream.write('\n')
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path, help='One WAV or a folder of WAV stems')
    parser.add_argument('output', type=Path, help='New output folder; originals stay intact')
    args = parser.parse_args()
    sources = sorted(args.source.glob('*.wav')) if args.source.is_dir() else [args.source]
    if not sources:
        raise ValueError('No WAV files found')
    for source in sources:
        if source.suffix.lower() != '.wav':
            raise ValueError('WAV input required')
        print(json.dumps(compress(source, args.output/(source.stem+'.flac'))), flush=True)


if __name__ == '__main__':
    main()
