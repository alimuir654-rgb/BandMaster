# Audio01 candidate — 7 November 2026

Common opening, recruitment and practice buttons now produce a restrained mechanical tap. Lineup/name/identity confirmation keys have a short rising interval; Back keys have a falling interval. Hover and focus remain silent. Two voices and a 70 ms global cooldown bound repeated feedback, and full voices finish rather than being stolen. A root-owned service survives UI rebuilds. All three original mono PCM cues are deterministic, have zero endpoints and conservative headroom, and require no samples, plugin, autoload or new dependency.

The existing Settings → Master Sound switch now saves its Boolean preference in `user://c27_audio_settings.cfg`. It applies to the master bus and stops current tails when muted. This is separate from the existing candidate and production gameplay save files. A failed preference write reports that the choice only applies to the current session. Missing or malformed settings use the current master-bus state. Gameplay data and artwork are unchanged.

This is a portable isolated candidate based on GitHub `dual-frame-proof-2026-10-28` at `b2647df2741a195a3ab8c77ed8cbddd277761fa0`, not an update to the Android v16 release. Dropbox contains the newer v16 APK and S144 screenshots, but their source commit `73f9f23` was not available in this repository. Do not replace the newer game with this older candidate. Carry the small audio module and bindings forward once that source is located.

## Actual verification

Godot **4.7.2**, local isolated project, separate writable XDG data/config/cache:

- 42 audio checks: deterministic and distinct PCM, duration/peak/edge limits, shared service, repeated binding, cooldown, occupied voices, mute persistence/recreation, disabled/hover/focus behavior and rebuild lifetime.
- 14 native Mesa GL input checks: real pointer and Space-key activation, settings rebuild, mute/unmute, disabled input, silent hover/focus and byte-for-byte unchanged gameplay save.
- Existing 73 gameplay and 88 opening model checks passed.
- Existing native pointer journeys at 390×844, 720×1280, 1280×720 and 1600×900 all returned empty failure lists, including rehearsal, expanded report and save/Continue. Title and rehearsal screenshots at all four sizes were opened. The same-state phone rehearsal PNG is byte-identical to the baseline.
- Clean editor import, project-reference validation and improvement gate passed. This is local evidence; remote CI success is not asserted.

The old full capture harness reports 25 texture, 20 shaped-text and one font RID leaks on shutdown. A separate unchanged-baseline run reproduces these exact counts. Audio unit and native input tests exit without those leaks. The dummy display emits an unsupported-VSync warning. This work does not fix the existing harness cleanup issue (#170).

Audio output was exercised with the Dummy driver and PCM samples exported. Speaker/headphone loudness, Android output and subjective sound quality still need listening review. These cues acknowledge button activation; they are not a sound simulation or proof that a save succeeded. Controls built directly by shared modal/report components keep their existing behavior; no global audio hook was added to the component library.

## Listen and test manually

1. Open the separately packaged isolated project in Godot 4.7.2 and run its main scene with your normal audio driver. In a full repo checkout run `experiments/playable_flightcase/opening.tscn`, not the production main scene.
2. Use Settings and normal choices: a short tap should sound once. Moving the pointer and tabbing between controls should stay silent. Hold/repeat inputs to check that feedback stays restrained.
3. Form a valid lineup, lock a band name and finish the identity: compare the confirmation sound with the falling Back cue. Enter practice and try a rehearsal; confirm audio continues across rebuilt screens.
4. Mute in Settings, quit and reopen the candidate. It should remain muted. Unmute, restart again and check that sound returns. Existing band saves should still Continue normally.
5. Listen to `click.wav`, `confirm.wav` and `back.wav` in the sample ZIP. Use the game for final loudness judgement: the player applies an additional −6 dB to these source samples.

For automated checks in the isolated project, run `godot --headless --path <project> --script res://experiments/playable_flightcase/audio_test.gd`, then the existing `native_test.gd` and `opening_test.gd`. Run `audio_input_test.gd` with a real display and `--rendering-method gl_compatibility`. Use disposable user data for model tests, which intentionally exercise candidate save files. The PCM test exports review WAVs to `/tmp/bandmaster-audio-evidence/`.
