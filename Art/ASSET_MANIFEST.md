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
