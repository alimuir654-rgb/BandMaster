# BandMaster — Screen hierarchy and interaction audit
Status: source-based audit of v12.4 (2026-10-25). Not a visual sign-off.

## North-star player contract
Within the initial viewport a player must identify (1) where they are, (2) the current state, (3) the one most relevant next action and its cost/time, and (4) how to go back. Scroll order: primary decision -> alternatives/trade-offs -> detailed management -> progress/history. Any unavailable action must explain its blocker and provide a remedy. One prominent primary CTA per decision area, not several unrelated gold buttons.

## Global shell — critical
**Observed:** `_render()` renders header and possibly an image hero, then a full “LATEST ACTIVITY” card, before destination content. Every scene builds a complete UI tree on change; scroll preservation is explicitly limited to roster and gear. Landscape uses left icon-only navigation, narrow screens use bottom navigation.
**Fix:** replace the persistent latest-activity card with a short dismissible status strip/toast *after* action success, without pushing primary decisions below the fold. Reserve hero art for contextual screens, never as a full-height blocker. Consistent back/return navigation; preserve scroll on in-place filter/selection changes, reset to start on destination changes. Show primary action, cost and days before scrolling. Test keyboard/gamepad focus and phone landscape / portrait widths.
**Acceptance:** no full-page Latest Activity panel displaces key action; no top-level action invisible behind a banner at 1280x720; after action, feedback visible and non-blocking; no stale scroll position on navigation.

## Home — critical
**Observed order:** scene strip -> environmental noticeboard (>=720px) -> desktop spotlight -> next move -> band image -> navigation destinations -> Band Pulse -> WAYS FORWARD -> upcoming gig/no booking -> chapter claim -> next locked venue -> latest songs and scrapbook -> shortcuts on phones. Several different objects claim primacy and repeat day, band, booking, action suggestions.
**Target:** top = *one* actionable “NEXT FOR YOUR BAND” hero showing next gig countdown (or “No gig booked”), contextual CTA and only 2 key metrics. Below = next chapter reward if ready (or compact objective progress), then band pulse with one actionable weakness, then routes to manage Band/Studio/Gigs. Move original songs, latest scrapbook and career advice to linked subsections or lower screen. Do not repeat band name or day inside second generic cards.
**Accept:** booked gig and claimable chapter have unambiguous priority; exactly one primary CTA at a time; compact screen can reach it without scrolling.

## Gigs — critical
**Observed order:** contextual strip -> PA/crowd dashboard -> photographic banner -> live briefing -> after-show report -> booked gig / show phases -> future venue picker and offer -> van repairs. The booked show's *actual required action* can be placed below several descriptive blocks. Soundcheck has strategy choices and a conditional backstage incident.
**Target:** context-sensitive page top: if show night, immediately show stage phase and next enabled CTA, incident before soundcheck strategy; if booked ahead, countdown + preparation CTA; if no booking, venue/deal selection and “BOOK SHOW” CTA. Place sound system artwork and historic results below the primary decision. Move repairs to travel readiness subordinate section.
**Accept:** “TAKE THE STAGE” or “CONTINUE THE NIGHT” visible quickly on gig day; player never offered booking as primary when an existing gig needs resolution; incident choice precedes performance; booked date and fee visible near action.

## Actions / Studio — critical
**Observed order:** scene strip -> contextual environment console -> photographic masthead -> choose-day tabs -> contextual image and metrics -> session control -> songbook -> songwriting workshop / rehearsal / socials / promotion. This delays writing/committing a song and repeats status/scene identity.
**Target:** top = three distinct activity modes with strong selected state and a clear day cost. For JAM show current draft state then *primary workbench* (creative choices and commit) immediately; place songbook as collapsible/secondary tab or side pane. For HANG OUT show band relationships and outings as immediate options. For PROMOTE show spend/cost/fan-reputation outcomes before marketing buttons. Use mixer/VU decoration within relevant workbench, not as an extra layer ahead of it.
**Accept:** editing a song does not spend a day and says so; commit explicitly says “1 DAY”; current draft saved through switching modes; phone player can reach first meaningful creative choice rapidly.

## Band — high
**Observed order:** editorial masthead -> management briefing -> conversation if selected -> roster cards and actions -> lineup overview -> group pulse/chemistry -> alumni -> recruitment -> dialogue engine configuration. Band profile interactions can create long card heights.
**Target:** top = lineup status plus alerts (“Drummer unavailable”, fatigue) -> roster and focused active member profile. Make TALK and response choices immediately adjacent to member identity, show one-per-day limit there; deeper social actions show their day costs. Keep relationship visualisation and former members lower, recruitment promoted to top only when lineup incomplete. Move dialogue engine settings out of management flow.
**Accept:** select a bandmate and see available TALK reply without scanning unrelated panels; simple chat vs spend-a-day choice clearly differentiated.

## Gear — high
**Observed order:** shop heading/readiness -> all catalogue selection buttons -> selected item detail and BUY CTA below. Large catalogues hide the purchase action.
**Target:** two-pane list/detail on desktop, sticky or adjacent selected-item details on mobile; show price, cash balance, readiness benefit and affordability next to BUY; owned items visually distinct. Put owned gear/filter controls near catalogue header.
**Accept:** select an item and buy without an additional full catalogue-length scroll; insufficient cash displays amount missing; no erroneous double purchase.

## Scene — high
**Observed order:** recording studio -> scrapbook (up to 20 entries) -> career momentum -> local buzz/press -> opportunity cards -> posters and press CTAs. Primary promotion buried after scrapbook, a potentially very long history.
**Target:** rename/segment into clear “PROMOTE” vs “SCRAPBOOK / HISTORY” subviews. Promotion landing top = current buzz/fan trend and spend options with costs/expected effects, then milestone. Scrapbook landing top = memory filters and memorabilia grid, no promotion controls interleaved. Recording should have an explicit destination or contextual subsection rather than becoming generic Scene top.
**Accept:** “POSTERS £25” and “PRESS £10” can be found without scrolling 20 scrapbook entries; memories have real dates/content; primary tab labels describe player intent.

## Priority implementation sequence
P0. Global nonblocking feedback and state-specific primary action; home and gigs first-fold ordering.
P1. Studio task-first creative workspace and Scene split; Gear selection/detail adjacency.
P1. Band roster+conversation focus, missing-lineup action priority; responsive navigation/focus.
P2. Reduce repeated hero/metric cards, improve audio/transition polish, artwork and animation.
Each PR should include behavioural assertions **and screenshot captures** at 390x844, 720x1280, 1280x720, plus relevant booked/unbooked, claim-ready/not-ready, song-draft/no-draft, lineup-complete/incomplete states. Do not infer rendered quality merely from a screenshot workflow passing.

## Review lenses
- Player/product: goal, consequence, progression feedback and action clarity.
- UX/accessibility: first fold, reading order, primary vs secondary CTA, explicit disabled reason, focus order, scroll position.
- Godot/engineering: deterministic state, no duplicated save mutations, no control overflow, mobile geometry, performance and view preservation.
- QA/release: run critical-path smoke test: create band -> write song -> rehearse -> book gig -> incident -> show -> receive outcome -> claim chapter -> save/reload.

## Definition of done
Do not call the hierarchy overhaul complete until each screen's primary task is reachable in the first viewport on target devices and the owner has reviewed actual gameplay screenshots at desktop landscape and mobile dimensions.
