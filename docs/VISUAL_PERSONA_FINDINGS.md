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
