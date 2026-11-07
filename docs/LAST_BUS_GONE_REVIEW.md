# Last Bus Gone owner review

The main menu offers **Last Bus Gone · Review Desk** when the local review audio
is installed in the editor, or in the dedicated **Android Audio Review** build.
The ordinary Android export excludes this audio. The review APK has its own
application ID (`com.bandmaster.lastbusreview`) and does not replace the career app.
The review export omits the unused root `*unsplash*.jpg` collection to keep the
download small; no runtime code or scene references those files. Used game art
and the normal Android export's artwork selection are unchanged.

The desk plays the selected 19.3-second excerpt (1:10.700–1:30.000) as four
synchronized stereo parts: Guitar, Bass, Drums and Vocals. A separate reference
button compares the identical range from the finished mix. The player never
layers the reference over the stems. Playback, pause, restart, seek, four faders,
mute/solo and master attenuation are implemented. Nothing autoplays or loops.
Leaving the screen stops audio; backgrounding the app pauses it.

## Assets and provenance

These are AI-generated Suno assets. The owner reports this exact version was
generated and downloaded during a paid subscription. Commercial interactive-game
licensing remains unresolved; this is a private owner review, not shipping approval.
The owner accepted isolated Guitar quality and reported clicks at the original
Guitar/Vocals endings. The chosen excerpt excludes those endings.

The WAVs are derived from the hash-verified assessment originals, with one common
frame range and 10 ms / 20 ms linear fades to exact-zero endpoints. They retain
48 kHz, stereo, 16-bit PCM and 926,400 frames per channel. Import trimming,
normalization, resampling, compression and looping are disabled. The local
`derivation-manifest.json` records source hashes, Dropbox identities and output
hashes. The original files are never overwritten. No full songs are bundled.

Audio and its identity manifest are ignored by Git; do not upload them to the
repository or CI. To reproduce locally with the private assessment folder:

```sh
python tools/prepare_audio_review.py --assessment-dir /path/to/assessment
godot --headless --editor --import --quit
godot --headless --export-debug 'Android Audio Review' /path/to/review.apk
```

The derivation script uses only Python's standard library. Use Godot 4.7.2 and
matching export templates. Android export needs a local SDK, JDK and debug key.
No keystore, SDK, source audio or assessment folder belongs in Git.

## Review steps

1. Open **Last Bus Gone · Review Desk** from the main menu, then press **Play**.
2. Lower a part, mute it, and solo one or more parts. Reset Mix restores the four
   original stem levels and clears mute/solo. The master starts at −6 dB.
3. Press **Hear Reference**, then **Back to My Mix**. The play position and pause
   state carry across. Stem controls are disabled while hearing the reference.
4. Pause, seek, restart and let the excerpt finish. It should stop after 19.3 s.
5. Leave for the menu, or background the app: audio must stop or pause respectively.
   Existing Continue/New Band and career pathways remain available.

## Verification and limits

Run the new behavioral integration test with an isolated user directory:

```sh
XDG_DATA_HOME=/tmp/bandmaster-audio-test godot --headless --path . --script res://tests/audio_review_tests.gd
```

It exercises actual imported PCM lengths/rates, the synchronized transport,
mute/solo, reference exclusion, seek/pause/end behavior, menu navigation and
byte-for-byte save preservation. It captures in-memory mixer PCM to check that
playback produces signal, muting silences it and reset restores signal. This is
numerical verification, not listening. Without private assets, it checks the hidden
menu entry and the screen's missing-audio fallback instead.

Validation performed for this change: Godot 4.7.2 import/parse; real-asset audio
review integration; missing-asset behavior in a normal exported Android PCK;
career regression; V22 save/UI integration; V22 opening handoff/UI integration;
V120 studio regression; structural validation; APK signature and asset checks.
Real Godot screenshots were captured at 390×844, 720×1280 and 1280×720 with Mesa
software OpenGL; controls stayed inside viewport widths. Android export succeeded
for arm64, with a minimum Android API of 24. No physical phone/emulator runtime
test or listening assessment was performed in this environment.

No persistent schema changes were made. This desk does not write career, band
or profile saves, advance days, award progress or replace existing music.
The stems do not reconstruct the finished mix precisely. Reset is a provisional
unity stem balance, not a claim to match the reference. Faders/EQ cannot create
genuinely simpler playing. The assistant cannot audition sound here; musical
cut points, internal artefacts and phone speaker/headphone playback need owner
review in the packaged build. Short fades address waveform discontinuities but
do not establish that a phrase ends naturally.
