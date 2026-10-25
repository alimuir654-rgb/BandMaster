# BandMaster — Visual production and reusable components research
Prepared 2026-10-25. **Production prep, not installed software or integrated artwork.**

## Research decisions (license / fit)
| Candidate | Intended use | License / compatibility | Decision |
|---|---|---|---|
| Existing WoldUI submodule | Buttons, hover, focus, interactive menu primitives | Already integrated | **REUSE**. Never add a second button theme framework. |
| Godot 4.7 Control, TextureRect and NinePatchRect | Physical paper sheets, setlists, tour calendar tiles, framed posters, venue dossier layouts | Native engine, no new dependency | **ADOPT**. Build the reusable image-backed UI pieces here first. |
| Kenney UI Pack https://kenney-assets.itch.io/ui-pack | 9-slice borders, sliders, tabs, input indicators | CC0 commercial use; 400+ sprites, SVG/vector sources | **OPTIONAL**. Curate only a few pieces; avoid generic game-looking panels overwhelming bespoke identity. |
| Kenney Input Prompts https://kenney-assets.itch.io/input-prompts | Keyboard/gamepad/touch prompt hints | CC0 commercial use, 1500+ icons | **SHORTLIST** for controller/keyboard accessibility after core screens. |
| Lucide https://github.com/lucide-icons/lucide | Consistent small action icons, e.g. calendar/van/heart/repair/music | ISC (retain copyright/license notice; subset Feather MIT) | **REUSE/SHORTLIST** where WoldUI symbols insufficient. |
| Dialogue Manager https://github.com/nathanhoad/godot_dialogue_manager | Editor-authored character conversations, branching prompts | MIT; **current v4 requires Godot 4.6+**, our project declares 4.7 | **PILOT ONLY** in isolated test scene. Evaluate serialization, save authority and Android before committing a dependency. |
| Game-icons.net https://game-icons.net/about.html | Diegetic instrument / story pictograms | CC-BY 3.0 with author-specific attribution | **DEFER** unless unique needed; credits tracking required. |
| Pixabay https://pixabay.com/service/license-summary/ | Embedded background photographs if suitable | Pixabay Content License with restrictions on standalone resale/redistribution | **REVIEW PER ASSET**; avoid committing photographs until model/property/trademark and provenance checked. |

## Art direction and capture brief
Create a *cohesive* original artwork package rather than random stock photos. Essential scenes and components:

1. **Band house**: lived-in rehearsal space, corkboard with pinned rehearsal card, hand-scrawled paper, tea/coffee stains, beat-up calendar, indirect tungsten light. UI: current day decision + deadline; no baked-in text in images.
2. **Songwriting table**: orthographic desk with notebook paper, pencil, setlist, coffee cup, cables and torn draft edges. Composite a texture background beneath *real selectable* LineEdit / option controls. Do not put important text into illustration, so localization and accessibility work. 16:9 scene + individual transparent objects.
3. **Practice room**: battered amps, rehearsal tape marks, drum kit, pedal board and whiteboard. Interaction: one central rehearsal plan and a room/lineup composition, not multiple repeated buttons.
4. **Promoter's office**: 3–5 distinct fictional adult booker portraits, venue office / booking desk, credible regional gig posters, client-free venue photos. Use consistent grading/lighting and avoid real identifiable people. Prepare 3 portrait moods (neutral, impressed, unimpressed) and a shared cropped fallback.
5. **Tour desk**: stylised fictional UK circuit board and route pins, printed date ledger, road itinerary, van/hotel trade-off cards. **Not a geographically accurate map** until coordinates or vetted routes exist. Tour costs must be sourced from game simulation.
6. **Gig night**: outside venue -> backstage soundcheck -> onstage lighting -> gig ticket/results, with distinct transitions; one prominent CTA per phase.
7. **Gear**: overhead instrument case and tagged listings; item photographs/illustrations for amp, microphones, pedals, drum kit, portable PA; wear/condition badge and provenance slip. Owned gear by member separate from shopping.
8. **Band relationships**: portrait pairs, noticeboard messages, neutral/private conversations and conflicts with explicit intervention choices. No generic romance assumptions. Decisions affect trust/morale and have clear consent/respect framing.
9. **Milestone artifacts**: song sleeve, demo cassette, printed gig ticket, press clipping, chapter certificate. Transparent overlays/text-free imagery; all names and numbers are real engine text.

### Export specifications
- Scene hero: 1920×1080 WebP at sensible compression, optional 1280×720 variant.
- Portrait: 768×1024 WebP, keep important face within central 70%; no written words.
- Desk objects: 512–1024 transparent WebP/PNG.
- UI border and sticker textures: 256–512 PNG, define nine-slice margins explicitly.
- Keep original source/metadata outside shipping texture tree, record author/license/source/creation method/date in `Art/ASSET_MANIFEST.md` for every committed file.
- Target export and preview in 390×844, 720×1280 and 1280×720; ensure contrast and focus rings atop photography.
- Never embed real copyrighted band marks or real identifiable musicians/promoters without permission.

## Architecture to unblock eight hourly sprints
A. Shared **DiegeticSurface** Control class: optional texture, tint/gradient overlay, responsive cropping, reusable edge/paper/metal treatment, theme fallback and focus-safe stacking. Use native TextureRect / NinePatchRect.
B. Shared **DecisionScene** Control class: scene backdrop + title + summary + optional character portrait + <=3 selectable responses + primary/secondary CTA; force idempotent confirm and cancellation. Reuse WoldUI.
C. Shared **MilestoneArtifact**: reusable graphic variant (song sleeve, tape, ticket, clipping, certificate), actual persistent event fields, changes and single Continue.
D. Shared **TourTimeline**: date strip with scheduled gigs/transport/overnight choice, no fabricated distance. Separate pure simulation service for fatigue/cash/van cost.
E. **RelationshipIncidentEngine**: pure scripted incidents with deterministic triggers, state-safe one-time resolution, paired portrait module and intervention options.
F. **EquipmentDossier**: item reference + holder + source story + condition + repaired state; bridge legacy `owned_equipment` string IDs with migration, don't invent existing gear ownership.
Prefer 3 or fewer compositional styles on-screen: interactive focus, secondary actions, history/details. Do not blindly add new `_card()` calls.

## Sprint targets / acceptance
| Sprint | Package | Evidence gate |
|---|---|---|
| 1 | DiegeticSurface + MilestoneArtifact primitives and goldens | Responsive screenshot crops, no contrast regressions, save-independent |
| 2 | TourTimeline + travel/accommodation pure model | Fixed deterministic trade-off tests, save/load |
| 3 | Tour planning integration and show-day routing | Venue booking -> itinerary -> event end-to-end |
| 4 | Member equipment history + condition migration | Legacy saves, repair economics, ownership constraints |
| 5 | Pair-specific conflict/relationship engine | Branch outcomes and no repeat reward exploits |
| 6 | Portrait-driven band interaction and intervention UI | Focus/gamepad, first fold and result mementos |
| 7 | Songwriting desk / setlist visual package and demo artwork | Same title safeguard, write/finish artifact, responsive capture |
| 8 | Stabilization/retro, performance, visual review evidence and release preparation | All suites green, new-game to show to save/reload smoke, residual bugs recorded |
These are suggested priorities; at each run pick the best *unfinished approved* work and don't duplicate changes already merged.

## Do not do
- Do not download arbitrary online photography into the repository just because it is labelled “free”.
- Do not introduce Dialogue Manager or mapping dependency in the middle of urgent save/gameplay repairs.
- Do not use purely visual map pins to misrepresent travel costs/locations or permit expensive actions without state check.
- Do not judge visual completeness from a green screenshots job without inspecting resulting images.
