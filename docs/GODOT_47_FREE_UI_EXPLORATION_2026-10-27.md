# Godot 4.7 native, free UI exploration
*27 October 2026 — owner-directed UI quality rescue; no purchase, no production merge.*

## High-value finding: **native Control offset transforms**
Godot 4.7 shipped `Control.offset_transform_enabled`, `offset_transform_visual_only`, `offset_transform_scale`, `offset_transform_position`, and `offset_transform_pivot_ratio`. The new visual-only offset allows safe hover/press/entry motion on children within Container-managed layouts **without mutating their actual layout geometry**.

Evidence: [Godot 4.7 release notes](https://godotengine.org/releases/4.7/) and [stable Control reference](https://docs.godotengine.org/en/stable/classes/class_control.html).

**Concrete sandbox committed:** `poc/ldtd_control_motion_47.gd` (hover 1.025x, press 0.975x; ~0.045–0.13s easing; hover + keyboard focus; no effect when disabled) and `tests/ldtd_control_motion_47_tests.gd` (signal idempotency, container resort stability, focus-safe tween, press, reset) on *isolated draft branch only*. Dedicated `.github/workflows/ldtd-47-native-motion-spike.yml` runs Godot 4.7.2. Treat as unverified until the exact workflow run is green.

**Important:** animation here is an input technique, NOT another art style and NOT evidence that an SVG roadcase meets the user-approved photoreal/crafted material composition.

## External candidates — decision matrix
| Source | Evidence checked 27 Oct | Recommendation | Reason |
|---|---|---|---|
| [Official Godot demo gallery](https://godotengine.github.io/godot-demo-projects/) | Multiple Resolutions/Aspect Ratios; GUI Theming Override; Accessibility; control gallery, input mapping | **USE CODE PATTERNS** | Strongest Godot-version provenance; free/official; no default demo visual skin in final UI |
| [Godot 4.7 new UI offsets](https://godotengine.org/releases/4.7/) | Released Control visual-only offsets enabling motion in containers | **BUILD NATIVE PROOF FIRST** | Removes need for extra GUI animation plugin |
| [Simple GUI Transitions](https://github.com/murikistudio/simple-gui-transitions) | MIT, Godot 4.3+, uses addon/autoload; docs explicitly say slide animations unsupported on Container children | **STUDY, DO NOT INSTALL** | More integration complexity than 4.7 built-in for responsive recruitment |
| [Main Menu Multi-Theme](https://godotengine.org/asset-library/asset/4258) | MIT, 4 themes, StyleBox-based | **REFERENCE ONLY** | Useful theme-switch pattern, but flat forms precisely rejected by owner |
| [Theme Assist](https://store.godotengine.org/asset/undiscovered-entertainment/theme-assist/) | MIT, 54 game controls, keyboard focus/sounds, Godot 4.4+, beta and AI-assisted code | **ISOLATED LATER IF NEEDED** | Could reduce common UI toil, but does not solve craftsmanship in artwork and has a new runtime dependency |
| [Pixel UI Free](https://godotengine.org/asset-library/asset/5494) | CC BY 4.0, Godot 4.3–4.7, author discloses AI-assisted graphics/code, unstable | **EXCLUDE** | Pixel fantasy visual style, AI disclosure, attribution and generic aesthetic inconsistent with owner creative target |
| [Sprite Juice Kit Lite](https://godotengine.org/asset-library/asset/5558) | MIT; hitflash/camera shake/hitstop, Godot 4.4+ | **EXCLUDE RECRUITMENT** | Designed for action impacts; disruptive on reading-heavy recruitment screen |
| [GDQuest Godot 4 demos](https://www.gdquest.com/library/demo_godot_4_new_features/) | Free code MIT; game assets CC BY-NC-SA | **PATTERN REFERENCE ONLY** | Cross-version layout/tween showcase; art not automatically suitable for commercial shipping |
| [Kenney Starter Kits](https://kenney.nl/starter-kits) | Official six open starter kits; City Builder demonstrates management game logic | **ENGINEERING REFERENCE ONLY** | No music-themed premium UI supplied |
| [Godot Playground examples](https://godotplayground.com/examples) | User supplied working public example library; direct web open intermittently fails | **SELF-CONTAINED EXPERIMENTS** | Good sandbox source; verify individual snippets rather than treating all as CI-compatible |

## What to test next — not a generic UI kit installation
1. Run the dedicated native 4.7 offset-motion test. Fix CI before claiming a working technique; wire to an isolated control gallery with the **existing BandMaster five-state metal and studio transport art** only if test green. Avoid layout shudders and click-hit mismatch.
2. Examine official **GUI Theming Override** and **Multiple Resolutions** in the demo viewer. Adopt theme-variation conventions for `RoadcaseTransport`, `RoleTab`, `RosterDock`, `RecruitCTA` while preserving physical input.
3. Create one **high-quality musician art asset** whose visual style truly fits the source mockup. Character source could be stylised hand-illustration; no synthetic persona headshot repurposed or AI-looking fake stock faces. A license/source checklist is required.
4. Inspect **390x844 and 1280x720 native** screenshots *against* the owner-approved mockup. No new scene rollouts until photo/craft/hierarchy meet owner approval. For responsive design, create meaningful independent compositions, not an arbitrarily scaled container stack.
5. After composition approval, add restrained hover/press motion, candidate transitions and disabled/focus treatments as a secondary enhancement.

## Exit criteria / no wasted time
**Owner artistic gate = P0**; a green Godot import/test is only engineering evidence. No production-save changes, automatic merges, Figma paid upgrades, Spine purchases, unverified free addons, custom C# or engine migration. If the recruitment screen is still less than convincing by the owner's 08:00 review, explicitly state the unresolved art source/pipeline and recommend specialist visual art direction before further UI programming.

Figma native editable shell already exists at https://www.figma.com/design/nNfK8L1pC6cuRwcYacmPoz but Starter MCP usage limit has been reached; current work proceeds in Godot. Latest user-approved mockup remains conceptual art reference, not a flattened sprite. All past V3/V4 feature-area rollouts remain paused.
