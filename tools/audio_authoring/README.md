# Offline audio authoring foundation

A nonshipping, Python standard-library tool for planning and checking audio studies. It supports **instrument clips, auditions and full ensemble song snippets** through the same request contract. Indie is the initial style profile; style guidance and backend/study descriptors live in JSON rather than guitar-specific code.

This first version **does not generate, edit, play, upload or integrate audio**. There is no render command, executable backend, network client, model download or new dependency. It is useful now for validating briefs, finding capability/rights/cost/budget blockers and inspecting real PCM WAVs. A backend integration is a separate next step.

From the repository root:

```sh
python3 -m tools.audio_authoring check-request tools/audio_authoring/examples/indie_audition.json
python3 -m tools.audio_authoring plan tools/audio_authoring/examples/indie_audition.json
python3 -m tools.audio_authoring plan tools/audio_authoring/examples/indie_song_snippet.json
python3 -m tools.audio_authoring inspect /absolute/path/to/review.wav
python3 -m tools.audio_authoring audit /absolute/path/to/bundle.json
python3 -m unittest discover -s tests -p test_audio_authoring.py
```

A valid `plan` exits zero even when it reports `status: hold`; it is an offline report. Always read `holds` and `generation_allowed` (always false in this version). Invalid/unsupported input exits two with a JSON error. No field or clearance label can enable execution.

## Requests and styles

The examples demonstrate a four-second rhythm-guitar audition proposal and a thirty-second multi-instrument song excerpt proposal. Durations describe the **whole asset, including its tail**. `tail_seconds` reserves part of that duration; it does not add extra time. Tempo, meter, harmonic structure or future authoring metadata can be recorded in `extensions`; `arrangement` holds the musical brief. Instrument IDs and roles are open identifiers, allowing multiple guitars in different roles and future instruments without changing the schema.

`musicianship` accepts optional qualitative technique, timing, originality, feel, versatility and presence descriptions. It does not calculate a skill score, invent a character biography or use reliability/collaboration as instrumental ability. Reports are private authoring data, not player-facing grades or a best-choice answer key. Select the band's actual style; Jack has no personal genre field.

Use a complete local registry with `--catalog /path/to/catalog.json` before the subcommand to add a style profile, provider descriptor or proposed study. Version 1 retains custom metadata under `extensions`; unknown core fields/future versions fail explicitly. A new genre can be represented as data; it still needs its own musical proof. Registering a backend descriptor is not implementing or clearing a backend.

## Backends and authority

The included ACE-Step 1.5 entry is a **research candidate**, not a connected/installed renderer. Its documented minimum is ten seconds. Source pin and provider code/model statements are recorded separately from actual output-rights, capability, local-runtime and cost clearance. Provider licensing statements do not prove the rights of a particular generated recording; prompt control does not prove isolated-instrument quality. Cost is unverified, not assumed free.

A later renderer can consume validated requests and produce a manifest of actual source/intermediate/review assets. Keep provider invocation separate from the planning/inspection module and retain explicit clearance before execution. This package never shells out or imports a dynamic provider. It also makes no claim about physical instrument realism, genre authenticity, audible skill calibration or listening acceptance.

## Budgets and provenance

Tool schema flexibility does not broaden an adopted asset study. The AU01 profile retains **four charged files / 32.097392 seconds / 2,950,158 bytes**, against **five files / 36.5 seconds / 4 MiB**. Historical local originals remain unavailable; the charged inventory is not a claim that they have been recovered. The old listening examples remain review history.

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

Next integration work: choose a practical cleared renderer, verify its actual raw format and instrument/style behaviour, adopt a complete study budget, then produce one bounded musical prototype for owner listening. Playback in the game remains a separate integration contract with Play/Stop/mute/interruption/silent fallback and zero gameplay/save/Finance/day effects.
