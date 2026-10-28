# Art bible and source-layer contract

## Unified visual language

**Physical environment:** portable backstage recruitment roadcase, battered gunmetal with restrained rivets, believable seams, aged contact paper, genuine shadow thickness; focus is the performer, not the cabinet. Use ONE material / light grammar for the whole composition. No large anonymous black planes. An overall dark case in recruitment does not change the separate light daytime rules elsewhere in the game.

**Portrait lens:** coherent British independent venue/rehearsal energy. Preferred first exploratory direction: candid documentary photographic realism, chest-up/waist-up, natural available light, authentic hair/wardrobe, believable hands or instrument if included. An authored editorial illustration alternative is allowed only as a deliberate *whole-scene* pivot, never a mix. Avoid recognisable real people, named living artists or celebrity likenesses.

**Typography:** already committed OFL Barlow Condensed (heads), IBM Plex Sans (body), IBM Plex Mono (technical readouts) where confirmed present; keep their actual licence texts. Do not pack font files in this ZIP. Test at physical export size; 11 pt is a technical floor from prior bug regression, **not** the desired normal body size.

**Physical controls:** reuse original Lab07 transport and Lab08 fader/rotary sources only where exact source paths exist in working branch; verify each origin/lighting state and semantic role. Meter bars are PASSIVE. A fader is an INPUT and never a stat. All states: normal, hover, pressed, selected/latched and disabled, plus focus affordance. Original textures should win over new flat-code approximations.

## Asset authoring contract

Produce **separate source assets**, not crops of a flattened screenshot. Keep:

1. Portrait master per immutable candidate ID, ideally >=2x physical displayed bounds, 1:1 crop positioning metadata and separately stored usable derivatives.
2. Case sides/corners, paper centre, metal tabs and fasteners in reusable nine-patch/nine-slice geometry; test seams on all four target screen sizes.
3. Real source control images per visible state, actual source and unique SHA256.
4. Fonts/licence documents *references*, not new redistributed copies.
5. Native strings/attributes/roster/talent in Godot Labels and data; never hardcoded into PNG layers.

## Asset import/provenance

Register each final-use asset, **including every five-state role-tab image separately**, in `Art/RecruitmentRecovery/ASSET_MANIFEST.json` with a safe **repository-relative** path, SHA256, origin, exact permitted licence/ownership basis, candidate ID for portraits, and visual approval state. Missing asset = `planned`, not a fake fallback. Non-verified licences are not final-use. Record any visible use of generated images explicitly in `origin_kind` and ownership basis; do not imply a generated face is a stock photo with consent.

Original source **does not equal** approved game art. Existing `Art/UI/RecruitmentV4` source includes schematic SVG case and controls; those are reference material until judged against the actual photographed owner concept. Existing `docs/visual-proofs/recruitment_portrait_*_ink_study.svg` remain rejected anti-target examples.

## Implementation guidance (source-backed)

- Godot `Theme` variations and `StyleBoxTexture`/`NinePatchRect` share art across states without stretching rivets or corners.
- `Control` + containers/anchors produce different mobile/landscape layouts; use explicit focus neighbours and first-control focus.
- Godot SVG import is not identical to browser rendering; inspect real pixels. Convert complex material SVG to correctly sampled PNG/WebP if necessary.
- Quality is judged using real in-engine screenshots with geometry, source integrity and human visual review; automated checks can detect broken assets, **not taste**.

## Capture requirements

Images: `390x844`, `720x1280`, `1280x720`, `1600x900` if the active Godot capture can produce them. The two contract sizes (390, 1280) are hard requirements. Save final capture filenames and GitHub artifact URLs in `RECOVERY_STATE.json`, once verified. Never pass a mocked SVG artboard off as a native screenshot.
