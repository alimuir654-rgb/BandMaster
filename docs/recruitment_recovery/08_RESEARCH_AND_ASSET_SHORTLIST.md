# Research / asset shortlist with use decisions — 28 October 2026

Use these grounded sources and the repo's prior `docs/GODOT_CHARACTER_UI_RESEARCH_AND_OVERNIGHT_GATES_2026-10-27.md`; do **not** restart research as a substitute for art production. URLs are reference links, not warranties, source ownership, verified local downloads or automatic permission to ship. Revalidate rights on *actual file intake*.

## Godot implementation — primary sources

1. [Godot GUI skinning](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html): cascading `Theme` resources + type variations; makes coherent art systems achievable without generic default buttons. **Use** shared case controls and font system, not ad hoc skins.
2. [StyleBoxTexture](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html): nine-patch textured surfaces with preserved borders. **Use** for paper/case edges, with margins inspected at actual sizes.
3. [Godot multi-resolution layouts](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html): anchors, content scaling and physical-aspect considerations. **Use** authored desktop/phone compositions rather than single stretched scene.
4. [Godot keyboard/controller focus](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html): explicit initial focus and neighbours. **Use** for role/candidate/action; never for passive meters.
5. [Godot image imports](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html): PNG/WebP/SVG support, limited SVG renderer. **Use** real native render verification; generate raster derivatives when complex SVG imports misrender.

## Useful industry practices

6. [Unity's game UI basics](https://unity.com/blog/video-game-ui-ux-basics): identify critical inputs/outputs, visual affordances, immediate feedback and simplify unnecessary information. **Use** five-second recruit decision read rather than ornamental density. Engine-agnostic process only.
7. [Interface In Game](https://interfaceingame.com/screenshots/): screenshots for visual hierarchy reference; **reference only**, not copyable/redistributable artwork.
8. [Game UI Database](https://www.gameuidatabase.com/): UI reference library; **reference only**, not a third-party asset licence.
9. [Godot forum/community references in the existing research brief](../GODOT_CHARACTER_UI_RESEARCH_AND_OVERNIGHT_GATES_2026-10-27.md): recurrent lesson is to design one holistic image composition before implementing controls. These are opinion/case studies, not objective commercial production guarantees.

## Asset leads and decisions

| Lead | Rights/source assessment | Decision for this sprint |
|---|---|---|
| **Existing original Lab07/Lab08 image-backed hardware** (see PR #193 + #198 source imports) | Already in development Git branches, exact source/sha/licence paths must be rechecked before use | **PRIORITISE** over recreating inferior vector keys; use only where materials match physical case. |
| **Existing `Art/UI/RecruitmentV4` images** | Original repository source: metal tabs/paper/SVG case. Not owner-accepted photographic quality | **TECHNICAL REFERENCE ONLY**; do not use as proof of visual pass. |
| **Existing `Art/Portraits/indie/*.webp`** | Real files in repo, identity/date/licence and resolution vary; previous review reported four 160×160 portraits | **INSPECT/INTAKE**; no assumption they pass at hero scale; never remap identity. |
| **Original SVG Alex/Nia ink studies** | `docs/visual-proofs`, code-authored originals | **REJECTED ART QUALITY**. Anti-target, not portrait source. |
| [Kenney UI Pack](https://kenney.nl/assets/ui-pack) | Official author page lists 430 UI items, CC0 | **OPTIONAL LOW-FIDELITY PROTOTYPING ONLY**. Do **not** inject its flat UI chrome into premium recruitment; not the solution to the art problem. |
| [Lucide icons](https://lucide.dev/license) | ISC licence subject to actual icon package and licence text | **EXISTING ONLY**. Use repo's curated icon assets if appropriate; no fresh pack import without visual fit and provenance. |
| [Three Figma Community references supplied by owner](https://www.figma.com/community/file/1460785931676185568/game-ux-kit) | Viewing/sampling design ideas is distinct from commercial redistribution of assets; verify actual pack licence | **INSPIRATION**, not source art, until explicit rights and export verification. |
| [Unsplash licence](https://unsplash.com/license) | Generally broad image reuse permission, but property/model/trademark rights and attribution provenance still need checking | **ENVIRONMENT REFERENCE ONLY**. Do not mislabel stock performer portraits as unique fictional musician identities or assume model release. |

## Licensing workflow

1. Record official product/creator URL and actual licence text, date accessed, and asset-specific rules.
2. For assets actually imported, store source SHA-256 and resolution, `origin_kind`, usable derivative path(s), identity/credit data and whether modifications are permitted.
3. Do not import or ship Figma examples, photography, or unrelated UI packs just because they are available publicly.
4. Original generated artwork: keep the actual output and clear origin; confirm contractual/usage terms separately, never state human-photographer permission where none exists.
5. Prefer directly authored, coherent art, with source verified in the repository, over assembling three visually inconsistent packs.

## Time-saving decision

**No new plugin/engine research until a specific unworkable Godot screenshot defect is demonstrated.** Root cause is art direction + asset pipeline. For this milestone the correct "specialist agents" are scoped instruction roles in `.agents/recruitment/`, not independently scheduled imaginary workers.
