# Figma-first recruitment shell — overnight experiment
**Created following owner direction, late 27 October 2026, ahead of 08:00 UK 28 October review. NOT owner-approved visual art.**

## Source of truth
Native **editable** Figma Design file: https://www.figma.com/design/nNfK8L1pC6cuRwcYacmPoz
- Figma frame **2:13** — `01 / RECRUITMENT / 1280 × 720` landscape.
- Figma frame **2:183** — `02 / RECRUITMENT / 390 × 844` phone.
- Native variables collection `LDTD / Recruitment / Semantic`, ten semantic colour tokens (back, surface, ink, muted, accent, paper, paperink, red, yellow, green).
- Editable native text and separate shapes; not a flattened screenshot. Barlow/Barlow Condensed typography.
- Each frame includes genre, role tabs, six selectable candidates / browse controls, singer portrait **art source placeholder**, six stat meters, personality/experience dossier or excerpt, visible point budget and recruit CTA.
- The deliberate placeholder **does not constitute usable character art**. Real professional illustrator-led or hand-authored modular character design remains P0.
- The first landscape/mobile artboards provide structure, not owner art approval or production-design equivalence. Initial structure is not yet turned into a mature library of reusable native components and variants.

## Decision gate
Do not import the current first-pass Figma shapes into the Godot main build merely because they're editable. Refine composition and source-backed character art until a side-by-side Figma quality review meets or exceeds the owner's recent approved visual mockup. Then build a small isolated Godot rendition. Keep Figma source text and dynamic state separate from material bitmap exports; use real native Godot controls. Preserve existing saves, avoid any Spine costs, only consider free Godot Skeleton2D/DragonBones examples.

## Research and product commitments
- Figma design-systems available through connected account; new file has a clean self-owned semantic collection rather than copying unrelated Material 3 or iOS components.
- Spine/DragonBones examples remain capability research only; no editor licence, runtime integration, assets or dependencies authorized.
- Compare visual results at native 390×844 and 1280×720; native Godot capture still a separate acceptance requirement.
- New V4 design contract and AGENTS.md remain binding. Do not merge draft PR #199 or resume whole-scene sprints.
