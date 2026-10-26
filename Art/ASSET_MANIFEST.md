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

## Sprint A original vector artwork (26 October 2026)
All four scenes are original hand-authored SVG illustrations created for BandMaster in this sprint, not third-party stock and not photographs. Copyright BandMaster project owner. No external attribution. Native UI labels overlay the illustrations; no user content is baked into SVG. Godot import and three viewport screenshot inspection must pass before production sign-off.

| Destination path | Scene and illustration | Creator | Date | License | Crop / transform | Review |
|---|---|---|---|---|---|---|
| `Art/Journeys/Songwriting/01-spark.svg` | Warm songwriter's desk, paper, pencil and cup | Original project artwork | 2026-10-26 | Project-owned | Godot cover crop | Pending visual inspection |
| `Art/Journeys/Songwriting/02-vibe.svg` | Cool cyan mixing console and signal wave | Original project artwork | 2026-10-26 | Project-owned | Godot cover crop | Pending visual inspection |
| `Art/Journeys/Songwriting/03-jam.svg` | Magenta rehearsal room, drums, amps, silhouettes | Original project artwork | 2026-10-26 | Project-owned | Godot cover crop | Pending visual inspection |
| `Art/Journeys/Songwriting/04-sleeve.svg` | Amber record sleeve and vinyl | Original project artwork | 2026-10-26 | Project-owned | Godot cover crop | Pending visual inspection |

## Sprint B original show-day illustrations (26 October 2026)
Five hand-authored original vector scenes created specifically for BandMaster. Copyright BandMaster project owner; no third-party assets or external model/brand likeness. These are stylised environmental illustrations, not photographs or owner-approved final artwork. All important venue names, fees, dates and choices remain live Godot controls.

| File | Visual subject | Palette / tone | Provenance | Review status |
|---|---|---|---|---|
| `Art/Journeys/ShowDay/01-load.svg` | Van, flight cases and instruments | Sage/garage tungsten | Original project SVG, 2026-10-26 | Godot import, populated crop and owner review pending |
| `Art/Journeys/ShowDay/02-road.svg` | Night motorway, distant skyline | Blue/moonlight | Original project SVG, 2026-10-26 | Godot import, populated crop and owner review pending |
| `Art/Journeys/ShowDay/03-arrival.svg` | Venue facade, doorway and van | Purple/neon | Original project SVG, 2026-10-26 | Godot import, populated crop and owner review pending |
| `Art/Journeys/ShowDay/04-soundcheck.svg` | Empty stage, amps, microphone and lights | Teal/work lights | Original project SVG, 2026-10-26 | Godot import, populated crop and owner review pending |
| `Art/Journeys/ShowDay/05-backstage.svg` | Velvet curtains and stage silhouettes | Burgundy/backstage | Original project SVG, 2026-10-26 | Godot import, populated crop and owner review pending |

All SVGs are 1200×640, original hand-authored geometry, no embedded copy or game data. Required visual checks: 390×844, 720×1280, 1280×720, including populated controls and scene-to-scene colour contrast. The missing Unsplash photographs remain missing; do not claim these vectors resolve the photography pipeline.

## Sprint C original destination environments (26 October 2026)
These three SVGs are newly authored original BandMaster environmental illustrations, 1600x900, project-owned and royalty-free for this game. No third-party marks, photography or embedded gameplay copy. Rendered as non-interactive background layers behind native controls; they are not a replacement for the missing approved photography or for owner art approval.

| File | Destination / subject | Visual identity | Creator / provenance | Review |
|---|---|---|---|---|
| `Art/Journeys/World/band-room.svg` | BAND / rehearsal room with amp, mic, guitar, window | Blue/rose, warm backstage light | Original SVG authored for project, 2026-10-26 | Three-size import and populated crop gate; owner approval pending |
| `Art/Journeys/World/gear-workshop.svg` | GEAR / worn workbench, guitar, effects case | Sage, tobacco wood, amber task light | Original SVG authored for project, 2026-10-26 | Three-size import and populated crop gate; owner approval pending |
| `Art/Journeys/World/scene-streets.svg` | SCENE / city wall, layered gig posters and street | Midnight blue, violet, neon rose | Original SVG authored for project, 2026-10-26 | Three-size import and populated crop gate; owner approval pending |

HOME uses existing shared studio.webp; STUDIO and GIGS reuse the original Sprint A/B artwork respectively. All six now have separate environmental identities. Source SVGs are editable; these remain illustrative interim assets, not final premium key art.
