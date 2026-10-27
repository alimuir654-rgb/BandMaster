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

## OWNER MOCKUP APPROVAL + RECRUITMENT IMPLEMENTATION PREFLIGHT — 27 Oct ~18:00 UK
**Real owner approval:** dark road-case recruitment layout accepted as starting direction. Follow-up: candidate portraits and all six red-to-green talent meters below portrait, meaningful bio/experience/prior bands/troublemaker/personality notes, use existing dark photographic transport keys, mix men and women, natural UK names (avoid all-US naming). Owner explicitly says "go ahead", authorizing isolated recruitment implementation, **not** resuming stopped broad scene rollout or merging old PR.
**Scope:** one testable genre-first → browse 5 role tabs → allocate talent → name-last PoC, scene `poc/ldtd_recruitment_v3.tscn`, script `poc/ldtd_recruitment_v3.gd`, pure data model `Scripts/recruitment_catalogue_v3.gd` and tests. Preserve old live `Scripts/band_builder.gd` and saves unchanged. Reuse actual committed source-backed portraits if available; for candidate images not yet sourced, deliberately display a clearly identifiable identity placeholder, do not invent/proclaim real headshots. Photographic portrait intake for all candidates is a release blocker, not a gameplay blocker.
**Verified source:** PR #199 head at start `c2e0501d7a67dd3c631e87f4a86a1a4632eb85d0` (draft, unmerged); GitHub last workflows GREEN. `Scripts/formation_catalogue.gd` defines 14 genre names, only 13 candidates in old builder; `Scripts/band_builder.gd` names band first and currently allows two-person lineups; `Scripts/member_portrait.gd` supports real source portraits for alex/jo/sam/dev only and otherwise letters, not true photos; five-state `Art/UI/FormationCraft` committed but muted art direction differs from approved dark recruiting board.
**Five simulated warning lenses:** player — talent cost/covered roles must be obvious at all times and clear before committing. Musician — 3-person formation needs distinct multi-role, four musicians must feel natural. Art — avoid reused mismatched paper UI and never substitute fake photographic headshots; prioritize whole composition. Accessibility — candidate and action above fold on 390 and 1280, six labeled high-contrast meters and keyboard controls. Release — separate new draft local state from old JSON, unique IDs/hybrid counted once, test deterministic per-genre candidate pools and budget, no CI claims without actual evidence.
**PRE-FLIGHT: PASS — isolated recruitment vertical slice only.** Any new balancing values remain labeled trials. Outstanding pinned-note requirement remains deferred unless formation material is touched.

## V3 implementation checkpoint / five simulated review lenses — 27 Oct ~18:25 UK
**Code in isolated draft:** `Scripts/recruitment_catalogue_v3.gd`, `poc/ldtd_recruitment_v3.gd`, `poc/ldtd_recruitment_v3.tscn`, `poc/ldtd_recruitment_meter.gd`, `tests/ldtd_recruitment_v3_tests.gd`, `tests/capture_ldtd_recruitment_v3.gd`, and dedicated `.github/workflows/ldtd-recruitment-v3.yml`. Existing live `Scripts/band_builder.gd` and JSON save paths untouched; no production connect, no main merge.
**Player — P1:** User can browse six per tab/genre and see 200-point resource and lineup, name step last; need inspect whether portrait and first meaningful choice appear together at 390. 
**Musician — P1:** Eight curated singers (mix of men, women, non-binary), seven archetypes per instrument, 36 stable unique identities, detailed band history and personality; multirole singers counted once, genre rotates six-person windows from curated pools. Trial role coverage vocals + harmonic + bass + drums; 3–6 roster accepted by model under talent cap. Not yet an accepted economy.
**Visual/material art — P0 open:** Only source-backed Art/Portraits/indie/alex, jo, sam, dev exist. Other profile IDs intentionally show native identity cards + honest PHOTO ART PENDING caption, not fabricated or reused photographs. The six singer headshots and additional 32 portraits require real consistent fictional character media. The on-screen paper dossier is functional and editing-native, but Godot screenshots from final revision need owner inspection.
**Accessibility — P1 active:** First Godot deterministic test succeeded in run 40558554811; screenshot gate failed on 390 physical >=44px test, so `_touch_factor()` and minimum physical hit/font sizes patched on later head, and diagnostic failed-image capture added. Do not mistake the earlier failure for an art pass. Tests specifically keep six red->green meters inert, with real zero and full.
**Godot/release — P1:** Focused model/UI suite passed from actual Godot 4.7.2 run 40558554811, but final head `61358c1081edc604c1a4f7728e16680b5dcdce2a` has targeted screenshot/render run [40559345507](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40559345507) pending/in progress as of checkpoint; verify exact last-head test/actual PNGs before engineering-complete report. No user:// or production save writes, deliberate no photo-ID aliasing.
**Open fixes:** verify 390,720,1280,1600 native screenshots and physical tappable interactions. Assess shortlisted candidate visual composition with owner, then commission/source individually traceable consistent portrait assets for six initial singer candidates. Do not resume scene S07/full integration without owner approval.
