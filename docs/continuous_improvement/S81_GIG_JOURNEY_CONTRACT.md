# Proposed S81: one complete Lantern Room night

Status: ROOT-ADOPTED IMPLEMENTATION CONTRACT for S81; not yet implemented or runtime-tested. Repository reads only; this file and source-inventory.json are scratch. Root must select the final policy, acquire a fresh lease, commit the scoped preflight and pass its gate after S80 release before source edits. The owner has authorised proceeding with complete band experiences and lifted the allocation constraint. That does not approve new artwork, replace identities, waive save/economy guards or create another queue.

## Source facts and safe seam

| Existing fact | Actual source |
|---|---|
| Current night only has arrival, soundcheck and stage. Its stage is a free view-state and all original phases can resume from career state. | Scripts/gig_night_flow.gd:3–45 |
| Managed local booking pins LOCAL_LIFT/local_lift, travel acknowledgement, soundcheck commitment and a plan; its booking ID is venue+scheduled day. | experiments/playable_flightcase/show_flow.gd:33–35,145–206 |
| Plan contains at most three unique FINISHED song IDs and complete immutable snapshots; soundcheck advances original night to stage and saves this plan. | show_flow.gd:208–248,281–294 |
| Existing projection validates intensity/set shape and derives effective readiness/success estimate. Altering readiness outside this pipeline breaks final policy/receipt validation. | show_flow.gd:57–71,250–307,325–364,381–432 |
| Full original paid flow is Calendar.perform → Promoter.settle → owned ShowFlow.after_original_settlement → Night.reset → Story/Calendar/Life → Reviews.apply → ShowFlow.record. | experiments/playable_flightcase/live_bridge.gd:137–182 |
| CareerDesk then applies Finance and atomic owner save before creating ShowReplay. Replay has only three whole-show summaries and is POST-settlement; it cannot host unresolved song choices. | career_desk.gd:1130–1202; show_replay.gd:220–293 |
| Original local venue is The Lantern Room/HOMETOWN, £5 travel maximum, one day; session cover is original £25. Booking uses three lead days. | Scripts/uk_gig_circuit.gd:4,52–101; Scripts/gig_calendar.gd:7,15–37,56–120 |
| Zero originals stays legal, limits final managed gross fee to £5 and has no invented covers/song IDs. | show_flow.gd:265,347–364; live_bridge.gd:174–175 |
| Original cancellation costs up to £15 and -3 reputation with zero days; no show income. | Scripts/gig_calendar.gd:122–138 |
| Finance increments sequence and ledger even for changed metadata at zero cost/day. Therefore NEW journey checkpoint saves MUST NOT call Finance.apply. | experiments/playable_flightcase/finance_policy.gd:106–185, especially171/179 |
| Owner save uses a temporary file and atomic rename, and restore supports schema1/unknown career fields. | opening_state.gd:318–407,426–450 |
| Radio's owned cookie/reveal/busy/checkpoint-save pattern is reusable, but its scene shell hardcodes Studio names and4:3. Avoid a radio regression by copying only the narrow presentation pattern. | radio_visit_desk.gd:176–249; activity_scene.gd:13–52 |
| Original optional tired-bassist incident is earned from actual active bassist fatigue≥60 while original night is SOUNDCHECK; it has original effects and one booking marker. | Scripts/gig_backstage_incident.gd:10–44 |
| S78 contexts and kept/broken/excluded rehearsal agreements are actual optional facts. Missing legacy context stays UNKNOWN. Existing evening-work logic is rehearsal-specific; do not silently make a gig absentee/wage rule. | situation_core.gd:19–82,121–136,167–240 |

Safe new outcome seam: after the existing owned adjustment at live_bridge.gd:155, before the original post-chain at163. Apply a small owned nonfinancial live-choice policy here ONCE, retaining original success, fee, readiness and S53 projection. Then original Story/Life, Reviews and ShowFlow.record see the actual final facts. Do not call the complete old perform API and add effects afterwards. Finance still sees one completed paid show.

## Bounded experience and controls

One due, managed LOCAL_LIFT booking at The Lantern Room. Future bookings/preparation stay on the existing desks. Do not expand venue economy, agent hiring, audio, instruments or jobs in this pilot.

Saved phases: set_out → travel → arrival → load_in → soundcheck → backstage → stage_entrance → performing → after_set → pack_up → wrap_ready. New semantic progress occurs ONLY at explicit input. These are data phases, not a requirement for eleven separate text screens.

| Scene | Meaningful experience | Explicit commitment |
|---|---|---|
| Vehicle and travel | Actual band/destination; an honest arranged lift, restrained source-backed vehicle/road motion and departure/arrival fades. A grounded short band exchange may recognise the last show or a saved rehearsal agreement. | Set out saves travel and original Flow.depart once. Watching/skip only settles presentation. Arrive explicitly saves arrival. |
| Door and load-in | Same venue and actual members; exterior to interior continuity. Carry the actual selected gear context without claiming inventory animations that do not exist. | Load in/start soundcheck calls original Night.advance once and saves matching journey phase. |
| Soundcheck | Existing rotary/fader/finished-song list and order remain interactive FREE drafts. A response reflects the committed approach. If original tired-bassist incident exists, present it here before plan commitment because its protected resolver only accepts original soundcheck. | Original SAVE SHOW PLAN locks existing plan/snapshots and advances Night to stage, plus new journey backstage phase in ONE owner save. The original optional incident retains its original resolution/effects/once marker; new checkpoints do not apply its effects again. |
| Backstage and stage entrance | Actual participants; exchange recognises supported preparation, existing pressure or remembered agreements. Then a visual passage into the correct audience-facing stage. | Ready/start set saves stage_entrance then performing; neither charges a day or resolves the show. |
| Performing | Visible ordered saved song titles, completed prefix crossed out, current song and an honest modelled room-vibe meter. Existing source-backed stage/crowd imagery; performer portraits can represent speakers, but must not be posed as playing. | FINISH SONG(id,expected cursor/revision) saves one actual completion and its pure modelled feedback. No timer/reveal/fade/audio estimate can complete it. One contextual intent after the first song is locked/saved, followed by a held witnessed response; it does not auto-finish another song. |
| After set | Let observed room/band feedback land before bookkeeping. Use ONLY saved completed cursor/vibe/intent facts; do not call this a paid receipt or promise the final fee/success. | Continue explicitly saves after_set→pack_up. |
| Pack up and leave | Reuse source-honest load-out/departure imagery and actual band. Close the night visually. | At wrap_ready, explicit LEAVE / WRAP THE NIGHT invokes final original settlement once. Watching packing-up or leaving animation never settles. |
| Saved result and next goal | Actual signed/capped saved consequences and full Details; original receipt/history/reviews and same actual goal. | Display only after final owner save. Free existing route; never claim a chapter reward automatically. No active journey wrapper remains after the booking disappears. |

Routine navigation stays quick. Every visual transition has an immediate skip-to-settled-frame/reduced-motion route with equal information and identical saved state. Important words/questions/responses remain player-held; first input can finish Ink reveal, a separate control advances the saved phase. No arbitrary enforced waits. Do not implement the experience as more plain Continue cards.

## Additive state and validation

Proposed TOP-LEVEL career optional key `gig_journey_v1` (not a mutation to original Scripts/schema1): `{version:1, sequence:int, active:{...}, unknown_extensions_preserved}`. Absent means legacy. Known empty active is idle. Unsupported/future/malformed payload is HELD and never silently normalised, discarded or migrated. Explicit String-index assignment for every persisted key; retain full typed save/reload checks (S78 StringName lesson).

Active contains:

* Stable journey ID + original ShowFlow.booking_id, scheduled day, venue ID/name/city, original transport/session-hire/promoter terms, policy_version/content_version/art-source-version and monotonic revision.
* Phase and old-original phase expected at each edge; started day/cash; ordered actual participant IDs/roles/snapshots. No inferred cast replacements or job facts.
* During pre-soundcheck, a guarded current source fingerprint refreshed ONLY after successful owned transitions. Start only on the due day, with supported managed booking, terminal/radio guards clear. New wrapper cannot begin a second activity.
* At soundcheck commit, freeze complete actual plan and FULL song snapshots, plan hash, validated original projection, source context (cash/day/members/readiness/morale/tension/gear/promoter/core facts) and a deterministic content/context fingerprint. Derive hash from canonical typed content; exclude only the journey wrapper itself, never unknown gameplay fields. That source state must stay exact through the remaining zero-cost phases.
* Cursor0..N, completed IDs EXACTLY equal to orderedIDs.slice(0,cursor), optional per-song modelled feedback for exactly that prefix, current modelled vibe0..100. No future song record, duplicated completion, reordered snapshot, nonfinite value or inconsistent partial prefix accepted.
* At most one locked event/intent with actual participant ID and frozen earned context. State explicitly distinguishes pending choice, saved choice and held reaction. A reload cannot reselect a participant, refresh the situation, reroll dialogue or change an answer.

All transition APIs take journeyID + expected phase + expected revision, plus expected songID/cursor where relevant. Own the owner render-generation cookie and ignore stale input identities. Set busy BEFORE dispatch. Exact duplicate input is read-only/idempotent, never another save or model effect. Touch release, held key, modal closure, resize, focus restoration, Menu/Continue and reduced-motion changes never count as a semantic action.

Other commitments remain locked while active: terminal takes priority; an existing radio visit prevents begin; active journey routes Menu/Continue to the due gig. Existing opening_ui.gd:1041 already routes a due show to CareerDesk, because all new phases keep the original day until final wrap. Extend CareerDesk central commitment guards/navigation rather than editing original practice/recording resolvers. Revalidate active journey after any old optional incident/soundcheck change, then freeze its post-soundcheck source. Do not treat current job schedules as an automatic gig attendance simulator.

At final wrap revalidate full source/booking/plan/participant/prefix/choice/version/cash/day/finance checkpoint and actual original eligibility. No stale chosen snapshot can settle a different booking. If booking disappeared, an exact existing receiptID is a read-only completed result, not a reason to perform again.

## Contextual live intent: concrete proposed small policy

This section is a REVIEWABLE proposed policy, not existing game behaviour. Root should accept or replace the complete formula before code; do not leave a vague “choice bonus” callback to improvise later.

Use one **read-the-room boundary after the first completed original**, rather than a random dilemma every gig. Its factual context is the saved first-song feedback, actual active musician with highest fatigue (stable roster order tie-break), original projection/readiness/intensity, and existing recorded rehearsal `broken`/`excluded` counts for that musician. On a low-pressure night it is a simple set-flow choice; with earned fatigue/history the musician/wording and mechanisms differ. Family support alone does not create a punishment, and unknown work/financial context stays unknown.

In-world intents: **Give the room a moment** versus **Keep the set moving**. Neither label/tooltip/colour/Details supplies a stat answer key or numeric forecast. The player has the performed room feedback and band interaction to assess.

Suggested deterministic calculation, all internal:

1. Initial room vibe = neutral40; do not derive visible pre-performance vibe from hidden quality_estimate. This is an illustrative current-room model, not measured attendance/audio or a pre-show success forecast.
2. Each explicit finished song adjusts vibe by clamp(floor((pinnedSong.quality−50)/15) + floor((originalProjection.quality_estimate−52)/10),−6,+6). Store actual resulting vibe with that completed song. Use the exact same pure function for replay validation and finish; no random or wall-clock input.
3. Let `fatigue` be the frozen chosen actual performer's fatigue and `pressure=min(3,broken+excluded)` from validated recorded optional core history. A missing agreements row uses Core’s established zero-count default; a malformed/future core refuses. Malformed core refuses; UNKNOWN jobs are not zero hardship.
4. `moment`: earned fatigue relief `min(4,max(0,ceil((fatigue−30)/15)))` for that performer at final wrap; tension relief `min(2,pressure)` ONLY when fatigue≥50; vibe adjustment +2 if the room is already≥55, otherwise−2. It is not a universal best/rest reward: interrupting a quiet room may lose momentum, and a rested player earns little/no relief.
5. `moving`: extra fatigue `min(4,1+floor(max(0,intensity−35)/25))` for that performer; tension pressure `min(3,pressure+max(0,floor((fatigue−45)/15)))`; vibe adjustment `clamp(floor((readiness−45)/10)−floor(max(0,fatigue−45)/15),−3,+4)`. A prepared, rested band can carry pace; tired/unresolved context may not.
6. Final extra fans = clamp(sign(diff) × floor(abs(diff)/2),−3,+3), diff=finalVibe−neutralFinalVibe (symmetric truncation toward zero), using a counterfactual computed by the SAME locked-context/song function with no live intent. Clamp actual career fields at final wrap and record actual after−before; do not show or commit an uncapped preview. No cash/day/reputation/readiness/success/fee changes from this policy. No original gear/approach/fatigue charge is replaced.

The formula is bounded and context-dependent; the choice does not award a fixed bonus vector. A simpler equivalent is acceptable if fully specified and tested. Do not add unrelated relationship/morale/job wage systems in this first pilot. S78 SituationCore.after_action may mark actually missed saved rehearsal promises once after the show advances the day; absent core remains absent. Its effect must enter the same final transaction/rollback, not a subsequent unowned save.

## Final composition and compatibility

Introduce a narrow internal live performer helper so the OLD public `resolve(state,"perform",...)` remains value-compatible ONLY when no active supported journey exists. Actual new managed UI uses new start/checkpoint/final-wrap APIs and cannot call direct paid perform. A direct `perform` attempt while active must refuse. Legacy unmanaged bookings and completed receipts remain original/read-only with no invented live transcript.

ONE final paid composition:

`validated active journey at wrap_ready → original Flow.prepare_performance → Calendar.perform ONCE → Promoter.settle ONCE → Flow.after_original_settlement ONCE → new pure live policy ONCE → Night.reset → original Story/Calendar/Life post ONCE → Reviews.apply ONCE → Flow.record ONCE with optional journey receipt extension → optional SituationCore.after_action once if existing supported core → Finance.apply(before,after,"live:perform") ONCE → clear active wrapper in this candidate → owner atomic save ONCE → visual departure/saved result`

Do not expose the wrapper as completed until that one save succeeds. The original projection remains unchanged and recomputable, and original managed receipt validation remains meaningful. An optional `journey_v1` receipt extension stores version, ordered completed IDs/snapshots, intent/context identity, pure modelled feedback, actual capped policy effects and no audio/attendance claims. It must be complete and validated; old receipts without it remain valid. Keep record limits/seen IDs and unknown extensions.

For NEW metadata checkpoints, snapshot the WHOLE owner/career, resolve a pure copied state, install it, owner.save_draft once, restore the whole original owner snapshot if save fails. `Finance`, original performance, Story, Reviews and rewards are NOT invoked by those checkpoints. Existing booking and original optional incident operations retain their original accounting contracts; do not describe their real effects as metadata-only.

Pause/Menu is free and retains progress. No free “cancel visit” button can clear completed-prefix/choice and reset the same booking. Explicit cancel booking retains original £15/up-to-cash and reputation consequences, zero days, one Finance/save and atomically clears a KNOWN active journey. If a future wrapper cannot be understood, retain its bytes and offer the original cancellation only where its independent source fields validate; do not erase or reinterpret the future wrapper. An unknown-format hold may require a compatible build.

Zero-original fallback: show “No originals selected” and an honest short-set stage, no invented song/cover. One explicit END THE SHORT SET metadata checkpoint enables after_set; no crossed-out fabricated titles, no song-specific response/intent claimed. Original zero-original gross cap and whole-show result still settle once at wrap. A one-original set offers its boundary interaction after that original and before after_set; it is not followed by an invented second song.

## Implementation scope recommendation

New owned pure `gig_journey.gd` (validation/checkpoints/context/vibe/policy/receipt facts); new owned `gig_journey_desk.gd` (experience view and semantic callbacks); bounded presentation-only `gig_journey_scene.gd` if needed for image/motion/held frame reuse. Narrow edits in `live_bridge.gd` (internal final composition seam and bypass refusal), `career_desk.gd` (owner callback/priority/save guard/resume) and `show_desk.gd` (delegate managed due UI/soundcheck to new journey while retaining existing source controls). No original54Scripts edit, no global dialogue engine or save-schema migration. Root must inspect actual changed dependency closure before allowlisting final paths.

## Art and motion gate

No art pixels were opened by this contract worker. The artist must pin actual current source hashes/cameras and native focal crops before root source/art preflight; this document is not visual approval.

Need source-honest vehicle/road, actual venue doorway/load-in/interior, backstage and stage/crowd/packing/departure mapping. `opening_stage.png` is audience-facing; reverse `s53_stage.png` is not a front-facing actor stage. A02v2 approved poster is NOT an instrument-playing layer. A05v3 radio source is approved for radio, not a gig environment. A04 unbranding/edge failure remains HOLD; no repeat full-image prompts, masking or multiplying musicians. Missing Zoe bass/Marcus drums layers do not become present through a portrait wiggle.

A source-backed stage/crowd + actual saved set + band speaker portraits can support an honest ART-INCOMPLETE gameplay pilot. It cannot be claimed as the requested musicians-in-turn performance result. Do not silently promote unapproved new performer art. If an owner-only art gate genuinely blocks that slice, record it and progress the next approved actionable audition/songwriting slice; do not repeat unchanged tests or turn the entire queue into no-op runs.

## Acceptance and HOLD

* Pure cases: all phases/cursors/one intent/context variants, high/low fatigue/preparation/history, all bounds/nonfinite rejection, typed snapshot immutability, malformed/future wrapper hold, unknown-fields preservation, old direct API no-active compatibility, new UI bypass refusal, zero/one/two/three originals, original zero gross cap, original session cover, local travel shortfall, final plan/roster/catalogue mutation rejection, policy caps and idempotence.
* Whole original-model controlled comparison with no active journey must be byte/typed-value identical. With journey, cash/day/success/gross/original projection exactly match old baseline; only declared optional metadata and capped live policy fields differ.
* Genuine new native journey, all four390x844/720x1280/1280x720/1600x900: set out → travel → load in → actual controls → backstage → stage → explicit saved original completions and intent → after_set → pack up → final wrap → actual saved result/next goal. Resume Menu/Continue after at least travel, soundcheck, first completion/choice, pack-up; no reroll, no duplicate effects. Demonstrate one metadata-save failure and one final-wrap-save failure, whole owner/disk rollback then single retry.
* Pointer, key, touch, held/duplicate/stale/release input, first input finishes reveal without phase change, reduced motion and skip equal facts, live resize and native scroll must preserve state. New checkpoints have EXACTLY0 Finance calls,0 day/cash/stat changes; finish exactly1 original paid pipeline/Finance/save. No resolver/save from view/tween/reveal/resize/reload.
* Original73gameplay/88opening/cleanimport/four genuine standard journeys on exact candidate; strict EMPTYall_error_lines, measured native orphan growth0. Source protection preserves original54Scripts/3trackedUID/fonts/rawart/passive hardware. One GL flock and exact4.7.2/fresh private XDG/tmp storage budget; no arbitrary deletion, new dependency or production saves.
* Actually open original PNGs at each place and each canonical viewport; assess place/character continuity/rhythm, first-fold actions/readability, source-camera correctness and honest result history. Five lenses explicitly SIMULATED, technical/native/owner verdicts separate. No feature-complete claim from source tests, metadata counts or an art study.

HOLD if full transaction seam/rollback is incomplete, art camera/identity is fabricated, repeated navigation substitutes for witnessed action, modelled vibe is sold as measurement, current UI can bypass the journey, any earlier phase charges/settles, standard safeguards fail, or two corrective attempts repeat the same ineffective method. Ship fewer coherent moments rather than unverified breadth. The SAME finite queue/thread and current01:00Nov3 write end remain; the new allowance statement lifts resource restraint, not an automatic deadline/controller extension.


## Root compatibility and implementation amendments — authoritative

* Begin maps existing managed phases: travel→set_out; acknowledged arrival→arrival/load_in; soundcheck→soundcheck; committed stage→backstage with existing complete plan frozen and cursor0. Do not make old saves depart or commit twice; no fabricated completed songs. Completed receipts remain read-only.
* Pin every actual roster slot/index and full snapshot. A missing candidate_id is legal in original MemberLife recruiting. Use a visit-local slot+snapshot-hash key; never infer C25 identity/job/portrait from a name. Present canonical portraits only for actual identified cast.
* Keep new wrap Finance action EXACTLY live:perform, and cancellation live:cancel. Otherwise costs are misclassified. All new metadata checkpoints bypass Finance entirely. Original optional incident uses original effects/accounting once, before soundcheck commitment.
* LiveBridge may import pure Journey. Journey must never preload LiveBridge. Pure Journey resolves metadata checkpoints and prepares/validates wrap context/policy; LiveBridge composes the original paid pipeline at the audited seam. Public legacy perform refuses an active or malformed/future wrapper; no-active legacy calls remain value-identical.
* New actual UI performs the journey before settlement, so it must skip old post-settlement ShowReplay. Keep replay for old legacy flows/read-only receipts.
* Controller semantics: begin, explicit phase advance, commit soundcheck, finish expected song/cursor, lock one intent, acknowledge held reaction, final wrap, original-fee cancel. Each binds stable journeyID/phase/revision/render cookie. Each free checkpoint saves metadata once and restores whole owner on failure. Only wrap runs original performance→Story/Reviews→Finance once; animation/resize/reload never does.
* Initial visible vibe is neutral40 until real explicit song completion. Extra fans use symmetric truncated half of final-vs-neutral vibe difference, capped±3. All policy bounds, original fees/success/readiness/projection stay as specified.
* New road art is a separately pending proposal. Existing three plates can support an honest art-incomplete native prototype; do not claim moving vehicle/playing animation from camera motion. A06 Nia reuse stays owner-gated.
* Owner latest48h extension ends21:24:35London4Nov; completed prior01:00 boundary is historical. One source writer/GL. Source/art integration freezes20:15Nov4; no newbreadth19:45, final21:15readinessonly/allwrites21:20.


## Root prefix-independence amendment — supersedes earlier example formulas

Independent review showed that full-set quality_estimate contains unplayed closer quality and must not determine the visible first-song feedback. Initial vibe is neutral40. For each actually completed original, step = clamp(floor((thatSong.quality−50)/15) + floor((frozenRawReadiness−50)/15) − floor(max(0,frozenIntensity−frozenRawReadiness)/20),−6,+6). Only completed song snapshots and frozen raw preparation/intensity enter that step; never full-set quality/set-shape/unknown future songs. Original full projection remains pinned and unchanged for original final show settlement. Test prefix independence against different unplayed closer qualities.

The one live pacing intent appears ONLY with N≥2 originals, after cursor1 while another original remains. N0 uses honest whole-short-set completion; N1 completes that one original without invented continuation or mid-set bonus. No live-intent effects when no intent exists.

Use frozen RAW career readiness, not effective projection readiness, in the moving-choice formula. Historical pressure = clamp(recordedBroken + recordedExcluded − recordedKept,0,3), after valid Core defaults; describe it as remembered rehearsal history rather than a causal claim about unrecorded relationships/jobs. Missing valid agreement rows use zero counters; invalid/future Core HOLD. Symmetric finalfanrounding remains sign(diff)*floor(abs(diff)/2), capped±3. No policy changes fees/cash/day/success/reputation/readiness or originalprojection.


## Root reachable first-song context threshold

With neutral40 and one completed song step capped±6, the only mid-set choice sees34..46. Use moment room-vibe threshold42 (starting to warm) for +2 versus−2, superseding the unreachable55 example. Keep it internal; provide witnessed room/band response, not the threshold or effect answer key. Test both reachable branches independently.


## Owner scheduling/cancellation steering — 2 November evening

The updated release must also address venue selection, booking dates/calendar and travel alignment, with gig day the focus. S82 source-grounded scheduling contract is being prepared; the one-venue S81 model is a core milestone rather than the whole requested release. Immediately remove prominent Cancel from the journey dock: put it behind SHOW OPTIONS, use a red cancellation action and guarded confirmation, keep pause/Menu accessible. Serious timing/commitment-dependent consequences require the fresh S82 policy/compatibility contract before changing economic math; do not add an arbitrary penalty to the frozen S81 model. No milestoneAPK claim that this scheduling request is already complete.
