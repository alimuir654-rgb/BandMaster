# BandMaster — Recruitment Quality Recovery Pack

**Package date:** 2026-10-28. **Target:** `alimuir654-rgb/BandMaster`, draft PR #199, branch `first-pass-scene-sweep-2026-10-27` (or a new feature branch created FROM it). **Intent:** production-management assets ONLY; no game scene implementation, no imported character art and no release claim.

## Install safely

1. Check out `first-pass-scene-sweep-2026-10-27` (or create a feature branch from it). **Do not unpack onto `main`**: the root `AGENTS.md` in this ZIP extends the recruitment branch's existing stop-the-line contract, which is ahead of `main`.
2. Save any uncommitted edits. Unzip to the repository root so `AGENTS.md` is at the top level, alongside `project.godot`. Existing files are not otherwise replaced.
3. Inspect the diff. The root `AGENTS.md` retains the prior 27 October directive and general development contract, with a new top-level recovery section. Never override a concurrently updated version without resolving it.
4. Run: `python3 tools/recruitment_quality_gate.py --root . --stage prep`.
5. Run: `python3 -m unittest discover -s tests -p test_recruitment_quality_gate.py`.
6. Commit on your feature branch / update the draft PR; do not merge. The new `.github/workflows/recruitment-recovery-plan.yml` checks **the planning contract**, not artistic quality.

## What this package actually contains

- Extended root `AGENTS.md` that links one mandatory quality programme to the existing repository contract.
- Five scoped agent ROLE INSTRUCTIONS under `.agents/recruitment/`. These are reusable instruction files for future agent/task runs, **not evidence that separate agents are installed, scheduled or executing**.
- Production bible, specific visual layout specs, art/portrait prompts, rights and provenance policy, curated research/asset shortlist, phased sprint playbook, rubric, change/sprint/decision logs, and a single owner review packet template.
- Machine-checkable project status and source-asset manifest, a stdlib validation script with negative tests, and an opt-in CI workflow.

## Confirmed source-of-truth anchors (not duplicated)

- `docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md` — binding design/release contract.
- `docs/RECRUITMENT_REFERENCE_LOCK.md` — reference SHA-256 `278998d5c7875557aab95ac6d225026481a29fddd23537a7c94ac99765caa223` and its **not-yet-GitHub-verified binary status**.
- `docs/GODOT_CHARACTER_UI_RESEARCH_AND_OVERNIGHT_GATES_2026-10-27.md` — earlier learning.
- `docs/RECRUITMENT_NATIVE_04_SPRINT_REVIEW_2026-10-28.md` — honest failed visual benchmark.
- `Art/UI/RecruitmentV4/` and `Art/Portraits/indie/` — *existing art in the draft branch*, not new approved assets in this pack.
- [Latest genuine Godot capture](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40630920202/artifacts/12791805791) — engineering success, visual P0 failure.

## The one decision that matters

Work on only ONE recruitment screen, two distinct musician portraits, and TWO authored layouts (1280×720; 390×844). No new scenes, plugins, game-engine migration, art subscriptions, merges or save writes. Five roles, six real passive attributes, correct talent/roster data and tactile controls are required. Release remains blocked until **the human game owner reviews true native screenshot evidence**. Avoid repeated owner prompts: a designated internal art director may provisionally accept *work for isolated integration only*, never final art.

## What it deliberately does NOT do

- It does not create good portraits or a finished screenshot by itself.
- It does not ship third-party asset libraries: a legal licence label is insufficient reason to import visually mismatched artwork.
- It does not assert automated artistic quality or sign owner approval.
- It does not enable automations; run authorization and scheduling are separate.
- It does not overwrite existing sprint ledgers, PRs, asset sources, runtime scripts or saves.

## Direct asset registration after image creation

Once a real `Art/RecruitmentRecovery/portraits/alex_master.png` exists, register its actual bytes (not a link or a placeholder):

```sh
python3 tools/register_recruitment_asset.py --root . --id portrait_featured \
  --path Art/RecruitmentRecovery/portraits/alex_master.png \
  --origin-kind generated_original \
  --rights-basis 'Original generation; use terms reviewed and recorded'
```

For a source from another creator, use `--origin-kind licensed_third_party --source-url https://...` and the exact licence/permission in `--rights-basis`. This registers a *ready source*, **not art approval**. Explicit sprint diff guard: `python3 tools/recruitment_scope_guard.py --root . --base <previous-sprint-SHA>`.

## Useful commands

```sh
python3 tools/recruitment_quality_gate.py --root . --stage prep
python3 tools/recruitment_quality_gate.py --root . --stage art
python3 tools/recruitment_quality_gate.py --root . --stage native
python3 tools/recruitment_quality_gate.py --root . --stage owner
python3 -m unittest discover -s tests -p test_recruitment_quality_gate.py
```

A **prep PASS** means only that the plan is complete and well-formed. The other stages must fail until their real evidence exists. In particular, no successful GitHub Actions workflow implies owner visual approval.
