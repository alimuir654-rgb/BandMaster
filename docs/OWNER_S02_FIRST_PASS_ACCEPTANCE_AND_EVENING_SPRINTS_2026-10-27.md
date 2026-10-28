# Livin' The Dream — 27 October 2026 owner first-pass approval and evening scene programme

## Owner decision — recorded at ~14:09 Europe/London, 27 October
**Formation / rehearsal S02 is ACCEPTED as a first-pass design direction.** It still needs polish. This permits the breadth-first NEXT scene sprints S03–S07 to proceed; it is **not** final art approval, production integration, gameplay release, consent to merge PR #199 into main, or a blanket waiver of mechanics, licensing, accessibility and responsive quality checks.

### Mandatory deferred visual polish: PINNED NOTES, not tape/random cork
- Replace visible arbitrary tape, fake adhesive, random high-contrast cork flecks and scratch-like decoration with **authentic metal drawing pins/pushpins** where a note, audition slip, photograph or ticket is physically attached.
- Pins must anchor actual visible paper edges (credible shadow, glint and short stem contact), not become scattered ornament. Use subtle photographed cork/board substrate behind **intentionally composed pinned items**; reduce patterned distraction.
- Keep headings, controls, live song names, costs, notes, stats and statuses in native Godot labels/buttons. Artwork must not bake mutable game values into a background screenshot.
- Preserve original five input states and purpose-specific button families, selected state on hover, readable ink and minimum 44 *physical* pixel targets.
- Log this as a **P1 polish item** for S07/consolidated pass, not a blocker to S03. Revisit if new scenes inherit the same issue.

## Scope and order — do not rebuild S02 instead of progressing
| Sprint | Deliverable | Required first-pass proof |
|---|---|---|
| S03 — Songwriting | Truly interactive daylight rehearsal/song notebook with choice of title, feel/structure and 3-session progress; image-backed Lab07 transport and original Lab08.4 rotary input; read-only outcome meters | Runnable isolated Godot scene, credible choice -> preview -> once-only result, >=4 device captures, daylight source, five-lens review |
| S04 — Tour planning | Bright physical paper itinerary with clipped route plan, booking and budget constraints, van readiness and days; travel actions with choices, not fake instant progression | Stateful real model preview, distinct itinerary/ticket/selector art, no invented route metrics, DAY native captures |
| S05 — Gig night | DAY load-in -> DUSK soundcheck -> NIGHT performance/cue board -> aftershow. Distinct crew/cue/setlist interaction and realistic decision time. | Runnable phase transitions, physical gig keys/setlist cards, deterministic consequence checks and four-device proof |
| S06 — Studio + career shell | Cohesive metal gear rack, photographic mixer controls and strictly inert game-stat meters, safe navigation from shared shell and authentic working musician flow | Reuse existing verified fader/transport/rotary/meter proofs; real preview without save mutation; tests for input-vs-output |
| S07 — Convergence | One owner-ready scene comparison gallery, mobile/landscape fixes, five-persona adversarial quality sweep, deferred pinned-note material test, typography consistency | Real native Godot screenshots and source manifests, remaining P0/P1 defect ledger, no false sign-off |
| Contingency | Fix highest-severity failing latest CI/render or owner-scene mismatch instead of decorating untested widgets | Concrete regression and exact artifact evidence |

### Important reuse + branch constraints
- Authoritative isolated working branch is `first-pass-scene-sweep-2026-10-27`, PR **#199**; base remains the separate photographic transport proof branch. Do **not** merge to main without explicit owner release instruction.
- Earlier song/tour/gig journey code is on a **different** draft branch (PR #192); inspect paths and integrate only proven files with tested resource existence. Original photographic control source is stacked across #193/#195/#196/#197/#198; only call resource paths verified on current head.
- `Art/References/TargetStates/**` and owner concept ZIP were previously unverified on GitHub: recheck once; reference pictures are art targets, never functional flattened controls.
- 390x844, 720x1280, 1280x720, 1600x900 Godot actual captures. Inspect both 390 + 1280 for first-fold actionable choice, no clipping, and DAY materially brighter than NIGHT. 44 real-pixel interaction target, native focus and distinct off/partial/on where relevant.
- Real local-state previews only; do not directly mutate production save or real economy. Preserve authoritative social/practice/songwriting models; exactly-once action settlement; no double spend.
- Simulated player / musician / material art / accessibility / Godot-release reviews are analysis lenses, not independent human approvals.
- First-pass success and terminal owner approval are separate states; use precise `IMPLEMENTED / CI PASS / ART POLISH OPEN / OWNER FINAL GATE OPEN` reporting.

## Ordered sprint handoff policy through 21:00 London time tonight
On every invocation read latest append-only sprint ledger and five-lens findings, inspect PR head and CI, append required PRE-FLIGHT record **before** implementation, then implement highest-value NEXT unfinished S03–S07 slice, test and append POST-RUN. Work on one draft branch with bounded incremental commits; no parallel writers. If an earlier scene remains red for functionality, repair instead of claiming progress. If it merely has recorded first-pass visual polish, carry it to S07 without blocking breadth.

At 21:00, **stop starting new code**. Issue one honest closeout: current head/CI, delivered scenes, reviewable real screenshot artifact links, defects and next sprint, no automatic merge and no claim that future unseen runs happened.
