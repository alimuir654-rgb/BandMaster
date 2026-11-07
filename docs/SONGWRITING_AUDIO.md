# Songwriting phrase prototype

In Career → Writing Room → Jam/Songwriting, the new **Build Your Band's Sound**
panel offers matched passage families for guitar, bass and drums when private
audio is installed, plus the archived original three-phrase bank. Each instrument draws from the first active matching band member.
An active guitarist, bassist and drummer are needed to use all three parts.
Writing without audio remains available.

The passage-family selector now adds **Steady Hundred / Early** and **Steady
Hundred / Later**, using the source ranges 4.8–14.4 s and 19.2–28.8 s respectively.
Each has one matched guitar, bass and drum-kit part. Choose the family as a unit;
these two sources cannot be accidentally mixed together within one composition.
Their musical style labels and boundaries remain provisional: the owner heard
two styles, but the assistant has no listening tool to confirm these exact cuts.
Both run 9.6 s. Breakdown follows the current family's midpoint, not the older
9.48-second timing. Drums include matching Percussion at a common gain; all five
full-quality source originals remain separate and unchanged.

Saved Rehearsam compositions still load their original recordings. The older
three-phrase bank is retained under **Rehearsam Loop / Original Bank**. Consumption
is isolated by source family for the new recordings, with original usage keys
preserved for old saves. Switching to another family during a committed draft
uses fresh phrases; earlier committed phrases remain used.

`tools/prepare_steady_phrases.py --assessment-dir /path/to/steady-assessment`
reproduces the six private working assets from hash-verified originals (requires
NumPy). Source/output hashes and drum-kit summation are recorded in the local
derivation manifest. `Audio/Songwriting/SteadyHundred/` is ignored by Git, and
normal Android exports exclude all private songwriting audio. Owner review build
version code 3 includes both new families plus the archived Rehearsam recordings.

New validation: `tests/steady_phrase_tests.gd -- --require-assets` exercises
source isolation, archived asset/key compatibility, JSON-loaded compositions,
family switching, 460,800-frame imported PCM and source-specific breakdown
timing. Existing phrase-bank/CareerHub, save/UI, practice and career regression
tests were also run. A real career screen was rendered at phone size. Android
runtime and exact musical phrase boundaries remain for owner review.

Enable **Use These Parts in My Song**, choose phrases and levels, and preview.
Solo isolates selected instruments. Breakdown removes that part in the second
half of the passage. Commit uses the existing one-day writing session: three
sessions complete a song. Previewing, changing controls or leaving consumes
nothing. A successful audio commit consumes each selected phrase from its
character's bank. The same draft can retain/refine it; another song cannot reuse
it. Changing to a fresh phrase consumes that phrase too; earlier committed
phrases remain used. Roster reordering preserves banks and new characters have
independent inventories. No quality bonus is awarded for adding audio.

Completed songs retain their composition. Songbook → View Sleeve provides
read-only playback, including when those phrases are no longer selectable or
their contributor has departed. Career saves persist audio settings and usage.

The archived Rehearsam bank contains nine aligned 48 kHz stereo PCM clips,
three passages per instrument, from AI-generated Suno Rehearsam Loop. Each is
455,040 frames / 9.48 seconds, with common in/out positions and short endpoint
fades. These are provisional four-bar candidates, not listening-verified bars
or guaranteed harmonically compatible combinations. They are different passages,
not three performances of each phrase. Banks share this small source set for
now; they are not yet 50 unique recordings per character. Character audition
snippets are a separate, non-consumable system and are not fabricated from these
song parts. No further Suno generations were used.

Private source/derived audio remains outside Git, under
`Audio/Songwriting/Rehearsam/`. The normal Android export excludes it. The
**Android Songwriting Review** preset includes it, hides the standalone Last Bus
Gone review route, and updates the separate owner-review app (version code 2),
preserving its saves. It does not replace the career app. Commercial game
licensing remains a separate pre-shipping clarification.

Validation: `tests/song_phrase_bank_tests.gd` exercises failed-session atomicity,
three-stage composition, JSON round trips, permanent consumption, draft reuse,
character replacement/reordering, completed-song playback, breakdown/reset,
exact PCM lengths and actual CareerHub preview/commit/save wiring. V22 practice
and save/UI integration, V24 studio presentation and career regression also ran.
Use isolated XDG_DATA_HOME for tests. No physical phone test or assistant
listening was possible.

Owner review:
1. Open the songwriting review app and start/continue a band with guitar, bass
   and drum players. Enter the Writing Room and choose Jam/Songwriting.
2. Enable the audio panel, choose phrases, play, try Solo and Breakdown.
3. Commit a session, leave and continue: settings should persist. Finish the
   three sessions, then hear the result from its songbook sleeve.
4. Start another song: the previous song's phrases should no longer be offered
   to those characters. Existing songs remain playable.
