# BandMaster — Ten-image Unsplash shortlist and icon queue
Prepared 2026-10-25. **Curated discovery cache, not imported production art.** Source pages explicitly indicated free Unsplash licensing at research time; recheck each page and any recognizable brands/people before shipment. These are real photographs, not assertions that a particular venue in the simulation looks like the photo.

## Ten direct image candidates
| Priority | Scene / slot | Direct photo | Photographer | Suggested treatment | Intake state |
|---|---|---|---|---|---|
| 1 | Studio working sheet | [Notebook, pencil, pen](https://unsplash.com/photos/a-desk-with-a-notebook-pen-and-pencil-on-it-Aiu_QeLt23s) | Kawê Rodrigues | Desk crop, UI editable text remains separate | REFERENCE — review crop |
| 2 | Home noticeboard | [Sticky notes on corkboard](https://unsplash.com/photos/sticky-notes-on-corkboard-5aiRb5f464A) | Jo Szczepanska | Pinned upcoming events and notes; existing text may be distracting | REFERENCE — review text legibility |
| 3 | Gigs / stage entry | [Empty small stage and microphone stands](https://unsplash.com/photos/a-dim-shot-of-two-chairs-and-microphone-stands-on-an-empty-stage-wN1CH6Ferbg) | Hannu-Pekka Peuranen | Dramatic low light hero for pre-show overlay | SHORTLIST — review crop |
| 4 | Gigs / nighttime alternate | [Blue-lit live stage](https://unsplash.com/photos/empty-concert-stage-with-blue-lighting-6ygYVj9d4jU) | ANABEAST | Secondary stage, NOT a specific real game's venue | SHORTLIST — review branding |
| 5 | Gear / pedal case | [Pedals on a towel](https://unsplash.com/photos/several-guitar-effect-pedals-on-a-towel--BCuXpA1tNc) | Austin | Organic analog film-style closeup, shop illustration | SHORTLIST — review trademarks |
| 6 | Gear / detailed effects | [Selective focus guitar pedals](https://unsplash.com/photos/selective-focus-photo-of-guitar-pedals-lEwyj4FiHHU) | Henrik Hjortshøj | Small inspection detail, useful for provenance story | SHORTLIST — review trademarks |
| 7 | Gear / guitar and amp | [Guitar and amp near window](https://unsplash.com/photos/a-guitar-and-amp-sitting-in-front-of-a-window-uTq7iBCnZ-8) | Clayton Malquist | Member equipment dossier contextual photo | REFERENCE — visible brands |
| 8 | Gear / amp alternate | [Moody amp closeup](https://unsplash.com/photos/a-close-up-of-a-guitar-amp-in-a-room-lsD_hO6AwP8) | J. Weisner | Worn amp item card, not implied own inventory | REFERENCE — visible brands |
| 9 | Tour / journey | [Van roadside at sunrise](https://unsplash.com/photos/a-van-parked-on-the-side-of-a-road-p-oZTcaCb0s) | Taneli Kantanen | Road-trip imagery only, don't imply route geography | REFERENCE — vehicle brand |
| 10 | Song milestone / recording | [Analog cassette closeup](https://unsplash.com/photos/a-close-up-of-an-old-fashioned-audio-cassette-EUBK8V243IU) | Immo Wegmann | Demo artifact visual with real dynamic Godot title layered on top | SHORTLIST — review crop |

## Scene slot mapping and fallback
- HOME: pinboard hero [#2]; secondary member portrait/notes from existing game assets.
- STUDIO: desk #1; song-milestone cassette #10; use original drawn paper labels as overlays.
- REHEARSAL: no suitable direct verified grassroots band-room photograph in this shortlist. **Use existing project studio/rehearsal art** pending research; don't force orchestral or generic office images.
- GIGS: stage #3 (primary), #4 (alternate), existing genre-specific venue art fallback. Never invent photographer/venue attribution.
- TOURING: journey #9 as backdrop/reference only; geographic route itself must be simulation-backed.
- GEAR: #5/#6 for effects and #7/#8 for amp/guitar; product photos are illustrative, not evidence that the band's item is that exact model.
- BAND: pinned-notes #2 for backstage story wall; keep the actual band's fictional character portraits from existing generator.

## Proposed repository folders
```
Art/
  ReferenceCatalog/   # metadata/shortlists only: no unreviewed downloads
  Backgrounds/shared/ # already exists — current safe fallback
  Photography/
    approved/          # only fully cleared, optimized licensed originals
    thumbnails/        # independently export approved crop only
  UI/Icons/             # curated SVG icons (not full 1,500-icon archives)
  UI/Textures/          # small paper, tape, ticket and metal textures
  ASSET_MANIFEST.md
```
Do not bulk copy 10 images or import from source CDN automatically. A source-page URL is **not** a cleared production binary.

## Icon policy — ready for adoption
Primary: **Lucide** SVG subset. ISC license, retain complete copyright and permission notice in `Art/UI/Icons/LUCIDE_LICENSE.txt` when actually vendoring. Prefer the already-supported `WoldButton.icon_start` names and existing `Art/Icons` resources; do not create a conflicting second icon API.

Choose only these functional concepts at first:
- Home: house; Gig: ticket; Venues: map-pin; Tour: route, calendar-days, car-front; Overnight: bed-double; Finances: wallet; Repairs: wrench.
- Studio: music-2, notebook-pen, audio-lines; Rehearsal: headphones, guitar; Band: users, message-circle, heart-handshake, alert-triangle.
- Milestone: award; Recording: disc-3; Navigation: arrow-left, arrow-right, chevron-right; Gear: sliders-horizontal, package, inspect/search.
- Confirm: check; Cancel: x; More: ellipsis; Warning: circle-alert.

Use a single nominal 24×24 grid, 2-unit stroke, current-color tint or a consistent SVG substitution process. Primary action may have leading icon + explicit label; status-only icons always include adjacent status text. Min hit area 44×44 logical px, target 48–56 for gamepad/touch. Icons never substitute for labels in consequential decisions.

Secondary/queued only: [Kenney Input Prompts](https://kenney-assets.itch.io/input-prompts) CC0 for future controller/key/touch hints, not regular action icons. Optional [Kenney UI Pack](https://kenney-assets.itch.io/ui-pack) CC0 for selective chrome; do not introduce a second theme. Both packs require manual asset retrieval/selection before integration.

## Intake and UI evaluation gate
1. Verify individual Unsplash photo page still shows **Free to use under Unsplash License**, not Unsplash+.
2. Record photographer, source page, rights status, intended scene and crop in `Art/ASSET_MANIFEST.md`.
3. Crop hero 16:9; reframe at 390×844, 720×1280 and 1280×720; ensure primary CTA, text, face/object aren't obscured.
4. Export Godot-compatible WebP at 1600–1920px hero; check compressed payload and actual import.
5. Avoid revealing any real named musician/booker/person as a fictional game character. Remove/avoid real music product trademarks where necessary.
6. Keep no-contact, no-stock-download fallback using existing repository art until curated binary is committed and inspected.
7. Capture representative gameplay states, not only fresh-save screenshot.

## Next runnable sprint action
Select first 2 images (#3 and #1) for crop/import experiments **after review**, then populate manifest, run viewport screenshot tests and compare old/new. Bring 3–5 approved icons into a reusable button demo with focus/gamepad tests before bulk importing any pack.
