# BandMaster state schema

This is an inventory and migration policy, not a full formal JSON schema. Check current source before editing fields.

## Known persistence paths
- `user://band_profile.json`: band profile data (see `Scripts/band_builder.gd` and consumers).
- `user://tour_save.json`: tour/career state (see `Scripts/tour_intro.gd`).

The `user://` scheme resolves to Godot's per-user data area, not the repository.

## Change policy
- Treat current saved keys, member structures and nested dictionaries as a backward-compatibility contract until inventoried.
- Do not rename, delete or change a saved key's type without a migration and an old-save regression fixture.
- Unknown or missing fields should be handled deliberately, with validated defaults where safe.
- Planned improvement: add a numeric `save_version` and explicit migration steps after confirming the current format.
- Test new game -> changes -> save -> restart -> load and validate all key gameplay values.

## Next audit
Document exact keys, data types, ranges and authoring locations from all three live scripts before the first save-format change.
