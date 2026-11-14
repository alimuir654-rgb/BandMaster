# UX70 — BandMaster UI/UX cleanup

## Decision

Use a fixed top navigation row: contextual return on the left, current place in the centre, Menu on the right. Keep navigation outside scrolling content. An active audition uses the explicit **End audition** label because aborting an audition writes saved state; it is not interchangeable with pausing.

Put the current character before their speech and show only the active reply group. Use the existing authored options—usually three, but the audition questions currently contain two. Keep a truthful way to proceed to the music without answering optional questions. More history, biographies, sound controls and reference notes remain available through disclosures.

## Observed baseline

| Family | Observed problem | First cleanup |
|---|---|---|
| Career | HOME/SHOP/BAND/SONGS at the top; HOME/MAKE/GIGS/BAND or Practice/Pause at the bottom elsewhere | One top return/Menu contract; group the home destination choices |
| Audition | Conversation, musical requests, listening tools and invitation decisions compete | Character and one current exchange; listening/written detail disclosed; invitation after musical response |
| Songwriting | Main MixingDesk shows seven recipe axes before a 48px collaborator portrait; speech repeats in footer | Existing collaborator portrait, authored idea and three replies first; answer opens listen/review/commit; controls disclosed |
| Rehearsal | Song, focus and pace shown together beside catalogue, repeated stats and full notes | Song → focus → pace → review in the same view; original explicit £15/one-day action remains separate |
| Musician | Three topics compete with three replies, agreement/history and commitment text | One selected topic and active exchange; other topics/history disclosed |
| Promoter | Existing character/speech/three replies already provide the closest model; extra history/venue prose competes | Preserve canonical promoter, dialogue and booking stages; fixed return/Menu and concise context |

These are source observations at baseline `3c85758dadf9d17fece8a4ab6e693f41660c047c`, supported by original SONG56 songbook, SONG60 writing and SONG63 rehearsal captures opened by root/reviewers. Latest owner feedback defines the intended direction; it is not proof of acceptance of an implementation.

## Protected behavior

UI stage/disclosure changes are free and local. Original audition, workbench and rehearsal owners still validate, charge, account and save once. Keep exact selected song and collaborator identities, optional audition answers, dirty Save/Discard/Keep, true failed-save rollback/retry, Menu/Continue and reduced-motion information. Do not edit authored audition content because its text participates in saved fingerprints. Do not invent pre-choice character reactions or expose hidden result math.

## Verification and remaining review

Capture same source-bound states at 390×844, 720×1280, 1280×720 and 1600×900. Review phone and short landscape first. Exercise real engine pointer/key/scroll input, fixed navigation coordinates, full type/targets, rapid repeat safety, dirty exits, one original paid transaction and reload. Native engine evidence is not physical-phone or human comprehension evidence.

Implementation and final evidence will be recorded in UX70_RESULTS.json and UX70_REVIEW.json. Specialized onboarding editors, complex gig performance controls and modal safety flows are reviewed separately; do not claim a whole-game visual acceptance from the priority slice.
