# Living the Dream — Premium Studio Controls Lab 07

**Status:** standalone art-first control validation. NOT production approved; no Godot runtime claim. No gameplay changes or save access.

## Run

1. Copy the `bandmaster_premium_controls_lab/` directory to the root of the existing Godot project.
2. In the Godot FileSystem tree, open `res://bandmaster_premium_controls_lab/premium_controls_lab.tscn`.
3. Press **F6** (Run Current Scene).
4. Try each control in idle, hover and toggled-on mode; the active illumination should remain after releasing the mouse.
5. Cycle Studio, Electronic and Punk and compare texture fidelity. Try disabling controls, keyboard Tab/Space, and **Compact scale**.

## Design choices

- Real image-based control faces, not procedural outlines. Source is original AI-generated artwork specifically for this game, informed by the owner-approved Lab 05 material study.
- Three control types, three genre palettes, five states each. Face sprites are baked at 2× source crop resolution for downsampling.
- Native `TextureButton` provides pointer/touch/keyboard semantics. Latched states use `texture_pressed` explicitly (fix for Lab 02's flash-on-release bug).
- Text baked into these demo textures (`PLAY / EXECUTE`, `JAM`, `GUITAR`) is **not yet suitable for dynamic production labels**. Dynamic labels must be separate overlays and ideally use a blank asset-face variant. No face artwork is being called production-ready.
- `/assets/*_reference.png` are still images from the common art sheet, for visual-only comparison (not interactive faders/knobs).

## Release gates

- Owner visual approval at 390x844 and 1280x720.
- Parse/run in target Godot version (not available in build environment).
- Readability and Tab/Space/Enter interaction for all controls; disabled must block input.
- Full game integration must bind genuine game state and reuse existing save authority.
- Before game rollout: separate text/symbol layers; reduce physical control footprint in interface layouts; validate accessibility contrast and focus.

## Provenance

The textures derive from a generated original audio-console-themed concept asset sheet (`hardware_art_source.png`), included for audit. No copied branded photographs or hardware product renders are used.

## Lab 07 parse fix — 26 October 2026

Fixed two GDScript type inference errors in `premium_controls_lab.gd`:
- line 138: `prefix` explicitly declared `String`.
- line 210: `face_h` explicitly declared `float`, with cast for ratio array value.

Static asset checks passed. Godot executable is not installed in the packaging environment, so actual Godot parse and runtime verification must be performed in the editor.
