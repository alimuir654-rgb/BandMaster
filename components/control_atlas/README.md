# BandMaster reusable controls / frame kit

Open this folder's project.godot in Godot 4.7.2 and run gallery.tscn. Use Controls / Hardware / Frames and Day / Night. Narrow screens scroll vertically. This is an isolated library proof, not a replacement for production scenes.

Drop-in wrappers live in scenes/: action, toggle, stepper, choices, browse, pagination, meter, panel, ticket. Set look, caption, initial and choices in the Inspector. Connect changed(value); call get_node(...).control for the typed runtime API. The factory in kit.gd exposes button(), toggle(), badge(), frame(), hardware(), PassiveMeter, Stepper, ChoiceStrip and BrowseSelector. APIs accept live data; example values are not new game rules.

Inventory / reuse:
- Action/tab/browse skins: reuse all six U18/U03 Lab07 states; native button adapters now reusable outside recruitment.
- RAG output meters: preserve 22 zero-to-ten state PNGs byte for byte. PassiveMeter exposes set_score() and never accepts focus/input. The original source atlas is not runtime artwork.
- Horizontal/vertical faders and two rotary inputs: original Lab08 studio_control.gd plus exact original base/cap/27+23 light layers. No restyling or code modification to this vendor component.
- Newly assembled reusable behaviour: boolean toggle; bounded integer stepper; exclusive segmented choice; wrap/bounded browser; pagination; selectable native row; passive value/price chip; icon/glyph action buttons.
- Frames: four source-derived panel/inset masters serving six presets (panel, inset, portrait, ticket, header, modal). Tiled quiet centres, fixed corner margins, explicit content-safe padding. Not 12 falsely independent art masters. A modal preset is a visual container, not yet a modal focus-trap/dialog manager.

Scene mapping:
Recruitment/personnel: choice strip, browse, selectable row, passive meter, portrait/panel/modal.
Songwriting: toggle, stepper, segmented choices, browse sections, fader/rotary, inset.
Rehearsal: toggle, linear/rotary input, meters, parameter strips.
Tour/booking: stepper, browse, cost chip, rows, confirmation panel; bespoke route-map/calendar editor remains future work.
Recording: existing transport/button states plus Lab08 faders/rotaries/meters; record logic remains in the game.
Gig/backstage: cue action, selected toggle, page/setlist row, passive output.
Management/admin: rows, price/value chip, pagination and modal panel.
No scene background or character changes. No gameplay expansion.

Native verification: xvfb-run -a godot --rendering-method gl_compatibility --audio-driver Dummy --path . --script res://native_test.gd
Evidence is stored in proof/ by CI. Source rights and SHA256 records are in MANIFEST.json and provenance/. Internal visual acceptance is separate from owner approval, which remains false.

Guidance: https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html (nine-patch/tile behaviour); https://docs.godotengine.org/en/stable/classes/class_button.html (native button states); https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html (keyboard focus). Use native Control sizing and separate input/output semantics.
