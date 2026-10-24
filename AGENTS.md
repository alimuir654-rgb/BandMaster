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
