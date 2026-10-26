# Living the Dream — visual reinvention and premium vertical-slice programme
**Decision:** 26 October 2026. **Status:** Approved production direction; NOT a release sign-off. Internal repository name BandMaster; player-facing name **Living the Dream**.

## Why this replaces incremental polish
The existing populated 1280×720 Band House capture (photo integration artifact, 26 Oct 15:32) shows a grid of bordered brown panels, a wall of equally weighted controls, multiple large amber actions, small body text and almost no meaningful visual focal point. This is a composition and interaction problem, not a corner-radius problem. Do not treat a passing Godot build or another small style change as the step change.

**North star:** a British indie-band management game with Football Manager's meaningful operational depth, Citizen Sleeper's grounded narrative atmosphere, and Persona's confident response to input—without copying any franchise's protected graphics, branding or interface. The player should identify their band, current problem and next action within five seconds. Every important scene should feel authored, not a data-entry form.

## Production constraints
- Preserve existing deterministic gameplay, state migrations, career saves, original-song authorship, booking economy, bandmate ownership, and exactly-once gig settlement.
- British grassroots setting, credible venues, small vans, GBP, local road signage and modest early-career stakes.
- Owner-uploaded photography is present: 30 source originals, 60 WebP derivatives, 14 assigned wide/portrait scene pairs. Files in a folder named `approved` are *runtime candidates*, not license or owner approval. Source-page, people, trademarks, generated-art rights and image provenance remain explicit release gates.
- Do not merge stacked PRs #177 → #178 → #180 → #181 → #182 while required CI is red or art/owner gates remain unresolved.
- Do not install competing UI frameworks. Current WoldUI is the production baseline. Theme Assist is a **time-boxed comparison spike only** after checking actual Godot version, source license and compatibility; reject if unstable or slower to maintain.
- New art direction: British music fanzine editorial typography, restrained gig-poster accents, dark photographic surfaces, tangible paper/ticket artifacts and purposeful data instrumentation. No indiscriminate grunge textures, emoji, noisy bevels or random coloured cards.

## Sprint A — flagship Band House redesign (highest priority)
**Goal:** A radical before/after transformation of the actual populated Band House, not a separate noninteractive mockup.
1. Freeze baseline captures at 390×844, 720×1280 and 1280×720 (plus current 1280×720 Band House screenshot) and write down visible defects.
2. Build two **working** visual treatments on the same actual band state: (A) streamlined existing WoldUI component foundation; (B) optional Theme Assist spike only if version/license check passes. Compare actual game screenshots and keyboard/controller behaviour. Choose one implementation and delete/disconnect the rejected experiment.
3. Define a compact UI kit: one main CTA per viewport, secondary contextual actions, tertiary/back links, destructive confirmation, distinct disabled state, 44px minimum touch target, keyboard focus, hover, pressed and reduced-motion states. No two primary actions in the same visual group.
4. Recompose Band House: cinematic band identity hero with **one clear next move**, compact cash/fans/reputation strip, visible rehearsal/booking context, three intentional destination tiles at most above fold, secondary information revealed by tabs/scroll or progressive disclosure. Avoid nested panels within panels.
5. Make photography visible and relevant, not a dark wallpaper. Contrast scrims should be local to text, with legibility and crop validation at each viewport.
6. Create a shared component specification and implement at least primary/secondary/tertiary/destructive actions, context banner, status pill and destination tile in reusable code. Apply first to title screen and Band House, not all screens at once.
7. Record before/after images, interaction GIF/video if possible, and exact component source paths. Human owner selects/approves the visual direction before global rollout.

**Exit gate:** populated Band House screenshot has an unmistakable hierarchy at all three viewports; main action is visible without scrolling on 390×844; at least 44px targets; legible text; no clipped action; no duplicated or competing CTAs; keyboard focus obvious; persona critic and UX reviewer no longer fail on screen composition; latest-head CI green. Aesthetic acceptance ultimately belongs to owner.

## Sprint B — one premium playable experience
**Goal:** rebuild one full creative-to-show micro-journey with the selected visual language, while retaining simulation rules.
- Four songwriting phases use photo-led layouts with distinct composition, visible choice consequences, progressive reveal and a tangible finished song sleeve. Eliminate repeated full-width choice stacks.
- The van-loading scene becomes a spatial, equipment-aware interaction using existing bandmate ownership and gear condition data. Drag/drop is optional; keyboard and touch-select must work equally well. Never create fake gear or fake penalties.
- Shared transitions use short, intentional fades and feedback; reduced-motion users get instant state changes.
- Narrative reactions should be authored and state-driven. Dialogue Manager can be evaluated separately but is not a prerequisite.
- Finish with a genuine songwriting→gig-day interaction and check save/reload and once-only costs.

**Exit gate:** complete playable path, each decision has clear before/after state, no duplicate charges or time spend, 390×844/720×1280/1280×720 inspected, five persona reviews with screenshot-linked defects and retests.

## Sprint C — coherent rollout, acceptance and owner build
**Goal:** extend proven visual language to Gigs, Gear, Band Life, Scene, scrapbook, venue negotiations and all critical navigation.
- Distinct workspaces with one dominant purpose each; replace noisy repeated tiles and amber button walls.
- Complete image rights/provenance, authentic UK on-road replacement, scene crop and text contrast checks.
- Reuse ticket stubs, setlists, sleeves and real gig details as native UI artifacts. Avoid invented photographic in-image text.
- Full acceptance: new band → formation → songwriting → rehearsal → promoter/booking → load van → on road → arrival → soundcheck → backstage → show → gig outcome → scrapbook → save/reload. Exercise cancellations, low cash, missing member and duplicate-song cases.
- Package a playable owner review build and concise comparison gallery. No release without owner visual approval and passing required CI.

## Specialist review loop — EVERY sprint, not a one-off report
Five independent **simulated** personas (not human participants):
1. **First-time player:** find next action, distinguish navigation from spending time, no ambiguous labels.
2. **Working British musician:** equipment, venues, loading, travel and grassroots culture ring true.
3. **Game critic / creative director:** would a screenshot look premium and recognisable? Does the interaction feel meaningful rather than a form?
4. **UI/UX and accessibility:** hierarchy, 44px targets, readable 16px minimum supporting copy on mobile, contrast, focus, reduced motion, portrait/landscape.
5. **Godot/release QA:** scene loads, import signatures, performance, save migration, determinism, once-only settlement, latest-head CI.

For every persona finding, log `ID | screenshot/state/viewport | severity P0/P1/P2 | observation | code/asset owner | corrective commit | retest evidence | status` in `docs/VISUAL_PERSONA_FINDINGS.md`. P0/P1 must be fixed or explicitly carried forward as release blockers; never silently close a finding because a workflow passed. Re-run all five reviews on actual *new* captures each sprint. Escalate a repeated critic/UX failure into a component/layout rewrite, not another border tweak.

## Automation/engineering quality gates
- Generate populated captures at 390×844, 720×1280, 1280×720 for title, Band House, songwriting, show-day and at least one world destination.
- Screenshot regression tooling may detect crop/clipping changes but is not a substitute for visual judgment. Include accessible keyboard navigation and touch target audit.
- Use GitHub Actions as the source of truth for CI. Each meaningful commit must be followed by latest-head validation. No red-CI merges.
- A successful screenshot job is evidence of generated images, not evidence that a reviewer inspected them.
- Prefer one impressive end-to-end slice over spreading superficial changes across ten screens.
- Deliver a concise sprint report with before/after visual evidence, new commits, tests, persona verdicts, open blockers and next sprint tasks.

## Immediate known defects and backlog
| ID | Severity | Evidence | Defect | Next action |
| --- | --- | --- | --- | --- |
| VIS-001 | P0 | `world-home-landscape.png`, 1280×720, 26 Oct photo screenshot archive | Band House is a dense matrix of brown bordered cards and buttons; visual hierarchy is almost flat | Sprint A recompose actual Band House |
| VIS-002 | P1 | `home-mobile.png`, 390×844 | Repeated action chrome competes with content and photographic atmosphere | Single CTA and progressive disclosure |
| VIS-003 | P1 | `show-journey-0-mobile.png`, 390×844 | Scene is text-heavy; validate photo foreground and control hierarchy | Sprint B spatial van-load composition |
| VIS-004 | P1 | `show-journey-1-landscape.png`, 1280×720 | Road photograph is urban traffic, not credible UK band van travel | Replace with rights-cleared British road image |
| VIS-005 | P0 | Godot workflow run 40357348493 at commit fd0e8585 | WoldUI V94 genre CTA accent test failed after button refinement | Restore exact genre accent and rerun CI; fix committed 5db0f057 |
| VIS-006 | P1 | Asset assignment manifest | Unsplash and generated-image rights review incomplete | Verify every shipped photo source and clearance |
| VIS-007 | P1 | Global navigation / title | Button implementation diverges from shared UI styles | Centralise button behaviour; initial title screen update committed 5a27ab75 |

## Definition of a step change
The before/after images should look like two generations of the product, not the same dashboard with flatter buttons. If they do not, Sprint A is not complete.
