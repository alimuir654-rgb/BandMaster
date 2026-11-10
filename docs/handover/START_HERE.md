# BandMaster — next chat starts here

Owner handover, 10 November 2026. Repository: `alimuir654-rgb/BandMaster`.
Use **`feature/playtest-polish-v20`**. Do not work from `main` or rewrite/force-push commits.

Read `AGENTS.md`, the improvement check/lessons, and
`docs/continuous_improvement/CURRENT.json` before changes. Use one writer and a fresh scoped preflight.
Historical overnight deadlines and older branch/build instructions do not supersede this handover.

## Latest continuation — INDIE38

Three new owner songs are now privately downloaded and technically assessed:
**Get the Good Plates Down** (Maya/Freya proposal), **Wear and Tear** (Lily/Dan)
and **Underneath the Kitchen Stairs** (Sam/Oscar). Each has five WAV stems;
the third also has an MP3 reference. Originals are at
`/workspace/bandmaster-indie38/originals`; exact intake IDs/revisions/content
hashes are in private `intake.json`. All16content/SHA/revision checks pass.

Read `docs/continuous_improvement/INDIE38_RESULTS.json`. There are9candidate
windows,45matched stem excerpts,27sparse/groove/full variants and3conservative
reconstructed full references under `/workspace/bandmaster-indie38/candidates`.
127actual source/asset/arrangement checks pass. One vocal PCM asset is shared
unchanged across each candidate's three backing arrangements. Source clocks
are identical within each set; rough rhythm estimates are ~102/~114/~114BPM,
not proof of the prompt tempos, bar grid, key or phrase boundaries. Third-song
MP3 first60s comparison shows no estimated start lag and0.956correlation;
reconstructed mix/mastering is not byte-identical original Suno output.

**No listening/character-fit acceptance or game integration yet.** Candidates
need lyric-boundary/separation/musical review before a separately versioned
vocal/keys runtime recipe and participant binding. Do not reassign these voices
to Nina or mix unrelated clocks/chords. Originals and derivatives stay private,
outside Git. No generation/credit spend, UI/save changes, APK, signing request
or key operation. Earlier CROWD37 host blocker remains unchanged.

## Previous continuation — CROWD37

The owner rejected the old crowd shortlist, then explicitly approved four new
table sources: BigSoundBank **2479 / 2486 / 3521** and Freesound **35748**.
Only the approved pub source35748 is acquired here. Its real cheer and required
CC BY credit in Settings are integrated and tested. The three BigSoundBank files
remain blocked by the selected running proxy (CONNECT403); an async request to
add `bigsoundbank.com` is pending. Do not use mirrors to bypass a denial or
substitute earlier rejected clips. No new boo was approved; that cue stays silent.

Read `docs/continuous_improvement/CROWD37_RESULTS.json` and
`docs/audio/CROWD37_SOURCES.json`. New private bank path is
`experiments/playable_flightcase/audio/crowd37/`; current preparation is explicitly
partial. `tools/prepare_crowd37.py fetch/prepare` restores the approved sources
with hash receipts; strict preparation refuses missing files. The owner project
materializer also refuses an incomplete bank or a new crowd version<=23 before
creating output. No APK or new signing request was made.

Character-grounded production prompts and identical-vocal-take reuse contract:
`docs/audio/INDIE_CHARACTER_VOCAL_KEYS_BRIEF.json`. Four singers and three
keyboardists; first suggested pilot Maya/Freya. Short complete2/4bar phrases,
one private vocal master across compatible sparse/groove/full backings. Private
Style Persona only guides identity across different songs; no exact-output
guarantee, voice generation, credit spend or vocal/keys runtime/schema change.

Current source: `/workspace/BandMaster-v20`; original source35748, logs and8
native Settings captures: `/workspace/bandmaster-crowd37/`. Isolated QA project:
`/workspace/bandmaster-crowd36/project`. Rejected CROWD36 worktree candidates are
preserved outside the shipping tree at
`/workspace/bandmaster-crowd36/rejected-worktree-candidate`. Workspace paths are
not Git attachments. All original app/key/privacy/frozenV23 rules below remain.

## Current work and evidence

- V22 source: `16c477c588758eaf07418361fcae79b43f147b05`.
- Formation/budget/portraits/three-act gig batch: `dba007e3022d9d1a39365aab78b127d6a1d79f84`.
  See `docs/continuous_improvement/NEXT32_RESULTS.json`.
- Pre-CROWD37 **game** baseline: `c6f320bba6b6f6399f679daab07c9572fdbd0d55`.
  Saved arrangements play during gigs. Four registered generated pub-crowd illustrations
  respond to saved room feedback and the actual final receipt. Audio starts only after
  successful original save; interruption/held-source/no-replay guards are tested.
  See `docs/continuous_improvement/CROWD34_RESULTS.json`.
- Crowd pass: **331 model + 808 native assertions**, four viewport sizes, 76 final original PNGs.
  All final checks pass; early failed evidence retained. Independent AI source/pixel review,
  **not** human testing, listening, physical Android verification or owner artwork acceptance.
- **Actual cheers/boos are still missing.** The fade/manifest path exists; absent clips stay silent.
  Do not describe crowd audio as complete or substitute generated noise.

## Next work

**Historical CROWD36 update (candidates subsequently rejected):** the selected environment now allows the official
CDN and both exact CC0 previews have been downloaded. Five short real Vorbis cue
candidates are prepared privately, with 48 passing real Godot decoder/lifecycle
checks. They remain **unaccepted pending listening and in-game mix review**;
production audio is still held. No listening tool was available. See
`docs/continuous_improvement/CROWD36_RESULTS.json` for hashes, levels, commands,
manual review steps and retained failure evidence. No new APK/request was made.
Current source worktree: `/workspace/BandMaster-v20`; originals and isolated QA:
`/workspace/bandmaster-crowd36`; private candidates are in the ignored
`experiments/playable_flightcase/audio/crowd34/` directory. These are workspace
paths, not Git attachments. `tools/prepare_crowd36.py` can restore candidates from
the exact official preview bytes without owner music. The old private music,
V23 APK and Android SDK paths below are absent in this executor. Do not mistake
the temporary QA manifest acceptance for a listening review or ship it.

The following access-failure account is retained history from CROWD34:

Finish the crowd/audio batch before another owner test release. Owner prefers bigger coherent updates.
First check the **selected running environment**, not just the published settings:
the last observation still showed enforced revision 1 with only
`*.dl.dropboxusercontent.com` as a custom rule. `cdn.freesound.org` download returned CONNECT 403.
No environment-change/restart tool was available. Recheck with a fresh connection in the new chat;
do not bypass a denied destination or equate a published configuration with applied access.

Exact CC0 candidates, pages and preview URLs are in `CROWD33_RESULTS.json`:
Small Crowd Applause / miuziqa / Freesound 858309 and Booing Crowd / NeoSpica / 504621.
Only source/licence pages were verified; no binaries acquired or listened to.
Inspect actual encoding/hash/levels and listening/fit if listening tools exist, then integrate.
Use modest pub ambience, fade in/out and receipt-driven final cheers/boos. Ordinary starting
room vibe is 40; a blanket “below 50 means boo” is wrong. Do not predict success before saved wrap.
No extra mandatory Continue screens or duplicate financial settlement.

## Existing app and signing

Keep app **`com.bandmaster.ownerplaytest.s40`**, entry scene
`experiments/playable_flightcase/opening.tscn`, and save directory `BandMasterOwnerPlaytestS40`.
Keep the original certificate/key; **never generate a replacement**.
Read **[`../signing/README.md`](../signing/README.md)** for the reusable detached workflow.
The original key remains in its original build environment. This chat has no original-key binding.
Only a small public request and returned signature need travel between environments.

V23 is a frozen **older, unsigned** candidate. It does **not** contain CROWD34.
Its existing request is unchanged and has no returned signature.
Do not sign it and call it the latest crowd build. A future package containing newer changes
needs version code **greater than 23**, fresh package audit and a **new** bound request;
retain V23 and its request byte-for-byte. No new APK is built by this handover.

## Workspace/private media continuity

Git contains source, generated artwork, public signing data and reports, **not the private owner stem banks or APKs**.
Do not upload owner audio to public GitHub or change Dropbox sharing. Existing older repository
audio is historical; this publication adds no audio/APK/key binaries.
Music is owner-generated paid-plan **Suno audio**, not human performances;
commercial interactive-game shipping permission remains separately unresolved.

If the same workspace is retained, use:

- Source: `/workspace/BandMaster-polish`.
- Private QA project with recorded media: `/workspace/main-audio-proof/candidate/project`.
- Crowd proof: `/workspace/bandmaster-crowd34/verification.json` and original PNGs/logs.
- V23 unsigned APK, policy, audits and request: `/workspace/bandmaster-next32/`.
- Original public V16 APK: `/workspace/main-app-check/BandMaster-Playtest-v16-arm64.apk`.
- Android tools: `/workspace/tools/android-sdk/build-tools/35.0.0/`.
- Godot: `/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`.

These absolute paths are **workspace-local, not Git attachments or guaranteed in a new executor**.
Check them before use. Restore missing private assets from retained owner Dropbox originals
and source/hash manifests; scripts include `tools/prepare_indie29.py` and `prepare_next32_audio.py`.
Do not silently relabel reconstructed media or a rebuilt APK as the frozen V23 bytes.
If the retained APK is missing, its old detached signature cannot authorize another binary.

Original owner source folder: connected Dropbox `/audio files` and the separately retained
assessment/intake source identities. Exact source provenance and build details are in the
existing AUDIO29/NEXT32/CROWD reports. Do not rerun unchanged broad QA or request music again
without first checking these retained sources.
