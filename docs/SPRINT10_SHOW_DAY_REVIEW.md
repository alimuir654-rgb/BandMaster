# Sprint B — five-place show-day journey / evidence and adversarial gate
Date: 2026-10-26. Stacked on Sprint A branch because PR #177 remains open. Do not merge until Sprint A is merged or retargeted and the latest Sprint B head has all required checks green.

## Implemented
- Five full-screen scenes: LOAD THE VAN (real equipment/van/readiness status), ON THE ROAD (existing overnight/drive-home plan, free replan), VENUE ARRIVAL (actual booking), SURVEY & SOUNDCHECK (real set approach, conditional bassist illness with consequences), BACKSTAGE/SHOWTIME (actual originals and one-time gig engine).
- Each stage has original art and distinct full-screen colour atmosphere; 220ms fade reuses Sprint A JourneyFade and input guard; reduced-motion toggle and keyboard focus restoration.
- Pure ShowDayJourney uses the existing GigNight phases, Calendar.replan, Backstage.resolve, GigNight.choose_set and Calendar.perform. Free navigation is saved as show_journey_progress keyed by booking venue/day; old saves fall back to the existing arrival/soundcheck/stage phase.
- No duplicated fees, van wear, travel deductions, show rewards or day spending. Final settlement remains CareerHub._perform_gig → Calendar.perform.
- Legacy show-day controls remain below the new journey entry for regression safety. **This is an explicit Sprint C simplification blocker.**
- Five original SVG assets documented in Art/ASSET_MANIFEST.md. No claim of missing third-party photos imported.
- Added three-viewport real interaction/disk regression and 15 populated screenshot captures to CI.

## Simulated persona review — not human playtesting
| Lens | Initial verdict | Evidence and corrective action |
|---|---|---|
| New player | CONDITIONAL | Five numbered locations and prominent entry CTA; action label shows next destination. Need actual phone first-fold crop review; legacy controls remain overly dense behind journey. |
| Working musician | CONDITIONAL | Gear loading, journey, venue arrival, soundcheck, backstage and approach choice follow credible sequence; show settlement remains after stage. Bassist illness resolves at soundcheck. More crew/promoter character moments could deepen authenticity. |
| Game critic | CHANGES NEEDED | Five environmental palettes and original art are more distinctive than a generic card stack; scenes 0 and 2 still primarily narrative and advance, not consequential choices. Sprint C must enrich environmental interactions and differentiate the overall game. |
| UI/UX/accessibility | PENDING SCREENSHOT REVIEW | 54px focused buttons, scrollable story, fixed footer, 220ms fade, reduced-motion. Need inspect actual populated PNGs at 390×844, 720×1280, 1280×720; confirm footer not clipped, typography and contrast. |
| Godot/release QA | PENDING CI | State progression uses authoritative engines and is keyed by booking; 3-size integration fixture covers travel replan, illness, approach, save, once-only settlement. Must verify latest-head structure, full headless, focused show-day and screenshot CI. |

## Stop/go release policy
Any red latest-head check or unreadable/clipped screenshot is a blocker. Correct implementation and rerun checks; no release claim based on earlier green runs. Actual visual quality remains provisional until populated PNGs are examined. Owner visual sign-off is separate.

## Carry to Sprint C
- Remove dense legacy show controls only after new journey passes all regressions.
- Distinct visual identity for formation/home/band/studio/gear/promoter and transition between tabs.
- Complete new band → writing → booking → journey → show → scrapbook → save/reload acceptance.
- Resolve or characterize resource/RID warning issue #170; record evidence.
- Upgrade schematic vector artwork if real populated crops fail game-critic/owner expectations.

## Actual screenshot inspection and corrective loop — 26 October 2026
Inspected **all 15 populated show-day PNGs** from screenshot workflow run 40304062853 (head ffca31c, artifact `bandmaster-ui-screenshots`): https://github.com/alimuir654-rgb/BandMaster/actions/runs/40304062853

- **390×844:** five distinct full-screen palettes and environmental illustrations, fixed primary action and Close/Reduce Motion controls, no observed clipping. Added a five-part progress rail and an authored line spoken by an actual roster member after the initial captures showed a large passive lower region. Gear loading now exposes owned-item holder/condition and explicitly labels unknown venue backline rather than inventing equipment.
- **720×1280:** improved after correction: story callout occupies the previously empty lower section while preserving the large illustration. Artwork is still schematic and does not yet meet final art-production ambition.
- **1280×720:** CTA and scene progression remain visible, but the narrow central content column leaves too much unused horizontal space. **UI/UX verdict CHANGES NEEDED** for landscape split composition; tracked in issue #179.
- **Game critic:** still **CHANGES NEEDED**. Five atmospheres are different and the soundcheck/road scenes have consequential decisions, but loading/arrival lack a memorable interactive environmental beat. Issue #179 blocks full visual release sign-off.
- **Working musician:** conditional pass: bassist fatigue intervention, route choice and set strategy are real mechanics, not decorative choices; venue backline is deliberately marked unconfirmed.
- **New player:** conditional pass: clear numbered location, destination CTA and bandmate reaction; first fold and typography remain owner-review items.
- **Release QA:** initial focused CI found a genuine bug: JSON converted integer booking days into `7.0`, changing the backstage incident identity. Fixed by canonical integer keys plus compatibility for prior `7.0` records. Pure regression now covers both formats; final latest-head checks still required.

**Decision:** Sprint B is a playable, screenshot-inspected vertical slice, **not** a finished premium visual release. Carry issue #179 to Sprint C, prioritize split-screen art composition and scene interactions over more mechanics. No owner visual sign-off claimed.
