# Linked song success and clear song metrics

Status: source-grounded design, 11 November 2026. This contract is not implemented gameplay or a new pilot build. Baseline source is `b93f44809fab04c43c0f91fe90b0f6af468e48d5`; unchanged runtime remains ENGAGE52 `81f6129d0f166ff0b854b0ae849bc419ccdcd60c`.

The owner accepted ENGAGE52's three audio replacements and presented screen revisions, then asked what decisions affect a song while writing, performing, recording and promoting, how those stages connect, and how players understand each song's strength. Keep that scoped acceptance separate from overall game/pilot approval.

## Player model

A strong composition needs a prepared band to deliver it. A recording captures a particular version and performance. Promotion brings that recording to listeners; their response depends on what they hear and the audience reached. Live feedback can inform a rewrite, preparation for the next gig, the recording and the eventual pitch.

The whole loop uses the same song identity. Avoid four unrelated activity scores or a single success score that conceals the reason for failure. A weak night does not erase a good song; buying promotion does not improve the writing. More money, complexity, volume or restraint must not always be the best answer.

## Four headline metrics

| Player label | Meaning | Display and evidence | What changes it |
|---|---|---|---|
| **Song strength** | How developed the composition and arrangement are, independent of today's band condition or publicity. | Existing saved quality shown as `72 / 100 · Strong`, with one source-backed reason. Retain existing bands: below45 Needs work;45–69 Promising;70+ Strong. Replace the misleading strength label Setlist ready; readiness has its own measure. No finished score for an unfinished draft: show `Draft · 2 of 3 sessions`. | Committed writing and, in a later supported revision path, actual reworking. Player previews and free comparisons never improve it. |
| **Live readiness** | How well this line-up knows this particular version of the song. | New per-song0–100 value and plain label such as Rough or Tight, established by actual rehearsal evidence. Before evidence, `Not rehearsed with this line-up`. Today's fatigue/absence is a separate contextual warning, not a stealth rewrite of the song's preparation history. | Relevant rehearsal and learning the arrangement. Revisions/new participants require refreshed preparation; one global rehearsal must not make every song equally ready. |
| **Recording quality** | How well a particular recorded version delivers the song. | New per-track0–100 result and plain label, attached to an immutable recording take. `Not recorded` when absent; select which take is being viewed. Separately show source composition revision. | Song strength at capture, preparation and studio performance, and appropriate production choices. A polish/complexity choice cannot turn any weak song into a hit. |
| **Reach** | How often the song has actually been heard in the game. | Counted `180 listens`, with sources and date in Details. Counts are listening events, not unique people or fans; repeat listening can count again. Before new tracking, `Not tracked`, not an invented0. Do not invent total live audience or credit a whole release campaign to every track. | Completed performances with supported listener evidence and campaigns/airplay with explicit song or recording-track attribution. |

Three bounded scores share a0–100 scale. Reach is an actual count, never a fourth percentage with a hidden denominator. Each row has a word label so colour is unnecessary. Do not add separate hook, lyric, coolness, commerciality and memorability meters in the pilot: those are not currently independently modelled.

**Audience response is a short evidence line, not another permanent score.** Examples: `Untried live`; `Last gig: the chorus caught on; the ending lost the room`; `Radio: listeners responded to the stripped-back take`. Attach the actual room/channel, date, version and sample count. If the model has not recorded a chorus-level outcome, use a whole-song observation rather than inventing that detail. One lukewarm audience is not a universal verdict. An untested song is not bad by default.

## Decisions and links across the four stages

| Stage | Meaningful player decisions | Inputs carried forward | Saved consequence and clear feedback |
|---|---|---|---|
| **Writing** | Choose the musical idea and song direction, structure and dynamics; choose who leads and whose suggestion to try; decide which difficult passage to simplify or develop; rework after actual feedback. | Active musicians' skills, established creative/relationship context, current song version and actual chosen arrangement. Style is identity; no genre or Verse/Chorus structure should receive an unconditional quality advantage. | Committed composition strength and reason, with the arrangement preserved. Example direction: `The new ending gives the song a clear finish`. Only show after a corresponding real outcome. Harder passages create preparation demands, not automatic quality. |
| **Performing** | Choose songs/order appropriate to the bill; rehearse chosen songs; choose an achievable intensity, pacing and how to respond to the room. | Song strength + preparation for that song/version/line-up, today's condition, actual room and set context. | Per-song performance response and whole-show result. A failure can reveal an execution weakness while preserving composition strength. Response can guide the next rehearsal/rewrite. Room fit affects reception, not intrinsic strength. |
| **Recording** | Select songs and versions worth capturing; decide when the band is ready; choose a live/raw or controlled/layered approach appropriate to the arrangement; keep or redo a take when a supported retake route exists. | Exact composition version, preparation, actual performers/condition and selected production approach. Strong live feedback informs selection but is not a free studio bonus. | An immutable take with its own quality and source link. Example direction: `The parts are clear, but the performance feels tentative`. Expensive production expands options rather than guaranteeing excellence. |
| **Promoting** | Choose a lead track, appropriate outlet/audience, pitch and release timing; balance further reach against using time/money elsewhere. | The exact released take and its quality, style/identity, recorded audience response, channel and timing. A known live favourite can motivate a pitch; its title alone gives no bonus. | Attributed listens and resulting response/conversion, reconciled with the original once-only campaign and band-wide accounts. A good pitch can secure attention; a good recording helps that attention turn into interest. Reach and response remain distinct. |

The player chooses in-world actions without a pre-choice numerical bonus, probability or highlighted best response. Show actual current state, saved feedback, prices and time clearly. After settlement, explain the actual outcome and relevant measured change. Do not show `choose this for +6 quality`, a predictive success bar, or a disguised stat-direction answer key.

## One song view, used everywhere

The songbook is the home of each song's identity, four rows and last response. The writing room, rehearsal/set selection, studio and promotion picker reuse that summary for the same song/version, with the relevant row prominent. Avoid rebuilding the protected passive band meters or adding a dashboard on every screen.

Illustrative future state, not real player data:

| AFTER THE LAST BUS | Current evidence |
|---|---|
| Song strength | 72 / 100 · Strong |
| Live readiness | 46 / 100 · Rough |
| Recording quality | Not recorded |
| Reach | 180 listens · tracked performances |
| Last response | Three gigs recorded; response varies by room. |

This tells the player the song is promising material that still needs preparation. It must not label it bad because the last set was tired. A second song could be tight and well recorded but have little reach; it needs listeners rather than more polishing. A third could have high reach and a muted response; buying the same campaign again is not the obvious cure.

On the phone show title, compact metric rows, the latest relevant observation and the real action/return route. Details contain source dates, versions, earlier takes, limits of evidence and history. Do not shrink text to fit a history dashboard. A post-action recap states what changed and why, followed by an actual choice of next activity.

## What exists now, and what must change

These are inspected functions, not architectural assumptions:

| Existing source | Actual current behaviour | Gap/implementation consequence |
|---|---|---|
| `Scripts/career_actions.gd:_write_original` | Composition quality depends on band readiness, active average skill and tension. | Preserve legacy result. Better source explanations can reference recorded inputs; do not claim to analyse audio or literal lyric quality. |
| `Scripts/song_workshop.gd:develop/finish`; `Scripts/song_chemistry.gd:calculate` | Leader/idea/form/session history saved; final form gives a fixed bonus; chemistry contributes. Leader identity is not an independent direct quality modifier here. | Richer writer-fit decisions and balanced structure choices require model work, not merely explanatory copy. Remove a universally best form only in a scoped balance change with regression evidence. |
| `experiments/playable_flightcase/song_workbench.gd:seal_paid`; `mixing_recipe.gd:craft`; `producer_recipe.gd:craft` | Selected recipe/capacity can adjust final quality and saves a producer-quality receipt; existing social effects are separate. | Reuse real receipts for current outcomes. Tone/theme are creative identity, not evidence of generated text or audio content judgement. Don't count the same craft adjustment twice. |
| `Scripts/practice_room.gd:resolve` | Rehearsal mostly affects band state and musicians. | True per-song/per-line-up readiness is new state and needs meaningful song selection and guarded settlement. Do not relabel the global readiness number as this metric. |
| `experiments/playable_flightcase/gig_performance_policy.gd:song_step/feedback/apply`; `gig_journey.gd:complete` | Pinned song quality, preparation/intensity and one live intent feed cumulative room response; finished-song IDs/context/feedback archived. Fan adjustment in this policy is based on chosen intent versus neutral, not an independent fan award for each strong song. Original gig settlement is elsewhere. | Current room vibe is cumulative, not a pure song rating. Reuse IDs/history; add justified response attribution and reconcile whole-show economics once. No second fan settlement for the same show. |
| `Scripts/recording_career.gd:record/release`; `experiments/playable_flightcase/recording_rules.gd:record/release` | Selected two/three-song snapshots pinned by IDs; track quality copied from composition; demo quality is their average. Release uses demo quality and buzz. | Recording currently has no independent studio-performance quality or expressive production decision of this kind. Add it explicitly with original snapshots retained. Do not relabel the copied value as new measured execution. |
| `Scripts/release_campaigns.gd:launch`; `experiments/playable_flightcase/promotion_rules.gd:launch` | Channel awards include recording quality; radio answers affect band fans/press/buzz, once per campaign. | No current per-song listen count or audience conversion model. Attribute new lead-track/campaign observations prospectively. Do not divide band-wide fan gains across songs and present that as actual reach. |
| `Scripts/songbook_presentation.gd:entries`; `experiments/playable_flightcase/recording_desk.gd:_song_facts` | Existing quality/verdict/history displays; missing live reception reported as not recorded. | Extend current views. Unknown legacy data remains unknown. Setlist-ready wording conflates strength and preparation. |

The present chain is partial. These proposed new metrics and decisions are not available merely because this document describes them.

## Persistence, fairness and provenance

- Use canonical song IDs, explicit composition revisions, exact performer IDs and recording/take IDs. Never join songs by title. Duplicate names must not blend their history.
- Reworking a song preserves its ID/history and creates a new revision. Preparation transfers only according to supported unchanged material; old recorded takes stay exactly as captured. Song improvement cannot retroactively upgrade a released recording.
- Rehearsal and recording receipts pin original source context. Today's fatigue cannot rewrite yesterday's take or an archived gig. Line-up changes cannot masquerade as preparation by the new musician.
- New records carry versioned additive metadata and unique event IDs. Keep unknown fields and existing saves, salaries, prices/day costs, finance guards, promises and once-only settlement. Never reset a career or rewrite a legacy recording to fill in missing scores.
- New listen tracking starts from actual supported events. Keep release-wide/unknown legacy attribution labelled. Reach cannot be inferred from fans, buzz, press, campaign cost or attendance at an uncompleted show.
- Repeated Menu/Continue/reload/recap/preview never grant strength, preparation, listens, fans or costs. A failed filesystem save rolls the full event back; retry commits once.
- All gameplay scoring stays authored and local. No runtime AI, new service, paid generation or invented audio analysis is required. Source audio remains private. Original app/save/signing identities and frozen V23/V24 remain protected.

## Bounded delivery order in the existing S80 queue

1. Establish a read-only song summary over existing song IDs/strength and supported recording/history facts. Add explanatory post-action receipts. Show unknowns honestly; no fake readiness/listens. Prove actual phone/short/wide/tall views and old saves before this display ships.
2. Add per-song preparation through selected rehearsal and carry that same snapshot into live delivery and a narrowly scoped recording approach. Preserve archived take values. Keep song strength distinct from execution and test awkward counterexamples: strong/unprepared, weak/tight, tired/high preparation and new line-up/old version.
3. Add attributed lead-track promotion/reach and contextual response. Reconcile existing release/show rewards once and demonstrate that the right audience can respond differently without changing intrinsic strength. Add no fabricated history to existing songs.

Before calling this linked pilot feature complete, run full writing→selected rehearsal→gig→recording→promotion→songbook journeys, real save failure/retry/reload, duplicated-title/legacy/mid-action fixtures, version changes and all four native viewports. Check player comprehension with owner/friends when available; simulated review and technical tests cannot establish that the metrics feel clear.

One next action: implement the first read-only song-summary slice under a fresh source/UI scope, keeping absent systems explicitly absent, then connect subsequent model slices through the same song identity. Do not issue an APK/signing request on the basis of this design alone.
