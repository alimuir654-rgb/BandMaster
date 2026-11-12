# Sprint 08 — release readiness and visual quality gate
Started early on 2026-10-26 at owner request. This checklist is **not** a release approval.

## Changes in this PR
- First-fold viewport audit now intersects action rectangles with every scrolling ancestor and rejects ancestor-hidden buttons. Previously clipped scroll content could be mistaken for visible.
- The UI audit frees one scene and advances a frame before constructing the next.
- CI now fails the viewport audit on Godot runtime `ERROR:`, `Invalid call` or `Invalid get index`, not just script and explicit audit failures.

## Mandatory release validation (unverified unless accompanied by evidence)
1. **Automated:** structure, headless, screenshots and all PR checks green on the last pushed SHA. Inspect `v129-viewport.log` for actual first-fold controls.
2. **New career end-to-end:** create a band, rehearse, write and finish a song, book a venue, choose travel, play a gig, view scrapbook, exit/reopen, confirm day/cash/songs/relationships/booking and gig history persist without duplicate charges.
3. **Visual manual QA:** view populated screenshots (not blank startup screens) at 390x844, 720x1280 and 1280x720: band formation, home, writing desk, song sleeve, gear case, band pair conversation, promoter, itinerary, gig result and scrapbook. Check font hierarchy, overflow, focus states, contrast, icon alignment, back navigation and visual consistency against the owner-supplied Football Manager benchmark.
4. **Photography:** the 20 Lucide SVGs and existing studio.webp are present, but `Art/Photography/approved/gear-pedals-hjortshoj.jpg`, `gear-pedals-austin.jpg`, `hq-corkboard-szczepanska.jpg` were not found on main in the Sprint 07 audit. Do **not** claim this gap is resolved until real binaries, source/license manifest, imports and crops have been reviewed.
5. **Leak triage:** isolate `#170` Godot RID/ObjectDB warnings per named test. Do not label as crashes without reproducing. Avoid hard-failing warnings until a clean baseline exists.
6. **Legacy save/identity:** verify missing recorded credits/condition are labelled unknown; separately track permanent member IDs when renamed or replaced.
7. **Owner sign-off:** record accepted screenshots and any visual defects in this file with issue links before marking release ready.

## Status at PR creation
- Source-level UI audit and CI error detection improved.
- Full-path interactive smoke: **not yet evidenced**.
- Visual screenshots individually examined/approved: **not yet evidenced**.
- Unsplash photo ingestion: **outstanding**.
- RID warning root cause: **outstanding**.
- Release candidate: **not approved**.

The next engineering increment should prioritize an automated full-path career fixture and actual review of captured screenshots, not more feature work.
