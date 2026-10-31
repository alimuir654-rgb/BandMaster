# Next bounded step: one real merchandise sale

Design only, prepared against `179f3366917d0aa629b1e79ede2d1f099a06d72f`. This starts no implementation, build, schedule or competing queue. Current-hour source and validation remain with root.

The useful next increment is **one stocked merchandise product sold once at a newly completed show**, with its real production cost, remaining stock and gross income visible in Finance. This can earn money without pretending that the existing recording/release system already sells units.

## Current source facts

- `Scripts/recording_career.gd`: `can_record(state)` requires at least **two actual `song_catalogue` entries**, £60 and another original since the latest recording. `record(state)` spends **£60/two days**, uses the latest three compositions and appends `recordings[]` with ID `demo:<starting_day>:<source_song_count>`, tracks, quality, source count and `released=false`.
- `release(state,index)` spends **£25/one day**, marks that recording released and adds quality/buzz-derived fans, press and buzz. It pays **no sales income**. `release_campaigns.gd::launch` likewise spends money for audience effects: radio £20/day; release party £35/day; regional press £50/two days and 12 press. Each campaign is once per released recording. A campaign named “release party” is not a settled Calendar show and must not generate a merchandise stand.
- Actual compositions have `song_catalogue[].id = original:<number>` (`career_actions.gd::_write_original`); `song_workshop.gd::finish` preserves it. `Songbook.entries` returns display rows **without IDs**. Do not use a displayed title, row number or array index as product identity. Recording track snapshots contain titles/quality, not source-song IDs.
- Finance already accepts explicit **gross** income/outgoing rows and has `Music sales` / `Merch sales` categories. There is no existing stock, unit-price, demand, order or paid-music resolver. Old tutorial prose mentioning homemade merch supplies none of those values.
- S49 now provides stable future-show IDs: `live_reviews_v1.records[].id`, formatted `s49:show:<venue_id>:<scheduled_day>`. Reuse that identity; bounded `gig_history` length or the current screen is not a settlement ID.

## Proposed first slice — rates are design proposals, not current game facts

One product: a plain band badge, using the saved band identity and existing native presentation. No new musician, image or font is needed.

| Visible policy | Proposed value |
|---|---|
| Production order | 10 badges, £10 total, one completed day |
| Sale price | £3 per badge |
| Stock | Actual produced units less actual sold units; initially zero |
| Channel | One stand at a newly tracked completed show |
| Interest | `floor(saved fans after the original show / 10)`; an explicitly labelled estimate, not measured attendance |
| Units | Whole units, capped by that saved interest and eligible remaining stock |
| Stand fee | £0 in this first slice; displayed explicitly |
| Selling time | No additional day after the already completed show |

These numbers need a visible versioned policy table and independent balance checks before implementation. They are not inferred from original models. Zero interest or zero eligible stock means zero units and zero income; there is no guaranteed first-sale reward.

Order confirmation shows quantity, full cost, one-day commitment and cash afterward. Add an explicit outgoing category such as **Merch production**; do not disguise stock production as equipment or subtract it again when units sell. Keep stock by stable batch/order ID so newly produced units cannot be sold retroactively to an old audience.

## Settlement and save boundary

1. Ordering creates paid stock only after finance reconciliation and the existing single owner-save transaction succeed.
2. On a **new** original show settlement, save a stand opportunity referencing its existing S49 show ID, policy version, eligible batch quantities and frozen interest. This creates no sales cash. Never backfill stands, reviews or income for historical shows.
   Proposed availability: the stand can settle only on that completed show day, before another action advances time. Browsing/reload do not close it; later-day attempts cannot backdate a sale. Display this limit before committing production or a sale.
3. An explicit after-show sale confirms the saved interest, sale price, units and resulting stock/cash. Use a stable ID such as `merch:stand:<show_id>:<product_id>` and persist its consumed state beyond trimmed visible history. Reopen, resize, reload and duplicate input cannot sell twice or reroll demand.
4. Keep this sale as a separate zero-day transaction after the original show has been accounted. Supply `Finance.apply` with explicit `Merch sales` gross income. Combining merchandise cash into the existing `live:perform` net result would corrupt its fee/travel/session split unless the full combined gross flow list were supplied.
5. Save failure restores cash, stock, offer, settlement ID, Finance and all unrelated state together. Existing show-day/terminal guards remain authoritative: a sale can reset a live zero-cash run under the current policy, but cannot revive a folded band.

Validate exact/insufficient production cash, zero/one/excess demand, sold-out and batch eligibility, one show/one settlement, reload/retry, failed saves and original finance arithmetic. Then inspect four native sizes using the current paper, Ink notes and 48px controls. Update Finance’s inactive-sales wording only for the implemented merchandise channel; music remains inactive.

Music sales should follow in a separate slice: expose the existing recording/release route first, then require a real **released `recordings[].id`** for every music product. Resolve that stable ID to its current index at commitment. A written song, `demos` count, press score or display row is not a recorded/released product, and no royalty or past income should be invented.
