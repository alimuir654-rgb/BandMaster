# Offline audio authoring

A nonshipping, Python standard-library tool for planning and checking audio studies. It supports **instrument clips, auditions and full ensemble song snippets** through the same request contract. Indie is the initial style profile; style guidance and backend/study descriptors live in JSON rather than guitar-specific code.

S92 introduced standard-library planning and inspection. S93 adds an **explicit local SFZ renderer** using recorded instrument multisamples and an isolated optional audio environment. Planning still cannot launch a backend. The tool does not acquire samples/models, call a service, play/upload files or integrate with Godot. Current musical proof is electric guitar in indie; other instruments and styles remain unproved.

From the repository root:

```sh
python3 -m tools.audio_authoring check-request tools/audio_authoring/examples/indie_audition.json
python3 -m tools.audio_authoring plan tools/audio_authoring/examples/indie_audition.json
python3 -m tools.audio_authoring plan tools/audio_authoring/examples/indie_song_snippet.json
python3 -m tools.audio_authoring inspect /absolute/path/to/review.wav
python3 -m tools.audio_authoring audit /absolute/path/to/bundle.json
python3 -m unittest discover -s tests -p test_audio_authoring.py
```

A valid `plan` exits zero even when it reports `status: hold`; it remains an offline report. `generation_allowed` stays false: changing catalog clearance fields never executes a renderer. The separate explicit `render-local` command requires an adopted source/study contract and exact reviewed local assets.

## Requests and styles

The examples demonstrate a four-second rhythm-guitar audition proposal and a thirty-second multi-instrument song excerpt proposal. Durations describe the **whole asset, including its tail**. `tail_seconds` reserves part of that duration; it does not add extra time. Tempo, meter, harmonic structure or future authoring metadata can be recorded in `extensions`; `arrangement` holds the musical brief. Instrument IDs and roles are open identifiers, allowing multiple guitars in different roles and future instruments without changing the schema.

`musicianship` accepts optional qualitative technique, timing, originality, feel, versatility and presence descriptions. It does not calculate a skill score, invent a character biography or use reliability/collaboration as instrumental ability. Reports are private authoring data, not player-facing grades or a best-choice answer key. Select the band's actual style; Jack has no personal genre field.

Use a complete local registry with `--catalog /path/to/catalog.json` before the subcommand to add a style profile, provider descriptor or proposed study. Version 1 retains custom metadata under `extensions`; unknown core fields/future versions fail explicitly. A new genre can be represented as data; it still needs its own musical proof. Registering a backend descriptor is not implementing or clearing a backend.

## Backends and authority

The included ACE-Step 1.5 entry is a **research candidate**, not a connected/installed renderer. Its documented minimum is ten seconds. Source pin and provider code/model statements are recorded separately from actual output-rights, capability, local-runtime and cost clearance. Provider licensing statements do not prove the rights of a particular generated recording; prompt control does not prove isolated-instrument quality. Cost is unverified, not assumed free.

A later renderer can consume validated requests and produce a manifest of actual source/intermediate/review assets. Keep provider invocation separate from the planning/inspection module and retain explicit clearance before execution. This package never shells out or imports a dynamic provider. It also makes no claim about physical instrument realism, genre authenticity, audible skill calibration or listening acceptance.

## Budgets and provenance

The historical AU01 profile retains **four charged files / 32.097392 seconds / 2,950,158 bytes**, against its former **five files / 36.5 seconds / 4 MiB**. The owner directly waived these limits for the new listening experiment and approved new dependencies. `OWNER_REVIEW_20261103` records the separate adopted scope and durable storage allocation. Historical local originals remain unavailable; new sample acquisition is not recovery of contemporaneous originals. Earlier examples remain review history.

The audition example plans a ten-second source and a separate four-second review. It correctly reports six total charged files and 46.097392 seconds, as well as format/capability/clearance blockers. The full-song example is representable but reports an unadopted study contract. A larger study needs a prospective scope/budget decision; this tool does not make it.

All raw, intermediate and derived assets count, including tails and complete container bytes. Cropping cannot erase the source. `same_asset` counts one physical source/review only when complete duration and format agree; an invalid same-asset claim is held and conservatively plans both assets. Planned bytes use requested PCM format plus a stated header reserve and are **estimates**, not verified provider output or a guaranteed upper bound. Inspect and audit the actual whole bundle before using those figures as evidence. Replanning clips individually is not an aggregate project allocation or a reservation system.

Example actual bundle (paths are absolute, or relative to the command's working directory):

```json
{
  "schema_version": 1,
  "study": "AU01",
  "assets": [
    {"id": "raw_take", "path": "/path/to/raw.wav", "role": "source", "parents": [],
     "rights_clearance": "cleared", "rights_evidence": "/path/to/reviewed-rights-receipt.json"},
    {"id": "review", "path": "/path/to/review.wav", "role": "review", "parents": ["raw_take"],
     "rights_clearance": "cleared", "rights_evidence": "/path/to/reviewed-rights-receipt.json"}
  ]
}
```

The graph refuses missing parents, cycles and repeated IDs/paths. Rights fields are supplied review records, not a license detector: `technical_audit_pass` cannot approve listening or game integration. Include every source and intermediate in the bundle; the tool cannot discover an omitted, undeclared asset. It does not delete files or refund charged history.

## WAV inspection

Inspection streams uncompressed **integer PCM WAV** (8/16/24/32-bit) in chunks and reports SHA256, complete container bytes, actual frame count, channels/rate, exact rational duration, sample peak, RMS and silence. Truncated or partial-frame data is refused. Silence has null level values, not invalid JSON infinities. Source formats can differ from review delivery formats; AU01's review rule remains mono 16-bit at no more than 48 kHz.

RMS is not LUFS. Sample peak is not decoded true peak. Inspection is not a listening/device/rights check and never normalises, trims, resamples or silently downmixes a file. Tests use tiny in-memory structural PCM fixtures, not generated musical/listening assets.

Playback in the game remains a separate integration contract after owner listening acceptance, with Play/Stop/mute/interruption/silent fallback and zero gameplay/save/Finance/day effects.

## Explicit sample rendering

Install `requirements-review.txt` in a dedicated CPython3.12/Linux x86_64 environment with existing NumPy, using `pip --require-hashes --no-deps --only-binary=:all:`. Wheel hashes are platform-specific. Pedalboard is GPL3; pysfizz is BSD2 and wraps sfizz. These are local authoring tools, not Game dependencies. Their licenses do not license instrument samples.

```sh
/path/to/isolated/venv/bin/python -m tools.audio_authoring render-local /absolute/path/to/score.json --output-dir /absolute/path/to/new-take
```

A version1 score declares ID/style, 44100/48000Hz, whole duration and reserved tail, explicit authoring authority and rights-receipt path, plus tracks. Each track declares instrument/role IDs, local self-contained SFZ path/hash, acquisition-manifest path/hash, independent voice count, gain and notes (`at`, `off`, MIDI `pitch`, `velocity`, `voice`). Independent voices can represent individual guitar strings. Incompatible overlapping notes on one voice are refused. Events retain sample offsets, note-off precedes a same-sample retrigger, and samplers stay alive across the score to retain alternate-take sequencing.

The current adapter checks a complete CC0 source inventory before and after rendering, hashes every sample and refuses includes/macros/undeclared SFZ samples. Other license classes or complex banks need a reviewed adapter change. It retains `raw.wav`, restrained `room.wav` and `render.json`, refusing existing take directories, clipped/nonfinite output, active voices at the end or an insufficiently decayed final200ms. It never trims away a source or tail. Measure decoded loudness/true peak separately before delivery; these checks cannot determine musical realism.

S93 uses a fresh Black And Green Guitars CC0 subset pinned to `b3b3249d37dc977a1a297bd2dc053e6d9b6b805c`:13 recorded MIDI pitches, three velocity layers,130 distinct WAVs /156 SFZ regions. The quiet layer repeats two distinct alternate takes over four sequence slots; medium/loud layers have four distinct takes. Numeric MIDI mapping governs pitch rather than filename octave labels. This replaces the rejected single-note repitch method. D/G/A/D phrasing uses playable fingerings and ordered up/down strokes. It is a sample-based virtual guitar, not a live musician or an accepted Jack performance.

New instruments can use other local SFZ tracks and explicit voice layouts; ensembles can contain multiple tracks in one aligned score. Style descriptors stay data. This interface permits those later experiments without claiming their audio quality has already been proved. A new character/performance variant needs an audible source-grounded listening comparison, separate from composition quality. Do not infer hidden skills, best choices or Game effects from authoring data.
