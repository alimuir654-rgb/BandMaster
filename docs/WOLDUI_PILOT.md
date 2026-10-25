# WoldUI Integration — UI Shell Pilot

Upstream: https://github.com/Holthouse/woldui-godot
Pinned commit: `26253fc71dac2e0b6b867dcd1620985d13dd9254`
Version: 1.2.0, MIT licensed; see `addons/woldui/LICENSE`.

## Getting started

Clone with submodules: `git clone --recurse-submodules https://github.com/alimuir654-rgb/BandMaster.git`, or run `git submodule update --init --recursive` in an existing clone.

Open `res://Scenes/WoldUIShowcase.tscn` in Godot 4.7.2 and launch it with **Run Current Scene**. This standalone scene is an early interface pilot, not a replacement for career gameplay yet.

The showcase proves a left navigation rail, icon-equipped commands, visual hierarchy, and a landscape workspace using native WoldButton controls. It does **not** yet implement destination navigation or swap the existing career screen. The transition will proceed only after we review actual Godot screenshot evidence and test behavior across display sizes.

## Next adoption steps

- Establish project-specific WoldUI tokens, theme and pinned icon set.
- Migrate shell navigation with real navigation callbacks and save-state continuity.
- Convert Home, Band and Studio to a two-column landscape structure.
- Capture compare screenshots at mobile portrait and desktop landscape.
- Maintain test gates, no changes to save schema or core simulation.

Avoid editing files in `addons/woldui`; add BandMaster tokens and adapters in project-owned folders instead.
