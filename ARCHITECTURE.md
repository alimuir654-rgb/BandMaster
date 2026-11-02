# BandMaster architecture — current baseline and direction

## Verified repository layout (October 2026)
- `project.godot`: Godot project settings; its main scene UID resolves to `band_builder.tscn`.
- `band_builder.tscn` + `Scripts/band_builder.gd`: band creation.
- `main_menu.tscn` + `Scripts/main_menu.gd`: menu.
- `tour_intro.tscn` + `Scripts/tour_intro.gd`: tour and career prototype.
- `icon.svg`: project icon.

All paths are case-sensitive on Linux CI. The scripts currently own substantial UI and gameplay responsibilities; do not assume the target architecture is implemented.

## Direction (not yet implemented)
- **GameState**: authoritative cash, band roster, relationships, equipment, career and time.
- **Simulation systems**: rehearsal, skills, finances, travel, gigs and fatigue as separate testable units.
- **Action service**: handles user-chosen actions such as buying equipment, practising and hiring staff.
- **Event provider**: state-driven native rules first; optional Ink or AI-generated prose later.
- **Save service**: versioned migration-aware persistence with round-trip tests.
- **UI**: reads state, dispatches actions, animates presentation; does not secretly own gameplay rules.

## Engineering policies
- Extend existing functionality before relocating it into new components.
- Add reproducible tests for mechanics and save schema before major refactors.
- Keep player control active between occasional story decisions.
- External AI is not required for emergence: start with deterministic triggers, parametric templates and seeded RNG.

## Decision presentation policy

Choices preserve uncertainty: explain in-world actions and stakes, while keeping nonfinancial outcome math, odds and hidden gates internal. Do not reveal a stat-direction answer key through tooltips, disclosures or confirmations. Explicit prices/time and actual state remain readable; saved consequences may be reported after commitment. Presentation hides forecasts without changing the deterministic resolver, eligibility, costs, save format or once-only settlement. Owner direction: 2 November 2026, superseding pre-choice delta previews.
