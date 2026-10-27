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

## Scene Worlds Sprint 02 — original tour control surface assets (27 October 2026)

| Destination | Source and provenance | Licence | Status / limitations |
| --- | --- | --- | --- |
| `Art/UI/Tour/road_case_surface.svg` | Original vector drawing authored for BandMaster's Tour Control Lab on 2026-10-27; brushed metal rails, recessed road-case panel, corner rivets, fine hatching. No outside photographs or logos. | Original project artwork, not third-party licensed | **Prototype material study**. Do not claim photoreal equivalence with owner-approved Lab 08.4 photographic knobs; test actual Godot SVG import and screenshot. |
| `Art/UI/Tour/ticket_stock.svg` | Original vector drawing authored for BandMaster on 2026-10-27; cream stock, perforation, paper fibres. No embedded UI text. | Original project artwork, not third-party licensed | **Prototype material study**. All venue/date text is native Godot UI. |

The owner's Lab 05/07/08.4 photographic hardware PNGs remain **outside GitHub** in conversation ZIPs as of this sprint. Do not claim those assets are in this PR or that the tour controls have passed owner art approval. These two original SVGs are *new tour materials*, not replacements for the approved studio hardware.

## Scene Worlds Sprint 04 — original writing desk surface (27 October 2026)
| Destination | Source / creation | Licence | Status |
| --- | --- | --- | --- |
| `Art/UI/Songwriting/writing_desk_surface.svg` | Original vector paper surface drawn for BandMaster on 2026-10-27: ruled cream stock, pencil margin, binder perforations, coffee-ring impression, masking tape. No embedded lyrics or labels, no third-party source. | Original project artwork | **PROTOTYPE** tactile surface only. Not photorealistic hardware and not approved as production art. All mutable text is native Godot. |

The approved Lab 05/07/08.4 photographic control assets remain absent from the GitHub branch as of Sprint 04; this material study does not replace them. Confirm final Godot SVG rendering and owner art approval before production migration.
