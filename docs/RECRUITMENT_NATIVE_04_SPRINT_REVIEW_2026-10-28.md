# 04:00 quality-spike evidence — genuine native Godot recruitment renders
**28 October 2026, UK. Isolated proof only, draft PR #199, not merged, not owner-approved.**

## Review the evidence first
- **[Actual Godot 4.7.2 native screenshot artifact, 390×844 and 1280×720, plus design/native comparison](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40630920202/artifacts/12791805791)**. This is the **final confirmed passing** 04:00 capture. It contains `editorial-native-390x844.png`, `editorial-native-1280x720.png`, `editorial-design-vs-godot-evidence.png`, and the two explicitly marked design-only references.
- [Actual GitHub Actions test run 40630920202 — PASS](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40630920202), Godot 4.7.2.stable.official, Linux Xvfb/GL compatibility.
- [Isolated native scene source](../poc/ldtd_editorial_native_handoff.gd), [native screenshot capture assertions](../tests/capture_ldtd_editorial_native_handoff.gd), [deterministic model/interaction test](../tests/ldtd_editorial_native_handoff_tests.gd), [workflow](../.github/workflows/ldtd-editorial-native-handoff.yml).
- Source-backed portrait remains `docs/visual-proofs/recruitment_portrait_alex_ink_study.svg`, **not a licensed human photograph or approved production art**. Original design-only artboards are separate SVGs. The Figma file was not edited in this run.

## What actually changed
- Created an isolated `poc/ldtd_editorial_native_handoff.tscn` and native GDScript Control tree. No changes to main menu, old V3/V4 scenes, recruitment catalogue, persistence or saves.
- Actual Godot `TextureRect` for the *original, code-authored* Alex vector portrait and independently textured paper dossier; **no full-screen artboard image used as a clickable screen**.
- Real `TextureButton` source-backed normal/hover/pressed/disabled states for five roles, six candidate positions, selected genre, recruit, browse. All live labels are Godot Labels. Six passive Control meters with native values and no focus/mouse input. First-fold recruit action is 65px desktop / 62px phone, role keys 44px.
- Bound to authoritative `Scripts/recruitment_catalogue_v3.gd` for actual role pool, Alex identity, age, town, 6 stats, cost, trouble, experience and exact remaining talent. In the un-recruited state **200/200** is correct. Alex costs **51**, leaving **149/200** if recruited. The earlier SVG design-only artboards misleadingly show **160/200** with an empty roster and **40** cost. This is a real source/logic mismatch; native proof fixes its display but the old design-only files are not yet revised.
- Deterministic native test proves recruit → roster/remaining changes → remove reverses, role/candidate switching, six read-only meters. Both native screenshot captures verified dimensions and nonempty real pixels.
- Real screenshot inspection found an embarrassing **1px font bug**: GDScript `phone and 12 or 16` is Boolean logic, **not** a Python-style ternary. It caused invisible role, candidate and meter captions despite green geometry tests. Replaced with `12 if phone else 16` and added regression checks for >=11pt and physical label width. The **final** artifact above includes visible labels. This is why pixel inspection matters.

## Actual pixel inspection — art quality remains BELOW owner gate
**ART P0: FAIL, no owner approval.** The visual composition is more intentional than old V3, but still materially weaker than the accepted photographed/physical roadcase reference. The new native proof itself is not a visually impressive game interface.

| Area | Actual observation from final PNGs | Gate |
|---|---|---|
| Portrait | Alex is the correct original person ID, not a swapped photograph, but looks like simplified clip art rather than a distinctive, convincingly drawn UK musician. | **P0 FAIL** |
| Material art | Existing source paper texture appears busy/lined and flattened; metal tabs read as stock gradients, not a unified convincing object. | **P0 FAIL** |
| Candidate rail | Real candidate names/IDs are shown, but no identity portraits for five alternatives. Deliberately no reused Alex face. | **P0 FAIL** |
| Typography | Dynamic captions now render, but many desktop/phone technical labels are small and blurry at native physical size; the artboard typography remains sharper. | P1 FAIL |
| Six attributes | Exactly six native, inert meters; values reflect the real singer catalogue rather than decorative SVG fiction. Phone labels are cramped; source artwork's labels/stats differ from the real model. | ENGINE PASS / UI P1 |
| Cost / talent / roster | **Correct** native 200/200 empty roster and 51-point Alex cost; actual action updates roster without writing saves. Earlier artboards are contradictory. | ENGINE PASS / DESIGN SOURCE P1 |
| Phone first fold | Five roles, six candidates, portrait, six bars, recruit action and roster are present at 390×844. Some information remains too small. | ENGINE PASS / UX P1 |
| Gameplay flow | This is only an art-handoff benchmark; it does **not** implement full genre-selection/name-last flow or complete mobile biography navigation. Existing V4 remains separate and unchanged. | NOT PROVEN |

### What the successful CI does and does not establish
**Confirmed:** Godot 4.7.2 imports source SVGs, renders native Controls at two physical sizes, supports texture-skinned native keys, and binds to real catalogue values. The scene can be exercised without modifying saves. The final capture test asserts readable font sizes after the visual bug was fixed.

**Not established:** character quality, material authenticity, matching the approved owner mockup, Figma fidelity, complete keyboard navigation, mobile dossier flow, complete genre→musicians→name interaction, third-party kit commercial reuse, real artist sign-off, production readiness. **The visual owner gate remains failed.**

## Recommendation for the 06:00 stop/go
**Stay in Godot for now.** This controlled proof shows the engine is not the cause of the poor portrait art, and changing to React/HTML would reproduce the same weak character art and design assets. A React comparison is not justified until a coherent, professionally illustrated/photographed, rights-clear source scene exists and Godot demonstrably fails to reproduce it. Do not buy Spine/DragonBones or pay for Figma/plugin access.

**Stop multiplying screens and cartoon vectors.** The next real dependency is a compelling, consistent, rights-clear two-character visual sample, preferably commissioned/original artist work or an independently inspected human-created pack with suitable licensing and genuine indie-band art direction. Keep one complete desktop and phone recruitment artboard as the acceptance target. Then adapt source texture layers and controls in Godot, check actual native pixels, and ask the owner to approve or reject before any rollout.

**Do not merge PR #199, modify production saves, or imply art approval.** The scheduled 06:00 sprint is report/quality closure, not more feature code.
