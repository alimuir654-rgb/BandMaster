# Premium Hardware Sprint 02/08 — Photographic Rotary Encoders / Lab08.4
27 October 2026. **Owner approval OPEN. No merge. No production integration.**

## Scope
Only rotary encoder and accurate luminous halo controls. This branch is based on the asset-intake programme PR #193; it does **not** alter or replace Sprint01 fader PR #195 or gameplay. Owner-approved Lab08.4 Focus/Buzz photo plates and exact tick/pad overlays are used *as-is*. No cut-up screenshot, generic SVG or recreated faux hardware.

## Source verification
- Source branch `premium-hardware-eight-control-families-2026-10-27`, commit `3e1c07d6a900d48845880f65ed56e3d52eacaee3`, verified GitHub tree includes `bandmaster_premium_dashboard_poc/assets/focus_ring_off.png`, `buzz_ring_off.png`, `rotary_pointer.png`, all 27 Focus and 23 Buzz LED PNGs, original `studio_controls_lab.tscn`, `studio_control.gd`. Remote binary `focus_ring_off.png` fetched via GitHub as actual base64 PNG, not just a filename.
- Original source files retain their existing paths. The dedicated workflow calculates and uploads SHA-256 for **53 original PNGs** (2 neutral plates, 1 pointer, 27+23 overlays). Original `tests/validate_lab084.py` checks alignment, uniqueness and no spill into knob/outer bezel.
- Source status: **P0 resolved**. The older intake document's "missing original base" statement is historical and superseded.

## New isolated implementation
- `Scripts/premium_photographic_rotary.gd`: native Control with original photo plate, ordered 27/23 original transparent LED overlays, independent pointer, mathematically exact -135..+135 degree rotation and 0..100 clamping.
- Zero/disabled uses **zero active LED overlays**; pointer rendered neutral rather than emissive. Never rotates an LED ring or overlays an artificial procedural ring. Focus, hover, press and latched have restrained *external* accessibility outlines, not replacement hardware.
- Mouse drag, touch drag, wheel, arrow/PageUp/PageDown/Home/End, Space/Enter latch. Disabled blocks mutations and focus. State signals are local to demo only.
- `poc/premium_rotary_quality_lab.tscn`: two photo dials in warm **light DAY**, petrol **DUSK**, dark **NIGHT**, selected by *explicit in-game scene phase* in isolated lab, not wall clock.
- `tests/premium_rotary_quality_tests.gd`: original overlay counts, all five levels, pointer angle, zero, clamp, drag, keyboard, selected, disabled, theme checks.
- `tests/capture_premium_rotary_quality.gd` + `.github/workflows/premium-rotary-quality.yml`: 4 viewports × 3 phases × 5 values = **60 scheduled actual Godot captures** plus 6 selected/disabled states, pixel/PNG dimensions and phase-luminance checks, 15-state mobile contact sheet and source SHA manifest. **Scheduled checks are not completed evidence until workflow succeeds and screenshots are inspected.**

## Quality gates — current evidence
| Gate | Status |
| --- | --- |
| Original photo source bytes | VERIFIED remotely; Lab08.4 original assets imported in #193 |
| Original static 27/23 overlay validation | Existing source validator present; rerun in dedicated workflow |
| Godot scene, input and focus states | CODE COMMITTED; runtime test PENDING |
| Real 390x844, 720x1280, 1280x720, 1600x900 screenshots | CAPTURE WORKFLOW COMMITTED; execution/inspection PENDING |
| Off/25/50/75/100 visual comparison and no residual light | Logic implemented; actual pixels PENDING |
| Day markedly lighter than dusk/night | Tokens implemented; renderer comparison PENDING |
| Photo texture/metal fidelity vs original Lab08.4 | Source sprites identical; Godot scale/crop inspection PENDING |
| Owner acceptance | OPEN / HOLD |
| Main-game integration/merge | NOT PERMITTED |

## Five simulated adversarial reviews (NOT human sign-off)
1. **First-time player — PENDING:** 0/25/50/75/100 readout labels make effect visible; need actual 390px screenshot for visual legibility and affordance. Reject if rings are indistinguishable.
2. **Touring musician — PENDING:** mechanical dial moves continuously, distinct Focus vs Buzz rings. Need compare whether partial illumination follows clockwise order and whether knob rotation feels physically believable.
3. **UI/material artist — FAIL until screenshot inspection:** original photographed metal and LED layers are preserved; no visual PASS until actual Godot renders show no ghost arc, pointer halo at OFF, stretch artifacts or bezel bleed.
4. **Accessibility — PENDING:** min 44px phase buttons, keyboard focus, disabled reason and separate selected status. Need verify actual device pixels and visible focus outlines on light and dark surfaces.
5. **Godot/release QA — PENDING:** independent source-import tests and screenshot workflow, no live save writes. Need verify final-head CI and inspect artifact before marking green.

## Handoff
1. Check dedicated GitHub Actions workflow at the **final PR head**. Fix GDScript parser, runtime, visual crop or image tests if red. Download actual 66-state screenshot artifact, inspect both dial rings at 0/25/50/75/100 in each phase, on mobile and landscape. Do not claim visual pass from workflow presence.
2. Confirm no illuminated LED/tick or pointer at OFF and disabled, exact 27/23 overlays, no halo spill or residual. If defects remain, keep Sprint02 open and repair before Sprint03.
3. Once runtime and screenshots are reviewed, update this document and PR comment with observed evidence, final commit and verdict. **Owner visual approval still OPEN** even after green CI.
4. Only then proceed to Sprint03 **photographic transport keys**, using original Lab07 sprites. Do not build another page.
