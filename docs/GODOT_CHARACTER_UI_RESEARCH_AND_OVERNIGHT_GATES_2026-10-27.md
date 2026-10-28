# Godot character and UI/UX research — binding overnight knowledge brief
**27 October 2026; repo `alimuir654-rgb/BandMaster`; draft PR #199, NOT approved for merge.**
**Research conducted before the 00:00–06:00 UK quality-rescue sprints.** Sources are documentation, public forums, and community case studies, *not* independent art reviews. Claims are traceable to the URLs below. This document supplements the owner's `docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md` and the actual concept reference `docs/RECRUITMENT_REFERENCE_LOCK.md`.

## Conclusion — do not change engine or buy anything
Godot 4.7.2 can already execute the necessary responsive/native input + texture skins + custom-portrait and animation work. The relevant unsolved problem is the *art pipeline* and overall information composition. Treat the last owner-approved recruitment mockup as visual design contract, not shippable texture. Do not purchase Spine, upgrade Figma, import unverified packs or add a new runtime plugin.

We need exactly ONE memorable recruitment candidate artboard at native 1280×720 and 390×844, then two contrasting candidates in the same style. Only after an art-direction PASS do we replicate/reuse components. A green import/test/controls assertion is not an art PASS.

## Evidence from real games and developers

### A. Art direction is not an optional styling pass
- [r/godot: Making pretty UI is so hard (5 May 2026)](https://www.reddit.com/r/godot/comments/1t4qvyl/making_pretty_ui_is_so_hard/): contributors explicitly suggest wireframing content and arranging a *holistic screen artwork* in Krita or Affinity **before** using Godot to wire controls. Someone reports creating art in Aseprite and still finding overall design hard; asset packs alone do not solve hierarchy.
- [r/godot: Is my UI better? (10 Aug 2024)](https://www.reddit.com/r/godot/comments/1eorlk0/): iterative improvement described through consistent typography, colour palette, background context and understated shadows; ornamental/detail overreach still hard. This warns against rivet/metal over-decoration.
- [r/godot: I didn't expect UI to be one of the hardest parts (8 Feb 2026)](https://www.reddit.com/r/godot/comments/1qzc6as/i_didnt_expect_ui_to_be_one_of_the_hardest_parts/): prioritize player decisions and surface extra detail progressively; reuse custom button/menu scenes, but keep them coherent.
- [r/godot: Advice for menus and UI (19 Jul 2026)](https://www.reddit.com/r/godot/comments/1v0ylsp/advice_for_menus_and_ui/): recommends visually studying [Interface In Game](https://interfaceingame.com/screenshots/) and [Game UI Database](https://www.gameuidatabase.com/) and then isolating buttons, avatars, labels, etc. into custom Godot scenes.
- [r/godot: I really enjoy making UI in Godot (13 Jun 2026)](https://www.reddit.com/r/godot/comments/1u4njgm/i_really_enjoy_making_ui_in_godot/): advanced custom image TabContainer example shows that well-structured native Godot UI *can* look polished. Do not infer any specific downloadable art from the conversation.

**BandMaster rule:** player sees exactly one current candidate, six plainly comparable stats, qualitative strengths/frictions, existing lineup and clear recruit/back/forward path in first 5 seconds. Portrait occupies dominant, intentional space. Omit unnecessary UI metadata and tiny over-ornamentation. Labels and points remain native editable text. Character visuals, dossier, case and controls must share the same imagined physical world, material scale, lighting and shadow direction.

### B. Source-backed UI shells using Theme resources, not dozens of ad-hoc local overrides
- [Godot official GUI skinning](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html) describes a cascading global `Theme` resource for fonts, colours, icons, StyleBoxTexture and focus; it is capable of heavily stylised GUIs, not just default gray controls. The docs feature *Tank Kings / Gear Up* as a very different custom game UI.
- [Godot theme type variations](https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html): shared variants are explicitly intended to prevent per-control override duplication. Proposed BandMaster variants: `CaseRoleTab`, `CaseCandidate`, `CaseTransport`, `CaseRecruitCTA`, `CasePaper`, `CaseRosterDock`; owner may simplify metal language if visual density worsens.
- [StyleBoxTexture](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html) / [NinePatchRect](https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html): true nine-slice retains source corners/edges and scales centre intelligently; *not* a whole-screen 1536×1024 baked UI texture. Test exact texture/patch margins at actual device sizes.
- [Godot Forum: Why can't I resize my textured progress bar? (18 Oct 2026)](https://forum.godotengine.org/t/why-cant-i-resize-my-textured-progress-bar-properly/145628): overly large source textures/incorrect 9-patch margins create poor resizing. Author at screenshot scale and import at appropriate device densities, rather than shrinking an 800×120 bar to 150px while hoping it stays crisp.
- [Godot Forum: How to put high-definition background texture on UI? (25 Oct 2026)](https://forum.godotengine.org/t/how-to-put-high-definition-background-texture-on-ui/145909): similar texture-size/resampling issue arises for backgrounds. The answer should be a properly designed *repeatable centre surface + fixed nine-slice border*, not simply doubling raster sizes.
- [Godot multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html): viewport stretch, anchors, Containers, texture filtering, separate responsive breakpoints must be intentional. Project uses `canvas_items` stretch, 720×1280 logical size; test physical 390×844, 720×1280, 1280×720 and 1600×900. 1280 and 390 require **different purposeful compositions**.
- [Keyboard/controller focus](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html): explicit initial focus + neighbour graph prevents native focus from jumping erratically in complex screens. No empty focus ring; 44px physical tap minimum, 48 preferred. Six read-only attribute bars NEVER capture focus.

**BandMaster architecture rule:** Do not copy the ugly visual defaults. Have a single approved theme and a *small* component family, test style, focus, pressed, hover, selected and disabled states. Preserve source-backed native texture seams and exact touch targets. V3 flat StyleBoxFlat helpers remain quarantined.

### C. Character art: build a cohesive illustrated cast before rigging them
- [r/godot: Modular 2D Characters (29 Jan 2026)](https://www.reddit.com/r/godot/comments/1qq9y23/is_it_a_good_idea_to_use_modular_2d_characters_is/): suggests assembling ordered parts into a compositor then rasterising stable sprites for efficiency; commenters warn that syncing parts across animation frames is tedious.
- [Godot Forum: Change skins (11 Feb 2025)](https://forum.godotengine.org/t/how-to-change-skins/101640): naive duplicate spriteframes per outfit is feasible but repetitive; shared skeleton/deformation can support texture swaps.
- [Godot Forum: Help animating 2D body parts (16 Dec 2023)](https://forum.godotengine.org/t/help-animating-2d-body-parts-multiple-sprite-components/37840): composite sprite hierarchy with independent parts is viable *if source sprite poses are aligned*.
- [Godot official cutout animation](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html) and [2D skeletons](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html): Godot can animate child sprites/pivots and Polygon2D/deformation; no Spine subscription required. A skeletal rig adds production burden. Character visuals must be attractive while static.
- [r/godot: Opinions on 2D skeletons (1 Aug 2026)](https://www.reddit.com/r/godot/comments/1vcynlc/opinions_on_the_2d_skeletons/): useful for repeated dynamic poses, but setup is not trivial and creates a particular look.
- [Dialogic 2 discussion (21 Aug 2026)](https://www.reddit.com/r/godot/comments/1vusiqq/dialogic_2_is_an_outstanding_plugin/): portrait emotion variants + built-in dialogue presentation are a possible *later* source of ideas for band chemistry; NOT a reason to install a dialogue plugin before the art quality gate.

**BandMaster character-art decision:**
1. Choose ONE controlled portrait direction: **recognisable British grassroots illustration / screen-printed music magazine** (inked forms and limited but expressive palette) OR **genuinely photographic sourced/consented portraits**. Do not mix these. User allows complete character replacement, so old four headshot IDs aren't sacrosanct.
2. Art direction Bible must define: camera angle/portrait crop, source resolution, ink contour style, highlight and shadow direction, palette per genre, wardrobe/authenticity, hair/faces/body proportions, identity consistency, value range, typography, photo/source rights.
3. Create **one singer + one contrasting candidate** from the same template to detect cloning. They should remain identifiable when you remove names. Avoid generic synthetic faces, unrelated stock looks, inconsistent ethnic/gender patterns or AI-looking pseudo-photoreal fantasy.
4. Source portrait at ≥2× intended visible physical pixels; keep original layered SVG/PSD/Krita with per-person immutable IDs, provenance and crop metadata. Measure at 390 and 1280. If art source cannot be verified, display a truthful art-pending card and consider the art milestone *unmet*.
5. Initial game can use a static portrait or at most two hand-authored expression frames (neutral / reaction). Do not build skeleton/Spine/DragonBones integration until portrait and complete recruitment frame gain owner approval. After approval, trial <0.4s subtle blinking / eyebrow/pose change with native Godot AnimationPlayer, subject to player preference/reduced-motion.

## UI/UX information architecture: progressive disclosure
- Landscape: genre and role first, browseable six candidate IDs, prominent portrait, six meters immediately beneath, dossier, next/recruit, dock. Use a lightweight layer approach—case/portrait/paper hardware textures separate from live text.
- Phone: top identity + role switch, larger portrait, six read-only stat indicators, primary recruit and fixed talent dock visible; detailed dossier occupies dedicated art-backed screen rather than collapsing 12pt prose under an oversized photo. Ensure all five roles visible/navigable; keyboard/gamepad and touch focus tested.
- First 5 seconds heuristic: player can identify person, primary role, approximate cost/strength, significant risk, what happens if they recruit, and remaining budget.
- Richer details such as prior bands and ambitions belong on an intentional *paper* details surface; never hide core cost/decision behind a tooltip.
- Day vs night is a world-state styling rule. Recruitment dark case does not imply songwriting DAY screens should be black.

## 00–06 UK overnight sprint acceptance rules
These replace vague instructions like 'more polish':
- **00:00 — art-direction lock.** Pick a single consistent illustrated vs licensed photo path, evidence why it suits game; complete one still 1280×720 candidate composition with asset source manifest. No extension/tool purchase.
- **02:00 — character production proof.** One additional *different* woman/man candidate in same style; check identity differentiation, dimensions, paper/cartridge texture and named art layers; source/rights SHA. If no convincing portraits possible, STOP character cloning and document blocker.
- **04:00 — engine contract proof.** Show *actual* Godot scenes at 1280×720 and 390×844, same source artwork, 6 inert meter stats, 3-step genre->musicians->name, genuine buttons. Test UI focus, all five roles, precise 200 point trial model, and native screenshots. No legacy helper fallback.
- **06:00 — stop/go and review preparation.** No fresh features. Screenshot side-by-side, record what source art has been faithfully implemented, baseline difference, problems, native import+gameplay tests, recommended next step for owner at 08:00. If below quality gate, state why rather than another minor iteration.

**No automatic PR merges, old-sprint restarts, main/save mutations, paid tools or licence assumptions.** All changes remain in draft isolated branch; provide owner actual file/PR/run links.

## Explicit rejections of seductive dead ends
- Shipping a fully flattened concept image with transparent click targets does not deliver editable gameplay and is prohibited.
- Generating 36 different faces with inconsistent random prompts, styles, lighting or poses is not a coherent cast.
- Pixel fantasy stock pack / theme kit designed for a different genre will not fix a British band simulator.
- Three differently sourced metal/wood/paper control packs can look less professional than ONE restrained material family.
- Animated buttons, CRT shaders, camera shakes and old-demo plug-ins cannot hide flat composition or a faceless lead character.
- A successful CI screenshot means **'rendered'**, not 'meets art standard'.
