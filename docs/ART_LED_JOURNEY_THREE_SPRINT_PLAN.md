# BandMaster — three-hour art-led journey programme
**Owner directive:** 2026-10-26. Start 08:52 UK (UTC); delivery window through 11:52. Three focused sprints. Main goal: replace overloaded same-tone panels with distinctive, cinematic, playable multi-scene journeys. No generic redesign-by-more-cards.

## Non-negotiable shared architecture
- One journey router/state machine integrated with existing saved simulation, not a second career/save model. Explicit scene ids, entry/exit, next/back and re-entry after reload. Navigation-only screens spend no career day and cannot replay mutations. Commit only at explicit action boundaries.
- Native Godot Control compositions; keep WoldUI, SceneSheet and licensed Lucide icons. Palette/lighting/typography/art direction changes per context. Key text stays accessible real UI text, not baked into images.
- Transition service: fade to black/colour, change scene content, fade back; 0.18–0.30s each leg, input guard during transition, fast/skip/reduced-motion option, focus restore, no black-screen lockups. Tests for rapid double activation and safe back.
- Artwork: original or approved licensed, tracked in Art/ASSET_MANIFEST.md; real actual imported files, not URLs or missing-photo claims. Use existing WebP when appropriate; do not block functional flow on absent photographs. Avoid copyright/trademark cues from existing bands. Create artwork variants for distinct atmospheres, foreground/midground overlays where possible.
- Every feature has a tangible player decision, authored reaction, state consequence, save/reload and three viewport captures (390x844, 720x1280, 1280x720). Prefer strong art, small amount of purposeful text, single clear action per scene.
- Protect existing save compatibility, deterministic economy/relationships, offline use and resource lifetimes. Do not merge on red CI, hidden controls or missing sprites.

## Sprint A — 08:52–09:52 — Journey system + songwriting storyboard
**Primary promise:** one real song goes through at least FOUR visually differentiated screens, not one lengthy form.
1. IDEA / spark: choose lyrical concept/theme/title seeds, bedroom or rehearsal notebook visual.
2. SOUND / vibe: choose energy, tempo feel, emotional colour and instrumentation intent, vivid studio wall/soundboard visual. Map choices to existing engine terms rather than invent an incompatible new mechanic.
3. BAND JAM / arrangement: members contribute, pick arrangement and session lead; rehearsal-room palette and portraits, consequential band dynamics if supported.
4. FINAL PASS / song sleeve: review title, concept and direction, commit a real writing session, inspect final song sleeve. Respect existing multi-day song completion; no instant fully finished song unless mechanics support it.
**Engineering:** extract journey shell/transition primitive; navigate back without duplicate day cost; preserve drafts during save/reload; keep current writing controls as safe fallback if unfinished.
**Evidence:** scripted journey, phone/tablet/landscape captures, label accessibility, no duplicate commit, working save reload; update visual manifest.
**Priority if short:** complete two rich art-distinct interactive scenes + extensible 4-step route instead of 4 shallow screens.

## Sprint B — 09:52–10:52 — Show-day cinematic journey
**Primary promise:** show preparation becomes a sequence of places and decisions, not one instantaneous button:
1. LOAD THE VAN: checklist/gear readiness, responsibilities and consequences of equipment condition.
2. ON THE ROAD: van ambience, travel choice, fatigue/van condition, only actual booked gig itinerary facts.
3. VENUE ARRIVAL: forecourt, promoter/crew welcome, event ticket, time/location only from simulated game data.
4. SURVEY / SOUNDCHECK: stage environment, venue mood, setlist and soundcheck tradeoff.
5. BACKSTAGE → SHOWTIME: performance transition, payoff, result memento/scrapbook.
**Engineering:** integrate existing gig booking and Gigs.play settlement; exactly-once costs/wear/payment, no fabricated geography or new action economy; reopen after save at correct step. Variations for low cash/van condition, missing gear and unavailable show.
**Evidence:** end-to-end booked-show journey, three viewports, outcome save/reload, fade and input-lock regression, manual image inspection.

## Sprint C — 10:52–11:52 — Whole-game tone differentiation + release hardening
**Primary promise:** formation, home, band life, studio, gear, promoter, tour and show have visibly distinct world/lighting/typography/hierarchy. Tie scene transitions into navigational shell. Maintain consistent button/accessibility grammar.
**Engineering:** scene-specific theme tokens rather than duplicate frameworks; art-backed first fold, one next-action CTA; reduce oversized generic card stacks. Confirm deterministic flows and legacy saves.
**QA:** full first-career story (new band → jam → song → book → load → road → venue → soundcheck → gig → scrapbook → restart/load); captures at three viewports; fail CI on runtime errors; inspect actual screenshots (do not equate screenshot generation with human review); investigate resource/RID warning #170 if capacity allows. Note old PR #51 remains stale, and Sprint 08 PR #175 requires its own CI review.
**Release:** record actual evidence and remaining defects; no release-ready claim without all checks and visual owner approval.

## Persona review gate for EVERY major PR (simulated critique, not real playtester)
- **New player:** can say where they are, why it matters, what happens next; no unexplained dead end or overwhelming first screen.
- **Working musician:** believable writing/rehearsal/show chronology, authentic backstage details, fair choices, no implausible instant outcomes.
- **Game critic:** meaningful pacing and scene variety, high production impression, no repetitive click-through filler; at least one memorable consequential moment per journey.
- **UI/UX/accessibility specialist:** scene contrast, responsive crops, focused primary action, readable text, 44+px targets, keyboard/controller focus, reduced-motion behaviour, safe back.
- **Godot/release QA engineer:** deterministic state transitions, exactly-once economy, legacy save reload, safe transitions, resource cleanup and green CI.
**Stop/go:** each reviewer records PASS / CHANGES NEEDED with code or screenshot evidence. Any blocker must alter current sprint scope, fix/retest, or defer release with a named issue. Do not overrule failed checks by using positive prose.

## Cadence and budget
Per ~60min sprint: 5 min branch/latest-main/CI intake; 35 min playable vertical slice + art; 10 min automated interaction and three-viewport capture; 7 min adversarial persona review and focused fixes; 3 min PR/retro/next handoff. If finished early, split remainder into 15–20 min fix-and-retest mini-sprints instead of padding. Keep changes substantial but testable. No claim that asynchronous work happens except through explicitly scheduled automation runs.

## Required reporting per sprint
Record PR/head SHA, files/assets actually created, before/after screen inventory, screenshot links, tests passed/failed, 5 persona findings with explicit blockers, outstanding risks, next prioritized corrective action and merge status. If workflow is still running, mark pending, not passed.
