# Overnight recruitment quality spike — 00:00 art-direction lock
**28 Oct 2026 (UK), draft PR #199; unmerged, not owner-approved.**
**Owner feedback:** existing Figma shell and V3/V4 Godot renders are too weak. This is an **alternate art-direction composition test**, not a declaration that the visual bar is met.

## Tangible deliverables
- [Desktop 1280×720 editable SVG artboard](visual-proofs/recruitment_editorial_desktop_1280.svg).
- [Phone 390×844 independently composed editable SVG artboard](visual-proofs/recruitment_editorial_phone_390.svg).
- Both contain a deliberately illustrated **Alex Vale** study, not a photograph or a claim about a real person. All source shapes and text are separate SVG elements (Figma can import these as design layers, subject to local editability tests). **Neither SVG is an interactive Godot scene or a runtime sprite**; dynamic text and gameplay must remain native in engine.
- Source rights: the geometry, character drawing and layouts were created for this isolated test, without copying third-party packs or real-person photographs. They are **programmatic vector studies** and are *not* artist-certified production character art. No external licence is claimed. No AI-generated photoreal face.
- Exact file URLs use the branch's immutable commit where possible; source remains draft/unmerged.

## Deliberate visual direction
**British indie-gig-zine / editorial casting dossier**, rather than more imitation rivets and multiple unrelated metal plates. Off-black #111718, amber #f4ad39, acid talent indicator #d9e35b, worn ivory #eee9db, restrained red #e45c47, green #9cbf7e. Main image mass is portrait + readable human story; surface decoration is secondary. Direction is inspired by authentic gig flyers, photocopied music press, band-contact sheets and handwritten talent dossiers. No pixel-fantasy, sci-fi or generic mobile dashboard kit. Use existing OFL Barlow Condensed / IBM Plex font files for Godot final; the SVG proof uses system fallback and is **not** a typographic pixel-match.

### Landscape geometry at 1280×720
| Region | Approximate bounds (x,y,w,h) | Behaviour |
|---|---|---|
| Header + talent | 35,20,1210,100 | Genre / stage and **160/200** trial talent prominently visible |
| Genre rail | 31,136,100,421 | Five genres; selection changes candidate pool |
| Six-candidate rail | 151,175,101,362 | Actual candidates need unique, rights-clear portraits; current circles are explicitly mock silhouettes |
| Five role tabs | 430,126,609,44 | Each role is 117×44 physical pixels, all visible |
| Featured portrait | 277,175,330,276 | Illustration study, not production-ready art |
| Six read-only meters | 279,506,~330,~77 | Immediately below portrait; row density is **too tight** and is P1 for Godot |
| Paper dossier | 632,174,409,379 | Age, city, experience, strengths, complication, ambition |
| Cost/risk + recruit | 1063,176,182,352 | Explicit cost and first-fold amber action |
| Persistent roster | 35,586,1210,105 | No one signed yet; name-last only after valid roster |

### Phone geometry at 390×844
| Region | Approximate bounds | Behaviour |
|---|---|---|
| Header | 18,15,355,79 | Talent 160/200 in first fold |
| Five role tabs | 17,106,356,44 | All roles visible and individually tappable |
| Six-candidate strip | 18,181,350,48 | Scroll/browse selection to be implemented; silhouettes are NOT identity art |
| Featured portrait + cost | 19,242,352,240 | 200×240 portrait, adjacent 152×240 price/identity card |
| Six read-only meters | 19,513,~355,138 | Readable 23px rows; no focus or pointer capture |
| Primary recruit | 19,664,352,60 | 60 physical px high; visible without scroll |
| Persistent roster | 19,737,352,88 | Empty until recruited; no premature member-count claim |
| Extended biography | Separate detail view | A true secondary file view, not clipped 10px text |

**The phone is a distinct composition, not a scaled landscape screenshot.**

## Quality inspection — candid P0/P1
**P0 art NOT PASSED:** Portrait is still simplified flat vector/clip-art adjacent, not a memorable British musician. It is *more honest* than mislabelled stock or fake AI-looking photoreal faces, but not sufficiently good. No complete artist-quality cast. Existing 160×160 source portraits are inadequate. Paper texture and environmental lighting remain too flat relative to the approved photographic roadcase. Six candidate thumbnails are silhouettes, not six distinct people. **Do not turn this artboard directly into a production sprite or multiply the faces.**
**P1:** 1280 desktop six meter rows are only ~13px apart and therefore too dense for comfortable reading; Godot layout should allocate ≥22px and reduce other furniture. Source SVG uses DejaVu fallback, not Barlow/IBM Plex, so typography must be re-reviewed with actual imported fonts. Some desktop nav uses 10–11px micro-labels; increase critical copy to 13–16px. Contrast/focus/disabled variants are NOT yet present; current static artboard cannot establish accessibility.
**P1:** The user-approved mockup image is not available as a committed source PNG, so pixel-by-pixel comparison remains impossible. Artboard comparison is conceptual only.
**P1:** Phone file details are a secondary view; a visible `VIEW FILE` affordance is present but not wired.

## Source, licensing and tool choices
- Original study contains no imported third-party images, no scraped photos, no purchased Spine/DragonBones assets, no Figma-to-Godot runtime dependency, no production-save mutation.
- [Kenney UI Pack](https://kenney.nl/assets/ui-pack) lists **430 assets** and **CC0** on the creator's site (checked 27 Oct 2026). Useful legally as a *technical UI sample*, but its neutral game look is not automatically a stylistic match. No asset downloaded or used here.
- Owner's [Econev 10,000+ Figma game UI library](https://www.figma.com/community/file/1401135710750637762/games-ui-ux-elements-library-10-000-by-econev) remains **reference only**. Price, individual component scope and commercial reuse licence were not independently confirmed. No assets copied.
- [Godot GUI skinning](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html), [type variations](https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html), [NinePatchRect](https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html) remain the no-cost implementation path. The artboard is NOT a baked interactive texture.
- Existing connected [Figma source](https://www.figma.com/design/nNfK8L1pC6cuRwcYacmPoz) remains intact; the Starter MCP quota prevented further native edits. These independent SVGs are importable **candidates**, not claimed to have been inserted into that file.

## Next ordered gates
**02:00:** Improve the Alex portrait *substantially*, and attempt one genuinely contrasting candidate in the **same visual grammar**. If either still looks like a generic avatar, record art P0 and stop cloning. Prefer verified original illustration or a licensed, consistent portrait set, never unlicensed photos.
**04:00:** Only if art composition approaches owner target, implement one isolated Godot 4.7.2 scene using native labels/Theme variations, source artwork slices, genuine role/genre controls, six inert meters, visible budget and roster. Native 390/1280 screenshots + deterministic tests. Do not call SVG artboard a native Godot capture.
**06:00:** Stop feature work; report exact code SHA, screenshots, visual gap, licensing and a go/no-go recommendation. No main merge.

**Owner art approval remains OPEN.**
