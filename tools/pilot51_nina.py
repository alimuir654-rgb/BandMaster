#!/usr/bin/env python3
"""Integrate two explicitly owner-approved Nina excerpts, never whole masters."""
from pathlib import Path
import hashlib
import json
from prepare_audition47 import excerpt

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'experiments/playable_flightcase/audio/recorded_indie39'
SOURCES = Path('/workspace/bandmaster-feedback47/originals')


def main():
    path = DEST / 'characters.json'
    registry = json.loads(path.read_text())
    assert 'cast_nina' not in registry['characters'], 'Never overwrite a prior assignment'
    specifications = [
        ('verse', 'Vocals', '1892ece982dcc23b33abccfaf5acf9b734d041ff851a6883675734d845931ea6', 432000, 388800),
        ('harmony', 'Backing Vocals', 'a9f4fc53ca671dbcc117c99a4085cb9e9c76347f7faff5a9d96a81fba4a45193', 2990400, 345600),
    ]
    materials = []
    for kind, stem, expected, start, frames in specifications:
        source = SOURCES / f'Last Bus Gone ({stem}).wav'
        assert hashlib.sha256(source.read_bytes()).hexdigest() == expected
        material = f'cast_nina_pilot51_{kind}'
        target = DEST / (material + '.ogg')
        row = excerpt(source, target, start, frames)
        row.update(path='res://' + target.relative_to(ROOT).as_posix(),
                   integration_authority='owner_approved_nina_20261111', integration_review_accepted=True,
                   owner_listening_accepted=True, owner_assignment='Use Last Bus Gone for Nina',
                   source_type='Owner-supplied AI-generated Suno vocal stem',
                   description='Independent recorded vocal idea; not an adjusted written exercise')
        registry['materials'][material] = row
        materials.append(material)
    registry['characters']['cast_nina'] = dict(role='Singer', materials=materials,
        fit='Owner-approved Last Bus Gone: short quiet lead and separate harmony excerpt.')
    path.write_text(json.dumps(registry, indent=2)+'\n')
    print(json.dumps(dict(candidate='cast_nina', materials=materials, owner_assignment_accepted=True,
                         assistant_listening_verified=False, source_masters_unchanged=True)))


if __name__ == '__main__':
    main()
