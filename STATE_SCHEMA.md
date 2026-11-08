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

## Audition conversation and musician connections (CHAR01)

An audition active record or completed receipt may contain `band_conversation_v1`:
`{version: 1, revision: 0..2, answers: {...}}`. Supported question keys are
`working_style` (`shared`/`direct`) and `commitment` (`dates`/`regular`). Each
question is answered once; its saved revision equals the number of answers.
A newly requested musical adjustment adds an empty marker if no questions were
answered. Old absent records remain valid and do not invent past conversations.
The original four phases, authored content pins and recruitment cost checks are
unchanged. Expected tokens retain four legacy keys until this extension exists;
then `conversation_revision` binds later explicit actions against stale input.

On actual band formation, invited current musicians' supported interaction
records are projected atomically into optional career `character_connections_v1`:
`{version: 1, records: {candidate_id: {...}}}`. Records retain stable candidate and
audition IDs, conversation, actual musical request, bounded player rapport
(-20..20) and attended-practice count. This is player-to-musician memory, separate
from musician-pair `relationships`. Authored starting stats are not overwritten.
Existing records and unknown compatible wrapper/record fields are preserved.
Malformed/future recognized data is held rather than reset.

An explicit rehearsal direction is a local `{focus: precision|listening,
effort: steady|push}` draft. Only the existing paid rehearsal applies its
condition/attendance/history-dependent effects, before the existing Finance and
owner save. The saved rehearsal report retains direction, individual notes and
actual final deltas. Failed persistence restores the whole previous career,
including rapport/counts, and retains the local draft. No-plan model calls retain
the original legacy behavior; previews, audio replay and biography reading do
not charge, consume phrases or increase relationships.
