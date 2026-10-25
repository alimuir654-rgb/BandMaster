# BandMaster: distinctive-scene UI overhaul (v13.1 onward)

Owner playtest findings, 2026-10-25. Each scene needs its own visual metaphor and primary mechanic rather than the shared card/progress/button language.

## Global
- Replace generic percentage bars with concise RAG statuses where exact values are not needed; contextual one-click remedies for warnings.
- Keep critical action in the initial viewport; preserve scroll on in-place selection, reset on cross-scene navigation. Avoid rebuilding and jumping to top for list selections.
- Prefer continuous instrumented workspaces over stacks of headings; retain keyboard/gamepad focus and screen reader naming.
- Track real rendering at 390×844, 720×1280 and 1280×720 with gameplay-state fixtures.

## Home: rehearsal-house noticeboard
Top: tonight/tomorrow schedule and one practical next action. Middle: rag status board with targeted repair/rehearse/social calls. Lower: notes pinned by bandmates, clippings, reminders. Warm physical paper textures and coffee-stained handwritten notes, not repeated statistics.

## Studio: songwriting table
Top: current song draft, scribbled notes, song structure and session control. Dedicated rehearsal room for instrument practice/chemistry. Songbook as a secondary physical setlist drawer. Make experimental riff/name/arrangement edits visibly no-cost; completing sessions spends days and shows the consequence.
Creative assets: notebook paper, guitar cables, amp labels, studio tape; interactive controls remain accessible over the visual texture. No real cigarette brand/product promotion.

## Band: people and conversations
Roster-first musician photographs/illustrations and status; selecting a member opens focused character scene with voice, choices and consequences. RAG for tired/unavailable, actions alongside the specific member. Chemistry backstage wall lower. A technical info pane is secondary.

## Touring: planning first, gig night second
Bookable venue map and route ledger, calendar dates, driving distance/time, van wear, hotel-versus-drive trade-offs, hotel cost and fatigue. Quote data must come from real game state; do not invent distances or locations. Promoter negotiations: separate booker portrait/conversation office with offers, visible guarantees, concessions, relationship changes. Booking commits once. Show-night starts a different phased event UI (arrival, soundcheck, backstage, stage). Road and hotel rules require a separate simulation module and state tests before activation.

## Gear: second-hand shop
Select equipment and inspect visible instrument photo, condition, cash, readiness benefit, price. Purchase at the selected item's side, not after full catalog; handle insufficient cash with meaningful path.

## Career / Scene: agency + scrapbook
Promotion desk with release/press options at top; archive and physical memorabilia in separate mode. Press coverage becomes staged headline scraps. Avoid nested generic cards.

## Sequencing and acceptance
1. v13.1: fix venue shortcut and scroll jump, RAG pulse, working dedicated promoter meeting, cost briefing and regression.
2. v13.2: dedicated tour itinerary and travel/accommodation mechanics with deterministic fatigue/cash/van consequences and save compatibility, responsive tour-calendar/map UI.
3. v13.3: studio notebook/setlist composition workbench with meaningful creative flow, eliminate duplicate control desk information.
4. v13.4: distinct Band conversations and Gear inspection, contextual feedback polish.
5. Real runtime captures for initial and later gameplay states and owner in-game signoff.

Use current WoldUI for tactile accessible controls; build purpose-specific widgets in Godot. Open-source Godot UI components and libraries can speed maps, transitions or iconography, but check licences and Godot 4 compatibility, and avoid adding dependencies that duplicate WoldUI.
