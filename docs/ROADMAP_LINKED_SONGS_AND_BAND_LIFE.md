# BandMaster — linked songs and band-life roadmap

**Planning record: 12 November 2026. Completed for Git publication: 13 November 2026. Branch: `feature/playtest-polish-v20`.**

The owner asked for a roadmap in Git after a non-audio project review and supplied the SONG53 design. This document sets the proposed order and acceptance gates. **It does not authorize implementation, schedule background work, approve a build or merge into `main`.**

The [S80 execution queue](continuous_improvement/S80_EXECUTION_QUEUE.md) remains the **single operational worklist**: update status there, not in a second tracker. This roadmap explains dependencies and done conditions. All new rows start **proposed / not scheduled**.

## The outcome

Make the player feel that they are developing **their songs with their people**, not completing unrelated activities.

A song should retain its identity from writing to rehearsal, live performance, recording and promotion. The player should understand why a strong song had a poor night, choose what to change, and recognise the consequences later. Character differences should change the available musical choices, not just the dialogue.

**First playable slice:** two songs, one chosen line-up, one meaningful co-writing contribution, a targeted rehearsal, an existing gig journey, a demo using the existing 2–3-track rules, and promotion of an identified lead track. Use two tracks for the smallest valid demo; do not quietly replace the demo rules with a one-track release. Test this connected slice before expanding the cast, styles, venues or career branches.

## Source truth and scope

| Evidence | What it establishes | Limit |
|---|---|---|
| Accessible branch head `89ef136e232709742150e025b8d0eba9b3ada27f` | Source inspected for the game-critic and musician reviews; existing song, rehearsal, gig, recording and promotion paths | Not proof that it contains the owner's latest local/Codex work |
| [Owner-supplied SONG53](continuous_improvement/SONG53_LINKED_SONG_SUCCESS.md), dated 11 November | Detailed linked-song design contract, imported unchanged | Design, not implemented gameplay or a new build |
| SONG53 source reference `b93f44809fab04c43c0f91fe90b0f6af468e48d5`; ENGAGE52 runtime reference `81f6129d0f166ff0b854b0ae849bc419ccdcd60c` | References supplied in the design | Both returned “No commit found” in the connected repository during this review; reconcile before coding |

The reviews used **simulated game-critic and musician lenses** on source and design. They were not independent human expert reviews, a fresh device playtest or an audio-quality assessment. The musical and player-experience recommendations below are design judgements; the source observations are facts only at the pinned accessible baseline.

Publication check, 13 November: the branch head `3d19d236d4b9604d44ebbbc4e94cc20a34b9d0e4` contained the scoped preflight only. The original uncommitted roadmap and SONG53 attachment were recovered and reviewed again. That head changes documentation only from the source-review baseline above; it does not resolve the two missing newer source references. The completion commit publishes this plan and its queue/handover links; all gameplay stages remain proposed.

The imported SONG53 remains the metric/data contract. This roadmap adds delivery order, character agency, musical fairness and playtest gates. If a proposed refinement conflicts with newer owner-approved work, resolve it explicitly at R0 rather than silently overriding that work.

**Out of scope:** Suno access or credit use, the new audio batch, audition coverage decisions, replacing rejected song 3, runtime AI, new dependencies, new biographies, economy redesign, new platforms, APK production and release/merge operations. Older audio-gap notes in retained history are not a fresh audit of the current indie library.

## Delivery order

| Queue ID | Stage | Depends on | Exit evidence |
|---|---|---|---|
| SONG53-R0 | Reconcile the actual latest source | None | One pinned baseline and an implemented/presentation/new-model inventory |
| SONG53-R1 | Honest reusable song summary | R0 | Real existing values, explicit unknowns, no fabricated readiness/reach |
| SONG53-R2 | Stable song revisions and personal authorship | R0; reuse R1 | Identity/credit contract and one saved, consequential co-writing choice |
| SONG53-R3 | Rehearse a particular song for a purpose | R2 | Song/version/participant preparation with proportionate transfer |
| SONG53-R4 | Carry preparation into the live experience | R3 | Explainable delivery and factual, saved aftermath |
| SONG53-R5 | Capture an immutable recorded take | R2–R4 | Genuine take quality, source revision and actual performers retained |
| SONG53-R6 | Promote a particular recording and track reach | R5 | Attributable listening evidence, campaign settlement exactly once |
| SONG53-R7 | Prove the connected player experience | R1–R6 | Uncoached end-to-end understanding plus reliability/native proof |

These are dependency stages, not promised sprints or dates. Routine approval of the roadmap is not acceptance of every proposed mechanic. Each implementation stage needs its own current scope, one writer, preflight and bounded evidence.

### R0 — reconcile before building

Locate the latest source containing the supplied ENGAGE52/SONG53 references, or establish with the owner which accessible revision should be the implementation baseline. Preserve newer local/remote work and all existing accepted changes.

For each proposed feature, classify it as **already implemented**, **presentation-only**, or **new model required**. Confirm canonical song IDs/revisions, actual cast/skills, current writing/rehearsal transactions, gig receipts, recording/release rules, promotion attribution, save schema and current native layouts.

**Done when:** the baseline SHA and relevant existing components are recorded; no task rests on an obsolete branch assumption. A missing commit is an implementation blocker, not permission to reconstruct or overwrite unseen work.

### R1 — tell the truth about each song

Reuse one summary inside the existing song, rehearsal, gig and recording surfaces. Avoid adding four repeated dashboards.

| Player label | Meaning | Honest empty state |
|---|---|---|
| Song strength | Saved composition/arrangement quality, independent of today's fatigue or marketing | Draft progress, not a finished score |
| Live readiness | How well these musicians know this version | “Not rehearsed with this line-up” only when that absence is known; otherwise “Preparation not tracked for this version/line-up” |
| Recording quality | Execution/production of a selected immutable take | “Not recorded” only when no take exists; otherwise “Recorded; execution quality not tracked” when legacy evidence is missing |
| Reach | Attributable listening events, not a fourth percentage or unique fans | “Not tracked” for missing/legacy evidence |

Preserve the SONG53 strength bands and separate today's fatigue/absence from learned preparation. Show a short audience-evidence line with the actual room/channel, date and version. Do not invent chorus or ending observations unless those outcomes are modelled.

**Done when:** the first read-only release shows only supported data; missing new systems remain labelled as unavailable. No new score is reverse-engineered from a convenient old field. A summary UI alone is **not** completion of linked-song gameplay.

### R2 — a song belongs to real people and a real version

Define canonical song identity, revision identity, contribution receipts and links to rehearsal/gig/take events before dependent features settle new data. Never join by title: two songs may have the same title, and a renamed song is still the same song.

Include **one bounded co-writing choice** in the first slice. Let the player choose an eligible bandmate based on established role, ability and history, try a musically distinct suggestion, keep or decline it, and later recognise the retained contribution. Do not always select the first non-leader, and do not require everyone to agree.

Credit only contributions actually retained, linked to that revision. Preserve earlier credits/history and distinguish credited writers from performers on a particular take. Do not add royalty accounting or invented biography.

**Musical fairness gate:** ability should expand what a musician can attempt. Holding the other inputs fixed, a more capable band must not be punished merely for intentionally playing a simple part. Difficulty, chemistry and expressive choices can still have consequences; more complexity is not inherently better.

**Done when:** one contribution and callback survive save/reload, declining remains valid, rename does not duplicate the song, and the identity/credit contracts support the later stages.

### R3 — rehearse something, not an abstract meter

Choose a song and a purpose: learn this arrangement, work on an actually tracked difficulty, or run the selected set. Reuse existing listening/precision, pacing, attendance, time and fatigue rules.

Preparation should reflect the **version and actual participants**. A cosmetic rename loses none; a changed section requires proportionate refresh; a replacement bassist has to learn their part while existing members retain their knowledge. Returning to a previously learned version should use the preparation that genuinely exists. Define and test the transfer rules rather than using blanket resets or inherited full readiness.

Let a difficult session create a useful next decision and a believable band response. It should not merely produce another stat notification.

**Done when:** practising song A does not fully prepare song B; an absent member receives no invented practice; partial transfer is saved correctly; cancel/failure/retry cannot spend twice. Keep the player-facing explanation simple without adding per-section skill meters.

### R4 — make the gig test the band’s preparation

Extend the existing venue, setlist and performance journey. Carry song/version/participants into the result, keeping preparation, current condition and audience fit distinct.

A strong song can be badly delivered; a modest song can be played tightly; a prepared band can still be tired or meet an unreceptive room. Feedback should explain the relevant recorded context without pretending one room's response is a universal verdict.

Include a brief character-specific aftermath tied to what actually happened and one meaningful follow-up route: rehearse, record, or keep the song as it is; offer revise only when a supported bounded revision route exists. Use existing feedback where adequate. Do not manufacture a generic dilemma after every first song or add obligatory Continue screens just to make the journey longer.

**Done when:** the three contrasting cases above are distinguishable in saved evidence and understandable in play; cumulative room vibe is not mislabelled as a standalone song rating; fans, income and gig rewards are not credited twice.

### R5 — a recording captures a performance, not a live score pointer

Keep a take immutable: source composition revision, preparation at capture, actual performers, production choices and execution result. Preserve the difference between **composition strength** and **recording quality** rather than renaming the copied old value.

An appropriate restrained production can be a good choice. Polish, budget and complexity must not be automatic winners or magical repairs for weak writing. Retain the existing recording costs, valid demo sizes and transaction owner.

**Done when:** subsequent rewriting/rehearsal/member changes cannot retroactively improve an old take; each supported take receives a source-backed execution assessment; the player knows which take is being viewed. Legacy takes remain honest about unknown execution evidence. Claim an audible difference only when a genuinely different approved take/arrangement supports it, not because a gameplay score changed. Full rewrite/retake systems are not implicit prerequisites: use the existing supported recording route and scope any expansion separately.

### R6 — promote the recording that was actually heard

Identify the lead recording track in a release campaign. Attribute listens only when the underlying event supports song/take attribution. Keep general band publicity, fans, spending and listening events distinct.

A campaign must not assign its whole reach to every track. Count repeat listening events honestly without calling them unique listeners. Live reach needs supported audience evidence; unknown old events stay unknown.

Let audience fit and recorded response inform the next decision; do not expose hidden success probabilities or a highlighted best promotional option before commitment.

**Done when:** the same take can be followed from release to evidenced reception; replay/reload/failure/retry cannot settle the campaign or reach twice; labels explain what was counted.

### R7 — test the musical story, not just the numbers

Run an uncoached first-slice playtest. Ask the player:

- Which song did you prepare, with whom, and why?
- Why did the gig go the way it did?
- What would you change next, and what would you deliberately leave alone?
- Which recording did you promote, and what does its reach actually mean?
- What did a particular bandmate contribute that mattered?

**Pass condition:** the player can explain the causal story and make a different next choice without an answer-key UI. Numbers populating all four rows, or tests passing, are not enough.

Separate **technical pass**, **internal design judgement**, **owner experience acceptance** and **release approval**. A fresh build/physical playtest requires its own authorized scope; this roadmap creates no APK request.

## Reliability and presentation gates throughout

| Case | Required outcome |
|---|---|
| Same title, rename, rewrite, old revision | Stable identity; proportionate preparation; immutable history |
| Replacement/absent/returning musician | Actual participants and retained knowledge, not blanket inheritance |
| Strong/unprepared; weaker/tight; prepared/tired | Separate writing, preparation, condition and room response |
| Simple part played by a skilled band | No penalty solely for spare ability; complexity is not the answer key |
| Cancel, real save failure, retry, double-submit, reload | Atomic rollback and exactly-once money/time/outcome settlement |
| Legacy and partial data | Additive safe migration; “unknown/not tracked”, no invented historic evidence |
| Empty/large song lists, long/Unicode names, four established native sizes | Essential choices reachable; readable phone layout; real native inspection for changed UI |
| Mute, reduced motion, skips and interruptions | Equal gameplay information; presentation never resettles an event |
| New choice presentation | Clear situation, prices, time and public goals; no hidden-math/probability previews |
| Existing game content | Preserve approved biographies, cast identities, assets, save/app/signing identity and unrelated mechanics |

## Band-life improvements after the connected slice

Keep these as later candidates in the same S80 queue, not prerequisites for every SONG53 stage.

**BL1 — commitments that mean what they say.** Distinguish a general “within the next few days” intention from an agreed dated session. Reuse actual availability, calendar and existing promise ownership; match the named people, date and follow-up across views. The inspected chat already states a four-day window, so this is a continuity/design improvement, **not a claim that a secret deadline was found**. Honour existing promises throughout the first slice; postpone any wider scheduling system.

**BL2 — ambitions with different trade-offs.** After the core loop works, explore a support slot, a credible demo, or a loyal local audience as genuinely different career directions. Ground opportunities in play history, with distinct opportunity costs and payoffs; do not add three differently worded count checklists.

**BL3 — a more reactive local scene.** Deepen the existing venues, promoters and peer bands through remembered performances, relationships and consequences before adding more towns or cast. Avoid a city map whose destinations are functionally identical.

**BL4 — wider co-writing and balance.** Expand the pilot's character-specific choices and grounded callbacks only after they work. Test song throughput, gig risk/reward and cash pressure empirically; review hypotheses are not proven economy exploits. Keep balance tuning separate from technical correctness and avoid unrelated global formula changes.

## Why these priorities

Source observations below were inspected at the pinned accessible baseline; re-check them at R0.

- [Song workbench](../experiments/playable_flightcase/song_workbench.gd) selects the first active non-leader for its target; [mixing recipe](../experiments/playable_flightcase/mixing_recipe.gd) suggestions mainly cycle fixed arrangement dimensions. This motivates player-selected, retained personal contributions, not a new dialogue-only layer.
- [Mixing recipe](../experiments/playable_flightcase/mixing_recipe.gd) and [producer recipe](../experiments/playable_flightcase/producer_recipe.gd) use an absolute capacity-versus-demand term in the craft modifier. It can penalise spare capability as well as overreach. This is evidence for the fairness test, **not a claim that every final score always falls with higher skill**.
- [Rehearsal intent](../experiments/playable_flightcase/rehearsal_intent.gd) already offers useful activity choices; targeted song/version preparation is the proposed missing connection, not a reason to replace the whole rehearsal system.
- [Gig performance policy](../experiments/playable_flightcase/gig_performance_policy.gd) already connects song and room outcomes. Extend its identity/evidence path and preserve the existing journey rather than creating a second gig controller.
- [Musician chat](../experiments/playable_flightcase/musician_chat.gd) and [career direction](../experiments/playable_flightcase/career_direction.gd) provide the starting points for later commitment/ambition work. Their existence does not by itself establish a satisfying player experience.

**Cut rule:** when scope grows, cut breadth first—additional characters, situations, styles, venues and dashboards. Keep the first slice's causal continuity, one meaningful character contribution, honest feedback and save safety.

**Next authorized action after this documentation handoff:** none automatically. When implementation is requested, start with **SONG53-R0**, reconcile the source and propose one bounded R1 scope; do not restart an old finite worker, infer a deadline or merge anything from historical instructions.
