# C20 COMPLETED — CONTROL LIBRARY AVAILABLE

Read docs/asset_base/C20_VERIFIED_REVIEW.md and STATE.json. The dedicated C20 lock is released. Latest owner direction still defers backgrounds/characters; reusable controls and frames now live in components/control_atlas. Do not re-run completed inventory or overwrite the verified kit. No merge or automatic programme extension.

# LATEST DIRECT OWNER REQUEST — C20 REUSABLE CONTROLS / FRAMES

Read `docs/asset_base/OWNER_CONTROLS_SPRINT.md` and `CONTROL_SPRINT_LOCK.json` FIRST. The owner explicitly redirected work after V19: leave scene backgrounds, reuse existing repository controls, build missing reusable controls, improve frames against the supplied atlas mockups. This authorises one scoped implementation sprint; not a schedule extension or final-art approval. Character/background generation is deferred. Preserve passive-meter artwork and semantics. Check the dedicated C20 lock before claiming STATE or modifying this branch; do not race this writer. Existing time-based reporting still uses actual verified evidence only.

# CURRENT OWNER MISSION — ASSET BASE THROUGH 16:00 UK 29 OCTOBER 2026

The owner authorised three workstreams after reviewing the source-material Godot experiment: **scene backgrounds/frames; direct controls/passive meters; character artwork**. Work autonomously on the supporting asset base, adjusting priorities, technique and optional breadth whenever visual quality is off track for the 16:00 review. This is authorisation to continue, NOT final artwork acceptance.

Before any work read `docs/asset_base/PROGRAMME_2026-10-29.md`, `STATE.json`, `LEDGER.md`, `.agents/asset_base/WORKSTREAMS.md` and the prior verified review under `docs/dual_frame_proof/`. One ordered writer on `dual-frame-proof-2026-10-28`; preserve main, PR #199 and production saves. Earlier 28 Oct stop/recruitment-only rules are superseded only for isolated asset-library/assembly work. No merges, costs or engine changes. Keep `owner_approved=false`.

Characters receive the first production slot. The controller must review actual pixels at 02/06/10/12 checkpoints and change the plan when off track; no more than one ineffective corrective continuation on a family. Freeze optional breadth before quality; no new families after14:00, no implementation writes after15:00, final review16:00, except the later direct C20 authorisation above. Scheduled work is a sequence of invocations, not a claim of continuous background execution. Relevant native proof already exists; do not restart its setup or use the pull-request-only run query to infer push CI absence.

---
# BandMaster — AI development contract

## Roles
The game owner sets creative direction and accepts gameplay changes. The assistant acts as programmer, tester, release manager and technical adviser.

## Non-negotiable rules
- Read `project.godot`, relevant `Scripts/*.gd`, scene files, and `ARCHITECTURE.md` before making changes.
- Use Godot 4 GDScript. Do not assume plugins or autoloads exist. Verify node paths, file names, signal names and APIs against the repository.
- Preserve current gameplay and JSON save/load compatibility. Never erase or reset user saves as a migration strategy.
- Separate simulation state, presentation, persistence and event content as the codebase grows; make incremental changes, not speculative rewrites.
- Prefer complete, ready-to-use files and exact paths over partial snippets. No placeholders.
- Every code change must include a brief change summary, test evidence (what actually ran), known limitations and manual Godot test instructions.
- Never claim runtime tests passed unless they actually ran.
- Commit work on a feature branch and propose a pull request; do not modify `main` without the owner's request.
- Preserve `.godot/` in ignore rules; never commit secrets, temporary cache or private save files.
- Document changes to the persistent state model in `STATE_SCHEMA.md`.
- Do not introduce paid services, cloud inference, Ink dependencies or art licensing requirements without discussing them with the owner.
- Prioritise player-initiated band management and emergent systems over endless forced multi-choice events.

## Acceptance checks
1. Relevant scripts parse in Godot headless editor (once runtime validation is configured).
2. Main menu, band builder, rehearsal and tour pathways remain reachable.
3. New game, save, quit, continue and reload round-trip correctly.
4. Critical bounds and event consequences are deterministic and reproducible where designed.
5. The owner can test a feature with short numbered steps.

## Baseline
At creation, `project.godot` starts `band_builder.tscn` via its UID. `Scripts/band_builder.gd`, `Scripts/main_menu.gd` and `Scripts/tour_intro.gd` exist. This is a documentation baseline, not proof of runtime correctness.
