# Autonomous sprint kit — BandMaster
Prepared 2026-10-25. This is an **execution contract** for the eight-run programme, not a replacement for the approved roadmap.

## Timeboxing
Each hourly trigger is a **maximum one bounded delivery attempt**, not an hour of continuous compute or a guarantee that GitHub CI finishes within the run. Never pretend to have worked for an hour when the execution returned earlier. Never start a conflicting branch if prior work is open.

Suggested resource allocation per run:
- 0–5 minutes: inspect merged state, open PRs, carry-forward defects and previous retro; choose one vertical slice.
- 5–35: implement model + single focused UI experience + tests together; create PR early enough to expose CI.
- 35–50: diagnose CI, fix runtime failures, compare screenshots and test save integrity.
- 50–60: merge only after all checks pass; write retro and next-sprint handoff. If validation hasn't finished, leave PR open and resume next run.
- Reserve a **10-minute fallback**: if substantive work is blocked, deliver a narrow verified regression, asset production component or hardening improvement.
- Work available from the trigger may be shorter than 60 minutes; in that case produce truthful partial status and carry forward.

## Persona review — every sprint
Run a structured adversarial review over *actual diff and captured UI*, not generic claims of persona endorsement. Use these lenses:
1. **First-time player / creator:** Can I identify my next action in 5 seconds without knowing mechanics? Does the moment feel personal? Does a song or bandmate have a memorable identity?
2. **Management-game veteran:** Are trade-offs credible and visible before commit? Are cash/day costs, alternate paths and gig deadlines coherent? Avoid button spam and fake complexity.
3. **UX/accessibility specialist:** One primary CTA, responsive first fold, focus visibility, touch target >=44 logical px, readable text on art, no traps in overlays, cancel safe.
4. **Godot gameplay engineer:** Mutations at correct simulation boundary, validation before charging a day, deterministic cases, reusable scenes, no warning-as-error, no global scene re-entry loops.
5. **Release/test engineer:** Legacy saves parse, reload works, no duplicate event payout, CI green, screenshots reviewed, provenance/license recorded, rollback understood.
Report per persona: 1 concern, evidence, fix or issue. **Do not claim human experts were consulted**.

## Required gate matrix
| Scenario | Assertions |
|---|---|
| New band / zero song / low funds | Choose first useful action, no softlock, disabled affordability explained |
| Two songs with same title | Rejected before consuming time/cash, preserve draft, distinct song can finish |
| Booked gig in future | Countdown, preparation available, no premature stage action |
| Show day arrival / soundcheck / stage | Correct single next action, non-show actions blocked at transaction boundary, one performance/payout |
| Overdue/cancelled booking | Graceful messaging, no endless show-day trap |
| Incomplete lineup | Promoter flow offers honest gating and session workaround where valid |
| Bad van and far venue | Actual cost and wear preview, no fake route distances |
| Low bond and exhausted member | Intervention visible, one-time consequences, no repetitive reward exploit |
| Old save | Missing keys get defaults, existing songs/gear/relationships survive |
| Layout 390x844, 720x1280, 1280x720 | Primary action above first fold, tap target, modal scroll and input focus, image crop |

Prefer behavioral tests in pure RefCounted engines over brittle source string assertions. Actual screenshot review is separate from CI existence. Keep failure logs concise and reproducible.

## Reusable architecture queue
1. **SceneSheet**: full-screen/subpage template with art/portrait, optional subtitle, content scroll, back and primary CTA, blocking modal semantics, focus capture/restore.
2. **MilestoneArtifact**: event-specific song sleeve, cassette, ticket, press cutting or reward badge, all populated from persisted state.
3. **DecisionCard**: outcome preview (day/cash/morale/van/relationship), current selection, commit/cancel, no duplicate callbacks.
4. **TourSchedule**: visible calendar grouped by day with pending/future show and simulated transit/stay choices; map imagery must not impersonate a real route.
5. **EquipmentDossier**: musician->instruments, known condition/provenance and repairs, with explicit unknown legacy fields.
6. **RelationshipCase**: deterministic triggers, pairwise incident, private meeting options and repeat-safe outcome.

Prefer Godot 4.7 built-ins + existing WoldUI. Collect cohesive **original** art briefs before asset generation; record new files in Art/ASSET_MANIFEST.md and distinguish placeholder from final artwork.

## Sprint closure template
Store each sprint as an entry in `docs/SPRINT_EXECUTION_LOG.md` or a GitHub issue comment:
- Sprint N/8; started/finished times *observed*, chosen issue/goal; commit/PR; files; playable change.
- Tests: Godot suite, viewport screenshots, save/reload, cases exercised, residual warnings.
- Persona findings: five brief evidence-linked notes, critical fix before merge.
- Retro: worked / failed / action to change next run.
- Handoff: exact next highest-priority task, unblock steps, open PR to resume.
- Milestone escalation only if a major architecture/design owner choice is truly necessary.

## Owner review at major milestones
After the first full touring loop, after living relationship/drama, and after final stabilization: provide the owner with 3 real screenshots and a short scripted game-testing path. Do not claim completion based on a green test suite alone.
