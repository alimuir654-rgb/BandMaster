#!/usr/bin/env python3
"""Derive private DGAD passage and isolated-preview candidates; retain originals.

Ranges are numerically populated candidates, not listening-approved bar cuts,
alternate performances, verified harmony or character assignments.
"""
import argparse
import json
import wave
from pathlib import Path

import numpy as np
from prepare_recorded_rehearsal import cut, tone, sha

RATE = 48000
FRAMES = 460800
STARTS = [19.2, 28.8, 38.4, 57.6, 67.2, 76.8]
VERSION = 'recorded_dgad_v1'


def write_asset(folder, name, x):
    x *= min(1.0, .9/max(float(np.abs(x).max()), 1e-12))
    x[:480] *= np.linspace(0, 1, 480)[:, None]
    x[-960:] *= np.linspace(1, 0, 960)[:, None]
    pcm = np.round(x*32768).astype('<i2').tobytes()
    path = folder/name
    with wave.open(str(path), 'wb') as wav:
        wav.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(pcm)
    return dict(sha256=sha(path.read_bytes()), pcm_sha256=sha(pcm))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assessment-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--audition-output', type=Path, required=True)
    args = parser.parse_args()
    assert not args.output.exists() and not args.audition_output.exists()
    assert args.output.resolve()!=args.audition_output.resolve()
    data = json.loads((args.assessment_dir/'measurements.json').read_text())
    paths = {}; sources = []
    for row in data['files']:
        path = args.assessment_dir/'originals'/row['name']
        assert sha(path.read_bytes())==row['sha256']
        paths[row['role']] = path
        sources.append({k:row[k] for k in ['name','role','id','rev','sha256','dropbox_content_hash']})
    assert set(paths)=={'Guitar','Bass','Drums','Mix'}
    args.output.mkdir(parents=True);args.audition_output.mkdir(parents=True)
    manifest = dict(schema_version=1, content_version=VERSION, review_only=True,
                    provenance='Owner-supplied AI-generated Suno audio', commercial_game_licensing='unresolved',
                    listening_verified=False, loop_verified=False, bar_grid_verified=False,
                    key_and_progression_verified=False, requested_harmony='D major; D | G | A | D',
                    tempo_estimated=True, no_time_stretch=True, sources=sources,
                    distinct_passage_candidates=6, alternate_performances_claimed=0,
                    fade_in_frames=480, fade_out_frames=960, entries={})
    for index, start_s in enumerate(STARTS,1):
        start = round(start_s*RATE)
        entry = dict(tempo=100, frames=FRAMES, sample_rate=RATE, channels=2,
                     source_start_frame=start, source_end_frame_exclusive=start+FRAMES,
                     provisional_bar_grid=True, parts={})
        for part in ['guitar_warm','guitar_gritty','guitar_biting','bass','kit']:
            role = 'Guitar' if part.startswith('guitar') else ('Bass' if part=='bass' else 'Drums')
            x = cut(paths[role],start,FRAMES)
            if part.startswith('guitar'):x=tone(x,part.removeprefix('guitar_'))
            name = f'dgad_{index:02d}_{part}.wav'
            entry['parts'][part] = dict(path=f'res://experiments/playable_flightcase/audio/{VERSION}/{name}',**write_asset(args.output,name,x))
            (args.output/(name+'.import')).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n[params]\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=0\ncompress/mode=0\n')
        manifest['entries'][f'dgad_{index:02d}_v1'] = entry
    (args.output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    # No existing character content/clip manifests are replaced. These short
    # isolated clips are private review material, outside the game project.
    previews = []
    for role, starts, profiles in [('Guitar',[.6,40.8],['cast_jack','cast_arjun']),
                                  ('Bass',[19.2,81.6],['cast_zoe']),
                                  ('Drums',[24.0,67.2],['cast_ellis','cast_marcus'])]:
        source = next(s for s in sources if s['role']==role)
        for index,start_s in enumerate(starts,1):
            name = f'{role.lower()}_{index:02d}_candidate.wav';start=round(start_s*RATE)
            previews.append(dict(file=name,role=role,source=source,source_start_frame=start,
                                 source_end_frame_exclusive=start+230400,frames=230400,seconds=4.8,
                                 possible_profiles_by_instrument_only=profiles,character_assigned=False,
                                 **write_asset(args.audition_output,name,cut(paths[role],start,230400))))
    (args.audition_output/'manifest.json').write_text(json.dumps(dict(previews=previews,listening_verified=False,
        character_or_written_part_match_verified=False,in_game=False),indent=2)+'\n')
    assert sum(p.stat().st_size for folder in [args.output,args.audition_output] for p in folder.iterdir())<64*1024*1024
    assert all(sha((args.assessment_dir/'originals'/s['name']).read_bytes())==s['sha256'] for s in sources)
    print(json.dumps(dict(song_families=6,song_assets=30,isolated_preview_candidates=6,
                          frames=FRAMES,seconds=9.6,tempo_estimate=100,originals_unchanged=True,
                          listening=False,character_assignments_made=0)))


if __name__=='__main__':main()
