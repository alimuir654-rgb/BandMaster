# Sprint C corrective mini-sprint — van loading as a real decision
**Parent:** #180 (stacked on #178 and #177). **Status:** implementation submitted, not release-approved.

## Code and test delta
- In LOAD THE VAN, each of up to four listed **owned** but unassigned items now offers a 54px accessible button for every active compatible bandmate. This uses the existing authoritative `Gear.assign` function, not a fabricated loadout economy. The chosen member and gear identity persist through `CareerHub`'s existing save callback.
- Already-assigned items show the actual carrier and condition; legacy unknown-condition items still display UNKNOWN. Incompatible or inactive bandmates are not offered. There is no extra cash/day charge, purchase, repair or premature show settlement.
- Expanded existing three-viewport show-day integration test: amp ownership and shop provenance, Jo loading assignment, disk persistence, duplicate action safety, free navigation, alternate route, incident, live approach and once-only settlement.
- This specifically addresses Sprint B/C reviewer finding that van loading was observational rather than interactive.

## Five simulated persona reviews (not independent humans)
| Lens | Current verdict | Finding / follow-up |
|---|---|---|
| New player | CONDITIONAL PASS | LOAD WITH [NAME] clearly communicates an action and item; still need screenshot evidence at 390x844 and 720x1280 that long gear lists do not bury the next CTA. |
| Working musician | PASS (focused mechanic) | Assigning a compatible bandmate to transport owned equipment is credible; existing condition/role and unknown backline are shown without inventing gear. |
| Game critic | CHANGES NEEDED (overall) | Loading is no longer passive, but arrival is still observational and artwork remains schematic; original #179 premium scene art blocker remains. |
| UI/UX/accessibility | PENDING SCREENSHOT REVIEW | 54px buttons and focus; scrollable story with fixed footer. Must inspect actual 390x844, 720x1280, 1280x720 populated captures on this exact head. |
| Godot/release QA | PENDING LATEST-HEAD CI | Test includes persisted gear holder, zero time/cash spend, duplicate action and original once-only gig settlement. Do not merge without latest-head green checks. |

## Release gate
Hold. No human owner approval. Remaining: authentic venue arrival decision, stronger environmental art, dense legacy UI, global fade-out/in, uninterrupted band-builder-to-gig test and #170 resource warnings. Parent PRs must merge in dependency order, with CI rechecked. No screenshot is claimed inspected on this corrective head until artifact retrieval/review.

## Actual populated screenshot review and corrective change
- Inspected real Godot captures from screenshot workflow **40311125442**, artifact **12644697894**, head `4624717`: LOAD THE VAN at **390x844**, **720x1280** and **1280x720**. The unassigned amp visibly offers `LOAD WITH ALEX` and the fixed `HIT THE ROAD` footer is not clipped. Stage 2 arrival screenshots also generated; no claim of premium quality.
- **UX failure:** phone supporting copy is small; 1280x720 story copy and decision label are visibly undersized even though the artwork and two-plane layout fit. Corrective code now enforces 14px minimum scene copy on phone/tablet, 15px in landscape, and 15px decision buttons. The three-viewport integration test now asserts the font floors.
- The latest typography-fix SHA requires **fresh** screenshot inspection and all CI gates. Do not reuse the green conclusion from `4624717` as latest-head approval. Game critic still **CHANGES NEEDED** because key art is schematic and arrival remains passive.
