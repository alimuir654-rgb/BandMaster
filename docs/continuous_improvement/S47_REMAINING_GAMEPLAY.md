# Remaining owner requests after the S47 finance foundation

Status: **Factual show reports and recoverable GUARANTEE pressure are implemented locally in S49 at `179f3366917d0aa629b1e79ede2d1f099a06d72f`. Broader venue-access pressure and actual music/merch sales remain DESIGN ONLY / UNIMPLEMENTED.** Social-to-booking and scouts were verified in S48 at `8d35ccaba0a81cc36c2c9c31ae6aa27e53bdb164`. These changes are local and not included in V5. This design record does not create another queue or schedule extension. The finance/14-day foundation has separate root-run evidence; verified V5/a9 remains the Android rollback.

The first implementation boundary remains one successful original-model result, then the new policy, then one owner save, then presentation. Save failure restores the complete original snapshot, including financial, review, sales, contact and opportunity metadata. No resolver runs inside an animation, render, query or reload.

## What exists and what is missing

- `Scripts/uk_gig_circuit.gd::available` gates venues by original reputation and fans. `play` records a success flag and fee; even a poor show currently pays a reduced fee and adds fans/reputation. No independent critic score or review gate exists.
- `Scripts/gig_calendar.gd::perform` applies original-material/repeat-venue effects, journey and equipment consequences. `promoter_meetings.gd::settle` adjusts the actual settled fee. Preserve these models rather than adding a second performance resolver.
- `recording_career.gd::release` and `release_campaigns.gd::launch` produce fans, press and buzz. They do not produce paid-unit sales, royalties, stock or merch revenue. Existing `press` must not be relabelled a review score or units sold.
- `band_social.gd::attend` already implements dinner, drinks and watching another band, requires two active musicians, charges per active member and advances one day. For the genuine three-person band, costs are **dinner £24 / drinks £18 / watch another band £15**. Those are existing model values, not proposed new rates.
- `career_opportunities.gd` already has pending/once-resolved narrative choices and a support offer. It has no persistent contact/scout network. Current unified UI does not expose every original feature.

## 1. Recorded performance and reviews

**Implemented in S49.** Each newly settled original show records its actual success flag, original settled fee, venue, scheduled/completed days and available original set/terms fields in `live_reviews_v1`. Stable booking-derived IDs, permanent consumed-ID checkpoints and bounded visible history prevent repeated reports. Legacy shows are not backfilled; no critic, stars or new quality score is invented. The report joins the existing saved Ink receipt after the authoritative original settlement chain and before one Finance/save boundary. Save failure restores the complete original state. The original design requirements below are retained for comparison.

Proposed additive review records link to a stable **newly completed show ID**, never the current screen. Retain the original success, venue, completed day, originals played and settled fee as facts. Authored review wording may describe those facts. Do not invent attendance, ticket sales, a critic identity or a numeric rating from fields that the original result never recorded.

A review is committed with the show and its financial entry, not when the player opens the report. Same-show replay, Menu/Continue, resize, skipped notes and repeated receipt inspection cannot create another review or alter its wording. Historical shows without tracking remain explicitly unreviewed; opening an old save does not fabricate past reviews.

A numeric quality/rating system would be a separate explicit policy. It needs an explicitly authored calculation and preserved inputs before it can affect eligibility. It must not silently duplicate or replace the protected original quality calculation.

Acceptance:

1. Genuine successful and poor original shows each create exactly one source-linked review with correct original facts.
2. Same show reopened repeatedly, including after disk reload, keeps the same record and adds no finance/event entries.
3. A failed save restores the original show, cash, review collection and counters together.
4. Legacy unknown review fields survive; no historical failure or success is fabricated.

## 2. Gig access and recovery

**Current S49 policy, active in the local checkpoint:** a newly tracked poor show pauses only the existing **ASK FOR A GUARANTEE** offer. **STANDARD OFFER** and **BRING YOUR CROWD** keep all original lineup, cash, travel and promoter checks. One later actual successful show restores the guarantee; rehearsal alone does not clear the report. Existing confirmed bookings are honoured, and legacy saves without tracked reviews remain neutral. Preview and commit use the same current selected-offer policy. This is a consequence on reachable hometown terms; it does not claim to add regional touring or paid-sales gates.

Keep all existing reputation/fan/lineup/travel checks. Any additional review/sales requirement belongs in one new pure eligibility policy used by both preview and commitment. Show every failing requirement and the concrete recovery route before confirmation. Revalidate at actual booking; a stale enabled button cannot bypass it.

**Proposal for review, not active behaviour:** an upper-tier promoter may require a qualifying successful local show after the latest adverse review. A confirmed existing booking is honoured; a new policy does not retroactively cancel it. The original hometown route remains a recovery route under its existing lineup/cash rules. One poor result must not create an irreversible lockout.

Additional per-tier review windows, success counts and paid-sales thresholds are **not yet configured or implemented**. List them in a reviewable policy table before implementation; there are no hidden fallback values. Preserve original venue eligibility beyond the explicit S49 guarantee rule above. A legacy save without new evidence is not silently treated as a string of poor reviews or zero historical sales.

Acceptance:

- Each authored threshold is tested at one below / exactly at / one above, independently of UI wording.
- Preview and actual commit return the same reason for the same current state.
- An adverse result closes only the intended future options; the stated recovery action reopens them.
- Existing bookings, original-model effects, saved identity and unrelated gate conditions remain intact.
- Terminal bands cannot book or recover by bypassing the finance guard.

## 3. Music and merchandise sales

Add actual products and inventory before cash sales. Music products reference an existing recorded/released recording ID; merch is an explicitly authored product, not an invented release or person. Stock quantities, production cost, unit price, sales channel, demand calculation and any fee must come from an authored **visible policy table**. None is assigned a shadow rate here.

Demand must be deterministic for a saved event or use a persisted seed/result. Re-rendering, opening a page or retrying a completed transaction never rerolls demand. Units sold are whole integers bounded by available stock and actual demand. No release, no stock or no demand means no invented sales. A sold-out product cannot become negative stock.

Each sale has one stable settlement ID, gross units × authored unit price, separately recorded real outgoing charges, exact stock reduction and matching cash. Production costs are charged when production occurs and are not charged again at sale. Preserve cumulative totals after bounded visible history is trimmed. New categories require an explicit additive policy update; never mislabel production as equipment or net profit as gross revenue.

The current finance view correctly says sales are inactive. Remove that statement only when a real sales command exists and passes the contracts; showing a £0 category does not mean the mechanic is active.

Acceptance:

1. Zero/one/exact-stock/over-demand cases cap units correctly and reconcile gross income, outgoing, stock and cash with independent arithmetic.
2. The original gig fee is not sold a second time as ticket revenue; history travel tariffs are not assumed to be actual charges.
3. Replay/reload produces no second stock decrement or payout. Two distinct legitimate events can sell distinct stock normally.
4. Failed save restores inventory, ledger, demand result, transaction ID and cash together.
5. Only genuine committed units count toward an authored gig gate. Press, fans, unsold stock and offers do not masquerade as sales.
6. A rescue sale resets the zero-cash run only under the tested closing-day rule; it cannot resurrect an already closed band.

## 4. Social opportunities, contacts and scouts

**Implemented in S48.** The first tracked successful watch-gig outing creates one durable promoter invitation; acceptance uses the original standard local booking, with three preparation days and no immediate fee income. Decline is free. After an accepted promoter introduction, a later successful outing at the existing Local Following milestone (25 fans and 10 reputation) can introduce a scout and the original `first_feature` interview. Persisted event IDs prevent repeat rewards, including legacy-resolved interviews and missing contact display rows. These are explicit milestones, with no random-on-render chance. Actual paid outings, booking, save/Continue and blocked-save/retry paths passed native checks. The following original design and acceptance requirements are retained as history.

First reuse the actual `watch_gig` outing: the current trio spends £15 and one day through `BandSocial.attend`; other costs remain the original model's active-roster calculation. A new pure opportunity policy may inspect the **successful committed outing** and create a source-linked opportunity. A page visit, cancelled choice, unaffordable outing or failed save creates nothing.

Contacts are business-role records linked to existing venues/opportunities, such as a local promoter. A scout is a narrative business contact, **not a new recruitable musician**. No new cast portraits, six-stat musician cards, roles or roster slots are implied. Preserve the canonical cast IDs and existing passive meters.

Use stable opportunity/contact IDs and persisted availability/resolution. Any chance, eligibility threshold or cooldown needs an explicit reviewed rule; do not use wall-clock/random-on-render generation. An encounter is possible only when that rule permits it, never a guaranteed reward disguised as chance.

Offer inspect/accept/decline through existing native controls. Present the original booking terms, actual costs and eligibility before accepting. Acceptance routes through the authoritative booking resolver; it does not directly grant fee, fans, reputation or a completed show. Decline consumes only the declared opportunity state, with no hidden day/cash penalty. Never consume the opportunity or create the contact twice on duplicate input or reload.

Acceptance:

- Actual trio watch-gig cost/day and active-member scaling are preserved; insufficient cash and fewer than two active players reject unchanged.
- One qualifying saved outing creates one opportunity; browsing/resize/reload do not recreate or reroll it.
- Once-only accept/decline and reopened-save fixtures preserve exact contact/opportunity IDs and original booking constraints.
- Save failure restores the outing/opportunity/contact/booking/finance state as one transaction.
- Existing resolved legacy opportunity IDs remain resolved; new namespaced IDs cannot collide with them.
- A declined offer or adverse review leaves an explicit future recovery path. A scout event never adds a person to the roster.

## Bounded delivery order

1. Verify the finance/14-day foundation and read-only final accounts; retain V5 if proof fails.
2. Review the missing policy tables and the factual review/gate proposal with the owner.
3. **Completed in S49:** factual newly settled show reports and recoverable guarantee-offer eligibility, retaining original settlement models.
4. **Completed in S48:** one genuine social-to-existing-booking opportunity and the later milestone-qualified original feature interview.
5. Next: implement one inventory-backed merchandise channel with a visible authored price/cost/demand table and independent balance/save tests. See `S49_MERCH_NEXT_SLICE.md`; its proposed values are not active game rules.

Within the owner-authorised scope, routine rates are development tuning and need no separate invented permission gate. Every future slice needs its own committed preflight, independent model arithmetic, actual save-failure/replay checks, four native viewports and inspected originals before packaging. This sequence is a proposal, not a running queue or authority beyond the current owner window.
