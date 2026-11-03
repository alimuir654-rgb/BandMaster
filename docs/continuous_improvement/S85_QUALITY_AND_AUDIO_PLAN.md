# Quality worklists and a limited audio pilot

Owner request, 3 November 2026: make the process improvements operational, give artwork and controls/layout roles concrete worklists, and prepare limited audio **for review**. Process/worklist changes are authorised now. Audio acquisition, creation and game integration remain unapproved proposals. Verified game stays `a8a8956396b8d7615e528feacfb914c65facfc4d`; no shipping code, art, audio or APK changed in this planning session.

## Operating agreement

The existing [execution queue](S80_EXECUTION_QUEUE.md) is the single current task list. It now has four dependency-ordered artwork jobs, nine controls/layout tasks and one bounded audio proposal. Historical sourcing notes and completed decisions remain references; they are not active jobs.

One implementation writer owns shipping paths. A separate controls/layout reviewer owns player-task review and verifies fixes, while artwork sourcing/method review can work in noncompeting scratch paths. The root coordinates leases, integration and the sole native renderer. Existing helpers fill these roles when activated; this does not create another automation/controller or promise continuous workers.

Each task records a player goal, start/end state, important beats and interruptions, actual approved reference/current images, source owner, demonstrated issue or review gap, controlled hypothesis, visible acceptance and disposition. The reviewer flags what blocks understanding or action before optional polish. Current state, local draft, saved record and public price/time must remain distinct; hidden outcome formulas or a best-choice answer key never appear.

Three existing gates remain mandatory: independent predesign; early native phone and shortwide important states before full integration/proof; final exact-source matched-state four-view and whole-journey review. Add a small risk-based state matrix: selected/focused/disabled controls; long text and glyphs; empty/held/error/retry; scroll/focus/modal/dirty exits; Menu/resume/reload; normal/reduced motion; physical targets and contrast. This is a scoped matrix, not a new whole-game suite on every edit.

Use the existing control factories and type/material rules. No broad theme rewrite, new GUI pack, smaller fonts to fit, decorative hardware replacement or passive-meter redesign. A geometry pass is insufficient when a saved notice is false, a quote loses its meaning or decision context is elsewhere. Actual owner playtest feedback is logged when received; simulated lenses and automated task completion are not human usability results.

**Next source priority:** UX01 phone soundcheck/set-list space, with UX02 only if inseparable. This is a demonstrated, art-independent gig limit. The later Zoe bass encounter remains separately scoped; the older S85 scratch audition proposal has not been implemented or adopted by this process session. All source work still needs fresh preflight/storage/early review.

## Audio inventory and why this pilot

The current408-input curated runtime contains **zero audio files or playback/bank resources**. The repository search found no loose WAV/OGG/MP3/FLAC/MIDI/SoundFont assets; archives were not opened. `opening_ui.gd:30,544–549` has a local `muted=false` toggle that changes Master bus mute. `settings_sheet.gd:84–90` displays preferences but does not persist them. Existing native tests prove Master mute/focus and unchanged career/save bytes, not audible sound.

The separate non-curated WoldUI addon has MIT-licensed procedural mallets/ticks/knocks/whooshes and a six-player pool. It is UI-feedback synthesis, not a believable guitarist or a cleared musical recording. Do not activate the whole addon or call its tones an audition merely because it exists. No custom audio-bus layout or effects chain is currently configured in the curated project.

The first useful experiment is **one Jack audition-room audio study**, anchored to the already-authored four-bar material. Hearing an actual arrangement change directly supports the player's existing request and comparison. A soundtrack, whole set, dialogue cast or generated song library would add assets without first proving instrument credibility and lifecycle safety.

## AU01v1 proposed hard scope

| Source clip | Maximum length | Purpose |
|---|---:|---|
| Quiet rehearsal-room texture | 6s | Establish this one room, with no speech or background copyrighted music. |
| One handling or doorway cue | 0.5s | One appropriate arrival/handling beat; no sound on every hover/click. |
| Original guitar study | 10s | Four bars of D/G/A/D support, matching the existing written study. |
| Space-for-voice guitar variant | 10s | Rests in bars1/3, G/D support in bars2/4, matching the actual requested material. |
| Answering-part guitar variant | 10s | Light D/A support and B–A–G / F#–E–D answers in the written gaps. |

**Hard maximum:5 clips,36.5seconds of unique source audio,4MiB total mono16-bit PCM at no more than48kHz.** Future compressed shipping audio is capped at1MiB, separately from Godot import/cache overhead. At most **two playback streams**: one room texture and one foreground example. Zero spoken or sung voices, indefinite loops, soundtrack, vocal imitation, audio recording/microphone, external streaming, runtime AI, paid services, new dependencies or engine changes. Do not split clips or rename variants to evade the total.

These are upper bounds, not an instruction to fill them. Durations include every fade and decay tail. For example,100BPM4/4 gives9.6seconds of four-bar material with up to0.4seconds left for decay inside the10-second file cap. Tempo, exact note lengths, strumming and tone are new authored recording specifications for listening review, not facts inferred from the current event-only score. Keep all three takes aligned, performed on the same instrument with consistent technique and matched perceived level. They demonstrate arrangement, not measured talent, accuracy, live skill, success odds or an earned career song.

## Source and listening gate

Prefer owned original recordings of the exact passages with performer permission. Otherwise each source must have a verifiable licence covering the intended redistribution and edit; stock loops that do not match the written parts are not substitutes. Preserve source provider/URL or recording origin, author/performer, licence/version/date/attribution, original bytes/hash, edits, material/version mapping and review decision. A website licence statement alone does not clear an uninspected binary. Do not infer rights from an MIT software licence or from artwork permission.

Keep the music free of recognisable third-party recordings/covers and the room free of identifiable speech or uncleared music. No paid acquisition, new model/service or unapproved dependency is implied. If a credible source cannot be produced within the caps and existing capabilities, **HOLD that source**, explain the exact blocker and continue other approved work. An atmosphere-only alternative would be a revised proposal, not silent promotion of a failed musical pilot.

First approve or revise **this plan**. The proposed approval covers a fresh source-study scope and delivery of only the selected five-or-fewer private listening excerpts to this owner through an explicitly checked private destination. This is a proposed narrow exception for audio excerpts to the current PNG/APK-only upload boundary; it takes effect only after the owner approves it. Raw session/stem archives, keys, saves, source code and learning history remain local, and public upload remains prohibited. No listening upload is authorised by the current planning request. Then the source-study scope may prepare the five-or-fewer cleared clips. The owner listens to the source study for believable instrument tone, coherent before/after arrangement, restrained room sound and appropriate volume. **No game integration before that listening acceptance.** Approval of the plan does not approve unheard audio.

## Proposed integration boundaries after source acceptance

- Use one small explicit playback owner, not the whole WoldUI addon. Bind approved clip IDs to the existing `cast_jack` / `s83_jack_written_v1` material IDs and a versioned audio manifest. No synthesis from arbitrary typed lyrics and no new song-generation mechanic.
- Offer native Play/Stop only for material already revealed in the actual encounter. The original take is available at its try-out; the adjusted example only after that request has been locked. Comparing first and adjusted material must not expose an unchosen future branch before the player's decision. Equal controls and presentation; no best-choice sound or colour.
- Playback is optional and initially user-initiated. The complete written material and captions remain available with mute, missing source, failed playback or no device. No hidden audio-only clue, simulated crowd telemetry or attendance/playing claim.
- Play, Stop, replay, completion, fade, resize, hide and interruption perform **zero Game, Finance, career-day, invitation, phase-completion or owner-save operations**. No completion callback settles a session. Resume/reload never auto-replays or re-invites anyone.
- Reuse the existing Master mute and define its local preference explicitly before coding. Any persisted mute preference belongs to separate app settings, never a career save/fingerprint. Existing preference absence defaults safely; a settings-write failure must not affect game state. No mixer UI expansion in this pilot.
- Mute stops/silences both streams immediately; unmute does not restart an interrupted clip. Stop on Menu, hide/free, application interruption and audio-focus loss; cap rapid replay at one foreground stream with a short fade. No lingering playback or extra pool allocation.
- Match foreground perceived levels; leave headroom, duck the room during the example and verify the final summed signal. Proposed review ceiling is−1dBTP for the final decoded mixed output. True peak needs suitable measurement; sample peaks or gain settings cannot establish dBTP compliance. If existing tools cannot measure it, keep that gate pending rather than inventing a pass. Listen on ordinary speakers/headphones, and on the target phone when a future owner-requested build makes that possible. Actual hardware listening remains pending until performed.

## Proposed verification and stop conditions

Before integration, adopt exact source/asset/settings paths and a storage plan covering retained raw clips, imported resources, private caches, listening evidence and failure reserve above the existing600MiB floor. The4MiB source/1MiB payload caps do not authorise cache allocation or deletion. Use the actual next free session; this is a proposal, not an integration lease.

Test actual Master mute, Play/Stop, phase-appropriate availability, rapid replay, source/format failure, missing-device fallback, Menu/teardown, suspend/resume, resize and normal/reduced presentation. Whole typed owner state, save counts, original talent/cash/day/Finance and once-only invitation counters remain unchanged by every audio action. Exercise existing sound controls with touch/key/focus and preserve all legacy save cases. Changed integration still needs the appropriate73/88/import/four-view and focused journey proof; unchanged suites are not rerun for planning.

Current native QA uses Dummy audio. It may verify stream/control/lifecycle behaviour, but **cannot establish audible quality or real device/audio-focus behaviour**. Source listening and later audible/device testing need their own actual evidence and scoped test contract; do not silently change the existing runner's audio driver or label Dummy results a listening pass.

HOLD for unclear rights, wrong notes/material, unconvincing instrument tone, audible clipping/jarring transitions, inability to stop/mute, extra voices/streams, essential information lost in silence, any gameplay/save change, or an exceeded cap. Two ineffective source attempts require a changed method or HOLD. No broad sound library, extra instruments or voices are added to solve a failed sample.

## Review decision and current status

**Pending owner review: AU01v1.** Approve the bounded source/listening study and selected private excerpts (integration still waits for listening acceptance), request a revision, or defer. The existing review board holds the decision; no existing checkbox is changed. Source generation/acquisition, playback code, licence clearance, listening quality and device verification are all still pending. APK work remains held until a new direct request.

The original finite window is unchanged: no new breadth after4November19:45, integration freeze20:15, last21:15 checkpoint readiness only, all writes/release21:20, hard stop21:24:35 Europe/London. Pending approval does not extend it. Unapproved audio does not block actionable controls/layout or written audition work.
