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

## Recorded song phrase use (optional career extension)

`recorded_phrase_uses_v1` is `{version: 1, records: [...]}`. Each record has
`candidate_id`, immutable `hook` (`steady_early_v1` or `steady_later_v1`), and
`project_id`. A candidate/hook pair is unique. Absence means no recorded phrases
have been used; malformed data is held for review and is never reset.

Only sealing the first paid writing session adds records for the current active
guitarists, bassists and drummers. The existing owner saves this extension in the
same transaction as the original session, finances and workbench receipt; failed
persistence restores the entire prior state. Preview, local edits, free saves and
auditions never consume. Later sessions use the first session's project binding
without consuming a changed lineup. Archiving or completing a project does not
refund use. Saved songs play their frozen recipe independently of availability.
Existing save paths, recipe versions and audition data are unchanged.
