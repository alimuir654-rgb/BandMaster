# Typography production gate — Visual Sprint 01 (27 October 2026)

## Scope and status
This sprint introduces a **type-role specimen**, not production fonts. The runnable PoC at `poc/scene_worlds_day_night.tscn` deliberately uses Godot's default font while showing the intended role labels. Do not describe the actual Barlow or Plex typefaces as installed or visually approved.

| Role | Candidate | Initial sizing | Reason |
| --- | --- | --- | --- |
| Editorial scene title | Barlow Condensed SemiBold | 34 px phone / 38–42 px desktop | Music press/poster flavour; compact chapter headings |
| Navigation and decision text | IBM Plex Sans Regular / Medium | 16 px body, 16–18 px CTA | Clear reading at phone sizes; avoid condensed paragraphs |
| Numeric equipment readouts | IBM Plex Mono Medium | 13–15 px | Familiar instrument readout and aligned figures |

## Verified upstream licence sources
- Barlow Condensed: Google Fonts upstream `ofl/barlowcondensed/BarlowCondensed-SemiBold.ttf` (Git blob `9df66576492bee4bd0559066825472808fa98adc`); SIL Open Font License 1.1, copyright 2017 The Barlow Project Authors. Source: https://github.com/google/fonts/tree/main/ofl/barlowcondensed
- IBM Plex Sans: `ofl/ibmplexsans/IBMPlexSans[wdth,wght].ttf` (Git blob `30f837e8b02e8ecddce6cbebc425b1f422392515`); SIL OFL 1.1, IBM copyright and Reserved Font Name Plex. Source: https://github.com/google/fonts/tree/main/ofl/ibmplexsans
- IBM Plex Mono: `ofl/ibmplexmono/IBMPlexMono-Medium.ttf` (Git blob `33c546f68b6007a45a3f10e845523abb2db25399`); SIL OFL 1.1, IBM copyright and Reserved Font Name Plex. Source: https://github.com/google/fonts/tree/main/ofl/ibmplexmono
- All three upstream `OFL.txt` files were read and licence headers verified using the official GitHub sources on 27 October 2026.

## Gate to production
1. Obtain exact font binaries from upstream via approved asset-import route; current GitHub text connector cannot transport TTF bytes, so **not committed** in this sprint.
2. Include each exact `OFL.txt`, provenance, upstream commit and SHA-256 of actual downloaded binaries; register in `Art/ASSET_MANIFEST.md`.
3. Wire `FontFile` or Theme resource in an isolated Godot branch; verify glyphs (British pound sign, punctuation, em dash, ampersand), line-height, truncation and Android export.
4. Compare 390×844, 720×1280, 1280×720, 1600×900 *actual Godot* screenshots in daylight/dusk/night, including focus, disabled and long-label states.
5. Only then propose typography sign-off. Keep fallback readable if any font resource fails.

## Shared colour proof (computed from sRGB WCAG relative luminance)
- Day background #ECE7DA / ink #17252C: **12.72:1**.
- Day background #ECE7DA / muted #4B5860: **5.94:1**.
- Dusk background #283941 / ink #F5EEE3: **10.40:1**.
- Night background #0B1116 / ink #F5EEE3: **16.48:1**.
- Amber primary #E6AE55 / ink #17252C: **7.89:1**.
These are palette-token calculations, **not a claim that all rendered text over photographs meets contrast**. The screenshot QA still needs to inspect those placements.
