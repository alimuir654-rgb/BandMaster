# Livin' The Dream — New-game reset: genre → recruitment → band name
**27 October 2026 owner-directed product pivot. DIRECTION CONFIRMED; balancing numbers and screen arrangement are PROPOSALS for review, NOT approved rules.**

## Immediate stop and handover
At approximately 17:51 UK the owner rejected the aggregate S02–S06 screen quality: individual control designs can be retained, but scene compositions and player flow are not acceptable. **STOP all remaining S07/scene-rollout work**, disable the existing evening sprint automation, preserve current draft PR #199 for reference and do not merge it. Do not quietly resume scene-wide sprints until a new first-screen interaction and coherent layout have passed owner review.

## Canonical new-game flow (owner direction)
1. **Choose GENRE first.** This determines the opening pool of musicians (not just its background theme). No band name yet.
2. **Recruit musicians**, using five role tabs: SINGERS / GUITARISTS / BASSISTS / KEYBOARDISTS / DRUMMERS. Each tab should present approximately **six browsable individuals per selected genre**, one focus candidate at a time with previous/next or swipe. The player compares musical strengths and consequences, adds/removes/changes candidates, and watches a persistent lineup bar.
3. **Choose band name after formation.** Confirmation is unlocked only after a valid, balanced lineup has been assembled.

## Singer system (owner-specified attributes, proposed normalization)
Six singing attributes, individually inspectable, 1–10: **Tone**, **Originality**, **Character**, **Presence**, **Soulfulness**, **Lyricism** (the requested lyrical genius dimension). Explicit future influence on songwriting and the live show, not merely cosmetic ratings:
- Tone + soulfulness → vocal fit, melodic communication, vocal character in recordings.
- Originality + lyricism → lyrical ideas, songwriting distinctiveness, song quality.
- Character + presence → stage impact, fan response, in-band dynamics.
Exact production formulas are to be designed and regression-tested once the mechanic is accepted.

Instrumentalists should likewise have six role-relevant attributes (e.g. timing, technique, feel, originality, versatility, presence), with one shared **transparent recruitment talent-cost currency**, but avoid treating loyalty/reliability/chemistry as interchangeable musical skill.

## Hybrid vocalists and lineups (owner direction)
A named individual may be listed in SINGERS and one of GUITARISTS, BASSISTS, KEYBOARDISTS or DRUMMERS if they can sing and play. Selecting them in either tab must recruit the **same person once**; their two positions are satisfied without duplicate cost/headcount or two cloned member IDs. Display clearly which instruments/voice they perform. Multitasking can influence arrangement/live difficulty, but do not artificially prohibit singer/drummers.

**Proposed viable founding lineup:** 3–6 distinct people with coverage of (a) lead vocals, (b) harmonic instrument [guitar OR keyboards], (c) bass/low end and (d) percussion/drums. Three people require a hybrid to cover four functions. Four members are the straightforward, non-penalized default; five and six are valid creative choices. This is a proposed test rule, not yet approved.

## Preventing everyone selecting the best singer — initial balance PROPOSAL
There is no real band budget before formation, so use a clearly visible **starting talent allocation** rather than imaginary money. Proposed first balancing trial, subject to gameplay simulation:
- Total allocation **200 points** for the founding lineup.
- Each individual's base recruitment cost is the sum of six relevant musical attributes (each 1–10), with a transparent **secondary instrument/vocal capability surcharge** of about 8–16 points for genuine skilled dual-roles (not two full recruit costs).
- 3rd and 4th members: **no size tax**. Fifth: proposed +6 organisational points; sixth: proposed +12 additional points (test whether even these penalties are necessary). Talent constraint naturally limits large superstar lineups. Record cost breakdown and remaining points on-screen.
- All candidates must have authentic trade-offs rather than strictly dominated alternatives. For example exceptional **Presence** vs exceptional **Lyricism**; high technical skill vs limited originality; reliable contributor vs brilliant-but-demanding personality. Genre compatibility, chemistry and growth potential influence decisions separately and observably.
- Show lineup previews for **3-, 4-, 5- and 6-member** cases to balance viability. No arbitrary "must hire a fourth" step; combinations should differ strategically.
- Do not turn this into a pay-to-recruit mechanic; actual gig revenue splits, rehearsal coordination and future touring costs can scale with headcount **after** formation, using existing systems.

## Screen/component contract for one testable recruitment vertical slice
- Begin with a restrained, editorial bright DAY background and a genuine purpose-led layout rather than decorative road cases everywhere. Retain proven tactile controls only where functionally appropriate.
- Genre selection: concise identity cards, clear genre differences and a single continue action; no band-name field.
- Recruitment: five stable tabs; large central musician portrait/profile; candidate carousel with prev/next plus touch swipe; six visible attribute meters with native labels and numerals; personality and genre-affinity trade-offs; obvious add/replace/remove.
- Persistent right-side/bottom lineup roster and talent balance. Responsive phone stack; 390×844 first fold must include active candidate, one actionable decision and remaining talent, without scrolling past a hero photograph.
- Keyboard and touch reachable; >=44 **physical** px target sizes; selected/hover/pressed/focus/disabled states; colour-independent progress.
- Artistically evaluate one complete recruitment screen **before** extending to other screens. Individual promising hardware controls are not permission to assemble an incoherent whole.
- Compare real Godot captures at 390×844 / 720×1280 / 1280×720 / 1600×900. Simulated player, musician, material-art, accessibility and engineering lenses should note specific concrete defects. Owner signs off composition and gameplay loop before production wiring.

## Repository findings verified at pivot
- `Scripts/band_builder.gd` currently presents band NAME before recruitment as part of its first `_identity()` screen. `step` 0/1/2 currently means identity/recruitment/review. This directly conflicts with new genre → members → name sequence.
- `Scripts/formation_catalogue.gd` already has **14 genres** but only **13 named candidates total**, most with one declared instrument and one generic skill number. `viable()` currently permits as few as two members if a drummer/multi-instrumentalist exists. The requested six singers per genre and six per each instrument/genre is not yet delivered. Reuse existing canonical IDs and compatible data where possible, enrich them without losing old saves.
- `STATE_SCHEMA.md` describes live `user://band_profile.json` and `user://tour_save.json`; preserve old keys and existing saves. Design a versioned safe migration/adapter for new multirole/skill structures, rather than overwriting or deleting user saves while prototyping.
- Do **not** conflate an independent audition/formation PoC in `poc/` with the current live `band_builder.tscn`: new work must be an isolated prototype until explicitly approved.

## Acceptance sequence / next engineering focus
1. Agree draft recruitment maths and genre roster constraints (numbers remain illustrative until tested).
2. Build **one** genre-driven singing/lineup prototype with six real distinct singer archetypes, exactly-one-person hybrid recruitment, a usable 3-versus-4-member balance example, and isolated deterministic tests; do not mass-generate hundreds of unreviewed profiles or touch production saves.
3. Owner reviews the *whole recruitment layout* and its meaningful choices, not a disconnected component gallery.
4. Expand role tabs and genre pools without changing the approved flow; only after this, add the band-name step and career handoff.
5. Regression: no duplicate IDs, true talent cap and clear spending, valid role coverage, alternatives not strictly dominated, choice persists when switching tabs, genre switch invalidates/reconciles draft lineup with confirmation, zero production save mutations.

**Current status:** specification only. No new recruitment code or visuals are claimed implemented, tested or approved by this document. PR #199 remains a draft scene-era artifact for source reuse, not a merge candidate.
