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
