"""Explicit local SFZ score rendering, outside Game; never acquires assets.

Scores can contain instrument tracks and independent voices (e.g. guitar strings).
Instrument/style descriptors are data. Only the S93 electric-guitar/indie study has
been musically exercised; accepting another score is not a quality guarantee.
"""
from pathlib import Path
import hashlib
import json
import math
import re
import wave
from .core import AuthoringError, load_json, identifier, integer, seconds, version


def sha(path):
    with Path(path).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def validate_score(score):
    version(score, 'score')
    if set(score) != {'schema_version', 'id', 'style', 'sample_rate', 'duration_seconds',
                      'tail_seconds', 'tracks', 'rights_receipt', 'authoring_authority'}:
        raise AuthoringError('Unknown or missing score fields')
    for name in ('id', 'style'): identifier(score[name], name)
    if score['sample_rate'] not in (44100, 48000) or type(score['sample_rate']) is not int:
        raise AuthoringError('Score sample rate must be 44100 or 48000')
    duration = seconds(score['duration_seconds'], positive=True)
    tail = seconds(score['tail_seconds'], positive=True)
    if duration > 120 or tail >= duration:
        raise AuthoringError('Local renderer supports at most 120 seconds including a shorter tail')
    for name in ('rights_receipt', 'authoring_authority'):
        if not isinstance(score[name], str) or not score[name].strip():
            raise AuthoringError('An explicit ' + name + ' is required')
    tracks = score['tracks']
    if not isinstance(tracks, list) or not 1 <= len(tracks) <= 16:
        raise AuthoringError('Score needs 1..16 tracks')
    ids = set()
    for track in tracks:
        if not isinstance(track, dict) or set(track) != {'id', 'instrument', 'role', 'sfz',
                'sfz_sha256', 'source_manifest', 'source_manifest_sha256', 'voices', 'gain', 'notes'}:
            raise AuthoringError('Invalid track fields')
        for name in ('id', 'instrument', 'role'): identifier(track[name], name)
        if track['id'] in ids: raise AuthoringError('Duplicate track ID')
        ids.add(track['id'])
        voices = integer(track['voices'], 'voices', 1)
        if voices > 12: raise AuthoringError('At most 12 independent voices per track')
        gain = track['gain']
        if type(gain) not in (int, float) or not math.isfinite(gain) or not 0 < gain <= 1:
            raise AuthoringError('Finite gain in (0,1] required')
        for key in ('sfz_sha256', 'source_manifest_sha256'):
            if not isinstance(track[key], str) or not re.fullmatch('[0-9a-f]{64}', track[key]):
                raise AuthoringError('Exact SHA256 required')
        if not isinstance(track['notes'], list) or not 1 <= len(track['notes']) <= 10000:
            raise AuthoringError('Track needs 1..10000 notes')
        by_voice = {}
        for note in track['notes']:
            if not isinstance(note, dict) or set(note) != {'at', 'off', 'pitch', 'velocity', 'voice'}:
                raise AuthoringError('Invalid note fields')
            start = seconds(note['at']); end = seconds(note['off'], positive=True)
            if end <= start or end > duration - tail:
                raise AuthoringError('Notes must end before the reserved release tail')
            for key, lo, hi in (('pitch',0,127),('velocity',1,127),('voice',0,voices-1)):
                if integer(note[key], key, lo) > hi: raise AuthoringError('Note outside MIDI/voice bounds')
            by_voice.setdefault(note['voice'], []).append((start, end))
        for notes in by_voice.values():
            notes.sort()
            if any(b[0] < a[1] for a,b in zip(notes,notes[1:])):
                raise AuthoringError('Overlapping incompatible notes on one voice')
    return score


def verify_sources(track):
    sfz = Path(track['sfz']).resolve(strict=True)
    manifest_path = Path(track['source_manifest']).resolve(strict=True)
    if sha(sfz) != track['sfz_sha256'] or sha(manifest_path) != track['source_manifest_sha256']:
        raise AuthoringError('Instrument/source manifest changed')
    manifest = load_json(manifest_path)
    if manifest.get('complete') is not True or manifest.get('license') != 'CC0-1.0':
        raise AuthoringError('This study adapter requires the complete reviewed CC0 source receipt')
    root = manifest_path.parent / 'instrument'
    allowed = set()
    for row in manifest['rows']:
        path = (root / row['path']).resolve(strict=True)
        if not path.is_relative_to(root.resolve()) or path in allowed:
            raise AuthoringError('Duplicate or escaping source path')
        if path.stat().st_size != row['bytes'] or sha(path) != row['sha256']:
            raise AuthoringError('Recorded sample changed: ' + row['path'])
        allowed.add(path)
    content = sfz.read_text()
    # This adapter deliberately accepts a simple explicit-region subset, no
    # executable plugin, includes, macros or outside/undeclared sample files.
    if '#include' in content or '#define' in content or 'default_path=' in content:
        raise AuthoringError('Only explicit self-contained SFZ regions supported')
    samples = re.findall(r'(?m)^sample=([^\r\n]+)$', content)
    if not samples: raise AuthoringError('No recorded samples declared')
    for sample in samples:
        if (sfz.parent / sample).resolve(strict=True) not in allowed:
            raise AuthoringError('SFZ references an undeclared sample')
    return {'sfz_sha256': sha(sfz), 'source_manifest_sha256': sha(manifest_path),
            'files': len(allowed), 'sample_references': len(samples)}


def events_for_track(track, rate):
    events = []
    for note in track['notes']:
        # Off before on if two events share a sample, preserving retriggers.
        events.append((round(float(seconds(note['at']))*rate), 1, note['voice'], note['pitch'], note['velocity']))
        events.append((round(float(seconds(note['off']))*rate), 0, note['voice'], note['pitch'], 0))
    return sorted(events)


def write_pcm24(path, audio, rate):
    import numpy as np
    peak = float(np.max(np.abs(audio)))
    if not np.isfinite(audio).all() or peak >= 1:
        raise AuthoringError('Refusing nonfinite or clipped PCM')
    values = np.rint(audio.T.reshape(-1)*8388607).astype('<i4').view(np.uint8).reshape(-1,4)
    with Path(path).open('xb') as f, wave.open(f, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(3); w.setframerate(rate)
        w.writeframes(values[:,:3].tobytes())


def render_score(score_path, output_dir):
    score = validate_score(load_json(score_path))
    sources = [verify_sources(t) for t in score['tracks']]
    receipt = Path(score['rights_receipt'])
    if not receipt.is_file(): raise AuthoringError('Rights receipt not found')
    receipt_hash = sha(receipt)
    # Explicit command only. Importing/planning/checking needs no audio deps.
    import numpy as np
    import pysfizz
    import pedalboard
    import importlib.metadata
    out = Path(output_dir)
    if out.exists(): raise AuthoringError('Output directory must be new; preserve earlier takes')
    rate = score['sample_rate']; frames = round(float(seconds(score['duration_seconds']))*rate)
    block = 256
    mix = np.zeros((2, frames), dtype=np.float32)
    active_at_end = []
    for track in score['tracks']:
        synths = [pysfizz.Synth(sample_rate=rate, block_size=block) for _ in range(track['voices'])]
        for synth in synths:
            if not synth.load_sfz_file(track['sfz'], quiet=False):
                raise AuthoringError('SFZ engine refused instrument')
            if any(n['pitch'] not in synth.playable_keys for n in track['notes']):
                raise AuthoringError('Instrument does not cover a requested MIDI pitch')
        events = events_for_track(track, rate); cursor = 0
        for start in range(0,frames,block):
            while cursor < len(events) and events[cursor][0] < start+block:
                at, kind, voice, pitch, velocity = events[cursor]
                native = synths[voice]._synth  # pinned pysfizz low-level sample-delay API
                method = native.note_on if kind else native.note_off
                method(at-start, pitch, velocity); cursor += 1
            count = min(block, frames-start)
            for synth in synths:
                left,right = synth._synth.render_block()
                mix[0,start:start+count] += left[:count]*track['gain']
                mix[1,start:start+count] += right[:count]*track['gain']
        active_at_end.extend(s._synth.get_num_active_voices() for s in synths)
    if sources != [verify_sources(t) for t in score['tracks']] or sha(receipt) != receipt_hash:
        raise AuthoringError('Source changed during rendering')
    if max(active_at_end): raise AuthoringError('Tail ended while sampler voices remained active')
    effects = pedalboard.Pedalboard([
        pedalboard.HighpassFilter(cutoff_frequency_hz=65),
        pedalboard.LowpassFilter(cutoff_frequency_hz=6800),
        pedalboard.Compressor(threshold_db=-22,ratio=1.8,attack_ms=12,release_ms=90),
        pedalboard.Reverb(room_size=.14,damping=.65,wet_level=.055,dry_level=.95,width=.5)])
    processed = effects(mix, rate, reset=True)
    if float(np.max(np.abs(processed[:,-round(.2*rate):]))) > .001:
        raise AuthoringError('Final 200ms not sufficiently decayed; extend full tail before review')
    out.mkdir(parents=True)
    write_pcm24(out/'raw.wav',mix,rate)
    write_pcm24(out/'room.wav',processed,rate)
    report = {'score_id':score['id'],'score_sha256':sha(score_path), 'frames':frames,
              'sample_rate':rate,'duration_seconds':frames/rate,'sources':sources,
              'notes':sum(len(t['notes']) for t in score['tracks']),
              'active_sampler_voices_at_end':active_at_end,
              'raw_peak':float(np.max(np.abs(mix))),
              'room_peak':float(np.max(np.abs(processed))),
              'last_200ms_peak':float(np.max(np.abs(processed[:,-round(.2*rate):]))),
              'versions':{n:importlib.metadata.version(n) for n in ('pysfizz','pedalboard','numpy')},
              'outputs':{p.name:sha(p) for p in out.glob('*.wav')},
              'rights_receipt_sha256':receipt_hash,
              'listening_acceptance':False,'game_integration':False}
    (out/'render.json').write_text(json.dumps(report,indent=2)+'\n')
    return report
