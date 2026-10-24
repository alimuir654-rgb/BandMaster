# BandMaster v2.2 — Owner playtest handover

**Status:** candidate checklist, not a certification of phone visual quality.

## Preparation
Open the Godot project from the latest validated `main` after the playtest PR is integrated. Keep a copy of existing `user://tour_save.json` and `user://band_profile.json` before starting a new band, since new-game replaces those saves. AI is optional and should be OFF for the baseline test.

## Guided first playthrough (30 game days)
1. Create a band with 2–4 musicians including a drummer. Give members contrasting traits.
2. Complete the scripted first three rehearsals. Choose at least one writing session, one focused set drill and one relationship-building choice.
3. Complete the scripted first gig at The Toadstool. Enter Career Hub; confirm the first gig appears in scrapbook/history and the band is unchanged.
4. Navigate Home → Actions. Complete one original by filling all three draft stages. Verify progress persists if you save to main menu and Continue Career between sessions.
5. Claim chapter rewards when requirements are met. Note any goal that becomes confusing or unreachable.
6. Book a hometown gig. Check the stated day, rehearse and/or write before it, then perform it **on the scheduled day**. Confirm cash, fans, reputation and scrapbook react.
7. Book another show and cancel it, or intentionally miss one once, to check the penalty and absence of repeat deductions. Save, exit and resume during a separate booking.
8. Play to day 30, or stop earlier if gameplay becomes repetitive or confusing. Note when motivation to continue rises or falls.

## What to report
Record the in-game day, screen/tab, what you expected, what happened, and a screenshot for each problem. Identify severity: Blocker (can't progress or save), Major (wrong result or unreadable UI), Minor (confusing or unattractive). Separately give each category a 1–5 score: onboarding clarity, character attachment, meaningful choices, gig excitement, interface readability and desire to play another 30 days.

## Known limitations / not release claims
PC Ollama conversations are opt-in; mobile uses deterministic dialogue. Headless checks validate code, saves and layout geometry, **not** physical tap accuracy, typography, motion or device-specific safe areas. Venue catalogue remains intentionally small. Career economics are simulation-balanced but still need subjective judgment. The older scripted intro and newer CareerHub remain distinct scenes joined by save migration.

## Handover gate
Do not declare this document a playable sign-off until Godot headless, structure, first-month acceptance, longer simulations and UI/save integration all pass on the same commit. Visual/mobile review still needs an actual rendered device playthrough.
