# Living the Dream — visual persona defect ledger
**Last inspected:** 26 October 2026. Reviews are **simulated specialist perspectives**, not interviews with actual people. Source screenshots are the owner-photography capture archive generated at 15:32–15:34 (earlier than button changes); never call these latest-head screenshots. Review against a fresh latest-head capture before closure.

| ID | Persona | Severity | Screenshot / viewport | Concrete defect | Owner / next fix | Status |
| --- | --- | --- | --- | --- | --- | --- |
| VIS-001 | Game critic / creative director | P0 | `world-home-landscape.png`, 1280×720 | More than a dozen outlined brown modules, duplicated amber calls to action, almost uniform visual weight; reads like an admin dashboard, not a premium game | Sprint A: replace above-fold grid with hero + one next move + compact status + restrained navigation; before/after comparison | OPEN |
| VIS-002 | First-time player | P1 | `home-mobile.png`, 390×844 | REHEARSE, BAND LIFE, TODAY'S PLAN, GIG DIARY, five world tiles and persistent bottom rail all compete before the player has chosen a direction | Sprint A: one action, three purposeful destinations, secondary actions behind progressive disclosure | OPEN |
| VIS-003 | Working British musician | P1 | `show-journey-0-mobile.png`, 390×844 | Van and gear look plausible, but loading is a text-list of condition percentages and one large assignment button, not the lived-in act of preparing a gig | Sprint B: spatial gear/owner assignment with touch and keyboard parity, real gear condition, no fake items | OPEN |
| VIS-004 | UI/UX accessibility | P1 | `show-journey-0-mobile.png`, 390×844 | Tiny labels and low-contrast green-grey over a busy photo; very large passive image gap before bottom actions; CLOSE and HIT THE ROAD are equal-sized competing actions | Sprint B: structured foreground, stronger type and contrast, one prominent action, 44px targets, focus and reduced motion | OPEN |
| VIS-005 | Game critic | P1 | `show-journey-0-landscape.png`, 1280×720 | Top 40% is cramped photo plus large bordered text block; middle 40% is an uninteractive dimmed photo; buttons are crammed along bottom | Sprint B: photo-led composition, context-sensitive foreground, no giant dead zone | OPEN |
| VIS-006 | Godot/release QA | P0 | Godot CI run 40357348493, commit fd0e8585 | `tests/v94_woldui_states_tests.gd` rejected themed CTA border: four genre accent mismatches | Fixed in commit 5db0f057, but **retest pending** on subsequent head | FIX COMMITTED, UNVERIFIED |
| VIS-007 | UI/UX accessibility | P1 | Title menu code `Scripts/main_menu.gd` | Independent `Button.new()` styling lacked shared keyboard focus and consistent states | Switched to `UI.button()` in 5a27ab75; latest-head screenshot/CI pending | FIX COMMITTED, UNVERIFIED |
| VIS-008 | British musician | P1 | `show-journey-1-landscape.png` | Urban traffic photo does not establish believable UK band touring | Rights-cleared UK van/motorway/service station photo and actual scene crop | OPEN |
| VIS-009 | Godot/release QA | P1 | `Art/Photography/SCENE_ASSIGNMENTS.json` | `approved` folder name does not prove legal approval; rights flags remain pending | Individual photo-page, people, brand, property and generated-image provenance audit | OPEN |

## Sprint review protocol
Each new sprint must append a dated section with five distinct verdicts: new player, British musician, game critic, UX/accessibility and Godot QA. Each verdict requires a real screenshot/state/viewport or executable test reference, one or more defects, severity, an accountable corrective task, and retest evidence. Do not repeat prior verdicts as new findings. Carry open P0/P1 defects into the next sprint and block release until resolved or explicitly accepted by the owner.

## Review checkpoint — 26 October 2026, initial photo screenshot inspection
- **New player: FAIL (VIS-002).** Too many same-priority controls before choosing a direction.
- **Working British musician: CONDITIONAL (VIS-003, VIS-008).** Van art credible; interactions and UK travel not yet.
- **Game critic: FAIL (VIS-001, VIS-005).** More functional than designed; composition fails flagship quality bar.
- **UX/accessibility: FAIL (VIS-004, VIS-007).** Text and action hierarchy weak; shared button change unverified.
- **Godot QA: FAIL at inspected commit (VIS-006).** Latest failing Godot CI found and targeted fix committed. New-head verification required.

**Release gate: HOLD.** The first shared button change is not a visual reinvention. Owner visual approval is outstanding.

## Sprint A implementation review — 26 October 2026, photo-led Band House

**Evidence:** Actual Godot screenshot artifact from workflow run [40364364434](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40364364434), commit `1a779efd`: `world-home-mobile.png` 390×844, `world-home-tablet.png` 720×1280, `world-home-landscape.png` 1280×720. This is a **simulated** six-role design review of rendered pixels, not external user testing. Compared with pre-redesign artifact run `40359538555`. The screenshot run succeeded; headless CI failed on legacy source-string tests at that commit. Subsequent fixes require a fresh visual retest.

| Persona | Verdict on inspected capture | Concrete observation | Severity | Corrective code and next gate |
| --- | --- | --- | --- | --- |
| Creative director | **FAIL** | `world-home-mobile.png`: hero is recognisably different but background repeats a busy music collage beneath it, destroying visual focus; oversized empty lower canvas | P1 | `c70d1c8` adds a solid deep-navy home backdrop; recapture and reassess composition. |
| Principal UI engineer | **FAIL** | `world-home-mobile.png`: DAY 12 wraps vertically at top right; hero shrank to content height because the nested `custom_minimum_size.y` assignment did not enforce 440px | P0 | `c70d1c8` sets full `Vector2` minimum and fixed-width non-wrapping day label; verify at 390/720/1280. |
| Interaction designer | **CONDITIONAL** | `world-home-landscape.png`: one amber next action and three destination buttons improve hierarchy; secondary Gear/Scene remain button-like and there is still a redundant Save/Menu control | P1 | `9ad2188b` quiets nav; Sprint B should convert low-priority actions to understated links and audit keyboard focus/feedback. |
| Working British musician | **CONDITIONAL** | `world-home-tablet.png`: headphones/notebook photograph signals music work but not a specifically British rehearsal house or working band | P1 | Evaluate alternate owner-uploaded rehearsal photo and location-specific details; verify rights before release. |
| New player / game critic | **CONDITIONAL** | `world-home-mobile.png`: primary REHEARSE is now obvious and destinations reduced to three, but crowded below-hero text and busy backdrop remain | P1 | Verify new dark canvas and larger hero in latest screenshots; then reduce below-hero secondary controls further if needed. |
| Godot QA / release engineer | **FAIL at inspected commit** | Godot run `40364364345` failed old v29 UX assertion; later run `40364855464` failed old v36 dashboard assertion. These assertions required the discarded card-grid layout, not functional simulation | P0 | Tests updated in `fe18e377`, `5a1f09b3`, `c3206ce5`, `d2001f4c`; **latest-head full CI must pass**. Verify save/load and once-only gig rewards in subsequent end-to-end acceptance. |

**Measured change, not quality proof:** first revision vs baseline changed approximately 44% of mobile screenshot pixels by a mean-channel >32 threshold, 43% on tablet and 44% landscape. This is a substantial composition change but **does not imply design acceptance**.

**Release gate: HOLD.** P0 visual wrapping/height and CI corrections are committed but require new rendered evidence. P1 authenticity, secondary-action hierarchy and image clearance carry forward. No human/owner visual approval has been inferred.
