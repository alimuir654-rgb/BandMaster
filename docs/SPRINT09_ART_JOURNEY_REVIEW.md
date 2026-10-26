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
| Working musician | CHANGES NEEDED | Idea, lyric concept, vibe, arrangement and leader are credible, and three-session chronology is retained. But vibe is currently saved as editorial identity rather than a musical/simulation consequence. Consider a real rehearsal feedback moment before finalising. |
| Game critic | CHANGES NEEDED | New scenes have distinct original art and transitions, but vector illustrations remain schematic. A sequence of selectors alone could feel like four pages of a form. Next art pass should add room-specific ambient action, bandmate presence, narrative payoff and variation by genre. |
| UI/UX and accessibility | PENDING VISUAL REVIEW | Minimum action heights 44–56px, scroll-safe central content, fixed footer, keyboard focus, reduced motion. Inspect 12 populated captures for legibility, controls, crop and contrast. The existing legacy editor below the new entry is a redundancy to remove after approval. |
| Godot / release QA | PENDING CI | Pure Workshop.develop still validates title and prevents duplicates, _finish owns the actual save; tests added for old saves and exactly-once. All required workflows must pass on latest head; check ObjectDB/RID warnings #170 separately. |

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
