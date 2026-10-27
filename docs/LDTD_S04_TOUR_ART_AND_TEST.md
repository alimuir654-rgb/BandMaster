# S04 — The Road Book: tour planning first pass

**Isolated scene:** `res://poc/ldtd_tour_planning.tscn`. From `res://poc/ldtd_career_scene_shell.tscn` select **TOUR** and **OPEN TOUR ITINERARY**. This is a standalone, nonpersistent Godot preview; it never reads or writes `user://` saves or modifies the actual career.

## Real player choices and rules
Choose between **Bristol / Cardiff / Birmingham** from `UKGigCircuit`, then **drive home** or **overnight** from `TourItinerary`. Every route shows real in-game travel cost, room tariff, van wear and fatigue. The amp condition (74%) is read from `GearShop.record` in a clearly sample band state; secure the physical load latch before confirming. Unaffordable or unsafe journeys are disabled by authoritative `Tour.validate`.

`Scripts/ldtd_tour_planning_preview.gd` adapts the verified earlier PR #192 `tour_planning_poc_model.gd` preview but **corrects its custom two-day booking**: the final `commit` calls actual `Calendar.book`, which reserves a show **three preparation days** after the sample day 5. The sample starts with £135 and van health 30. A confirmed itinerary creates one real `booked_show` object with chosen `travel_plan`, but does **not** advance the day, deduct travel/room costs, wear the van, perform a gig, or mutate the source dictionary. A second confirm is rejected. In-game tariffs are fictional, not actual distance/hotel quotes. The sample gear provenance is explicitly labelled as sample, not a claim about the owner's inventory.

## Art provenance and honesty
- `Art/UI/TourCraft/`: **original authored procedural vector textures**, not photographs. Four purpose-built families (`venue`, `route`, `seal`, `commit`) each have separate idle, hover, pressed, selected and disabled SVGs, imported into Godot as Texture2D. All labels, prices, destinations and state remain native GDScript. The clipped `itinerary_sheet.svg` is original authored paper/metal, with **no arbitrary tape**; `route_map.svg` is a decorative route sketch, not an accurate road map. See the source README.
- `Art/Photography/Formation/corkboard_day_pexels.webp`: existing real photographed cork with photographer/license/SHA in `Art/Photography/Formation/SOURCE_PHOTO_MANIFEST.json`; daylight shader lifts shadows on actual source pixels.
- `Art/Backgrounds/shared/gear.webp`: existing repo-backed **daylit music-equipment shop WebP image** reused as an interim gear-check/road-preparation photo, **not** a verified photograph of a van or venue. This corrects the first native S04 screenshot's dark, dusk-like home photo. Real daytime van/loading photography remains a **P1 art gap** for later refinement.
- Native tracked OFL fonts: `Art/Fonts/BarlowCondensed-SemiBold.ttf`, `IBMPlexSans-Variable.ttf`, `IBMPlexMono-Regular.ttf`. Owner's exact approved three target-state PNGs are not verified imported.

## Verification gates
- `tests/ldtd_s04_tour_tests.gd`: real route choices, £32 room, cash/van preview, gear condition, 3-day Calendar booking, once-only, no save/performance, unsafe/unaffordable failures, selected hover, native artwork and read-only stats.
- `tests/capture_ldtd_s04_tour.gd`: **actual Godot** 390x844, 720x1280, 1280x720, 1600x900 DAY planning, plus 1280x720 NIGHT confirmed. Asserts first-fold three venues, both routes, van seal and action all >=44 physical px, no photo/choice or scroll/dock collision.
- `.github/workflows/ldtd-tour-s04.yml`: Godot 4.7.2 import, authoritative touring regression, S04 model tests and screenshot artifact upload. A committed workflow is **not** proof of a green run; inspect the run status and genuine PNGs before marking engineering PASS.
- Owner S02 first-pass approval allows S04 breadth, not final art approval. **S07 P1:** formation's tape/random cork must become believable metal pins anchoring paper/photo edges. Avoid introducing decorative tape into S04.

## Manual playtest
Open `poc/ldtd_tour_planning.tscn` in Godot 4.7.2 at 390x844 or 1280x720. Change venue and travel plan; verify costs and fatigue change. The booking stamp starts disabled; click **SECURE THE LOAD** to enable it, then confirm once. Inspect `booked_show.day == 8`, `cash == 135`, `tour_day == 5`, `van_health == 30`, and empty `gig_history`. Click confirm again: no new booking. Switch DAY/DUSK/NIGHT and inspect paper, photograph, native text, keyboard focus, selected-hover and disabled states. Return to the scene gallery; existing career saves must remain untouched.

**Status:** source implementation prepared; final engineering and visual evidence must be recorded after the focused GitHub Actions run, not inferred from this document.
