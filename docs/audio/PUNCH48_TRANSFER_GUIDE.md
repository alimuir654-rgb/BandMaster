# Smaller Suno transfers without losing the stem masters

For the next export, send a small MP3 listening mix first. Once a take is chosen,
keep its full-length stems as lossless masters and transfer FLAC copies. Most
game uses will remain short excerpts cut from those retained masters.

Suno's [download guide](https://help.suno.com/en/articles/13926081) lists MP3 song
downloads on web/mobile and WAV for Pro/Premier on the website. Its
[Studio export guide](https://help.suno.com/en/articles/8128193) documents WAV
multitrack exports, selected time ranges and individual WAV clips. The latter
page is under the Studio v1 archive; exact controls may differ in newer Studio.
These sources do not document a direct FLAC export. Convert after downloading.

Use FLAC for the accepted PCM16/PCM24 WAV stems. Retain their original sample
rate, bit depth, channels and complete start/end silence. Disable normalising,
silence removal, tempo changes and independent trimming. Every stem needs its
original timeline offset so lead, harmony and backing still align. MP3 is useful
for a quick review but is lossy; it is not the only retained stem master.

An actual retained `Last Bus Gone (Vocals).wav` converted from 34,014,892 bytes
to 12,915,409 bytes: **62.03% smaller**. Both decode to exactly the same complete
PCM samples at 48 kHz/stereo. Savings depend on the recording; this is one
measured example, not a guaranteed ratio for every stem. Original unchanged.

On Android, a local audio converter must explicitly offer WAV-to-FLAC with the
above settings. Preserve the WAV until the FLAC has been verified. No cloud
converter or new sharing permission is needed. A current FFmpeg Media Encoder
store listing was inspected, but its FLAC controls/compatibility have not been
verified on the owner's phone, so no app-specific successful workflow is claimed.

For a computer or this private workspace, the bounded helper uses existing
FFmpeg and Python, refuses to overwrite output, rejects unsupported float WAVs,
and compares decoded PCM hashes before writing a receipt:

```sh
python3 tools/punch48_compress_stems.py /path/to/WAV-stems /path/to/new-FLAC-copies
```

The helper does not upload, delete or replace anything. On intake, record the
new FLAC source hash and exact decoded PCM relationship. A decoded WAV may have
a different container/header hash; never relabel it as the historical original
WAV bytes. Keep original manifests/approvals and existing private banks intact.

The game can use smaller compressed excerpts after source acceptance; these
transfer copies do not rebuild or change V23/V24. All owner audio stays private.
