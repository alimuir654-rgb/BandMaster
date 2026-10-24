# BandMaster v2.2 — Cross-functional release review (2026-10-24)

## Scope and decision
**Status: IN DEVELOPMENT / NOT RELEASE-READY.** Introduce a calendar-driven gig loop without replacing old saves or changing the existing performance resolver. The release must include clear UI, tests and player testing before being described as finished.

## Business analyst / product-owner proxy
**Player problem:** Gigs currently play immediately when selected. This undermines rehearsals, songwriting, deadlines and band drama. **Requirement:** Book for Day +3; see the date prominently; spend actions preparing; perform only on the scheduled day; cancel for a known cost; miss the day and incur an actual consequence. Old saves without a booking continue to work. Success is measured by player comprehension and meaningful preparation decisions, *not* number of buttons shipped.

**Open acceptance criteria for the full v2.2 vertical slice:** Onboard starting lineup, songwriting, three rehearsal-preparation options, calendar, member story consequences, and a unified first-30-day walkthrough. This PR is the calendar subsystem, **not the full v2.2 release**.

## Engineering reviewer
Architecture: pure Calendar resolver operates on copies of state. UI resolves then commits through existing `_finish`; the previous `Gigs.play` path remains available for legacy tests. Calendar stores `booked_show` in `career_extra` with empty dictionary when cleared because `_apply` copies present keys only. No network dependency.

Critical cases: booking availability, invalid set approach, duplicate booking, insufficient lineup/resources at show time, day-advance crossing show date, cancelled-show reputation and cash, stale/legacy saves, session drummer costs. Scheduling only verifies promoter eligibility; performance deliberately checks the actual lineup, budget and van at show time. This allows meaningful risk but requires player messaging when performance is blocked.

## QA reviewer
Automatic checks: test booking date, action-based preparation, performance gate, completion, cancellation, expiration, idempotent penalties, JSON round-trip, previous-state immutability. Also retain existing 720-turn career simulations, member tests, AI fallback and headless scene smoke tests. **Remaining gap:** the old playtest lab exercises direct gigs, not the booked-calendar UX. It needs a dedicated 30/90/180-day campaign simulation before release.

## Three player personas
**New player:** Needs an obvious countdown, venue location, actions remaining, and an unmissable `PLAY THE BOOKED SHOW` action. Risk: insufficiently visible deadline when browsing other tabs.

**Music-management enthusiast:** Wants strategic preparation, lineup risk and a meaningful cancellation decision. Risk: one concurrent booking constrains long-term planning; consider multi-show queue later after reliability is proven.

**Mobile player:** Needs clear tap targets and portrait-friendly controls; laptop-based Ollama must never be a required dependency. Risk: tab bar and horizontal button groups may crowd narrow screens.

## Gate and recommendations
1. Godot imports, scene loads and all tests pass.
2. UI walkthrough on a real phone and desktop (automated headless cannot verify visual quality).
3. Save/load mid-booking, on performance day, after cancel and after missed show.
4. Expand playtest to 30-, 90-, 180-day simulated careers under contrasting strategies.
5. Balance economy so players cannot gain unlimited cash/reputation from low-risk hometown gigs without rehearsal.

**Highest priority product finding:** treat the calendar + rehearsal + choices + story as one connected vertical slice, not a release merely because a CI job is green.
