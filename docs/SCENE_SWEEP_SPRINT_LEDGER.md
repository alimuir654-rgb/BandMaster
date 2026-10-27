# Livin’ The Dream — First-Pass Scene Sprint Ledger

Mandatory rule: BEFORE ANY SCENE CODE each sprint MUST read this ledger, docs/SCENE_SWEEP_LESSONS_AND_PERSONAS.md, docs/LIVIN_THE_DREAM_SCENE_QUALITY_GATES_AND_SWEEP.md and prior PR/CI. Append a PRE-FLIGHT record of relevant feedback and prevention tests; only then edit code. After tests and visual inspection append actual persona findings and POST-RUN with links, defects, and handoff. Simulated personas are not human approvals. Never merge into production without owner visual approval.

## Approved baselines and branch risk, 27 Oct 2026
- Player-facing name: **Livin’ The Dream**; development repo BandMaster.
- Original Lab05/Lab07/Lab08.4 image-backed hardware committed on #193; fader #195, housed fader + readonly meter #197, transport #198. Photographic realism and differentiated input/readonly behaviour required.
- Approved concept references: Songwriting rotary, bright-DAY touring pen/paper, NIGHT gig callboard, documented with SHA-256 in docs/LIVIN_THE_DREAM_SCENE_QUALITY_GATES_AND_SWEEP.md. The owner says ZIP uploaded. At preflight PR198 branch SHA 53028ace and main SHA 8920640e lack Art/References/TargetStates and archive; this is NOT verification that upload failed or user needs to re-upload. Recheck remote import on each sprint.
- WARNING: previous 3 scene-world journeys and typography are on separate draft branch visual-sprint08-convergence-typography-release-gate (#192), not on our #198 branch. Do not call unimported paths. Safe integration/cherry-pick planning required; don't duplicate gameplay.
- All new first-pass scenes should use genuine separate visual layers and engine-native editable text. No screenshot-as-interactive-art. Warm light DAY, petrol DUSK, graphite NIGHT from simulated game state. Model-readonly gauges. Existing career/save untouched in PoCs.

## Eight bounded sprints
| ID | Deliverable | Current status |
|---|---|---|
| S00 | Read previous logs, source and branch review, quality gates and persona ledger | DONE — target ZIP verification outstanding |
| S01 | Cross-scene career shell and visual world navigation (actual Godot scene, 4 sizes) | IN PROGRESS |
| S02 | Formation and rehearsal: relationships, practice, early social journey; daytime scrapbook | QUEUED |
| S03 | Songwriting: notebook, structure, real 3-session preview, photo transport/rotary | QUEUED |
| S04 | Tour: paper itinerary, van readiness, route and budget preview | QUEUED |
| S05 | Gig night: daylight load-in, dusk soundcheck, dark-stage setlist, aftershow | QUEUED |
| S06 | Studio and shared career: coherent integrated premium hardware; input vs meter | QUEUED |
| S07 | Cross-scene convergence: 4-device screenshot gallery, visual deltas, persona sweep | QUEUED |

Each sprint is one isolated/draft PR or one ordered commit on a shared draft with a checkpoint; DoD = native runnable code, realistic asset provenance, mobile/tablet/landscape/desktop Godot images, deterministic tests and recorded five-lens review. Mark BLOCKED if actual artwork missing. Nothing automatically merges.

## PRE-FLIGHT S01 (following S00) — 27 Oct 2026 ~11:21 Europe/London
Read before implementation: previous docs/SPRINT_EXECUTION_LOG.md, control quality review history (PRs #193/#195/#197/#198), current quality gate doc, previous scene programme #192 and inspected Git trees.
Lessons carried: no loose dark hardware on cream; no faders for non-editable stats; 0 = no residual glow; 44 physical px; UI must have deep physical craft, not cheap flat cards; DAY must look daylight; screenshot/actual render checks over green CI; never mutate saves or duplicate settlement.
Persona preflight: player needs obvious next step; musician needs credible journey; art director expects real layer materials; accessibility expects readable and full target; engineer demands no missing scene links, proper logical-to-physical layout and regression. PRE-FLIGHT: PASS for S01 isolated shell implementation, target reference-import claim remains UNVERIFIED.

## Append-only sprint records
Before every subsequent sprint, append 'PRE-FLIGHT Sxx' with checked paths, last POST-RUN, five persona feedback points, action, test plan, artifact state, then 'PRE-FLIGHT: PASS/BLOCKED'. After work append 'POST-RUN Sxx' with exact file/PR/CI links, 4-size Godot screenshots, five simulated lens findings, defects and next handoff. Prior mistakes must remain visible and searchable.
## POST-RUN S01 — 27 October 2026 ~11:45 UK
**Scope:** first-pass Livin’ The Dream six-context career shell. Branch `first-pass-scene-sweep-2026-10-27`; draft PR #199. Files: `poc/ldtd_career_scene_shell.gd/.tscn`, `tests/ldtd_s01_scene_shell_tests.gd`, `tests/capture_ldtd_s01_scene_shell.gd`, `.github/workflows/ldtd-scene-first-pass.yml`, `tools/check_scene_sprint_preflight.py`.
**First real Godot proof:** [successful six-context + 48 real screenshots, run 40497305354](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40497305354), [artifact 12730777488](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40497305354/artifacts/12730777488). Devices: 390×844, 720×1280, 1280×720, 1600×900, DAY/NIGHT x six contexts. All six page tabs switch, DAY warm light, NIGHT graphite, keyboard-focusable ≥44px native actions, links only open real photographic proofs, dummy routes explicitly say PENDING, no saves.
**Visual inspection defects at initial green CI:** photo map materially mismatched: Songwriting and Studio inadvertently used an ON-ROAD VAN image, Tour used a MUSIC SHOP. **Corrected** by using writing=home, tour=studio/van, studio=formation/rehearsal. First-time player lens found "OPEN BAND DESK" implied a functional scene which does not exist; relabelled pending-only CTAs "REVIEW ... BRIEF" so no false claim. Current head `7bd99ea4` (includes art/wording and CI workflow trigger fix); **its screenshot/regression CI is pending at this entry**, do not treat the previous green run as proof for this head.
**Five simulated persona lenses (not real people):**
1. Player: functional tab and 48px action dock helps orientation; warning P1 new scene family itself is not playable until S02–S06.
2. Musician: story stages and role labels coherent; warning P1 band's road/workshop images must represent credible context, not misplaced vintage photo.
3. Art director: day/night contrast and source-backed photography pass baseline; **P0 visual craft gap** vs owner-approved layered paper/pen, genuine stitched equipment panel, and night callboard. This is intentionally the S02–S06 backlog, NOT art approval.
4. Accessibility: four device layouts and native focus pass geometry; P1 secondary provenance/type 11–13px small on phones; raise readable font sizes when designing actual content.
5. Godot/release: six contexts, phase and safe demo links compile and render without `user://` access; no #192 cross-branch path invoked. P1 source target ZIP not verified on this branch and scene-worlds journeys still separate.
**Next S02 preconditions:** read latest logs FIRST. Verify owner target ZIP and inspect original #192 journey separate branch. Build formation+rehearsal as an actual Godot stateful day-first paper/scrapbook scene, not another generic family preview. Keep S01 shell up as shared launcher. No main merge; owner visual gate OPEN.

### S01 FINAL QA ADDENDUM — 27 Oct 2026
**Status S01:** ENGINEERING + RESPONSIVE BASELINE **PASS**; full photoreal target-scene VISUAL GATE **OPEN**. Corrected code head `7bd99ea4` passed preflight + six-scene navigation/state + 48 native day/night/screensize capture matrix in [Godot run 40498151447](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40498151447), [48-image artifact 12732296201](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40498151447/artifacts/12732296201). Final native captures visually inspected for desktop and phone: career home, formation rehearsal, songwriting home, tour road van, gig performance, studio rehearsal now contextually correct. Daylight shell substantially light; night is dark, but photo/time-of-day lighting is not yet physically re-shot. Six family shells are navigable; only photographic hardware proof links are playable so far. **No claim all six story journeys exist.** No save writes.
**S02 GO with constraints:** Add real isolated formation/rehearsal choice flow with credible UK early-band story, native text/read-only stat semantics, paper/scrapbook material. Do not call current flat shell an approved target. Resolve owner reference image ZIP GitHub import location before declaring target-source gate PASS; branch inspected has not verified remote TargetStates PNGs. Read S01 persona log first, then log PRE-FLIGHT S02 before code.
