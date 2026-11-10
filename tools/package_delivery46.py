#!/usr/bin/env python3
"""Package the exact signed V24 as standard small Android-readable 7-Zip volumes."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

APK_SHA = 'a46446c507ba165fc79dc70dbadb73fe4861f04d71b3710e073afbee2f4bca66'
APK_SIZE = 461783381
APK_NAME = 'BandMaster-Playtest-v24-arm64.apk'
VOLUME_BYTES = 48 * 1024 * 1024


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as file:
        while block := file.read(4 * 1024 * 1024):
            value.update(block)
    return value.hexdigest()


def dropbox_hash(path):
    value = hashlib.sha256()
    with path.open('rb') as file:
        while block := file.read(4 * 1024 * 1024):
            value.update(hashlib.sha256(block).digest())
    return value.hexdigest()


def package(apk, archiver, output):
    assert apk.name == APK_NAME and apk.stat().st_size == APK_SIZE
    assert digest(apk) == APK_SHA, 'Exact signed V24 required; never rebuild or substitute'
    assert archiver.is_file() and not output.exists(), 'New private output directory required'
    output.mkdir(parents=True)
    parts = output / 'parts'
    parts.mkdir()

    def run(label, arguments, cwd=None):
        result = subprocess.run([str(archiver), *map(str, arguments)], cwd=cwd,
                                capture_output=True, text=True, timeout=180)
        (output / (label + '.log')).write_text(result.stdout + result.stderr)
        assert result.returncode == 0, label + ' refused: inspect retained log'
        return result.stdout

    run('create', ['a', '-t7z', '-mx=0', '-v48m', '-bd', '-y',
                   parts / 'BandMaster-V24.7z', apk.name], cwd=apk.parent)
    volumes = sorted(parts.glob('BandMaster-V24.7z.*'))
    assert len(volumes) == 10
    assert [p.suffix for p in volumes] == ['.%03d' % n for n in range(1, 11)]
    assert all(0 < p.stat().st_size <= VOLUME_BYTES for p in volumes)
    assert all(p.stat().st_size == VOLUME_BYTES for p in volumes[:-1])
    run('test-all-volumes', ['t', '-bd', volumes[0]])
    listing = run('list-all-volumes', ['l', '-slt', volumes[0]])
    assert listing.count('Path = ' + APK_NAME + '\n') == 1
    extract = output / 'extracted'
    extract.mkdir()
    run('extract-all-volumes', ['x', '-bd', '-y', '-o' + str(extract), volumes[0]])
    extracted = list(extract.rglob('*'))
    assert len(extracted) == 1 and extracted[0].name == APK_NAME
    assert extracted[0].stat().st_size == APK_SIZE and digest(extracted[0]) == APK_SHA
    assert digest(apk) == APK_SHA, 'Original signed APK must remain unchanged'

    instructions = '''BandMaster V24 - Android phone installation

1. Download ALL TEN files named BandMaster-V24.7z.001 through .010 from Dropbox.
   Save every part in the SAME local phone folder, keeping the names unchanged.
   These are transport archive parts; do not try to install individual parts.
2. Open ZArchiver on your phone. Find that folder, tap BandMaster-V24.7z.001,
   and choose Extract here. It reads the remaining parts automatically.
   If needed, get ZArchiver from Google Play (publisher: ZDevs).
3. Tap the extracted BandMaster-Playtest-v24-arm64.apk and install as an UPDATE.
   Do not uninstall BandMaster or clear its storage: keep your existing saves.

Allow roughly 1.5 GB of free phone storage for the parts and extracted APK.
If extraction reports a missing volume, check that all ten parts finished
downloading to the same local folder. Dropbox offline-only copies may need
exporting/saving to the phone first. Keep the .001 to .010 file extensions.

This is the same signed V24 APK, not a new build or split app installation.
Original certificate, app ID and saved-game location are preserved.
Once installed successfully, the downloaded archive parts can be removed.
'''
    guide = parts / 'V24-ANDROID-INSTALL.txt'
    guide.write_text(instructions)
    records = [{'name': p.name, 'bytes': p.stat().st_size, 'sha256': digest(p),
                'Dropbox_content_hash': dropbox_hash(p)} for p in [*volumes, guide]]
    receipt = {'schema_version': 1, 'APK_name': APK_NAME, 'APK_bytes': APK_SIZE,
               'APK_sha256': APK_SHA, 'volume_bytes_max': VOLUME_BYTES,
               'volume_count': 10, 'standard_7z_all_volumes_test': True,
               'native_clean_extraction_exact_APK': True, 'archive_files': 1,
               'only_archived_file': APK_NAME, 'original_APK_unchanged': True,
               'new_APK_build': False, 'Android_physical_test': False, 'files': records}
    (output / 'manifest.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--archiver', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    package(args.apk.resolve(), args.archiver.resolve(), args.output.resolve())
