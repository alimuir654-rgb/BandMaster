# Drop-in installation

Place the included components/control_atlas folder at res://components/control_atlas in an existing Godot 4.7.2 project. Do not replace that project's project.godot. Run components/control_atlas/gallery.tscn with F6, or instance scenes/*.tscn into your own screen. The standalone testable ZIP is a separate project with its own project.godot. Resource paths are explicitly scoped; move the folder only with Godot resource-path refactoring.

# Drop-in installation

Place the included components/control_atlas folder at res://components/control_atlas in an existing Godot 4.7.2 project. Do not replace that project's project.godot. Run components/control_atlas/gallery.tscn with F6, or instance scenes/*.tscn into your own screen. The standalone testable ZIP is a separate project with its own project.godot. Resource paths are explicitly scoped; move the folder only with Godot resource-path refactoring.

# Drop-in installation

Place the included components/control_atlas folder at res://components/control_atlas in an existing Godot 4.7.2 project. Do not replace that project's project.godot. Run components/control_atlas/gallery.tscn with F6, or instance scenes/*.tscn into your own screen. The standalone testable ZIP is a separate project with its own project.godot. Resource paths are explicitly scoped; move the folder only with Godot resource-path refactoring.

# BandMaster reusable controls / frame kit — C20

## Try the standalone gallery
Open the standalone package's project.godot in Godot 4.7.2 and run gallery.tscn. Use Controls / Hardware / Frames and Day / Night. Narrow screens scroll vertically. This is an isolated component proof, not a replacement for production scenes.

## Use the library
The drop-in package contains components/control_atlas only: add that folder to an existing project without changing project settings. Run its gallery with F6 or instance one of the nine scenes. The factory and wrappers are tested both standalone and inside a separate host project. Paths are scoped under res://components/control_atlas/ in the drop-in version.

Wrappers: action, toggle, stepper, choices, browse, pagination, meter, panel, ticket. Set look/caption/choices/initial in the Inspector; panel also exposes frame_preset. Connect changed(value). The control property exposes the underlying typed API. For hardware use Kit.hardware("horizontal"|"vertical"|"focus"|"buzz", initial). For selectable list rows use Kit.button(caption,look,"browse",true). Example labels and values are not new game rules.

## Inventory and reuse
- Action/tab/browse: 36 original U18/U03 Lab07 images, six states and two looks. Native button adapters and live labels; proportional runtime downsampling before nine-slice, original bytes retained.
- Passive RAG meters: 22 original zero-to-ten runtime images unchanged. PassiveMeter.set_score() updates model-driven values; no focus or pointer input. The pre-existing source atlas is not a runtime requirement.
- Horizontal and vertical faders, Focus and Buzz rotaries: Lab08 source bases, caps and 27/23 LED layers; existing input/lighting logic retained. The drop-in export changes resource prefixes only and records both original and module code hashes.
- Newly reusable behaviours: boolean toggle, bounded integer stepper, exclusive segmented choice, wrap/bounded browser, pagination, selectable row adapter, passive value/price chip, glyph/icon action buttons.
- Frames: four source-derived panel/inset masters serving six presets: panel, inset, portrait, ticket, header and modal. Quiet centres, complete fixed corner details, explicit content-safe padding; portrait preset is a vertical mount. These are not twelve independent artworks. Modal is a visual panel, not a complete modal focus-trap/dialog manager.

## Scene-by-scene component allocation
| Scene | Reusable controls | Frame presets |
| --- | --- | --- |
| Recruitment / personnel | Action, role choices, browse, selectable rows, passive meters, value chips | Portrait, panel, ticket, modal |
| Songwriting | Toggle, bounded stepper, segmented choices, section browse, fader/rotary | Panel, inset, header |
| Rehearsal | Linear/rotary inputs, toggles, passive meters | Panel, inset, header |
| Tour planning / booking | Stepper, browse, cost chip, rows, confirmation actions | Panel, ticket, modal |
| Recording | Existing action/transport states, Lab08 faders and rotaries, passive outputs | Panel, inset, header |
| Gig / backstage | Cue action, selected toggle, setlist rows, page selection, passive output | Panel, header, ticket |
| Management / admin | Selectable rows, value/price chip, pagination, confirm/cancel | Panel, inset, modal |

## Explicit remaining scope
A dedicated passive ring-meter family, richer purpose-drawn pictograms, a full modal focus-trap/controller, route-map/calendar editing and scene-specific gameplay bindings are not claimed complete. Existing controls can be used without those optional families. No scene background, character, recruitment logic or production-save changes are included.

## Verification and provenance
Native test: xvfb-run -a godot --rendering-method gl_compatibility --audio-driver Dummy --path . --script res://native_test.gd (standalone). The drop-in uses the corresponding res://components/control_atlas/native_test.gd path.
Tests include actual pointer/keyboard activation, disabled input, bounds and once-only signals, exclusive choices, passive semantics, wrappers, four viewport sizes and live resize. Hardware source reuse is verified separately from the new behavioural APIs; this is not a full gameplay playthrough.
Hashes, source dimensions, safe insets and inherited source/rights basis are in MANIFEST.json and provenance/. Lab07/Lab08 surfaces are owner-supplied image-generated photographic-style artwork, not claimed real photography. Artistic review remains separate from green tests; owner_approved stays false.

Guidance: https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html ; https://docs.godotengine.org/en/stable/classes/class_button.html ; https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html . Use native sizing, complete corner slices and separate input/output semantics.


## C21 frame styling and hardening
Six distinct source-derived frame profiles in each look (twelve PNGs). Frames are decorative, non-focusable containers; live children remain native. FRAME_STYLES_C21.json defines margins, safe insets, provenance and hashes. Invalid frame look/preset values fall back to flightcase/panel; styles are per-instance.
Kit.dialog(title,message,look) creates a reusable overlay: add it to a full-rect screen, connect completed(bool), then open_modal(). Escape cancels, Tab/Shift-Tab remain inside, and previous focus is restored. Call queue_free() on completed for one-shot dialogs. No gameplay/save state is changed.
Existing native_test.gd remains the original C20 suite; frame_test.gd adds source/style, reflow and modal input/focus checks. Art remains subject to owner review.


## C21 frame styling and hardening
Six distinct source-derived frame profiles in each look (twelve PNGs). Frames are decorative, non-focusable containers; live children remain native. FRAME_STYLES_C21.json defines margins, safe insets, provenance and hashes. Invalid frame look/preset values fall back to flightcase/panel; styles are per-instance.
Kit.dialog(title,message,look) creates a reusable overlay: add it to a full-rect screen, connect completed(bool), then open_modal(). Escape cancels, Tab/Shift-Tab remain inside, and previous focus is restored. Call queue_free() on completed for one-shot dialogs. No gameplay/save state is changed.
Existing native_test.gd remains the original C20 suite; frame_test.gd adds source/style, reflow and modal input/focus checks. Art remains subject to owner review.
