# BandMaster — Typography Starter / Scene Contrast Contract
26 October 2026 — initial design research, not final approved typography.

## Font candidates and verified licensing
1. **Barlow Condensed**: editorial chapter/title headlines, high impact over photography. Original open licence SIL OFL 1.1 (https://github.com/google/fonts/tree/main/ofl/barlowcondensed). Download exact upstream source, include OFL.txt and credit in repo before embedding.
2. **IBM Plex Sans**: paragraphs, buttons and scene descriptions. Official open-source IBM design font (https://github.com/IBM/plex), OFL in official distribution.
3. **IBM Plex Mono**: 3–5 character technical readouts, timestamps, channel label displays, numerical meters; no oversized blocks of monospaced narrative. Same OFL verified in official IBM Plex distribution.
Fallback: Godot standard project font; do not depend on fonts installed locally on Windows for Android exports.

## Design rhythm
- Day mode: dark charcoal text over ivory paper (#ECE7DA), cool paper-grey secondary surfaces (#D7DCE0), darker ink (#17252C); physical hardware isolated within dark machined-metal housings. Distinctly LIGHT first impression even if gear remains dark.
- Dusk: deep petrol (#283941), warm sky/sunset lighting (#B97A58), ivory text on dark modules. Keep decision content readable.
- Night mode: graphite (#0B1116), raised steel (#182329), ivory foreground (#F5EEE3), lamps/LED as purpose-coded colours.
- This is a starting token shortlist; exact colour contrast measurements and runtime screenshot review required.
- Genre colours alter secondary LEDs, poster art, instrument mood and restrained accents; **do not make day mode dark just because genre is metal/punk**.
- No dynamic backgrounds keyed to wall-clock. Prefer explicit simulation phase derived from scheduled scene and game time.
- Avoid graphic typography embedded in scene illustrations except fictional ambient posters/art; keep actual UI labels editable.
- Test caps/word spacing at 390px width; avoid long all-caps sentences and small condensed body copy.
- Each screen requires: chapter heading, location/stage cue, one narrative sentence, state consequence, one dominant action.
- First sprint: create actual type specimens with day, dusk and night context; verify content overflow and import on Godot 4.7, preserve attribution and asset manifest.
