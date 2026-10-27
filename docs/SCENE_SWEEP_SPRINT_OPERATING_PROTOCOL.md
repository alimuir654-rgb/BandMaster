# Livin’ The Dream — Time-Efficient First-Pass Sprint Operating Protocol

**Purpose:** Make each hourly trigger yield the maximum *verified useful change*, rather than spending the entire run reading the same sources, drafting plans or waiting for CI. The scheduled run has no guaranteed one-hour continuous execution window. Prioritise concrete, independently useful outputs early.

## Mandatory sequencing — one scene slice per sprint

| Phase | Effort allocation (guidance, not a timer guarantee) | Work |
|---|---:|---|
| 1. Preflight and recover | ~10% | Read the latest `SCENE_SWEEP_SPRINT_LEDGER.md` **and** `SCENE_SWEEP_LESSONS_AND_PERSONAS.md`, inspect the last PR/head/CI, confirm reference bytes, inspect previous defects. Append sprint-specific PRE-FLIGHT before edits. Reuse existing code instead of rediscovering it. |
| 2. Highest-value implementation | ~55% | Build one *runnable* scene-specific interactive journey with an appropriate photographed/material surface and native data labels. Set up cross-scene link only when its resource exists. Commit early to draft branch. No additional placeholder pages. |
| 3. Functional and renderer gates | ~20% | Godot 4.7.2 compile, focused deterministic action tests, source provenance and four viewport captures. Send CI while continuing other nonconflicting productive actions (asset mapping, review checklist, tests); do not idle polling a single workflow. |
| 4. Adversarial visual review and repair | ~10% | Inspect actual screenshots (mobile and landscape minimum), fix the highest-severity concrete failure, rerun relevant checks; don't equate green CI with art approval. |
| 5. Document/handoff | ~5% | Append POST-RUN and five simulated persona findings with exact severity, defect repro, CI/asset links, next preflight, blocker(s). Clearly distinguish ENGINEERING PASS, ART GAP and OWNER GATE OPEN. |

Percentages are planning weights; not claims about how much wall-clock time an automation actually runs.

## One ordered implementation queue — avoid contention
- S00/S01 done: shared shell and S01 photo comparison. **Do not rebuild them during S02–S06.**
- S02 formation/rehearsal > S03 songwriting > S04 touring > S05 gig night > S06 studio/career > S07 convergence.
- Single authoritative **draft branch / PR #199** unless an independent isolated branch is necessary. On subsequent runs verify current head, base and changed paths before creating a branch or PR. Prefer an ordered commit with checkpoint evidence to six conflicting simultaneous PRs.
- **Never spawn a second active automation** for parallel scene code editing. Parallelise *independent* steps within one run (source search / review reading / provenance, CI submission / inspection, image capture), not concurrent edits to the same GDScript or ledger path.
- Preflight must inspect actual latest POST-RUN. If previous sprint genuinely remains unfinished/red, repair its P0 failure or explicitly log BLOCKED before advancing. Avoid five successive sprints each rewriting the same common UI.
- The prior #192 tour/songwriting/gig journeys are on a **different branch**. Read and reuse their verified logic/assets by explicit safe integration rather than reimplementing state systems. Do not call paths until present on active branch.
- S01 photographed WebPs and original Lab textures are available; approved three concept-image target ZIP is *owner-supplied but not yet verified imported*. Query Git tree/branch once per run and record precise result; avoid repeated blind searches or requests. Concept references are not UI texture atlases.

## Throughput and quality acceptance
- Minimum deliverable per scene sprint: one stateful scene with tangible player choice + correctly labelled consequence or preview, and one **actual Godot** capture at 390×844 and 1280×720; full 720×1280 and 1600×900 also required before engineering DONE. When plausible capture off/partial/on and relevant DAY/DUSK/NIGHT.
- Capture the **changed scene**, not the full 48-frame S01 navigation shell, every run. S07 performs the expensive full cross-scene comparison matrix.
- Add a focused per-scene workflow with **path filters** so a retrospective-only commit does not repeatedly run every large screenshot suite. Retain standard regression workflows at checkpoints.
- Fail on specific problems: missing original image asset, clipping, overlap, below-44px target, 0%-glow residue, false-stat editing, wrong game-time lighting, unhandled key/touch, save mutation, repeated settlement.
- Visual art direction is separate: if the material is still generic/flat against owner-approved photography and layered paper, mark **VISUAL HOLD** even if all tests pass. Never use synthetic screenshots as real Godot evidence.
- On finding a defect, prioritise **P0 game correctness/material regression > P1 layout/semantics > P2 copy/polish**. Fix P0/P1 before authoring extra decorative variants.

## Required evidence log for Sxx
```md
## PRE-FLIGHT Sxx
Evidence inspected: [ledger previous POST-RUN, review last 5 findings, PR/head, CI/artifact, source paths]
Lessons carried: [at least two concrete bugs with prevention tests]
Persona warnings: Player [...]; Musician [...]; Art [...]; Accessibility [...]; Godot/release [...]
Planned slice: [real scene path, model and input, source art, target view]
PRE-FLIGHT: PASS | BLOCKED [reason]

## POST-RUN Sxx
Actual code [files/commit], runtime and screenshots [Godot run/artifact]
Tests [PASS / FAIL / BLOCKED], scene state/model rules [details], quality comparison [actual defects]
Five simulated persona results [specific reproduction, priority, next fix]
Target-quality gate [OPEN unless owner approves], draft/no merge [true]
Next preflight [ready resources, current blocker, exact asset paths]
```

If a tool call fails or the run cannot finish the scene, commit partial usable code + tests, document exactly which gate is red and hand the next run a *resumable* task instead of making a promise of later delivery. User is game owner and should only be asked to decide material choices at the consolidated review, unless an unresolvable owner-only upload becomes a hard blocker.
