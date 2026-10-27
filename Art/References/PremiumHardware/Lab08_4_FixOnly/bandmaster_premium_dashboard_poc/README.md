# Living the Dream — Premium Hardware Controls & Dashboard PoC (Lab 08.1)

This proof of concept is **isolated from the main game**. No existing game files are replaced, no career data is read, and no saves are changed.

## Installation

Copy the entire `bandmaster_premium_dashboard_poc` folder into the **root** of your existing BandMaster Godot project. It must be located at:

`res://bandmaster_premium_dashboard_poc/`

Open **either** scene and press **F6 (Run Current Scene)**:

- `studio_dashboard.tscn` — first integrated landscape/portrait career dashboard prototype using approved buttons and experimental faders, knobs, and meter.
- `studio_controls_lab.tscn` — larger component inspection bench for interactive image-layer controls.

## Controls

- Drag faders horizontally/vertically.
- Drag rotary controls vertically to change values.
- Use mouse wheel or arrow keys when focused; Home/End jump to limits.
- On touchscreens drag to adjust.
- Toggle **JAM** to test persistent lit button state.
- Press the theme selector to cycle **Studio / Electronic / Punk** accents and artwork.
- Desktop sidebar channels are clickable; phone layout cycles the selected channel using the smaller channel bank.

## Implementation

- Approved Lab 07 transport, pad, channel artwork reused in three colour families; editable navigation labels are separate from the housing texture.
- Lab 05 photographic references reused for **stationary control plates** and **movable cap/rotor textures**.
- Fader tracks were reconstructed where baked-in caps previously left ghosts. The physical cap is a separate texture and moves with the input value.
- The knob face rotates as a separate circular image inside its fixed bezel.
- The meter's fixed baked lights are masked in the display channel; segments are redrawn based on the actual meter value (red at low, amber at medium, green at high).
- All demo metrics are illustrative and not connected to BandMaster game state.

## Quality limits, not yet production approval

- The asset layering was composition-tested, but **Godot runtime was not available in the creation environment**. Run the scenes on your installed version and report errors/screenshots.
- Some tiny etched labels in the original photographic artwork remain baked into the backing plates. They are not game-data values.
- Lab 08.1 limitation (superseded by Lab 08.2): rotary LEDs were static. The updated Lab 08.2 renders 21 independent segments driven by each dial value.
- Genre palette only changes hardware-button image states and dynamic accents, not the metal itself.
- Desktop presentation targets **1280×720**; portrait presentation targets **390×844** with scrolling. Inspect both before adoption.
- This is a PoC, not a full gameplay implementation or release candidate.

Original generated art is included only for this BandMaster prototype. Do not present photo-reference layers as separately licensed third-party OEM artwork.

### Optional automated Godot smoke

From your BandMaster project root:

`godot --headless --path . --script res://bandmaster_premium_dashboard_poc/tests/lab08_smoke.gd`

The smoke test checks resource loading, value clamping and instantiation of both scenes. It does **not** replace visual inspection.

## Lab 08.1: rotary and spacing corrections

- **Venue Buzz:** corrected native image-centre from (194,218) to (220,218); removed the cropped rotor that was rotating part of the LED ring and creating the dark missing wedge.
- **Creative Focus:** same fixed-photo/independent-pointer treatment, eliminating the second baked-in knob pointer.
- New `rotary_pointer.png` is a small independent emissive pointer. No LED rings or black mask move with the dial.
- Both base plates have their original baked-in pointers removed, preserving the rest of their physical metal textures.
- Desktop console controls have separate housings (with a meaningful gap) and labels outside the hardware image bounds. The MORALE label is moved clear of the fader base on phone and desktop.
- The old `focus_rotor.png` and `buzz_rotor.png` are omitted because they included LED-ring fragments and were not safe to rotate.
- Visual evidence: `rotary_fix_comparison.png` contains independent 0/57/100 level views. This is static rendering evidence, **not** a Godot screenshot.
- Typography (font family/weight, header hierarchy and condensed nav) is deliberately postponed until the geometry and rotary fixes pass the owner's Godot review.

## Lab 08.2 — dynamic LED rings and repaired vertical fader

- Each knob has a fixed **off** photograph plus 21 cached, photo-derived transparent LED overlays. Active segments depend on the live 0–100 value, not a baked colour ring.
- The pointer retains its separate rotating layer; only the indicated LED count and pointer change. Venue Buzz displays red → amber → green; Creative Focus uses warm amber illumination.
- `assets/vertical_base.png` has the baked-in old-cap stem and left-side cap ghost repaired. Its travel illumination is drawn dynamically in `studio_control.gd` and moves with the cap.
- `tests/validate_lab082.py` checks all segment images, visual states and ghost suppression; `tests/lab08_smoke.gd` now covers 21 loaded LED layers and range endpoints.
- The source and artwork have **not been run in Godot in this environment**. Run the scene and examine both dials at 0/25/57/82/100, followed by the vertical fader at 0/50/100.
- No changes to career game data, saves, or the approved transport/pad/channel artwork. Typography deferred.

## Lab 08.3 — Final ring illumination cleanup (26 October 2026)

- `focus_ring_off.png` and `buzz_ring_off.png` are rebuilt from their original photographic plates with the old baked-in LED colour and halo removed, including Venue Buzz's inner orange/green spill.
- All 42 `focus_led_00..20.png` and `buzz_led_00..20.png` segments are regenerated as separate RGBA overlays. Faint upper/right Creative Focus ticks receive a restrained emissive treatment so the full 0–100 arc lights correctly.
- The interactive Godot logic in `studio_control.gd` remains unchanged: it still composes the photo-derived overlays in order, based on `level`, and rotates the independent pointer. All button artwork, faders, career demo state and scene layout are unchanged.
- `lab083_knob_states.png` shows reference composites at **0 / 25 / 50 / 75 / 100** for both knobs. This is an **image-layer preview**, not a Godot screenshot.
- Validate source and images with: `python bandmaster_premium_dashboard_poc/tests/validate_lab083.py` from your project root (Pillow, numpy and OpenCV required only for this optional static check). Godot itself needs no Python packages.
- Godot acceptance: open `studio_controls_lab.tscn`, use Home / End and drag both knobs from 0 to 100. Check **0 means no coloured halo**, 50 means roughly half the arc is illuminated, 100 means full ring. Also open `studio_dashboard.tscn`; check knob pointer and LED updates. No new changes to saves.
- If you already have Lab 08.2 installed, extract the **fix-only** ZIP into your BandMaster project root and **replace** existing files. `LAB_VERSION.txt` must read `08.3` to distinguish the update from cached old copies.
- These are static image and integrity-tested assets. A Godot runtime test **was not possible in this creation environment**; the owner should verify on the installed Godot version before approval.


## Lab 08.4 — Precision LED alignment (visual quality correction)

- Creative Focus uses 27 narrow tick overlays aligned to the photographic surround.
- Venue Buzz uses 23 discrete backlit pads. Each pad keeps its photographed housing and neutral unlit appearance.
- Active LEDs are confined to their physical faces with restrained local bloom. No image-wide glow or high-pass mask strokes.
- Off, 50% and fully illuminated states are compared at the actual ~194px game size in `lab084_ring_test_game.png`.
- The Godot runtime script loads a different number of LED textures per control and still maps live values 0–100 to the appropriate number of segments.
- `tests/validate_lab084.py` validates per-layer masks, unique pixels, bounded illumination and visible range changes. `tests/lab08_smoke.gd` has matching 27/23-layer runtime assertions (execute locally in Godot).
- This is isolated to lighting. Existing dashboard, button faces, pointer movement and saves are unchanged.
