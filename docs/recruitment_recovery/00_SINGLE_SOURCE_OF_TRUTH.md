# Recruitment rescue — single-source-of-truth index

**Scope frozen 2026-10-28.** Owner's visual reference and the V4 contract supersede this pack if they conflict. This folder is the *operational* layer, not an alternative art direction.

## Priority reading order for every sprint

1. Root `AGENTS.md`; `docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md`; `docs/RECRUITMENT_REFERENCE_LOCK.md`.
2. This index and `RECOVERY_STATE.json` (the **one** mutable milestone/stop-go state).
3. `01_VISUAL_TARGET.md`, `02_ART_AND_ASSET_BIBLE.md`, `03_ACCEPTANCE_RUBRIC.md`.
4. The assigned role in `.agents/recruitment/`; `04_SPRINT_PLAYBOOK.md` and previous entry in `05_SPRINT_LEDGER.md`.
5. Real prior Godot screenshot evidence and the latest branch head/CI; specifically the 28 Oct failed art review.

## Non-negotiable product demonstration

A recruitable singer in an immersive British indie-band case-file interface, one contrasting second person, and a clear candidate-switching/recruit action. The recruit screen remains an isolated proof. **No work on other screens.** A premium screen must be *visually* compelling at actual device size, not just code-correct.

## Production state (do not invent approvals)

- Owner-approved concept: reference direction **YES**, but reference binary currently unverified in GitHub; see exact SHA in `docs/RECRUITMENT_REFERENCE_LOCK.md`.
- Latest native Godot implementation: tested, **visual rejected**, no owner visual acceptance.
- New creative target for these sprints: **NOT YET PRODUCED**.
- Candidate photographs/illustrations: two cohesive, rights-proven source portraits **NOT YET APPROVED**.
- Merge and production integration: **FORBIDDEN pending owner authorisation**.

## Gate model

- **Prep:** instructions, roles, schedule, manifest and CI lint exist; not a design pass.
- **Art target:** 1280×720 + 390×844 target compositions plus 2 independently recognisable characters, each with provenance and material/layout review. Art director may record `provisional_pass` to permit isolated engineering; simulated reviews are not owner approval.
- **Native:** source layers, real Godot controls/data, capture and compare at both sizes (additional 720×1280 and 1600×900 desirable), engine tests, rights audit, no screenshot-as-game shell.
- **Owner:** human review of the *genuine native* evidence, explicit signoff. Never inferred by role agents, green CI or repeated automated polls.

## Active unblocker

A genuinely good, matching pair of musician portraits and a composed benchmark; do NOT start another programmatic SVG portrait or polish the old clip-art. A weak benchmark is a stop, not a reason to build controls anyway.

## Interface contract

Real game data uses `Scripts/recruitment_catalogue_v3.gd`, whose un-recruited pool is 200/200 and Alex Vale's recorded cost in the 28 Oct proof was 51; **read this source fresh before asserting values**. Don't bake numbers/names into art. Passive meters cannot receive focus or input. Player-selectable roles and recruits have honest texture states and explicit focus. No save writes.
