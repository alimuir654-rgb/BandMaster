# BandMaster architecture — current baseline and direction

## Verified repository layout (October 2026)
- `project.godot`: Godot project settings; its main scene UID resolves to `band_builder.tscn`.
- `band_builder.tscn` + `Scripts/band_builder.gd`: band creation.
- `main_menu.tscn` + `Scripts/main_menu.gd`: menu.
- `tour_intro.tscn` + `Scripts/tour_intro.gd`: tour and career prototype.
- `icon.svg`: project icon.

All paths are case-sensitive on Linux CI. The scripts currently own substantial UI and gameplay responsibilities; do not assume the target architecture is implemented.

## Optional audio review
`Scenes/AudioReview.tscn` and `Scripts/audio_review.gd` provide an isolated,
save-free review desk. Four parts share an `AudioStreamSynchronized`; a separate
reference player is mutually exclusive. Local private review assets are prepared
by `tools/prepare_audio_review.py`, ignored by Git and excluded from the normal
Android export. The dedicated Android Audio Review preset opts into those assets
and a separate app ID. See `docs/LAST_BUS_GONE_REVIEW.md` for build/review steps.

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
