# Original Labs received — 27 October 2026 08:57 UK

**Owner delivered original ZIP files in the current project conversation; source bytes were inspected and validated locally.** Do not continue to call them "not provided". **They are not yet committed to GitHub**, so autonomous workflows cannot assume they are accessible there.

## Received archives and SHA-256

| ZIP | Bytes | SHA-256 | Contents / status |
| --- | ---: | --- | --- |
| BandMaster_Hardware_Lab_05_Art_Review.zip | 4,209,812 | `7770ceaa63e59ffa52180d90c143d919d85337c55a9d9c7ffec1112c1ca8f391` | 8 photographic **reference images**, README. Flattened art **only**; NOT standalone fader/knob sprites. |
| BandMaster_Studio_Hardware_Lab_07_Parse_Fix.zip | 19,952,534 | `f477ba9a6e0f080bf90af119fc84fc481fd104219a57debf869f2ce18de26fa2` | 57 PNGs, one runnable `premium_controls_lab.tscn`, GDScript, original source sheet, README and validator. `validate_assets.py` **PASS** for 45 state textures across 3 families/3 palettes/5 states. Godot runtime **not tested** in this intake. |
| BandMaster_Lab08_4_Fix_Only.zip | 692,621 | `a128063cc4ebec6847c8d513dfaf61d2feb913240a9fbb7de9eec93b849b3f52` | 52 PNGs including 27 individual Focus LED ticks + 23 Buzz LED pads; `studio_control.gd`, smoke and image tests, 2 composites. ZIP integrity **PASS**. This is a **PATCH ONLY**; it is missing `focus_ring_off.png`, `buzz_ring_off.png`, baseline scene files, independent fader cap/base images and other Lab 08 base assets. Original validate_lab084.py cannot pass standalone (FileNotFoundError for focus_ring_off.png). |

Source ZIPs passed ZIP CRC checks and 129 source files were extracted under path-safety checks. Independently generated a SHA-256 manifest and standard-library validator: **PASS** for all 129 imported file hashes/PNG headers, Lab07 testbed wiring existence, 27/23 exact LED overlay counts. Import is ready for operator transfer.

## Repo import artifact available in this conversation

`BandMaster_Hardware_Repo_Import.zip` (24.9 MB, **not** a GitHub repository attachment) contains:
- `bandmaster_premium_controls_lab/` root-level runnable **Lab07**;
- `Art/References/PremiumHardware/Lab05/` **reference only**;
- `Art/References/PremiumHardware/Lab08_4_FixOnly/` quarantined **patch only**;
- `Art/References/PremiumHardware/SOURCE_SHA256_MANIFEST.json` checksums;
- `tools/validate_premium_hardware_source.py` full checksum and overlay validation;
- `docs/PREMIUM_HARDWARE_SOURCE_INTAKE.md` safe source-intake instructions.

To make this available to GitHub Actions and autonomous sprints, **the operator needs to extract this ZIP on a dedicated branch and commit the files**, or upload the extracted files using GitHub's UI. Committing the ZIP alone is not enough for Godot `res://` paths. The existing GitHub connector cannot transfer binary bytes from this conversation into repository files. Do not claim that the repo contains these assets until actual remote paths are verified.

## Source/use constraints
- Lab05 controls are baked into flattened reference images. Never animate the whole composite or drag a baked cap leaving a ghost. Need physically correct isolated backing/cap sources for Sprint 01.
- Lab07 has 45 actual state sprites (3 genres × 3 control families × 5 states), and can be mounted as a standalone native TextureButton demo. Baked text remains a production limitation.
- Lab08.4 LED overlays can be reviewed and validated in isolation but cannot run standalone without the **earlier full Lab 08 baseline** (most importantly `focus_ring_off.png`, `buzz_ring_off.png` and two scene files). Request that exact baseline if unavailable; no fake ring art.
- **Owner page structure approval remains; control quality owner approval OPEN.** No main merge. Do not silently restart from page creation.
