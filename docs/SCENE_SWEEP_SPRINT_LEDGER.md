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