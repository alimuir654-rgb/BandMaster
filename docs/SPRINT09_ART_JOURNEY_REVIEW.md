# Sprint A — art-led songwriting journey review
**Date:** 2026-10-26. **PR:** #177. **Status:** implementation on branch; release gate not yet satisfied.

## Implemented evidence
- Four real UI states: THE SPARK (lyrical concept, idea, working title), FIND THE SOUND (vibe, arrangement), IN THE ROOM (actual session lead and recorded history), THE SONGSHEET (review then commit).
- Four original SVG scene illustrations with different subject, palette and full-screen ambient treatment. Manifest records origin and pending crop approval.
- Reusable 220ms fade-to-black/scene/fade-back with transition input guard, focus restoration and explicit reduced-motion switch.
- Only the final session button calls Practice.compose; engine retains its existing three writing sessions and one-day economics. Concept and vibe are carried through draft, actual session and finished sleeve, without inventing metadata for old songs.
- Legacy inline songwriting editor retained as a fallback until owner approves new journey; this means the broader ACTIONS screen is **not yet simplified**.
- New tests: sprint09_songwriting_journey_tests.gd (three viewports, transition double-click, four imported illustrations, saved third-session result); sprint09_songwriting_metadata_tests.gd (pure immutability, legacy signature, provenance, reduced-motion).
- Existing screenshot capture extended to render all four journey stages at 390x844, 720x1280 and 1280x720. Screenshot workflow now rejects Godot runtime/script errors even if PNGs were produced.

## Simulated adversarial persona gate (not human participants)
| Lens | Verdict | Evidence and necessary action |
|---|---|---|
| First-time player | CONDITIONAL PASS | Four numbered locations, clear Back/Next, explicit one-day confirmation. Verify first-fold CTA in actual populated captures and no accidental overlay confusion with the legacy editor. |
| Working musician | CONDITIONAL PASS | Lyric concept, vibe, arrangement and leader are recorded; stage two now reacts to vibe choices and stage three includes an actual musician portrait and trait-authored voice. Vibe is editorial identity, not yet a new quality/balance mechanic; keep that transparent. |
| Game critic | CHANGES NEEDED | Four distinctive illustrations, whole-room colour, scene-specific CTAs and bandmate presence now improve variety. However the illustrations remain stylised/schematic and large portions of phone/tablet scenes are passive backdrop. Next sprint must add more cinematic environmental moments and consequential interaction, not another four forms. |
| UI/UX and accessibility | CONDITIONAL PASS | Inspected 12 populated captures at three sizes: no clipped primary action or major art crop, distinct palette and fixed footer. Some supporting text is small; large unused lower-space on tall devices and a narrow centre column in landscape remain polish items. Owner sign-off outstanding. |
| Godot / release QA | FOCUSED CI PASS; FULL CI PENDING | Pure Workshop.develop validates titles; free-form choices persist across reload without spending a day and clear on commit. Focused journey CI passed on commit 67a3ff3; screenshot workflow passed. Full Godot regression and all latest-head checks must still be verified; investigate #170 separately. |

## Mandatory corrective plan if any gate fails
1. Fix CI failures immediately; never merge a red head or rely on an earlier green commit.
2. Inspect actual screenshots. If crop, contrast or scene difference fails, revise art/layout and regenerate all 12 captures.
3. For next art sprint, prefer environmental interaction, character reactions and meaningful choices over more identical selection widgets.
4. Keep the fallback until end-to-end songwriting, save/reload and visual owner approval are confirmed; then replace dense inline controls with a short journey launch and compact songbook.
5. Carry forward all open CHANGES NEEDED/PENDING findings to Sprint B/C and owner sign-off; no unearned release-ready claim.

## CI / visual record
- Earlier PR head `55fd0f4` failed Godot headless: an accidental `_input` native override and two inferred string types. Fixed in `c82f7e4`.
- The original screenshot workflow produced PNGs despite Godot parse errors. This was a false-positive release gate; fixed by per-capture error scanning and requiring a success marker.
- Latest head CI and actual screenshot inspection: **pending**. Use PR #177 Checks and the `bandmaster-ui-screenshots` artifact; do not claim visual approval until examined.

## Actual screenshot inspection — 26 October 2026
Inspected all 12 populated journey PNGs from GitHub Actions screenshot run #208 (commit `67a3ff3`, artifact `bandmaster-ui-screenshots`):
https://github.com/alimuir654-rgb/BandMaster/actions/runs/40300445414/artifacts/12639653710

- **390×844 phone:** stage-specific art and colours are immediately distinguishable; fixed Back/Next and reduced-motion controls remain on-screen; concept/title inputs and musician portrait are visible. Supporting labels and session history could be larger.
- **720×1280 tablet:** legible, no primary CTA clipping, but large empty lower-half areas. Keep atmospheric art but improve scene pacing/content density rather than adding generic cards.
- **1280×720 landscape:** artwork fills the scene and CTA remains fixed. Central creative controls occupy a relatively narrow strip; could use a split cinematic composition with character/environment left and decisions right.
- **Storytelling:** stage two now gives an immediate authored response when vibe changes; stage three shows a real portrait/trait voice. These were added after an initial review flagged a static-form feeling.
- **Verdict:** functional and visually distinct, but **not yet the final modern production-quality art pass**. Human owner approval is still required.

## Corrective CI history
- A first pure metadata test incorrectly skipped the engine's session-progress advancement, producing false failures; fixture corrected and regression rerun.
- Godot 4.7 treats `trait` as a reserved identifier; direct `--check-only` script validation isolated the parse failure and it was renamed to `trait_name`.
- Screenshot capture originally passed despite script errors. It now requires a success marker, rejects script/runtime errors, uses dummy audio to avoid expected ALSA failures, and produces 12 additional journey screenshots.
- Latest reviewed implementation at `67a3ff3`: focused CI passed, screenshot CI passed, structure passed; full headless CI pending at review time.
- Further PR commits require fresh latest-head checks. Do not merge based on the earlier head alone.
