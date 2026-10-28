# Recruitment V4 — 20:00 owner-directed visual repair review, 27 October 2026

**Scope:** Isolated V4 art/layout and native capture checks ONLY. PR #199 stays draft and unmerged; no S03–S07 rollout, main changes, save writes or live band-builder integration. The owner-approved 1536×1024 concept is a *target*, not a shippable image. This is a simulated review, **not owner art approval**.

## Exact tested code and evidence
- Last code commit: `7598b973c45a621908addf081fe1ce17008150ff`.
- Focused [Godot 4.7.2 V4 CI **SUCCESS**](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40575809685): source SHA and forbidden-helper lint, native import, isolated deterministic recruitment model, **16 actual PNG screenshots**: 390×844, 720×1280, 1280×720, 1600×900 × genre/recruit/name, plus 390/720 paper bio and 390/1280 viable-roster screenshots.
- [All 16 actual Godot screenshots — artifact 12767049269](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40575809685/artifacts/12767049269). The actual 390 recruit, 390 bio, 390 name, 1280 recruit/ready/name and 720 genre/recruit/name PNGs were opened and visually inspected. No screenshot is an invented render.
- Previous verified 14-screen baseline [40570753488](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40570753488) / [12765348109](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40570753488/artifacts/12765348109).

## Specific fixes based on native pixels
1. **Phone role dead end fixed:** all five SING/GUITAR/BASS/KEYS/DRUMS tabs are now visible and individually reachable at 390; the old three-tab window trapped the player away from keys/drums. A viable lineup now exposes a real **NAME BAND** key at 390 and 1280, without overlapping ADD/REMOVE. The capture gate asserts role labels, name action, 44 physical px minimum and non-intersection.
2. **Paper biography fixed:** the original punched paper margin was physically underneath native text. All text now starts after the punched holes; story, strengths, friction, history and ambition are legible at 390 and 1280.
3. **Name-last stage given physical material:** a source-skinned, focusable real LineEdit replaces the default flat black field; a native-data founding-roster paper slip fills the previously empty name stage. The field's text inset was widened to clear hardware rivets. Disabled amber button captions now remain visible.
4. **1280 landscape footer fixed:** empty roster slot captions moved above the lower case edge. Selected tabs retain their selected texture on hover; photographic transport keys have keyboard focus feedback.
5. **720×1280 tablet composition repaired:** candidate portrait is now a deliberate 440×350 portrait region instead of a pixelated 572×175 strip; six passive meters get 35px rows and larger native text. Genre keys use available vertical height; name-stage roster paper scales to the tall screen.

## Five adversarial simulated persona findings (not human reviews)
- **First-time player — P1:** the five roles and 200-point budget are visible; however the genre-to-musician difference is only a short text brief and the choice consequences need stronger at-a-glance visual communication.
- **Working musician — P1:** the 3-person Alex/Sam/Jo hybrid roster reaches name-last without double-counting, but a 200-point talent allocation and fifth/sixth penalties remain trial balancing, not approved game rules. Personality/ambition are written notes, not proven live career effects.
- **Art director — P0 ART BLOCKER:** the original low-resolution Alex source becomes visibly soft/pixelated at 720 and tightly cropped at 1280. Only four legacy identity portraits exist; other identities must retain honest PHOTO ART PENDING until individually sourced/generated with rights and SHA provenance. The SVG case/paper is coherent but still flatter than the approved photographed roadcase mockup.
- **Accessibility — P1:** 390 phone buttons are at least 44px and five role labels fit, but condensed tab copy is small; the six landscape meter labels and small paper body copy at 1280 need larger physical type. Inspect keyboard focus and selected contrast manually.
- **Godot/release — P1:** the exact focused V4 job is green and local model state never calls production save APIs, but screenshot/geometry tests do not establish artistic fidelity. The approved reference PNG is not imported to GitHub for exact visual comparison. A real owner visual decision remains required.

## Remaining acceptance blockers and manual check
**ART HOLD**: obtain distinct rights-clear, identity-matched, adequately resolved candidate portraits with per-file SHA/terms; increase photographed material realism and improve 1280 meter/photo hierarchy against the approved concept. Do not substitute another candidate's face, bake dynamic data into a screenshot or call CI a visual sign-off.

Manual Godot 4.7.2: open `res://poc/ldtd_recruitment_v4.tscn`, select Indie rock, enter recruitment, inspect all five tabs, browse six candidates, inspect the paper file, recruit Alex/Sam/Jo, confirm 70 talent remaining, use NAME BAND, type a name, and verify no `user://` save changes. Review native 390 and 1280 first; check 720 and 1600 thereafter. **No main merge or S03–S07 restart.**

---

## 21:00 focused V4 art-quality continuation (27 October 2026)

**Exact last code/art commit:** `1b3f2f94c25f3de3adae1ca093767bbd5f84d054`. Focused **Godot 4.7.2 CI SUCCESS**: [run 40584695348](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40584695348), [18 genuine native PNGs / artifact 12770788504](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40584695348/artifacts/12770788504). Four viewports (390x844, 720x1280, 1280x720, 1600x900) in all three stages, plus two paper dossiers, two viable-lineup screens and two deliberately unsourced Josh Bennett contact screens. The focused job completed import, pure model tests, source-SHA/forbidden-helper checks and all 18 real captures. Latest PR head remains **draft, unmerged**; owner art gate is **OPEN**.

### Concrete native-image fixes, inspected
1. Original authored metal case now has folded corner guards, side latches, edge seals, wear and extra fasteners; paper has subtle worn folds, grain and edge shading. These remain **SVG vector material proofs**, not photographed metal or paper.
2. The former 1600x900 case texture was non-uniformly stretched to a 390x844 phone, deforming round rivets into long ovals. Independently authored 390x844 phone and 720x1280 tablet case SVGs now preserve hardware aspect and align the case's roster separator to the native dock. The actual 390/720 Godot screenshots were opened and inspected.
3. The 720x1280 portrait region now uses 440x450 rather than 440x350, revealing nearly the whole 160x160 source image and filling an otherwise empty gap above the dock. **It does not invent lost photographic resolution.**
4. Landscape dossier copy and six read-only meter labels/values were enlarged; actual 1280x720 and 1600x900 screenshots show the six bars, paper story, strength, friction, experience and CTA without new collisions.
5. Selected metal tabs now have a lighter amber centre for dark native labels. The SVG midpoint contrast estimate rises from ~2.2:1 to ~5.2:1 against the existing dark ink; this is a calculated colour check, **not** a full accessibility audit.
6. An authored empty-film contact frame explicitly says **PORTRAIT / ART PENDING** for unsourced Josh, verified by two native captures. No other candidate's face is aliased to Josh and no fictional photograph is claimed.

### Five simulated adversarial findings — not human approval
- **Player, P1:** Genre choice is navigable and the 390 first fold includes five roles, photo/ID, six stats, recruit action and remaining points; the genre-to-pool consequence still reads like a short text brief rather than a vivid choice.
- **Musician, P1:** Alex/Sam/Jo form a valid three-person hybrid lineup without double-counting; the 200-point talent pool and fifth/sixth penalties remain a trial economy, not owner-approved balance. Personality and trouble notes are not yet proven downstream mechanics.
- **Art director, P0 BLOCKED:** All four existing portrait sources are only 160x160 pixels; 32 of 36 canonical candidate IDs have no source photo. The 1280/1600 portrait is visibly enlarged and tightly cropped. The new film card is honest but **not a replacement for casting photography**. Vector roadcase material still falls short of the photographed owner mockup.
- **Accessibility, P1:** 390 role tabs and actionable keys satisfy the focused >=44 physical-pixel gate; selected captions are clearer, but condensed labels, 1280 meter numerals, keyboard focus and assistive-technology semantics need owner/device audit.
- **Engineering, focused PASS / owner gate OPEN:** V4 remains an isolated no-save scene; no legacy flat helpers, no `main` merge, no S03-S07 restart. Automated geometry and screenshot generation cannot establish art fidelity. The approved 1536x1024 reference binary is still absent from GitHub, preventing an exact image side-by-side.

**Source blocker and first portrait pilot:** [V4 portrait source intake brief](V4_PORTRAIT_SOURCE_INTAKE_2026-10-27.md). Next art step is 2-3 individually rights-cleared, identity-matched high-resolution portraits with SHA/source records, then an owner comparison at 390 and 1280. Do not resume broad scene work or production integration. On/after 22:00 Europe/London, stop code changes and provide handover only.
