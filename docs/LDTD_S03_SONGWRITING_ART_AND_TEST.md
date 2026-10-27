# S03 — songwriting first-pass implementation and source ledger

**Scene:** `res://poc/ldtd_songwriting_journey.tscn` (isolated; no production save, career or autoload mutation). From `res://poc/ldtd_career_scene_shell.tscn` choose **SONGWRITING** and **OPEN SONGWRITING JOURNEY**.

## Playable flow
1. See an actual source-photographed daytime rehearsal room and separate native-text paper notebook. Change song title, **Riff / Lyric / Groove**, and **Verse / Chorus / Slow Build / Loose Jam** via source-image Lab07 sampler pads. The chosen pad remains visually latched on hover.
2. Turn the actual **Lab08.4 Creative Focus** illuminated ring by pointer, touch, mouse wheel or arrow keys; it adjusts a **non-economic arrangement sketch BPM only** (not a false improvement to readonly career stats). The original Lab07 photographed transport key is a separate arm/standby preview; no audio or fake playback is claimed.
3. Press the **COMMIT SESSION / 1 DAY** original printed-stationery control; this uses `Scripts/practice_room.gd::compose` on a deep copy via `Scripts/ldtd_songwriting_preview.gd` adapted from PR #192. The first and second sessions progress a draft; the third creates one actual local catalogue original. Pressing again cannot double-spend a day. Invalid title, duplicate title and unavailable musician are rejected by authoritative rules.
4. DAY / DUSK / NIGHT switch photo/material tint without altering game time. The owner accepted formation as **first pass**, not final art; scene is for review only.

## Actual tracked art and rights (not newly invented)
- **Lab07 original photographed hardware**: `bandmaster_premium_controls_lab/assets/pad_studio_{idle,hover,pressed,active,disabled}.png` and `transport_studio_{idle,hover,pressed,active,disabled}.png`; original source and state contact sheet in `bandmaster_premium_controls_lab/README.md` and `Art/References/PremiumHardware/SOURCE_SHA256_MANIFEST.json`.
- **Lab08.4 original precision rotary**: `Art/References/PremiumHardware/Lab08_4_FixOnly/bandmaster_premium_dashboard_poc/studio_control.gd` (original control implementation), `bandmaster_premium_dashboard_poc/assets/focus_ring_off.png`, `focus_led_00..26.png`, `rotary_pointer.png`, and `Art/References/PremiumHardware/Lab08_ASSEMBLY_SHA256.json`. Never fake ticks using a diffuse overlay.
- **Photographed room and cork**: `Art/Photography/Formation/daylight_music_room_pexels.webp`, `corkboard_day_pexels.webp`; photographer/source/license/SHA in `Art/Photography/Formation/SOURCE_PHOTO_MANIFEST.json`. Reused photographed room from formation as a **first-pass writing-room stand-in**, not claimed to depict an actual writing session or the owner target photograph.
- **Printed paper and stamp**: `Art/UI/FormationCraft/rehearsal_notebook.png`, `commit_*.png`, `tab_*.png`; authored procedural (NOT real photographed paper), 22 PNG original source checksums in `Art/UI/FormationCraft/SOURCE_SHA256.json`. Purposeful paper notebook/commit reuse only, not a universal generic theme. **P1:** this paper inherits the older taped edge; replace with authentic pins during S07 material sweep as owner directed.
- **Native fonts**: `Art/Fonts/BarlowCondensed-SemiBold.ttf`, `IBMPlexSans-Variable.ttf`, `IBMPlexMono-Regular.ttf` and their tracked original SIL OFL licence notices.

## Required review and evidence
- `tests/ldtd_s03_songwriting_tests.gd`: authoritative three-day resolver, invalid/duplicate title, local deep-copy, once-only finished guard, photo/material and control presence.
- `tests/capture_ldtd_s03_songwriting.gd`: genuine Godot PNG 390x844, 720x1280, 1280x720, 1600x900 DAY, plus 1280x720 NIGHT finished; 44px touch, no first-fold hidden choices and no scroll/dock collision.
- `.github/workflows/ldtd-songwriting-s03.yml`: actual Godot 4.7.2 import/test/render; source checks and artifact upload. **Do not mark PASS until run completes.**
- Owner's exact target images `Art/References/TargetStates/**` remain absent on this branch, so no pixel-to-target acceptance claim. Full art signoff, production merge and save integration remain open.

## Manual Godot check
Run `godot --path . --scene res://poc/ldtd_songwriting_journey.tscn`; at 390x844 and 1280x720 confirm all three idea pads and three structure pads are visible above the fixed commit dock. Change title and both pad groups; observe selected artwork. Drag/focus rotary, arm/disarm transport, commit exactly three times, inspect finished original and disabled commit. Check night phase and no changes to any existing saved game.
