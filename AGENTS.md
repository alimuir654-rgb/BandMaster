# STOP-THE-LINE VISUAL QUALITY DIRECTIVE — 27 OCTOBER 2026
**READ FIRST**: [docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md](docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md). This owner-directed V4 visual contract supersedes earlier broad scene queues, V3 design, and generic UI-helper defaults. Do **not** resume S03–S07, merge PR #199 or modify live formation/save workflows without further explicit owner approval.

- Never use `Scripts/ui_theme.gd`, `WoldButton`, `StyleBoxFlat`-driven primary `_button()` or `_panel()` from `poc/ldtd_recruitment_v3.gd` in **new** screens. Historical modules remain for running old scenes and old saves; quarantine rather than deleting their transitive dependencies blindly.
- New recruitment screen must be assembled from purpose-built physical image layers and five-state input texture families, with native real content. Approved reference is the richly photographed roadcase recruitment mockup: genre sidebar, singer/instrument tabs, left candidate rail, dominant musician photo, six inert red-to-green horizontal attribute meters immediately below, paper personality/experience panel, fixed band roster/talent dock, genuine transport arrows.
- **Composition acceptance before functionality breadth.** An automated code/screenshot test PASS is not a visual PASS; inspect 390x844 AND 1280x720 genuine Godot captures against approved reference. No screenshot-as-interactive-background shortcuts, wrong portraits, fictitious provenance, invented art approval.
- Enforce as CODE: CI forbidden-helper/design-contract lint, texture source/provenance audit, physical-target/visibility validation, 4-device screenshot artifact, documented human-owner visual gate. Never quietly downgrade to flat controls when a texture fails.
- User approved V4 recruitment direction only: mixed UK candidates and genre first→musicians→band name last, NOT merging or release. See V4 contract for detailed stop/release matrix.

---

**RESEARCH-LOCK UPDATE (27 Oct 2026, before midnight sprints):** Read [Godot character and UI research + 00/02/04/06 art-first acceptance gates](docs/GODOT_CHARACTER_UI_RESEARCH_AND_OVERNIGHT_GATES_2026-10-27.md) before making any recruitment, character, portrait, design-system or animation change. Owner permits replacing *all* characters. Stronger requirement than component-count: two coherent, recognisable musicians and one compelling complete recruitment screen. Start static with actual authored/rights-clear character art; no animation/plugin/Figma upgrade/Spine spend until artwork qualifies. New UI must use properly sized nine-sliced source-backed textures, reusable Theme variations, accessible keyboard/tap targets, actual Godot native captures and documented human-approval blocker. Never infer a green code test means an art PASS.

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
