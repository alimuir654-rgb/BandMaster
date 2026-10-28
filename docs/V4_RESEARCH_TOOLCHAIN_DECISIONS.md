# Research-led design/build decision record — 27 October 2026
## What the owner rejected and what changes in process
The Godot V3 scene compiled and passed layout tests yet looked like an old, cheap desktop UI. Its screenshot test asserted merely six meters, six role options and a visible large button, **not composition, photographic proportion, material craft, visual similarity or user emotion**. This allowed a complete aesthetic regression. Owner request makes artistic quality a P0 release constraint.
The approved recruitment reference is a dark riveted road-case with bespoke physical keys, a substantial photographed player, six meters beneath that player, a stapled/dog-eared paper character file, a genuine six-person candidate photo rail and a visible talent roster; no generic grey Godot styleboxes.

## Research findings and tool decisions
| Tool/pattern | External evidence | Action for BandMaster |
|---|---|---|
| Godot `StyleBoxTexture`/NinePatchRect | https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html | **Adopt.** Compose reusable tactile panel shells and nine-patch bezels; no whole-screen screenshot-as-UI. |
| Godot Themes and theme variations | https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html and https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html | **Adopt.** Native dynamic labels + coherent photo-based states; this also enables future accessibility overrides without rewriting every control. |
| Godot Containers | https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html | **Constrain.** Containers own the layout of children, causing previous oversized black regions, over-expansion and vertical label wrapping. V4 prototypes use explicit landscape vs portrait composition maps then progressively encapsulate proven regions in responsive containers; never rely on a hierarchy of unbounded expand flags. |
| Penpot | https://help.penpot.dev/user-guide/ and https://help.penpot.dev/user-guide/design-systems/design-tokens/ | **Trial.** Open-source visual components, variants, design tokens and inspect workflow. The owner-approved visual reference should become a component-annotated blueprint there before large UI rollouts. Do not claim a Penpot file is already created or add a paid workflow. |
| Screenshot baseline QA | https://playwright.dev/docs/test-snapshots and https://github.com/KantaiMishima/godot-vrt | **Adopt methodology, not an unverified dependency.** Stable Godot 4.7.2+Xvfb actual screenshots at 390/720/1280/1600, owner-chosen reference, thresholded pixel diff with editable region masks, independent scene semantic tests, tracked human-art acceptance. `godot-vrt` is a research candidate pending license/maintenance and CLI/Godot version check; no plugin installed. |
| Godot semantic/e2e testing | https://gua.orizika.com/godot/ and https://github.com/graydwarf/godot-ui-automation | **Evaluate later.** Could automate focus, keyboard/touch, tab changes and real navigation; don't bring in unreviewed addons until native V4 screenshot convincingly matches the creative bar. |
| UI tap area | https://developer.android.com/guide/topics/ui/accessibility/apps | **Adopt** platform recommendation 48dp and retain project hard floor 44 *physical* pixels in actual Godot screenshot test; no meaningless logical-unit comparisons. |
| Physically plausible art assets | Original photo/texture and 3D compositing workflow; Blender/Krita/Inkscape candidates | **Stage 2 trial.** Replace SVG material proof with actual authored or licensed raster/photographic surface maps: 3D roadcase bevels, ambient occlusion and wear layers baked separately, paper and frame as nine-patch sprites, different artefacts for day vs night. No unlicensed site scrapes. |

## Concrete architecture and ROI
- Separate art-direction approval (actual Godot screenshot) from mechanics engineering approval. The former cannot be satisfied by the latter.
- Source-pack `Art/UI/RecruitmentV4` holds integrated roadcase/paper/material prototypes and two five-state hardware families; source token palette and typography should be exported to machine-readable manifest as it matures.
- `tools/check_v4_visual_contract.py` fails CI for legacy/default V3 helpers. It must reject regressions but **may not reject reusing pure V3 recruitment gameplay model**.
- Reuse the successful photographic Lab07 transport buttons, exact BarlowCondensed/IBM Plex fonts and red-to-green inert attribute meter data.
- Keep `Scripts/ui_theme.gd` and V3 helper files for **existing production callers only**. Do not delete old code to disguise transitive dependencies; mark them deprecated and add a CI check preventing new import sites.
- For character photographs: create a casting Bible (same realistic camera/lighting, wardrobe, UK grassroots style), immutable candidate ID/photograph mapping and provenance table. No unlabeled reuse of Alex's photo for a different person, or a pseudo-portrait stock photo that could imply it is a fictional person's real biography.
- Begin with **one representative singer** and **two real device layouts**. Only after owner approves assembled frame and portrait/dossier legibility do we source the full mixed roster and the genre-specific casting pools.

## Stop/go test (measured by actual build)
1. Same major regions and convincing material dominance as the accepted reference; photo is a major visual anchor, NOT a postage stamp.
2. Distinct rich control states via image sprites, native focus/disabled, no StyleBoxFlat primary inputs.
3. 390x844 and 1280x720 actual screenshots, plus 720x1280 and 1600x900, inspected for crop/letter wrap/visual hierarchy.
4. Confirm portrait provenance before claiming photographic coverage; report placeholders as blockers.
5. Gameplay deterministic & isolated: role, genre, 200-point trial cap, hybrid and roster name-last, no saves.
6. One explicit owner visual gate. PR #199 remains draft and unmerged.

**Status while written:** V4 roadcase/paper/five-state sprite family, scene and tests committed; native Godot render and original-photo asset quality await exact-run confirmation. Prior V3 accepted mechanical tests are not proof of visual acceptance.
