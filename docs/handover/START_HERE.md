# BandMaster — next chat starts here

Owner handover, 10 November 2026. Repository: `alimuir654-rgb/BandMaster`.
Use **`feature/playtest-polish-v20`**. Do not work from `main` or rewrite/force-push commits.

Read `AGENTS.md`, the improvement check/lessons, and
`docs/continuous_improvement/CURRENT.json` before changes. Use one writer and a fresh scoped preflight.
Historical overnight deadlines and older branch/build instructions do not supersede this handover.

## Latest continuation — BUILD43 / V24 signing handoff

All audio is restored and the new combined **unsigned V24 APK is built and audited**.
No more audio uploads are needed. Packaged source `462b68ad7211a639bea204a6ab0d94f4fd942875`;
read `docs/continuous_improvement/BUILD43_RESULTS.json` and the current V24 section
of `docs/signing/README.md`. This supersedes the older restoration/build holds below.

Actual compiled APK assets pass500model +416native(fourviewports) +10focusedSettings
+69metadata +17publicsigner checks.62originalPNGs retained,15files actually opened.
Desktop compiled-payload proof, not listening or physical Android testing. Source
crowd/vocal approvals retained; global owner artwork approval remains false.

Private APK: `/workspace/bandmaster-build43/BandMaster-Playtest-v24-UNSIGNED.apk`,
461,781,871bytes, SHA`e957cd727a2a584942c07170a7d298468017ec428f73754af82613b11a93a5f1`.
App/entry/save identities unchanged. New public request:
`docs/signing/BandMaster-V24-APK-v2-signing-request.json`,
SHA`8072969d2d165075f5cf7df30aa118ed95232b8c7b71d10c2c3b732b02cc191b`. It is bound to this exactAPK/source, not V23.

Only next action: original signing environment uses its existing original key and
returns the small V24 signature JSON. Current environment has no original key.
Then assemble this exactAPK with `--public-reference` and require fresh official
apksigner/unchanged-payload checks. No replacement key, app-ID change or key transfer.
The initial editor import's unused automatic debug key was caught before export,
removed without reading/signing, and fallback prevented for the successful build;
see retained incident evidence. V23/policy/request and public fixtures unchanged.

Private sources/media/APK stay outside public Git. Actual source root:
`/workspace/BandMaster-v20`; current SDK and evidence:
`/workspace/bandmaster-build43/`. Original-key reference now uses the exact pinned
public V22 request+real signature, explicitly retaining its historical official
audit rather than claiming an absent V16 APK was freshly verified. Writer released.

## Previous continuation — RESTORE42

The owner restored the older sources. **All requested audio is now recovered**;
AUDIO41's missing-file hold below is historical.25originals506,891,492bytes were
downloaded privately and checked against Dropbox block hashes/SHA/revisions.
Five Steady Hundred originals match their historical hashes;10Steadyv1 WAVs
reproduce the archived bytes exactly. Actual rehearsal title is Rehearsam Loop.

Source `dc2eca1ad54b63310c076dee500f5e4730358a23`; read
`docs/continuous_improvement/RESTORE42_RESULTS.json`. Original unchanged preparers
recover170legacyWAVs,32currentfoundations,20characterclips, title music and3formation
cues. Existing approved INDIE39/CROWD37 banks and original sources stay unchanged.
Title Ogg was re-encoded, with its tracked SHA receipt renewed truthfully.
Private originals/receipts/proof: `/workspace/bandmaster-restore42/`;
restored indie intake: `/workspace/indie-intake-20261109/`. Worktree and isolated
QA project both contain the recovered banks. `tools/restore_legacy42.py` documents
the bounded recovery workflow and refuses to overwrite banks/intakes.

890asset +724Godot model checks pass, including all32legacy sources and six
families through18real paid stages with failed-save rollback/retry/exact typed
reload.5184legacy recipe outputs retain the baseline hash. A complete1130-file
version24 project at `/workspace/bandmaster-restore42/materialized/project`
passes clean import and every source-manifest hash. No new UI/art, listening or
physical-device claim; earlier native evidence remains separately retained.

No APK or signing request created in this restoration session. Next prepare and
audit the full unsigned version24 package, then a new bound detached request.
Preserve app/save identity, frozenV23/request and original key environment.
Media remains private; no more audio uploads are needed. Writer released.

## Previous continuation — AUDIO41 source availability audit

The owner cleared older Dropbox content. A fresh read-only audit exhausted
`/audio files` and `/BandMaster` listings and checked local inventories. The new
three songs and complete crowd bank are retained, but the older source sets are
absent from the known audio folder/local banks. Do not promise full restoration
from Dropbox without checking what is actually there.

`/BandMaster/BandMaster-recorded-audio-source.zip` remains. Its20,785,360bytes,
historical SHA`33d96e02a9601f1c994e211cbd5cbe6aa6f4e1473176aacab42cf3e332ee167d`,
Dropbox block-content hash and ZIP CRC were verified. The ZIP contains only the
old `recorded_steady_v1` bank, not currentv2 or the later banks. No old source was
applied and no audio was relabeled. Private copy/inventory:
`/workspace/bandmaster-audio41/`. Read `docs/continuous_improvement/AUDIO41_RESULTS.json`.

Required original WAVs: **Guitar, Bass and Drums** for each of **Steady Hundred,
Rehearsam** (earlier rehearsal instrumental), **D–G–A–D, G–D–Em–C,
Rehearsion Space, Rehearsal D Minor**, plus **Percussion for Steady Hundred**:
19stems total. Full mixes are optional references. The owner can restore these
from Dropbox Deleted files if available or reupload to `/audio files`. No recovery
or Dropbox mutation was performed here. A retained V22 APK or complete private
prepared-bank backup could be inspected as an alternate source if supplied;
none is currently in the known retained folders/local workspace.

No need to reupload Get the Good Plates Down, Wear and Tear, Underneath the
Kitchen Stairs or the four crowd MP3s. No engine/build/signing or app/key/V23
change. The full version24 package remains held for legacy-media restoration.
Writer released; global owner artwork approval remains false.

## Previous continuation — CROWD40

The owner supplied all four approved crowd MP3s in chat. **The crowd bank is now
complete**; the previous three-file acquisition blocker is resolved by these
uploads. No further crowd download or environment allowance is needed for this bank.

Source `4220499c1cdb6fff964e62d19a6de0b79625d21f`; read
`docs/continuous_improvement/CROWD40_RESULTS.json`. Exact source hashes are pinned
in `docs/audio/CROWD37_SOURCES.json`. Private originals/receipt, complete prepared
bank and evidence are at `/workspace/bandmaster-crowd40/`; worktree and isolated
QA project both contain the complete ignored `audio/crowd37/` bank.
Run `tools/prepare_crowd37.py prepare --sources <private originals> --output <new directory>`
to restore it offline. The pub upload matches the earlier official SHA; the three
BigSoundBank files are owner uploads, not newly verified network downloads.

Entrance2479, between-song2486, courtesy3521 and final cheer35748 use short real
recordings. Courtesy starts at2.0s to include active applause. An initial FFmpeg
seek/fade ordering defect was caught numerically and corrected with explicit
trim/reset before fades; independent PCM comparison now checks every derivative.
Both early attempts remain in private evidence. Required CC BY credit remains
packaged and visible in Settings. No rejected boo is included.

Final **495checks pass**:48source/preparation,7compatibility,60Godot decoder/lifecycle
and380native. Four real main-app gig journeys use the paid Maya/Freya version5
song, verify stage overlap/courtesy, failed-save rollback, held-source interruption,
Menu/Continue no replay and exact reload. The one-song fixture earns a poor-show
verdict, correctly leaving its unapproved boo silent; positive cheer is tested
in the real-stream component proof.48original PNGs retained,12opened. No new
assistant listening or physical Android claim; derivative listening remains unverified.

**No APK or signing request was created.** The crowd preflight now passes for
version24, but older private music banks and the Android SDK are absent here.
Next restore those retained private banks into a fresh build workspace, audit
the whole combined version24 package, then create a NEW detached-signing request.
Keep frozenV23/request unchanged, app ID/save folder unchanged and the existing
key in its original environment. Owner audio stays outside public GitHub.
Writer released; global artwork approval remains false.

## Previous continuation — INDIE39

The owner approved the displayed **first** sparse/full excerpts for all three
songs. These are now integrated privately: Maya/Freya — Get the Good Plates Down,
Lily/Dan — Wear and Tear, Sam/Oscar — Underneath the Kitchen Stairs.
Only candidate1 is promoted; later candidate windows remain review material.

Runtime source: `c376cc08e8a96a8da7146dc590c5207bdfdf90ed`.
Read `docs/continuous_improvement/INDIE39_RESULTS.json`. Six character previews
and three additive version5 song foundations use15exact approved PCM assets in
ignored `experiments/playable_flightcase/audio/recorded_indie39/`.
`tools/prepare_indie39.py` recreates that bank from retained private INDIE38
candidate1 sources. The same vocal asset/level is retained across backing
arrangements. Live writing requires the named active singer/keyboardist;
completed saved songs retain their original performers. Nina has no supplied clip.
No initial talent-budget rebalance was made for the expensive Sam/Oscar pair.

104model and312native checks pass across four viewports, with32original captures
and16opened originals. Actual three-stage paid save/rollback/reload is verified
with the affordable Maya/Freya band; all three source bindings and15PCM files
are checked. The5184-case legacy recipe hash is unchanged. Evidence and isolated
saves: `/workspace/bandmaster-indie39/`; QA project remains
`/workspace/bandmaster-crowd36/project`. This is desktop source/native proof,
not new assistant listening, physical Android proof or global artwork approval.

At the INDIE39 checkpoint there was **no new APK or signing request**, and Crowd37
still needed three recordings. CROWD40 above completes that bank.
Keep V23/request unchanged, use a new audited version>23 request, preserve app ID
and sign only with the existing key in its original environment. All owner music
and derivatives remain outside public GitHub. Writer released.

## Previous continuation — INDIE38

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

At the INDIE38 checkpoint there was **no listening/character-fit acceptance or
game integration yet**; INDIE39 above supersedes this hold for candidate1. Other candidates
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
- Historical CROWD34 evidence lacked actual crowd clips. CROWD40 above now supplies
  all four approved sources; no new boo was approved, so that cue stays silent.

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
