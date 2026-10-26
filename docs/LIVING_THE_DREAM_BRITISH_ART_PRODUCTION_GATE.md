# Living the Dream — British photographic art production gate

**Player-facing game:** **Living the Dream**. **BandMaster** is repository/internal tooling only. Never ship BandMaster as the on-screen title, launcher, title screen, store name or exported game name. No US-roadtrip visual shorthand. The AI-generated infographic from 26 Oct is internal planning only: **NOT APPROVED SHIPPING ART**.

## Art direction and geography
Contemporary British independent-band journey: terraced houses and cramped bedrooms, community rehearsal rooms, sticky pub carpets, narrow UK streets, rainy ring roads, service stations, brick music venues, local promoters and modest first gigs. Lived-in, credible and aspirational; music-first, not fantasy arena spectacle. Documentary photography, natural texture and cinematic grading. British vehicles/road signs, left-hand driving; GBP and UK dates. Avoid generic American highways, deserts, yellow school buses, neon Las Vegas-style nightlife and stadium crowds at tiny shows.

**Production default:** vetted free Unsplash photography (individual photo page, author and commercial/people/property/trademark check) rather than AI-generated hero images. Original UI, overlays, paper textures and text are acceptable; do not invent in-image game text. Reuse the same visual grading, film grain, 3 layers (background image, legibility scrim, interactive foreground) across assets, but *never* reuse one full background across different stages solely by tinting it.

## Actual scene-by-scene asset queue (each requires a real, verified binary before marking DONE)

| Journey | Scene / distinct mood | Photo brief | Game interaction |
|---|---|---|---|
| Formation | Bedroom floor / daylight | second-hand instruments, tea cup, handwritten notice board | recruit and choose identity |
| Songwriting 1 | THE SPARK / warm interior | notebook and acoustic guitar, UK terrace-room intimacy | lyric concept and title |
| Songwriting 2 | FIND THE SOUND / cool studio | close-up amp, pedals, mixer, cables | tempo/vibe |
| Songwriting 3 | IN THE ROOM / amber | real rehearsal-room wide, band silhouettes only if permitted | arrangement and member lead |
| Songwriting 4 | THE SONGSHEET / paper closeup | pencilled setlist/record sleeve surface with no readable borrowed text | review and commit |
| Show 1 | LOAD THE VAN / morning grey | UK panel van boot with flightcases on residential street | gear/crew assignment |
| Show 2 | ON THE ROAD / rain-blue | left-hand UK road, motorway services or van interior | travel trade-off |
| Show 3 | VENUE ARRIVAL / dusk | brick pub/music venue exterior, UK city street | promoter/arrival |
| Show 4 | SOUNDCHECK / tungsten | small venue stage, monitors and lighting rig | set/soundcheck |
| Show 5 | BACKSTAGE / intimate red | cramped dressing-room corridor, instrument cases | last minute decision |
| Showtime | GIG / theatrical contrast | achievable 50–150 capacity pub/club performance | play and real outcome |
| Home | Band house / morning | music-room table, British flat, corkboard | days and next plan |
| Gear | Shop / green workshop | used amps and guitars in independent shop | buy and repair |
| Band life | Rehearsal break / warm human | chairs, mugs, drum kit; recognisable people only cleared | conversation |
| Promoter | Desk / overcast | gig flyers and paperwork, no real recognisable brands | negotiate |
| Scrapbook | Paper archive / nostalgia | pinned ticket and photos with native UI text | revisit milestones |

## First tranche: no more planning-only acceptance
1. Download **actual individual Unsplash Free** photo files to production branch; validate bytes/signature/dimensions, source page, person/brand/property clearance; record photographer, link, license and transformation in Art/ASSET_MANIFEST.md. Not just URLs or a workflow. Re-check three previously proposed JPGs: they have never been verified present.
2. Produce two graded/cropped versions for each approved photo: landscape 16:9 (1920x1080 max) and mobile tall (e.g. 900x1400), with dark text-safe region and controllable UI scrim. Import as Godot-compatible WebP/PNG or JPG. Use dedicated photographs for each stage.
3. Integrate priority first SIX photo scenes: songwriting spark/vibe/rehearsal and van/arrival/soundcheck, then finish remaining show stages and career hubs. Prefer fewer complete polished journeys over dozens of poor fallback panels.
4. Inspect *populated* actual Godot screenshots at 390x844, 720x1280 and 1280x720; compare phone legibility, high-contrast control overlays, geography/car cues, safe areas, cropping, fades, active input and distinctness; store a contact sheet and individual artifact references.
5. Five simulated persona gates: first-time player (understands progression), working British musician (scene authenticity), game critic (real premium differentiation), UX/accessibility (responsive/contrast/focus/reduced-motion), engineer/QA (valid bytes/manifest/offline/load-save/CI). **Critic or UX CHANGES NEEDED blocks release**; report concrete defects and revise, not semantic PASS inflation.

## Four implementation sprints — art-first, acceptance-based
- **P1: photographic procurement and audit** — source/verify/import first six photographs, license and manifest, crop both ratios, create proof-of-import test. If binary download blocked, record exact blocker and work from already verifiable repository photography, rather than replace the photos with AI vectors.
- **P2: songwriting art journey** — wire independent photography into four authored stages, native typography and mood-specific scrims, no duplicated panel backgrounds; capture all viewport states and run persona gate.
- **P3: show-day cinematic journey** — 6 distinct UK location photographs, fade transitions and meaningful actions already implemented, inspect left-hand road/car evidence and exactly-once gig state.
- **P4: whole-world polish/release** — replace fallback art in home/gear/band/promoter/archive, suppress dense controls by progressive disclosure, end-to-end create-band-to-gig-to-save test and owner-ready screenshot pack.
Each sprint is done **only** when actual image bytes are in GitHub, the game renders them, 3-size screenshots are inspected, tests pass and five persona verdicts documented. 60min timebox is not permission to mark unfinished work completed. Divide into smaller fix/test passes when appropriate.

## Constraints / hold points
- Never state that stock-photo availability equals in-game integration. No unsourced or invented Unsplash license releases; check recognisable faces, trademarks and private properties separately. Unsplash license permits typical commercial image use but cannot grant other people's rights.
- No AI-generated hero art without explicit owner approval. The prompt-generated planning collage is **discarded** as an in-game candidate.
- Existing stacked PRs #177, #178, #180, #181 are unmerged. Integrate via #181 head and preserve dependency order; never merge a red head. Track #170 runtime resource warnings separately.
- No more generic visual QA victory statements; evidence is a playable capture showing each context and a reviewer pass/fail matrix.
