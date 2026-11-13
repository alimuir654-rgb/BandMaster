# Character interactions — ENGAGE52

Implemented on `feature/playtest-polish-v20`, source `81f6129d0f166ff0b854b0ae849bc419ccdcd60c`. Source changes only; no new APK.

## What the developer sources support

[Gareth Damian Martin on Citizen Sleeper](https://www.pointnthink.fr/en/interview-gareth-damian-martin-2/) describes grounding characters in their real lives and work, and writing scenes to discover their voice, posture and mannerisms. The useful lesson for BandMaster is to give each encounter an immediate personal concern and a recognisable way of answering. This is a design application of the interview, not a claim of implementing Citizen Sleeper's systems.

[Greg Kasavin on Hades, official GDC podcast article](https://gdconf.com/article/roguelikes-and-narrative-design-with-hades-creative-director-greg-kasavin-gdc-podcast-ep-16/) discusses narrative continuity: characters acknowledge earlier encounters and their outcomes. BandMaster already saves promises, pitches, selected tracks and radio answers; those facts can inform dialogue without adding a new reward or save system. Only these two primary articles were read for the implemented conclusions. An Oxenfree search was exploratory; its video was not watched or transcribed.

## Applied changes

- Promoters Mo, Jules and Ray now have different immediate concerns, scene beats, pitch responses and an optional question about sharing a bill. Your actual pitch and requested terms appear as your own words, followed by the promoter's response. The original financial proposal remains visible and authoritative.
- All18 musicians now give individual replies about their playing, writing together and rehearsal intentions. Actual saved agreements still use the existing four-day deadline and consequences. After answering, the real saved reply scrolls into view instead of focusing the next-action footer.
- The existing student-radio presenter is now named Frankie while retaining the existing saved presenter ID and portrait. The selected track informs the introduction; later questions and responses acknowledge the actual saved earlier answer. No extra Continue steps, reward hints or new payment path.
- Songwriting replies use dark textured surfaces against the paper; checked selected replies become gold with dark lettering. Audition primary actions and playback controls have clear button surfaces and selected states.
- Arjun's initial player and both independent ideas use new cuts from the approved D–G–A–D Suno guitar master. Casey's first independent idea uses a different active passage from the approved rehearsal drum master. Original sources and old materials are retained. Recorded ideas are explicitly separate from written scored exercises.

## Evidence and limits

960final assertions passed, including four native sizes, original model coverage, all18audio lifecycles and actual filesystem failure/retry/reload paths. 68final screenshots were produced;20originals were opened, covering each changed flow at each size. The early controls and saved-reply visibility were held and corrected after pixel inspection. Source/media/signing audit and exact logs are recorded in `ENGAGE52_RESULTS.json`; no technical pass establishes human engagement, audible quality or artwork acceptance.

This pass improves authored exchanges and continuity. It does not add voice acting, character animation, an engine migration or a new branching conversation runtime. Independent musician ideas remain separate from genuinely performed responses to the four-bar exercise. Owner review is the next step before a combined source freeze.
