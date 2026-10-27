# BandMaster Asset Provenance Register

Every new shipping image, icon, texture, portrait or audio file must be entered here before merge.

| Destination path | Asset label | Author/creator | Source URL / generator or brief | Creation/acquisition date | License and attribution requirements | Transformation / crop | Reviewed by | Status |
|---|---|---|---|---|---|---|---|---|
| *No new assets included in the research-prep PR* | — | — | — | — | — | — | — | Research only |

## Intake checklist
1. Check the original source and exact individual-asset license; archives can contain mixed terms.
2. Prefer newly commissioned/original illustrative assets, existing repository assets, and CC0. No real band logos or identifiable unlicensed people.
3. Preserve original credits and required notices when adding ISC/MIT/CC-BY resources.
4. Keep actual title/stat data in native Godot labels; do not bake game text into a picture.
5. Compress images, confirm Godot import and verify crops on 390×844, 720×1280 and 1280×720.
6. Mark images as *placeholder* if a generic venue/background is reused across otherwise unique places.
7. Record version and checksum in a future manifest revision when art files are committed.

## Asset import PR #166 (25 October 2026)

### Icons actually committed
- `Art/UI/Icons/*.svg`: curated Lucide icon subset, source https://github.com/lucide-icons/lucide/tree/main/icons. ISC license with accompanying `Art/UI/Icons/LUCIDE_LICENSE.txt`. Original SVG geometry unchanged; fixed tint to BandMaster ivory (#F2F0E9).
- Intended for icons on stage/venue/touring/gear/relationships/navigation WoldUI controls. Verify viewBox, contrast, and icon size inside Godot before first integration.

### Photographs — VERIFY BINARY IMPORT BEFORE USE
- `Art/Photography/approved/gear-pedals-hjortshoj.jpg` — Henrik Hjortshøj, https://unsplash.com/photos/selective-focus-photo-of-guitar-pedals-lEwyj4FiHHU ; Unsplash License, direct photo page verified as free. Gear close-up; branded pedals may require editorial review.
- `Art/Photography/approved/gear-pedals-austin.jpg` — Austin, https://unsplash.com/photos/several-guitar-effect-pedals-on-a-towel--BCuXpA1tNc ; Unsplash License, direct photo page verified as free. Gear shop alternate.
- `Art/Photography/approved/hq-corkboard-szczepanska.jpg` — Jo Szczepanska, https://unsplash.com/photos/sticky-notes-on-corkboard-5aiRb5f464A ; Unsplash License, direct photo page verified as free. Band HQ pinboard.
- These JPEG destinations are **pending ingestion** until verified by repository byte fetch. The shell importer and GitHub workflow are not themselves evidence that image bytes exist.
- Once downloaded, perform a manual visual and framing review and note any crop/derivative changes here before representing them as production-approved scene art.

## S04 isolated tour artwork — 27 October 2026

| Destination path | Asset label | Author/creator | Source URL / generator or brief | Creation/acquisition date | License and attribution requirements | Transformation / crop | Reviewed by | Status |
|---|---|---|---|---|---|---|---|---|
| `Art/UI/TourCraft/{venue,route,seal,commit}_{idle,hover,pressed,selected,disabled}.svg` (20) | Four five-state physical tour ticket, route, van-load latch and booking-stamp families | Original authored procedural artwork for this game | S04 owner first-pass tour scene brief, SVG markup committed on feature branch | 2026-10-27 | Original commissioned-in-project art; no third-party image embedded | Godot imports SVG as Texture2D; native dynamic captions over art | Simulated five-lens QA pending actual Godot screenshots | Draft first-pass, final owner gate OPEN |
| `Art/UI/TourCraft/{itinerary_sheet,route_map}.svg` (2) | Clipped paper and schematic route sketch | Original authored procedural artwork for this game | S04 brief; not an actual geographical road map | 2026-10-27 | Original art; no third-party image embedded | Imported SVG; paper/metal effect | Simulated art QA pending actual Godot screenshots | Draft first-pass, final owner gate OPEN |
| `Art/Photography/Formation/corkboard_day_pexels.webp` | Source photographed cork (reused) | Eva Bronzini, existing Formation manifest | `Art/Photography/Formation/SOURCE_PHOTO_MANIFEST.json` | Existing source | See existing manifest and Pexels licence | DAY-only shader grade | Existing S02 QA | Reused interim material |
| `Art/Backgrounds/shared/home.webp` | Home-world scene photograph (reused) | Existing S01 photo intake | Existing repo asset, original source review remains in scene-world records | Existing source | Verify original S01 licence before shipping | DAY/DUSK/NIGHT tint; **not** claimed as actual van photograph | S04 actual Godot screenshots pending | Interim first-pass backdrop |
