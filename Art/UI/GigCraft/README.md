# S05 — original showboard hardware art and source-backed photography

The 40 `{gear,sound,approach,cue,hold,go,advance,encore}_{idle,hover,pressed,selected,disabled}.svg` textures and `showboard.svg` are original authored procedural SVG artwork made for this isolated first-pass game scene on 27 October 2026. They are **not photographs**, and their final tactile quality remains under owner review. Source: owner S05 gig-night showboard brief. No third-party image, sample venue name, price or live song caption is baked into these SVGs. Godot renders the real labels and outcomes as native controls.

The existing repository `Art/Backgrounds/shared/gear.webp` (DAY equipment interior), `backstage.webp` (DUSK staging), and `gigs.webp` (NIGHT show) are reused, with original upstream source and rights still subject to repository-wide asset review before shipping. They are repo-backed image files, not new verified externally photographed downloads. Check actual Godot screenshots for true image daylight, contrast and stage composition.

Five texture states per input plus keyboard focus outline; latched selection retains chosen raster on hover. No save writes or real audio. Source gameplay is authoritative `Scripts/gig_calendar.gd` / `uk_gig_circuit.gd`, with the pure preview adapted from earlier PR #191.
