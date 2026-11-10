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

## Career musician conversations and shared bills (STORY22)

`musician_chat_v1` is optional `{version:1, records:{candidate_id:record}}`.
Each record retains its stable musician ID, last conversation day, bounded
player rapport, up to twelve authored dialogue turns and an optional plan.
Plans bind their issue day, four-day window, source report hash, starting
fatigue and boolean push intent. Reading/topic selection is free; the owner
accepts one contextual reply per musician/day and refuses replacing a pending
promise. Unknown compatible fields survive; malformed/future recognized data
is held. No audition history or original musician-pair relationship is invented.

The original atomic owner writer reconciles pending promises from genuine new
session reports and matching participant IDs, or observed recovery/deadline.
Clear Air and informal jams cannot satisfy a promised rehearsal. A tired push
can be remembered as strained. Memory/rapport changes alter later conversation
and which further push the musician will entertain; they grant no daily stat
reward. An active gig checkpoint freezes this reconciliation until wrap/cancel
so its career hash remains valid. File replacement succeeds before reconciled
memory becomes live; a failed save preserves both old memory and disk.

`scene_bill_v1`, inside optional `booking_terms_v1`, freezes the promoter pitch,
asked/accepted existing offer ID, original public standing/review restriction,
bill order and stable peer-band IDs. New bands open; established bands may
receive main-support/headline positions. The existing venue, fee, cancellation,
trip, drummer and Finance policies are unchanged. A changed band must discuss
a fresh offer; legacy requests without this extension retain their old behavior.

`scene_encounter_v1` optionally belongs to an existing gig journey checkpoint.
One higher-bill advice choice is possible backstage and one support/help choice
after the player's set. Watching is possible only for acts still above the
player in running order. The original journey revision/source hash protects
input; no new phase, day, payment or settlement occurs at these checkpoints.

The original final wrap applies bounded context-dependent audience/fatigue
effects and records optional `scene_contacts_v1` `{version:1, venues, bands,
processed, receipts}`. Contacts retain played/supported counts; processed
commitment IDs are durable, while the last eighty typed receipts retain the
frozen bill, encounter and actual facts. IDs parse to the original venue/date
and bind to original seen booking slots. Advice can help, do little or hurt;
support earns remembered contacts used in subsequent promoter dialogue/terms.
All effects share the original Finance/save transaction and roll back together.
Legacy bills/contacts remain unknown; no past supports or band friendships are
manufactured.


## Update A: compatible band-life policy (UPDATE24)

`musician_chat_v1` remains version 1. New promises carry `identity` from a per-person
`plan_sequence`, plus `revision_count` (0 or 1). An explicit free revision archives
the exact previous promise in optional `plan_history_v1` `{version:1,records:[]}`
(maximum24); it creates a new four-day agreement once. History entries contain
`identity`, `plan`, `closed_as` (revised/completed) and `day`; visible history uses
the original terminal status, including missed or strained. Old promises remain
readable without these fields. Reading/checking-in never extends a deadline or
changes rapport. New reconciliation stores `effort_evidence` and uses actual
attending-member `direction_notes[].worn` and report direction, falling back only
to recorded pre-session fatigue. Unknown legacy effort is disclosed; resolved
history is not recalculated. New direction notes add `effort`, `fatigue_before`
and `worn` to the original report.

`scene_bill_v1` now dispatches its internal `version` 1/2; version1's constructor
and reconstruction are unchanged. Version2 context adds `local_played` and frozen
available `favors` (band ID to exact favor ID); `set_limit` is1 for a voluntary short
opener and3 otherwise. Crowd pitches without established following receive the
original guest-list tariff; local scene pitches can earn main support from real
played/support history. Prices/travel/settlement remain the original policies.
Only new proposals use version2; existing bills and saved receipts remain valid.

`scene_contacts_v1` remains version1. Its optional `favors` dictionary has at most
one record per authored peer band: `{id,source_commitment_id,used_by}`. IDs bind
to a recorded help wrap. Empty `used_by` means unspent; nonempty means a different,
chronologically later settled commitment. Retained source and consumption receipts
must agree. Helping again while owed never stacks favors. A frozen bill offers
`support.choice=call_favor` with exact `band_id`/`favor_id`. It is consumed only in
successful original wrap, never previews/checkpoints/cancellation or failed save.
Version2 receipt facts add actual `member_fatigue` before/after rows; the nominal
fatigue field allows -2 for reciprocal help. Own-band care eases only actually worn
players. Old bill-v1 receipt bounds remain unchanged; all updates use existing
owner save rollback and once-only journey identity.

## Approved singer/keyboard recipes (INDIE39, additive version5)

Existing recipe versions2/3/4 and recorded_phrase_uses_v1 records retain their
meaning. Version5 uses the version4 fields plus `keys` (14 keys total). `hook`
is one of indie39_plates_01 / indie39_wear_01 / indie39_stairs_01. `voice` pins
Maya/Lily/Sam's canonical candidate ID; `keys` pins Freya/Dan/Oscar respectively.
Hook, voice and keys form the immutable composition identity after the first
paid session. Pace/groove/originality and tone remain source-fixed. Existing
craft calculation, paid accounting, receipt hashing and full rollback are reused.

The new hook's manifest and PCM fingerprints are immutable code-bound source
identities. A live draft/trial/paid write requires its exact active singer and
keyboardist. The first paid cohort records those two IDs in addition to existing
instrument participants in the unchanged three-field phrase-use ledger. Later
stages require the same binding; duplicate phrase use remains unavailable.
Completed saved songs retain their frozen original voice/keys and can play after
lineup changes. No legacy source, character, recipe or saved song is rewritten.
Missing media stays unavailable, never a substitute singer. No Nina clip exists.

Source phrase frames remain fixed (453120 / 403199 / 403199 at48000Hz stereo
PCM16). Approximate onset-derived tempos are presentation clocks, not a claim
of exact bars/key or a live musical performance by the named fictional cast.

New formations store integral lead-vocal stats using the existing loader's
number normalization. Numeric values and genuine fractional stats are preserved;
this avoids a float/int representation change on the first reload. No save
migration or loader change is introduced.
