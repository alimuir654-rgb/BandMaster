# Livin’ The Dream — Premium Control Proof → Full Scene Sweep
**Owner quality directive — 27 October 2026.** This programme supersedes premature page-by-page integration and generic vector-control passes. **BandMaster** is repository/development name; the **player-facing game is "Livin’ The Dream"** (retain typographic apostrophe in presentation, ASCII "Livin' The Dream" in identifiers where necessary). Do not silently rename the repository or save namespace.

## Product decision
1. **ONE next family proof now:** Lab 07 photographic **transport/playback key** for a daytime songwriting session. Use real image-backed idle, hover, pressed, latched and disabled textures; separated editable labels and true input logic, no sound simulation falsely advertised. It must inhabit a believable enclosed rehearsal-console module within a bright DAY environment. This is a *proof*, not a production scene rollout.
2. **Gate it** against the actual reference images and adversarial QA; owner reviews real 390×844 / 1280×720 Godot screenshots (and 720×1280 / 1600×900), not only a design render. If a review fails, correct and rerun rather than advance.
3. **Then breadth-first first pass across all key interfaces**, on isolated branches, sharing design tokens/components. Produce target comparisons across band formation/rehearsal/songwriting; tour/on-road; load-in/show/aftershow; studio/common career. Each family gets a clear stateful user journey, no fake all-at-once full polish. *Do not* merge directly to main.
4. **One owner scene-by-scene review sweep**, record defects, and do a deepening second pass by severity and player impact. Reserve final work for visual consistency, accessibility, saves/regression and integration.

## Approved target-state visual references (27 Oct)
Actual PNG owner-approved concept snapshots have been packaged as `LivinTheDream_Approved_TargetViews_Repo_Import.zip`, SHA-256 `f7049134dad06295bc01e17219c9139d9f0cd0029580c6574875484c223d1c42`; this ZIP was created in the owner conversation but is not yet necessarily in the GitHub repository.
- `01_Songwriting_Rotary_Approved.png`, SHA `cac57df8c09be44f34cb761d20e492eead9f8e565ea755fa6b18ee6cf79a8443`: bright DAY, flush dark metal/cream housing, premium brushed rotary encoders and exact LED rings.
- `02_Tour_Planning_Paper_Approved.png`, SHA `2eab9a78bdde66219a99b59edb38d2a120f85cb171c484bfafd627f86d0328a0`: genuinely tactile clipped itinerary, road-map strip, checklists, ticket, pen/tape and documents; DAY **much lighter**.
- `03_Gig_Night_Showboard_Approved.png`, SHA `8dba2da1add21a3fe5835385bd55f949e49f7a9031a7e710a5270742ce2c2540`: gig NIGHT call-board with real paper/setlist/pen/highlighter/tape and practical stage atmosphere.

**These are approved target views, not gameplay screenshots or shippable backgrounds.** All three contain invented sample cities/venues, map distances, amounts, song titles, timings and player-facing branding. Never treat their factual sample data as actual simulation; copy their *material quality and composition*, separate dynamic elements, and populate via game models. For UK band progression do not copy the concept's US/Australian touring details as default.

### Repository source intake
A guarded GitHub Actions workflow `.github/workflows/livin-dream-target-art-intake.yml` imports/validates the three references if the **exact** supplied ZIP is placed at repository root *on this draft feature branch*. Until verified with an actual workflow run and remote Git tree, retain this description as **pending image import**. CI cannot read conversation-only attachments. Preserve SHA manifest and provenance. Do not use low-resolution screenshot crops as production button sprites.

## Material architecture
- One **pale warm app shell / natural daytime world**; real notebook, paper/cork, worn road-case, or dark recessed studio hardware is *within* an integrated physical container. The console backing must blend with the individual plates—avoid disjoint rectangular cards around gorgeous photos.
- DUSK: tungsten warm arrival/soundcheck; NIGHT: dark backstage/stage with selective practical glows. In-game action/state drives phase.
- **Editable** controls: faders/knobs, venue selectors, paper checkboxes/lineup rearrangement and tactile buttons. **Read-only** game state uses meters/gauges/typed values; no fake editing by dragging outcome stats.
- Each surface must communicate why its physical form exists: scrapbook for band milestones, rehearsal notebook for songwriting, road-map/van case for tour, stage clipboard for gig, metal controls for studio/rehearsal. Do not use a universal dark dashboard over every scene.
- Keep captions/lineups/lyrics/cards/shows as native Godot text outside the baked photo layer. Render front-of-photo tick marks or fixed printed labels only when their meaning does not conflict with context.
- One primary action per scene with meaningful consequence and clear next step; no instantaneous empty button funnels; no production save mutations in labs.

## Hard definition of done (every proof AND every scene slice)
| Gate | Required evidence | Failure condition |
|---|---|---|
| Source/rights | Original binary texture SHA manifest, file provenance, no unlicensed asset; material layer is truly image-backed when realism is claimed | Baked screenshot stretched to pretend it is an interactive component |
| Materials | Side-by-side TARGET concept vs REAL Godot 4 view, native-scale visual inspection, coherent frame/trim/lighting | Generic SVG hero, mismatched dark hardware on loose light background, visibly cheap shadows, unconvincing paper |
| Value/state | Normal/hover/focus/pressed/latched/disabled, in-game DAY/DUSK/NIGHT, **zero means no residual illumination**, unbiased led mapping | A lit segment persists at 0; ghost fader rail; selected texture flashes on release |
| Semantics | Read-only stats never take input; player controls alter only an intended parameter; action confirms before cost | Fader edits actual morale/reputation result; read-only meter focusable |
| Native proof | 390×844, 720×1280, 1280×720, 1600×900 **captured by Godot** with off/partial/on where relevant, stored as CI artifact | Static Photoshop/AI mock submitted as actual renderer evidence; capture not reviewed |
| Readability/a11y | Minimum 44 *physical* px targets; high-contrast editable text; keyboard focus & disabled reason; scrolling/no clipped first-fold CTA | Critical label below size; no visible focus; clipping/collisions |
| Game safety | State machine observable; no double payout/duplicate songwriting, preview real costs, no writes to user:// in PoC | Unexplained fake economy or unintended save mutation |
| QA/release | Godot 4.7.2 headless import + deterministic tests + existing career/load/screenshot checks, PR + reproducible artifacts, reviewer defects attached | CI red, warnings hidden, review incorrectly called human/approved |
| Owner | Explicit approval of actual visuals | No merge until owner approval; **quality HOLD** always remains open until owner sign-off |

**Each sprint retrospective must record**: actual commits/assets, screenshot links, exact failing pixels/text where possible, game state changes, five adversarial personas below, fix or blocker, next-family handoff. Scheduled hour is not guaranteed one full hour of work.

## Five structured simulated persona challenge lenses (NOT actual people)
1. **First-time player:** identify the next useful act in 5 seconds; can distinguish editable vs informational surface; no deceptive affordance.
2. **Working musician/venue crew:** plausible real rehearsal, van/gig logistics, meaningful setlist and cue interactions, credible day/night staging; no fictional venue data presented as accurate.
3. **Senior material/UI art director:** same photographic craft as Lab 05/07/08.4 and three approved target sheets; believable surface joinery, texture scale and coherent light direction; reject glossy toy components or flat imitations.
4. **Accessibility/responsive UX:** 44px targets, tap/keyboard, colour-independent status, text/caption contrast, scroll and focus continuity; no illegible handwriting for functional data.
5. **Godot/reliability engineer:** proper input release/latched state, one-time consequences, no duplicate save writes, no 2D scaling distortion or screen-specific hardcoding, actual renderer and regression evidence.

## Next execution sequencing and review authority
- Proof transport control: implement and publish draft PR & screenshots now.
- User approves or rejects proof and standard. Do not treat a green build as quality approval.
- Broad scene first-pass: batch via bounded automation or isolated PRs once quality bar is proven. Produce **one comparison mosaic per scene family** plus individual interactive Godot journey; no fake screenshots.
- Owner sweep after all families at the same maturity. Collect annotated severity P0/P1/P2. Then selectively polish, integrate to real career and test save/load on old saves and mobile.
- Preserve draft stacked #193/#195/#197 art contracts; no unreviewed merges to main.
## 27 Oct OWNER QUALITY RESET — compulsory for EVERY scene from this point
Owner rejected generic `Button` skins, flat panel rooms, dark photo behind DAY, and scenic UI that lacks the approved Tour/Songwriting/Gig paper/hardware richness. This is **P0**, overriding previous breadth-first pace. Scripted geometry or engine green does not waive a P0 visual deficit.

### Component quality contract
1. Every primary and secondary player-action class must have **purpose-made scene-specific source artwork** (e.g. auditions, hand-stamped papers, route tickets, stage call keys). Reuse a component *only when its physical purpose and visual world genuinely match*. No flat `StyleBoxFlat` default buttons, Godot-default look, or universal theme masquerading as premium.
2. A minimum **idle / hover / pressed / selected-latched / disabled** set, with visibly different physical wear/lighting; native focus outline, keyboard/touch and a reason for disabled. Graphics are original PNG/texture assets with source and SHA provenance. Type/data are editable native Godot UI, not painted into bitmap.
3. Craft the entire *workspace*: layered paper/cork, folded tabs, grommets, photo prints, pinned music notes, ink, real shadow/recess joins; the surface should be coherent and purposeful. A photo placed behind flat boxes is a P0 fail.
4. DAY must have **bright believable daylight *inside* the depicted image**, not merely a light interface around a dark photo. DUSK and NIGHT require distinct practical lighting consistent with in-game time. Same photo digitally tinted does not automatically prove true daylight.
5. Layout must show the decision *in the first fold* at 390×844 **and** 1280×720, alongside the scene-specific visual anchor; no giant hero photo pushing all meaningful choices below the viewport.
6. Inspect *actual* Godot screenshots at four viewports; owner target comparison is a human visual judgement separate from geometry checks. Obvious synthetic/scratch noise, inappropriate photo/copy, flat hierarchy or cramped body font = P0/P1, not PASS.
7. Source assets license-cleared; original generated materials must say "authored procedural" and must not be mislabeled photographs. Prefer real image-backed photographic textures when premium image authenticity is required. No invented venues/locations/cash/date baked from mockups.

### Corrective example: S02B formation
Original source state set in `Art/UI/FormationCraft`: 4 distinct stationery control genres × 5 visual states, real Godot text, native focus, original deterministic 22-PNG + SHA manifest, textured workspace. [S02B Godot proof 40509981048](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40509981048) passes 9 native device renders, 4 material families and once-only mechanics. **Visual hold remains OPEN** due unrealistic cork granules, weak typography and dark room photo in DAY. The next step is genuine texture/daylight sourcing and art-direction refinement, not a return to generic S03.
