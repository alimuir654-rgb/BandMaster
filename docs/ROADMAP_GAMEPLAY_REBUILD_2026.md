> **26 October 2026 visual-production supersession:** The three gameplay batches below remain a historical functional plan; they do **not** define the current visual release gate. The approved next programme is [Living the Dream — visual reinvention](LIVING_THE_DREAM_VISUAL_REINVENTION_2026.md): Sprint A flagship Band House redesign → Sprint B premium songwriting/van-loading vertical slice → Sprint C coherent rollout and owner-ready acceptance. All five simulated persona reviews, actual three-viewport screenshots, rights checks and latest-head Godot CI are mandatory. No incremental button-only sprint may be reported as a visual step change. The stacked PR chain #177→#178→#180→#181→#182 remains unmerged until gates pass.

# BandMaster — three-release Gameplay & UX Rebuild
Approved direction 25 October 2026. Ship three substantive playable batches, with CI and merge after each.

## Principles
- A lived-in band simulator, not repeated card stacks. Distinct workspaces, one dominant action, meaningful decisions and illustrated milestones.
- Reuse existing WoldUI controls, genre artwork, band mechanics, current save system and shared UI helpers. Add new reusable FocusedScene and MilestoneArtifact primitives rather than independent modals.
- Do not pretend unimplemented map, hotel, relationships or distance mechanics exist.

## Batch 1 — v13.3: P0 show-day and payoff
- Repair Take the Stage. Open a dedicated stage-entry scene with venue art, atmospheric lights-down sequence, Confirm Start Show and safe Back.
- On gig day, take player to Gigs and prohibit non-show time-consuming transactions at the simulation entry boundary.
- Song completion/gig/rewards/recording each show unique artifact treatment with real event details, delta stats and one Continue.
- Regression tests: confirmation vs cancellation, performance once, show-day lock, save reload, viewport.

## Batch 2 — v13.4: authored songs + venue journeys
- Song title free-text editing, creative lead, arrangement, note and draft history, A/B takes and explicit one-day commit.
- Duplicate title/identity validation BEFORE spending the day; preserve drafts; migration-safe existing song data.
- Finished song becomes a sleeve/artifact; searchable songbook with original provenance.
- Dedicated venue browser -> venue details -> separate promoter negotiation. Photographic venue cards, cost/travel/requirements/booking. No list-click scroll jumps.
- End-to-end tests for creative choices, repeated titles, venue booking and results.

## Batch 3 — v13.5: authentic systems and distinct scenes
- Tour planner with dated calendar, route and driving/overnight-stay trade-offs. Base costs/van wear/fatigue on explicit simulation data, not fictional distance estimates.
- Equipment loadout per member: owned/borrowed, repair, condition, provenance and personal attachment; separate second-hand music shop.
- Band chemistry: pairwise trust/conflict/closeness; scripted jealousy, excluded writing credit, relationships between adults, apologies, mediation and fallout. Deterministic state transitions, not arbitrary drama.
- Repeatable illustrated interventions and consequences, responsive layouts and player-state screenshot review.

## Engineering/reliability contract
- Shared scene/view router, accessible WoldUI buttons and controls, one prominent CTA per decision scene.
- Common MilestoneArtifact for sleeves, gig tickets, reward certificates, demos.
- Prefer existing assets. Research OSS Godot dialogue manager/map/timeline components, check exact licensing and Godot compatibility before adopting; don't add duplicate styling frameworks.
- Three-view test at 390x844, 720x1280, 1280x720, plus booked/show-day, low cash, duplicate draft, unavailable musician, ready reward scenarios.
- Smoke lifecycle new band -> compose -> rehearse -> negotiate -> book -> show -> outcome -> reward -> save/reload.
- Full CI then automatic merge for each feature batch. Actual hands-on owner review still required for visual sign-off.
