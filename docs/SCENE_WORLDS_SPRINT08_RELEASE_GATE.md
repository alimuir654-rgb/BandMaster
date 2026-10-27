# BandMaster — Sprint 08/08 Convergence, Typography and Release Gate
**27 October 2026.** Sprint 08 branch `visual-sprint08-convergence-typography-release-gate`, draft PR #192 stacked on #191. **No production merge; owner visual approval OPEN.**

## What is actually delivered
- Three isolated playable PoCs already exist: tour planning `poc/tour_planning_journey.tscn` (Sprint 03), songwriting `poc/songwriting_journey_poc.tscn` (Sprint 05), gig-night `poc/gig_night_journey_poc.tscn` (Sprint 07). These are not wired into the production career router and do not modify live saves.
- Sprint 08 imports **actual licensed font binaries**: Barlow Condensed SemiBold (headlines), IBM Plex Sans variable (body/buttons), IBM Plex Mono Regular (instrument readouts), plus SIL OFL notices. Exact upstream Git blob hashes are recorded in `Art/ASSET_MANIFEST.md`.
- `Scripts/scene_world_typography.gd` centralises semantic roles, and the **runnable isolated review launcher** `poc/scene_worlds_convergence.tscn` switches three families and simulated day/dusk/night. It can launch the three earlier journey PoCs without accessing production career saves. `tests/scene_worlds_convergence_tests.gd` and the 18-image renderer workflow check font import, colour contrast, focusable primary, mobile-first action and background.
- Previously captured *actual Godot* screenshot artifacts are linked below. The six-image mobile/desktop side-by-side inspection is based on original Sprint 03/05/07 captures, **not generated mockups**. New Sprint 08 gallery captures are a separate CI gate; don't confuse them with owner-approved hardware artwork.

## Eight-run ledger (verified preceding-run evidence)
| Run | Scope | PR | State / evidence |
| --- | --- | --- | --- |
| 01 | Shared day/dusk/night palettes and theme contract | #185 | Draft; real 390/720/1280 screenshots and theme tests |
| 02 | Tour road-case, itinerary and van latch controls | #186 | Draft; 17-image cumulative screenshot artifact |
| 03 | Playable tour choices and dusk arrival, real game tariff model | #187 | Draft; [23-image actual Godot run](https://github.com/alimuir654-rgb/BandMaster/pull/187) |
| 04 | Daylight notebook and arrangement controls | #188 | Draft; 6 actual renderer captures |
| 05 | Playable three-session original song journey | #189 | Draft; 9 actual renderer captures |
| 06 | Gig-day stage cue controls and interlocks | #190 | Draft; 9 actual renderer captures |
| 07 | Real gig approach and once-only show settlement in local copy | #191 | Draft; [four successful final-head workflows](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40459332851), 12 actual renderer captures |
| 08 | Cross-family review launcher, actual OFL font import, release gate | #192 | **Check latest-head CI and 18 screenshot artifact; owner approval still OPEN** |

The production repository's `main` branch has not received the seven draft visual implementations. PR #184 was the merged planning document. PR #183 is a separate, untouched dashboard PoC; do not conflate it with the scene-world stack.

## Observed design quality — actual screenshot comparison
- **PASS, theme distinction:** day backgrounds are materially light (#ECE7DA); dusk petrol (#283941); night graphite (#0B1116). The six compared tour/songwriting/gig mobile and desktop Godot screenshots visibly maintain this distinction, and the theme's colour contrast assertions were tested previously.
- **PASS, isolated game rules:** tour previews real costs/van wear, songwriting validates titles and consumes one simulated day per session, gig journey settles once using existing gig engine. None of these PoCs writes a real career save.
- **P0, premium visual identity NOT ready:** approved Lab 05/07/08.4 photographic hardware assets are still outside the GitHub `Art/UI` tree. Repository `Art/UI/Tour` contains two original SVG prototypes and `Art/UI/Songwriting` one paper SVG prototype. Do not substitute these for owner-approved image-backed controls or claim equivalence.
- **P1, daytime scene photo:** gig load-in uses a dim, indoor performance/backstage photograph even though the surrounding canvas is light. Tour and songwriting also need more convincing day-specific photography and art direction. Actual day screenshot review shows the discrepancy.
- **P1, landscape layout:** at 1280×720, all three scene PoCs occupy narrow centred columns with substantial empty side space and relatively small information type. They meet first-fold technical gates but do not yet meet the premium desktop design bar. Tablet whitespace persists in writing/gig layouts.
- **P1, typography integration:** real fonts are now imported, but only the isolated Sprint 08 gallery uses the role contract. Existing PoCs and production screens remain on fallback typography until a deliberate migration and screenshot regression.
- **P2, accessibility:** touch targets and primary CTA were programmatically checked at the required viewports in prior runs, but keyboard/gamepad traversal, high-zoom long labels, screen reader equivalents and reduced-motion scene transitions require an integrated hands-on review.

## Five simulated adversarial reviews (not real human approval)
1. **First-time player:** single primary CTA is visible in the three journeys; concern: stage/strategy choices and multi-step composition need a concise context label and progress explanation before real integration.
2. **Touring musician:** equipment and soundcheck gates make practical sense, and tour costs use actual simulation values; concern: day gig imagery and hardware material are not authentic enough to convey the moment.
3. **Management-game veteran:** explicit cash/van/fatigue and gig approach preview, one-time settlement are credible; concern: scene PoCs are not yet connected into a complete career-to-tour-to-show loop.
4. **UX/accessibility:** mobile fixed actions and theme contrast pass previous screenshot gates; concern: desktop whitespace, small secondary text and the selected/disabled visual states need stronger visual QA with imported fonts.
5. **Godot/release QA:** local state isolation and existing engine calls protect the production game; concern: final CI on #192, imported-font Android rendering, main-scene routing, old-save load and rollback are still unverified.

## Controlled integration and rollback order — do not skip gates
1. **Owner visual gate:** compare actual rendered scenes with Lab 05/07/08.4 approved reference sheets; obtain the original separated PNGs, rights/provenance and production-safe exports. Explicitly approve/reject the road-case, writing and stage hardware; no bulk migration beforehand.
2. **Day photography:** create/import coherent bright daytime tour desk, rehearsal desk and venue load-in photographs; dusk/night alternatives. Keep dynamic text in Godot and provenance in manifest.
3. **Typography integration:** adopt role contract in isolated PoCs first; verify Barlow/Plex line wrapping at 390×844, 720×1280, 1280×720 and desktop, with legible buttons and readouts; validate font licence notices and Android import.
4. **Responsive redesign:** widen desktop composition or use contextual side rails, remove tablet dead space, preserve fixed primary actions and 44px targets; screenshot-review each populated phase.
5. **Gameplay wiring:** integrate one scene family at a time behind a reversible feature flag/route. Preserve exact-once payouts, save/load and prior gameplay semantics. Test full formation → write → rehearse → book → load → travel → soundcheck → show → aftershow → save/reload.
6. **Release gate:** CI green on final integration head, 3-viewport real screenshots inspected, regression/old-save/Android tests green, no unlicensed art, explicit owner visual sign-off. Until then **RELEASE HOLD**.

## Evidence and reproducibility
- Earlier real Godot screenshot artifacts: [tour run #187](https://github.com/alimuir654-rgb/BandMaster/pull/187), [writing run #189](https://github.com/alimuir654-rgb/BandMaster/pull/189), [gig run #191](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40459332851/artifacts/12713298954).
- Run local Sprint 08 specimen: `godot --path . --scene res://poc/scene_worlds_convergence.tscn`. Headless: `godot --headless --path . --editor --import --quit`, then `godot --headless --path . --script res://tests/scene_worlds_convergence_tests.gd`.
- New 18-capture workflow: `.github/workflows/scene-worlds-convergence.yml`. Its final run, artifact and visual inspection must be linked in PR #192 after completion. Do not report runtime PASS based on source existence.
- This gate document is a review record, **not** a claim that the new controls or the game are release-ready.
