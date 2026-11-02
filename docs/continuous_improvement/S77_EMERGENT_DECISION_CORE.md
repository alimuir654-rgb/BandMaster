# Shared situation and consequence core — proposed first implementation

Owner requirement, 2 November 2026: situations must emerge from gameplay and impacts must flow through musicians, relationships, tension, momentum and outside pressures. Day jobs and family support belong in biographies. This is a concrete implementation design; S77 hides advance outcome math but does not implement this core or invent new C25 biography facts.

## Current source facts

- Scripts/band_drama.gd pair_pending uses actual trust, fatigue, song contributions, current participants, resolved IDs and priority. resolve_pair still applies fixed choice vectors.
- Scripts/member_life.gd pending/resolve/refresh uses loyalty, fatigue, morale and availability. Its THE DAY JOB is a later day20/low-loyalty event, not a starting employment simulation.
- Scripts/career_story.gd observe records changes and milestones; its journal retains80 entries. It cannot serve as permanent promise memory or decision authority.
- Scripts/gig_calendar.gd perform already demonstrates contextual settlement from material, chemistry, gear, travel and previous visits. Reuse this approach to contextual consequences.
- Scripts/practice_room.gd resolve assumes every active member participates. Changing life_status temporarily to fake attendance would corrupt other systems.
- Data/CharacterCast/approved_cast_2026-10-29.json has18 approved fictional musical biographies; there are no recorded jobs, wages, shifts, rent or family-support facts. Existing names, IDs, portraits and raw bios remain intact. No dedicated momentum model exists; some counters/journal facts are useful inputs, not complete permanent history.

## The shared loop

1. An actual player action creates or changes facts: request rehearsal, accept a booking, finish a song, pay a cost, honour or break an agreement.
2. A pure context query reads recorded commitments, availability, preparation, fatigue, relationships, personal financial pressure, outside obligations and recent verified band activity.
3. The coordinator surfaces an earned situation only when its source conditions exist. Participants and context come from those facts; priority/cooldown prevent constant popups. Pressure can continue in the background without forcing a choice screen.
4. The player chooses an intent such as reschedule, ask for flexibility, proceed with available musicians or share a burden. Dialogue and biography explain the stakes; no hidden-stat answer key or exact future vector is displayed.
5. Mechanisms derive consequences from the actual attendance, resources, preferences, urgency and promise history. The same intent can be welcomed, resented or ineffective in different contexts. Use bounded context-sensitive calculations, not a fixed +trust result attached to every copy of one answer.
6. Commit the whole transaction once, save its factual effects and promises, then present the outcome. Those facts feed the next situation. Narrative rendering and reopening never settle anything.

Content can be authored while selection, participants, timing and consequences remain state-driven. Deterministic state-based emergence is sufficient for the first pilot; runtime AI, new dependencies and an unreviewed random-outcome layer are unnecessary.

## Biographies and personal context

Add an owned, versioned context layer keyed by the existing stable candidate ID. Keep stable background separate from career-changing employment and commitments. Player-facing biography prose should cover:

- Day job or study, typical availability and ability to take time off.
- Living responsibilities and financial constraints, expressed as authored facts rather than hidden numeric ratings.
- Family support, savings or lack of a safety net where established. A musician whose parents cover rent has different freedom from someone depending on shifts.
- Ambition, preferred way of working and what the musician has actually agreed to do.

Family support changes constraints and freedom; it is not an automatic bad-person trait. Friction arises from unequal expectations, cost-sharing, attendance, sacrifices and the player's handling of them. Someone with support can also contribute time or resources generously. No appearance, voice description or name implies wealth. Existing musicians with unrecorded background retain UNKNOWN; do not retroactively invent missed wages, jobs, debts or previous promises. New authored profile proposals should be reviewed alongside their bio wording before becoming canonical starting facts.

## Minimal additive state and API contract

Proposed optional career.situation_core_v1, under existing save version1: version/revision, member_contexts keyed by stable member ID, planned commitments keyed by stable commitment ID, durable promise/attendance facts, active instances and processed action IDs. Preserve all unknown extension fields. No full-career copies inside the save. Keep this state outside fingerprinted demos and outside canonical completed-activity markers.

Each instance locks situation ID/type, real participant IDs, source commitment/action IDs, content and policy versions, context fingerprint/revision, pending phase, chosen intent and actual consequence receipt. Missing/future/malformed data must be held safely; missing context must not fabricate an earned trigger. Journal prose can summarize these facts, but trimming the journal must not erase promises or permit duplicate events.

inspect(career, proposed_action) returns valid recorded constraints and earned situation candidates without mutation. resolve(career, instance_id, intent, expected_revision/context) returns one next state and sourced consequence facts. Internal preview and commit use the same pure mechanisms, with no preview math exposed to the player. The owning action controller performs the established post-chain and Finance ONCE, then one owner save. Restore the entire career, instance and promises on failure. Terminal, active radio and due-show priorities remain authoritative. Legacy completed cases stay read-only and never resolve again under a new policy.

## First pilot: rehearsal versus a real work commitment

Use one explicitly recorded evening shift and one requested rehearsal on the same career day/window. Current time advances in career days, so use explicit DAY/EVENING commitment tags for this pilot rather than inventing an hourly clock. A daytime job does not automatically make evening rehearsals impossible.

Show the affected musician, their actual job obligation, the coming booking/preparation and relevant agreements. Offer action intents, not guaranteed outcomes. Rescheduling creates a real planned rehearsal without secretly charging a day; the ordinary cost/day is charged only when rehearsal actually occurs. Proceeding records actual attendees and why the absent musician was unavailable. An attendance-aware owned practice adapter is required; do not temporarily falsify life_status or award absent musicians practice/song contributions. An all-attending control must match the existing original practice transaction exactly.

A near gig can make postponement costly; excluding a musician repeatedly can create resentment; honouring an agreement may build confidence; a broken agreement should continue to matter later. Different financial safety nets change what people can reasonably commit to. Resolve from those actual facts and histories instead of repeating one fixed outcome for reschedule/proceed.

Personal wages, rent, parental support and voluntary band contributions require a separate explicit accounting policy. They must not silently alter the shared band cash, invent historical contributions or reset the existing Finance14-zero-day rule. The first availability/relationship pilot must state clearly whether personal money is simulated; no wage-payment claim from a biography sentence.

## Acceptance before calling the core implemented

- No job conflict without a real recorded obligation; UNKNOWN legacy context creates no invented pressure.
- Identical action intent under contrasting actual commitment/history/booking contexts yields appropriately different supported consequences. No universally best choice or fixed bonus card loop.
- Actual attendance, preparation and money records agree; all-attend legacy control remains byte/typed-state equivalent.
- Promises and consequences survive reopening and journal trimming; duplicate callbacks/cooldowns cannot settle twice.
- Full-career failed-save rollback/retry, source revision guards and once-only Story/Calendar/Life/Finance/save remain intact.
- Four-size native journeys show context before choice and consequences after it, without tooltips/Details revealing hidden math.

Implementation order: approve the factual job/support bio layer and bounded accounting/attendance contract, implement the shared state/transaction kernel with one work-conflict pilot, then migrate existing bandmate/social/radio/performance situations incrementally. Do not rewrite all events or claim full emergence from this document.
