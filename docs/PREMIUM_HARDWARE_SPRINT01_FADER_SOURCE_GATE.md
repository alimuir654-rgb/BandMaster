# Premium hardware — Sprint 01 / 08: precision faders
**27 October 2026 ~09:00 UK. Status: P0 SOURCE-BLOCKED / OWNER QUALITY FAIL.**
**No main-game integration, no visual approval, no screenshot-based sprite extraction.**

## Evidence checked before work
- Owner correction and eight-family programme: [PR #193](https://github.com/alimuir654-rgb/BandMaster/pull/193), `docs/PREMIUM_HARDWARE_EIGHT_CONTROL_FAMILY_SPRINTS.md`.
- Owner's 08:57 source audit: `docs/PREMIUM_HARDWARE_RECEIVED_SOURCE_AUDIT_2026_10_27.md` on #193, commit `60b82dba71d46c412c6dfb94c6d17837bb10e895`. **Owner HAS supplied original ZIPs**; do not ask them to repeat that work.
- Lab05 ZIP checksum `7770ceaa63e59ffa52180d90c143d919d85337c55a9d9c7ffec1112c1ca8f391`, eight flattened reference PNGs; NO separate cap/rail/light sprites. Lab07 ZIP has a validated standalone control scene and 45 state sprites, but is not the isolated fader source. Lab08.4 is lighting-fix-only and missing its base/off scenes.
- Repo-import ZIP `BandMaster_Hardware_Repo_Import.zip` (24.9MB) exists in the owner's other project chat but is not mounted in this scheduled run. GitHub fetches of `bandmaster_premium_controls_lab/premium_controls_lab.tscn`, `Art/References/PremiumHardware/SOURCE_SHA256_MANIFEST.json`, `tools/validate_premium_hardware_source.py`, and `Art/UI/PremiumHardware/Faders/fader_cap.png` returned **404 on 27 Oct ~09:00 UK**. Do not imply owner ZIPs are missing; the outstanding step is **binary import to a GitHub branch**.
- Baseline: #192 remains draft; the page layouts are accepted, but owner rejected the control art. #183 is separate. #193 remains roadmap-only.

## Actual delivered this bounded run (NOT a completed premium fader)
1. `Scripts/premium_hardware/fader_state.gd`: isolated fader state model with exact 0..1 clamp, drag top=1/bottom=0, keyboard coarse/fine, disabled no-input, focus/hover/pressed/selected priority and **0 LED intensity at value 0 or disabled**. No game save/economy access.
2. `tests/premium_fader_state_tests.gd`: behavioural checks of 0/50/100%, out-of-track drag, disabled interlock, state precedence, keyboard and off-state.
3. `Art/UI/PremiumHardware/Faders/source_manifest.json`: truthful **BLOCKED** manifest with no invented files or hashes, names of eight required layers for day/dusk/night.
4. `tools/validate_premium_fader_source.py`: strict PNG CRC, RGBA8, decompressed alpha, exact SHA-256, safe path, cap geometry, glow-on/off geometry, and **all-zero off-glow alpha** validation. Status is READY_FOR_REVIEW, never auto-APPROVED.
5. `tests/test_premium_fader_source.py` and `.github/workflows/premium-fader-source-gate.yml`: tests distinguish a valid *blocked intake report* from source-art PASS; future READY status without actual assets and a Godot scene fails.

## Required fader source, exact minimum
Production-ready **separated, clean** PNGs for each palette (day/dusk/night):
`base.png`, `rail.png`, `cap_normal.png`, `cap_pressed.png`, `cap_disabled.png`, `level_on.png`, `glow_off.png`, `glow_on.png`. Matching state dimensions, transparent clean light overlay, source rights and SHA-256. A flattened Lab05 sheet is reference-only and **cannot** be sliced into movable hardware. Existing Lab07 transport sprite assets are valuable for Sprint 03, not a substitute for fader layers. `source_manifest.json` requires each imported layer's `palette`, `layer`, repo-relative `path`, `sha256`, `width`, `height`; set `status` to `READY_FOR_REVIEW` only after import.

## Quality gate, actual evidence
- Image-backed Godot fader scene: **BLOCKED** (no approved separated fader source).
- Real renderer captures at 390x844, 720x1280, 1280x720, 1600x900: **NOT CAPTURED**. Do not fabricate screenshots from old UI or CI.
- Physical finish, zero rail residue, native-scale Lab05 comparison: **FAIL / NOT EVALUABLE** until art is imported.
- State-model test: pending GitHub Actions final-head execution; not equivalent to visual validation.
- Repo import: **P0 open**. Source ZIP already provided in owner project chat; exact transfer of repo-import ZIP extracted contents is outstanding. Do not commit ZIP alone.
- Owner visual approval: **OPEN**. No merge.

## Five simulated adversarial reviews (not human sign-off)
1. **First-time player — FAIL visual:** no runnable fader sprite, cannot judge control affordance. Input semantics specify top high/bottom low; require actual hardware to inspect.
2. **Touring musician — FAIL visual:** no isolated cap/rail, so a real fader cannot physically travel without leaving ghost pixels. Reject screenshot cutouts.
3. **UI/material artist — FAIL:** no true machined cap, rail, etched ticks or state-driven light at native pixels to compare against Lab05. Require original separated source, not generic vector art.
4. **Accessibility — PARTIAL input, FAIL visual:** keyboard step, focus state and disabled logic defined; 44px hit target and focus-ring visibility cannot be measured until renderer exists.
5. **Godot engineer/release QA — PENDING:** model has no career mutations; CI must run on exact head. No screenshot or asset approval from script-only checks.

## Exact next action / handoff
1. Import the owner-created `BandMaster_Hardware_Repo_Import.zip` extracted tree onto a **separate safe branch** (never claim it contains isolated fader layers). Validate remote bytes and manifest.
2. **Sprint 01 remains BLOCKED** for premium fader art until clean Lab05 fader cap/rail/level/glow layers are available. When received, implement image-backed `poc/premium_fader_lab.tscn`, mouse/keyboard focus and four viewport captures; compare actual Godot pixels with Lab05.
3. On the **next scheduled family run**, follow the eight-family queue's order without falsely marking Sprint 01 complete. The next family is rotary encoders (Sprint 02); use received Lab08.4 overlays but flag missing baseline/off plates and scene files, do not invent halo sources.
4. No production merge. Story ideas from [London Guitar Institute, 12 Jan 2024](https://www.londonguitarinstitute.co.uk/from-garage-to-stage-tips-for-starting-a-band/) were reviewed: bandmate fit, jamming, early local gigs, writing originals, band agreement. They remain deferred under #193, with no gameplay implementation here.
