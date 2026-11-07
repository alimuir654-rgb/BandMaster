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

## Songwriting audio (optional, v1)
- `band.members[].audio_bank_id`: stable string allocated on the first successful
  audio commit. It travels with the character when the roster changes order.
- `career_extra.next_audio_bank_id`: next integer suffix, default 1.
- `career_extra.used_song_phrases`: array of `character-id|instrument:phrase`
  strings, default empty. Preview never writes these. A committed phrase remains
  unavailable for new songs, but the current draft can keep/refine its own part.
- `career_extra.current_song_draft.audio_mix`: optional dictionary with
  `source: rehearsam-v1` and `parts` keyed by guitar/bass/drums. Each part stores
  integer `phrase` (0–2), `level_db` (-48..0), `breakdown`, `solo`, contributor name
  and stable `contributor_id`. Finished `song_catalogue[]` entries retain a copy.

Old saves need no eager migration. Missing fields mean no audio, no consumption
and no assigned banks. IDs/consumption and session progress are saved together
only after a valid, successful session. Character audition audio is independent
of these consumable songwriting keys. The prototype shares three source passages
across characters; it does not claim distinct character performances or 50 clips.
