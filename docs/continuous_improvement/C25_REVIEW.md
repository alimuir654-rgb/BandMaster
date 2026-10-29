# C25 — approved cast imported and scored

## Delivered
The exact owner-approved 18-person generated casting reference is now committed at `Art/References/ApprovedCast20261029/approved_cast_reference.png`, along with 18 unscaled, label-free small preview crops, a source/crop/hash manifest and explicit limitations. No new independent portrait masters were generated. The reference is approved for casting; global artwork/game-balance approval remains false.

Source: 1536x1024 PNG, SHA256 `52968f3fd0d2cc9b1b477088421921b771a30e62445bd2ad88b87929f809327f`. AI-generated fictional casting sheet, not real photographs, not CC0, not a model-release claim. Preview widths222–240 and heights226–228 remain honest native resolution; do not enlarge these into claimed production portrait masters or use the labelled full sheet as a game screen.

The additive catalogue is `Data/CharacterCast/approved_cast_2026-10-29.json`; human-readable scores are `Data/CharacterCast/SCORES.md`. Guitar5, singers4, drums3, bass3, keys3. Six musical scores per role on1–10, with separate authored reliability/collaboration values, biographies, strengths and friction. All names/traits/ages/towns are fictional design content, not inferred from appearance. New IDs use `cast_`; existing Alex Vale/alex, Nia Griffiths/nia_griffiths and sam/Sam Clarke remain unchanged.

Two wildcards WITHIN the approved18, not20 new people: Bex/guitar56talent, reliability5, collaboration2; Sam/vocals55talent, reliability3, collaboration3. Their advantages and drawbacks are explicit, without a hidden cost discount. Existing recruitment formula and200talent budget are reused, including fifth-member overhead6. Of540 one-per-role lineups,274 fit the budget; cheapest152. Maya/Jack/Zoe/Dan/Casey costs178. Sam/Tom/Ben/Dan/Ellis costs176. Nina/Bex/Ben/Dan/Ellis costs180. Both stars with cheapest bass/keys/drums costs204, requiring an actual recruitment trade-off.

## Integration boundary
`experiments/character_cast/catalogue.gd` is an opt-in adapter with `people`, `combined_people`, `by_id`, `pool`, `cost`, `stats_for`, `labels_for` and `rehearsal_risk`. It does not replace a live career screen or mutate saves. Behaviour/risk values are authored metadata; personality penalties are NOT yet wired into existing gameplay. The next overnight gameplay writer should expose these traits honestly in recruitment and connect them through existing rehearsal/relationship models, not invent a competing economy or silently claim consequences already operate.

The original recruitment catalogue was absent from the checked-out working branch despite a previously fetched excerpt. First native setup therefore failed; this BM-15 recurrence was logged before correction. The corrected adapter reuses the exact existing repository blob `9c40d3ae04558195e09961471c67e4e7952009a7` from read-only PR199 source commit `c084690f7ccde4625eaebf68b89ae476fd08724d`, vendored under the isolated experiment. The current formation catalogue remains the dependency. No production rule script was replaced.

## Verification and publication
Tested code: `e11a89f7ad3f52b55c956d3bbc4a815aff218400`.
Successful cast/import/publication run: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40969779247
Actual publication commit: `c330c1feb0cd3aa3df3a25bf7e8a44a6e5628482`.
Godot4.7.2 targeted headless data/rule tests:270checks, zero failures. This is native engine logic verification, NOT a rendered recruitment screen or new four-viewport gallery.
Other tested-code checks: structure40969779374 SUCCESS; improvement gate40969779198 SUCCESS; full existing headless/regression40969779234 SUCCESS.
Artifact12939198737, `c25-approved-cast-evidence`, 4409650bytes, downloaded SHA256 `401de73bb1df5d64aa71174e31077917b0a78de33b06668494f2a3ae655b4ab0`.
Downloaded archive safely extracted; exact original image SHA and all18 manifest derivative hashes independently verified. Opened `BandMaster_C25_Cast_Scores_Review.png`, composed at original crop scale from the downloaded artifact; inspected all18 actual crops including Bex and Sam. Faces remain visible and baked names/role panels excluded. This review sheet is explicitly labelled non-native; no screenshot claims.

Tests cover role distributions, six-score ranges, real model cost, affordable recruitment, viability, duplicate prevention, exact removal refund (including fifth-member overhead), re-add restoration, overspend rejection, deep-copy independence, canonical identity preservation and image load/dimensions. Full gameplay balancing and active trait consequences are still unverified.

## Five simulated lenses
- Art direction: approved natural starting-out casting retained; same-person instrument variants not imported. Actual photo regions suit small contact previews only; no false high-resolution claim.
- Technical art: exact source hash and18 crop manifests verified; generated-reference rights basis explicit. No enlargement or baked card labels in preview crops.
- UI/accessibility: six musical labels and statistics follow the existing role contract; behaviour fields separate. No UI layout/input change or four-viewport screenshot claim in this data-only task.
- Godot engineering:270focused tests pass using byte-exact existing rules; production identity, meter/control sources and saves unchanged. Missing-branch dependency correction logged and pinned.
- QA/producer: assets truly published and retrieved, not just staged. Initial balance has meaningful affordable options and two costly high-friction picks; not a full balance-playtest claim. Next effort belongs to connected gameplay, not more frames or casting generation.

## Next action
Resume the already-authorised overnight flight-case playable slice. Use this opt-in scored cast in recruitment and carry selected IDs/traits into existing songwriting/rehearsal logic; show genuine consequences only when tested. Preserve canonical identities and source limits. Park notebook/optional art, freeze implementation at08:00 and report evidence at09:00 Europe/London30October2026. No additional schedule, main/PR199 edit, purchase, merge or production-save mutation is authorised by this closeout.
