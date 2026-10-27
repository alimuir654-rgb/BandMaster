# S06 — Studio recording and career first-pass, 27 October 2026

**Owner status:** S02 formation first-pass acceptable; S03 songwriting, S04 tour and S05 gig isolated engineering green. S06 remains **draft/isolated** and does not imply final material approval, production save integration or permission to merge PR #199.

## Play the studio journey

Open `res://poc/ldtd_studio_recording.tscn`, or choose **STUDIO** in `res://poc/ldtd_career_scene_shell.tscn`. The demo sample contains two original songs (qualities 67 and 74), £185, 18 fans and real readiness 61. Use the **photographed faders** to adjust monitor-only guitar/vocal balance, the original Lab08.4 rotary for headphone focus, and the original five-state Lab07 transport to **arm the deck**. The action dock then allows **RECORD TWO-DAY DEMO / £60**. On the resulting DUSK mix phase, choose **RELEASE DEMO / £25 / 1 DAY**. The NIGHT release is terminal, and duplicate record/release actions cannot change state.

This uses `Scripts/recording_career.gd` on a deep-copied local sample. Actual `Recording.record` requires two originals and £60, records two days later, adds one demo and +3 readiness. `Recording.release` charges £25 and one day, updates fans/press/buzz and flags that demo released. **Fader/rotary levels are monitor preferences only; they do not secretly change song quality or game outcome meters.** The photographed meter is inert, unfocusable, reads authoritative readiness and has zero-lit state at 0. No production save writes or actual music playback.

## Art and source provenance

`Art/UI/StudioCraft/README.md` documents each original photo-derived Lab05 fader, Lab07 transport, Lab08.4 rotary, Lab08 meter and existing five-state studio navigation control. One new **authored procedural SVG** is the brushed metal housing, not a claimed photograph. The DAY source is the previously licensed, genuinely bright Pexels **music-room** photo, not a recording-studio photo; DUSK/NIGHT use the existing repo rehearsal/backstage-room background with no new external provenance claim. All costs, song titles, meter readings and player-facing captions are native Godot text, not baked into art. The original approved target ZIP remains unverified in Git.

## Test plan and acceptance

`.github/workflows/ldtd-studio-s06.yml` runs the S06 preflight gate, source-presence/rights check, Godot 4.7.2 headless import, deterministic `tests/ldtd_s06_studio_tests.gd`, and **eight actual Godot renderer PNGs**: DAY at 390×844, 720×1280, 1280×720, 1600×900, plus DUSK and NIGHT at 390×844 and 1280×720. `tests/capture_ldtd_s06_studio.gd` asserts 44px targets, first-fold deck and fixed action, photo/chassis sources, phase captions, non-interactive meter and terminal release.

**Initial implementation head:** `90b8aa63f12bdcf9b3eb654849e7ab48fad1d483`. [Focused native workflow](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40546299494) was queued at initial checkpoint; no success or actual screenshot inspection is inferred from code alone. Revisit after run completes and append precise failure or screenshot findings. Five simulated lenses: player action clarity, musician recording semantics, photographic material depth, accessibility/focus/first-fold, and release engineering/save safety. No human owner final art approval.

## Deferred owner-directed S07 polish

Formation/rehearsal tape and random cork must become **realistic metal pushpins physically anchoring actual paper/photo edges** to subdued photographed cork with credible shadows. S06's chassis is an initial visual housing, not a claim that all premium metal materials are finally approved.

## Native screenshot correction
Initial S06 Godot run 40546299494 passed all eight captures, but actual opened DAY 390, DAY 1280 and NIGHT 1280 images showed blank phase strips, baked READINESS words on monitor faders, an original HYPE meter mislabelled readiness, and a rainy van photograph wrongly presented as studio NIGHT. The corrective implementation adds foreground phase text, native metal guitar/vocal monitor nameplates, maps the HYPE meter to real buzz, substitutes the verified existing backstage rehearsal-room image for DUSK/NIGHT and raises footer text contrast. Await the corrected run and inspect new native pixels before claiming the visual defects closed.
