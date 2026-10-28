# LIVIN' THE DREAM — V4 Visual Production Contract
**Owner override, 27 Oct 2026 at ~19:01 Europe/London. Status: binding design/release rules for new scene work.**
**Precedence:** user creative direction > this contract > previous scene sweep guides and historical screenshots. No previous first-pass art sign-off implies V3 UI acceptance. PR #199 is DRAFT and MUST NOT be merged.

## 0. What failed — no rationalising
The owner approved a visually rich roadcase **recruitment mockup**: full scene composition with riveted dark metal frame, artist portrait, six meters beneath the portrait, left genre rail, role tabs, contact-sheet candidate rail, torn/off-white paper biography on the right, persistent lineup, physical transport arrows and amber primary recruit control. The implemented Godot V3 used large untextured StyleBoxFlat rectangles, tiny square portrait, default-ish buttons, empty black bands, tiny text and disconnected component layers. All CI passed while **the actual screen was radically poorer**. That is a visual production-process failure, NOT a few missing polish tweaks. Old V3 is retained solely for gameplay tests / as a documented anti-reference.

**Hard gate:** Do not describe V3 as visually approved, final, premium or ready for integration. No page rollout, typography-only or arbitrary smaller color iteration while new V4 art target is failing.

## 1. Reference-to-implementation pipeline (visual before feature breadth)
1. **Pin the target.** The owner-approved 1536x1024 recruitment mockup from this conversation is an **art direction target only**, never an interactive source asset. Store an exact imported copy/reference SHA and cropped annotations only if the binary is available in repo. If not, store this textual pixel/region contract, and do not falsely claim pixel-perfect measurement. Inspect the source reference and native capture side by side.
2. **Map visual structure:** 10–15% left genre cabinet, ~10–15% thumbnail rail, ~30% focused performer and meters, ~30% paper profile notes, bottom ~14% live band dock. Landscape base 1536x1024; phone is a separate purposeful composition, not a shrunk landscape card column.
3. **Material system first:** original, licensed source-backed or authored image texture layers, nine-patch frames for case/paper, rivets/corner plates, physical shadows and real photographed musician portraits where licensed/verified. No big feature commits until a single real Godot 1280x720 AND 390x844 capture shows composition convincingly.
4. **Build real reusable components** (themed/native labels; photograph-backed transport; photo/ID portrait; artist-paper note with native biography; indicator-only six-channel red→amber→green meters; countable roster ticket; genuine tactile five-state tabs and recruit keys). Layout is where they are assembled: no stacking generic floating boxes around premium controls.
5. **Prototype one selected candidate with real data, then generalize.** With missing portraits, retain explicit identity placeholders and mark ART BLOCKED; NEVER map another person's face to a made-up candidate or invent licensing. Owner should inspect 2-3 genuinely different candidates; do not mass-produce hundreds of filler heads.
6. **QA gates**: CI parses/tests engine and generates four physical viewport native screenshots; screenshot inspector and designer independently compare target/material mass, density, photo dominance, luminance, hierarchy, readable labels, button geometry and touch/focus states. Document exact failures. No 'passed' based on source code presence or unit tests alone.
7. **Owner gate**: only real owner reviews confer visual approval. Simulated player/musician/art director/a11y/engineer reviews are checklists, not independent sign-offs.

## 2. Design rules — non-negotiable
- **One believable object/environment, not a dashboard of unrelated rectangles.** Recruitment lives inside an integrated dark worn road-case with brushed gunmetal/edge riveting, warm amber practical focus and honest photo/print surfaces. Source-backed stage portraits and paper are the principal visual mass, not background rectangles.
- **No generic `StyleBoxFlat` normal/hover/pressed primary controls in NEW V4.** Use source-verified five-state TextureButton or reusable `StyleBoxTexture` nine-slice (normal/hover/pressed/selected/disabled), plus explicit keyboard focus. Old `Scripts/ui_theme.gd`, `_button()`, `_panel()` families in `poc/ldtd_recruitment_v3.gd` are **quarantined**, not shared by V4. Do not delete them until callers are migrated and regressions pass.
- **Visually branded status, not generic Godot widgets**; no naked OptionButton, SpinBox, default TabBar; new controls may use native InputEvent handling but all visible skins must match the art contract.
- **Typography with evidence:** tracked Barlow Condensed for uppercase headings, IBM Plex Sans for native biography and numerical controls, IBM Plex Mono for small technical readouts, original OFL files preserved. Legible at physical rendering sizes; no illegible diagonal handwriting as player instructions.
- **Every portrait = unique canonical person ID and consent/licensing provenance.** Mixed genders, British locations/names, believable variation; identities never swap when switching genre. Missing photo is an explicit source blocker, not permission to mislabel a reused male photo as a female or a different person.
- **Six source-driven, inert red-yellow-green attribute meters under portrait**; native 1–10 labels and values, 0 means no active value marker; meters no mouse/focus/drag. Keep candidate data/role-specific attributes authoritative.
- **The on-screen paper dossier** includes age/town, career bands count/years, temperament, specific strength, friction, trouble risk and ambition. Show meaningful costs and trade-offs.
- **Session flow:** genre first → musician roles (singers/guitarists/bassists/keys/drums; six candidates per role/genre) → band name last. True two-role singers count as one person; 3–6 distinct members within proposed 200-point allocation, transparent fifth/sixth costs. These are trial numbers, not signed-off balance.
- **DAY vs NIGHT semantics:** formation/recruitment is intentionally dark physical in-room roadcase, which is not a blanket licence to make future DAY touring or songwriting night-black. World phase controls backdrop, not local real-world clock.
- **Every meaningful control**: 48 physical px target preferred (44 minimum hard), keyboard focus, disabled text, hover/press/latch differentiation, selected state persistent over hover, real click result. Accessibility should be measured, not assumed.
- **Don't bake dynamic character name, stat numbers, genre labels, budget, roster or story into images.** Only author texture material, fasteners, borders, fixed controls/markings; data is engine-native and testable.
- **No shadow hierarchy drift:** directional light, edge thickness, wear scale, typography baseline, primary focus consistent across scene; demonstrate side-by-side at 390,720,1280,1600.

## 3. Technical architecture
`res://poc/ldtd_recruitment_v4.tscn` is a new isolated scene, not V3 restyling. Use presentation components in `Scripts/ui_v4/` or `poc/`, physical texture assets under `Art/UI/RecruitmentV4/` with source SHA manifests. Pure rules from `Scripts/recruitment_catalogue_v3.gd`; never use `Scripts/ui_theme.gd` or V3's `_button`, `_panel`, `_style`. Build an art-direction **layout map for landscape and phone separately**, with explicit max panel widths, gutters and first-fold regions.

Godot architecture specifics:
- `Control` handles events; `Container` handles dynamic sizing; carefully limit `SIZE_EXPAND_FILL` to intended regions; nested containers can unintentionally expand small items. `NinePatchRect` and `StyleBoxTexture` preserve ornate borders.
- Test via direct Godot 4.7.2 native renders. CI screenshots run with stable engine/system/fonts and include image-diff material comparisons after a **human-accepted** baseline exists; pixel mismatch alone doesn't imply artistic regression. Never update golden baselines automatically after code commits.
- Lint gates reject `Scripts/ui_theme.gd`, `StyleBoxFlat.new`, `UI.button`, `WoldButton`, `TextureProgressBar` as a primary input in new V4 scene. Support source manifest, real texture load, focus and inactive state.

## 4. Source-backed research and workflow improvements
- Godot `StyleBoxTexture`: https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html (nine-patch scaled image without distorting fixed borders; do not copy full screen as texture).
- Godot `GUI skinning`: https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html (inherit/share theme; native style fallbacks need explicit override).
- Godot `Containers`: https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html (layout flags own children; avoid accidental stretch).
- Godot `Theme type variations`: https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html (reuse different physical control families, rather than manually restyling each button).
- Android accessibility https://developer.android.com/guide/topics/ui/accessibility/apps — platform recommends 48dp targets; pixel-to-logical conversion still must be checked in render.
- Playwright visual diff https://playwright.dev/docs/test-snapshots — methodology for stable screenshot baselines & per-viewport diffs; not a request to add a Chromium runtime to the game.
- Apply visual-diff to the actual Godot PNGs with PIL/OpenCV/ImageMagick on CI; add mask/geometry readouts for first-fold buttons, portrait bounds and case/photo surface coverage.

## 5. Release and authorisation matrix
| Gate | Allowed after engineering PASS? | Owner approval required? |
|---|---|---|
| Build isolated V4 visual slice with reusable physical controls | Yes | Owner already approved creative direction |
| Inspect/refine Godot screenshot until quality near approved mockup | Yes | Show result |
| Generate/source/migrate unique character photos with provenance | Yes for genuinely rights-clear/approved inputs | Ask owner if paid/third-party terms materially change |
| Turn V4 into live `band_builder` / old-save migration | NO | YES |
| Resume S03–S07 broad scene roll-out | NO | YES |
| Merge #199 / change main | NO | YES |

**Definition of “promising on return”**: revised binding contract committed; generic-V3-helper reintroduction guard in CI; new image-backed recruitment proof actually runnable, plus native 390+1280 screenshots inspected and defects documented. If hardware/photo source bytes are missing or CI is red, report exact blocker, not an imaginary visual PASS.

## 6. Five adversarial checks on every screenshot
- First-time player: in 5 seconds can see current genre, current candidate, stat trade-off, next action and remaining points.
- Musician: stage experience/temperament relate to gameplay, role coverage and talent price are plausible; 3-person hybrid not double-counted.
- Art director: face/texture > generic boxes; object is integrated, roadcase hardware physical and paper pinned plausibly; ratio against target controlled.
- Accessibility: text, focus and touch safe at physical 390+1280, no vertical letter wrapping, predictable swipe/keyboard.
- Godot/release: paths, licensing, five states, no save edits, selection/price not changed by rendering.
