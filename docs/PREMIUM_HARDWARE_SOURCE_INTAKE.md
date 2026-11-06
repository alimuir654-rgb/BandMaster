# BandMaster — Premium Hardware Source Intake (27 October 2026)

## One owner-reviewed import
This is a **repository-root drop-in archive**. Extract on a NEW hardware-source branch of `alimuir654-rgb/BandMaster` (not on `main`), commit the extracted contents, and open a draft PR. Nothing in the current game is overwritten by the proposed paths. The laboratory scene is at:

`res://bandmaster_premium_controls_lab/premium_controls_lab.tscn`

Run the static validator from the repository root:

`python tools/validate_premium_hardware_source.py`

The ZIP contains the source images, scripts, original README documents, a SHA-256 manifest, and this import guide. It is not itself a production gameplay integration.

### Contents and important limitations

1. **Lab 05 art review** — eight reference/control images, flattened and not interactive. Stored under `Art/References/PremiumHardware/Lab05/`. The caps/tracks/rings still require genuine separately moveable layers; do NOT crop image screenshots and call them working sprites.
2. **Lab 07 premium control laboratory** — 45 distinct full-colour states (three hardware types × three palettes × five states) and runnable Godot `TextureButton` testbed in `bandmaster_premium_controls_lab/`, plus original source sheet and validation script. Lab07's validator passed in this intake session. Some hardware artwork has baked text and cannot be used as production dynamic labels until separated.
3. **Lab 08.4 precision light fix** — 27 Focus tick overlays + 23 Buzz pad overlays, `studio_control.gd`, smoke/static scripts and sample composite screenshots. Isolated under `Art/References/PremiumHardware/Lab08_4_FixOnly/` because **this ZIP is a patch, not a complete standalone Godot control**. It is missing `focus_ring_off.png` and `buzz_ring_off.png` (neutral base plates), other Lab 08 base assets, and its two referenced `.tscn` scenes. Do not replace the Lab 07 lab's script with this partial Lab 08 patch.

### Critical visual quality gates

- The 27/23 segment sprites are designed to illuminate precise photographic positions. Keep them individually rendered and counted from the actual value; 0 must have **zero** active overlays.
- Lab 05 reference images require independent stationary rails and moving fader caps to avoid ghosted tracks. Do not claim that the reference crop itself is a draggable control.
- Lab 07 is a **complete art/testbed intake**, but no owner sign-off on its application to new scene families is implied.
- At all times, preserve warm LIGHT daylight, transitional dusk, and dark stage-night scene styling; don't assume original dark studio housings should make all daytime screens dark.
- Actual Godot screenshots at 390x844 / 720x1280 / 1280x720 / 1600x900, focus/pressed/off value checks and game/save regression gates remain mandatory for each of the eight family sprints.

### Git command-line import (once, from repo root)

```bash
git checkout -b asset-intake-lab05-lab07-lab084-20261027
unzip BandMaster_Hardware_Repo_Import.zip -d .
python tools/validate_premium_hardware_source.py
git add Art/References/PremiumHardware bandmaster_premium_controls_lab tools/validate_premium_hardware_source.py docs/PREMIUM_HARDWARE_SOURCE_INTAKE.md
git commit -m "Import original premium hardware Lab05, Lab07 and Lab08.4 source references"
git push -u origin asset-intake-lab05-lab07-lab084-20261027
```

If using GitHub's web uploader, upload the EXTRACTED files on a new branch, not merely the ZIP; a ZIP sitting in the repo is not imported as Godot scene resources. Avoid commit on `main` until owner review.

### Provenance
User-supplied archives in this project conversation. Original Lab 07 README states the control source artwork was generated for this game and includes its common source sheet. Lab 05 is explicitly reference-only; Lab 08.4 explicitly fix-only. Individual SHA-256 values and exact original ZIP paths are in `Art/References/PremiumHardware/SOURCE_SHA256_MANIFEST.json`. Do not assert third-party brand ownership or an approval status not expressed by the owner.
