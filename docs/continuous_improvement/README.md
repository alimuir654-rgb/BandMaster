# Continuous improvement — single entry point

Start with [CHECK_BEFORE_WORK.md](CHECK_BEFORE_WORK.md), then [LESSONS.md](LESSONS.md), the append-only [ISSUES.jsonl](ISSUES.jsonl), [CURRENT.json](CURRENT.json) and its session. This is the canonical policy for future work, not another competing sprint plan. Original records are indexed in [SOURCE_AUDIT.md](SOURCE_AUDIT.md); exact current owner direction is in [OWNER_FEEDBACK.md](OWNER_FEEDBACK.md).

The goal is the mockups. Engineering validation, internal visual comparison and owner acceptance are three different decisions.

## Operation
Before implementation, commit a scoped session containing current document hashes, the reviewed issue-log prefix, relevant BM IDs, original target hash/locator, actual pixel-inspection record, protected sources, baseline and controlled comparison. Run `python3 tools/improvement_gate.py check --session docs/continuous_improvement/sessions/<ID>.json`.

Every new issue or recurrence is appended BEFORE the next implementation iteration. Prepare a JSON event with event_id, id, event, observation, expected, evidence, severity, cause_confidence, prevention, verification, recorded_at, owner_role, affected_paths and next_action, then run `python3 tools/improvement_gate.py append --event <event.json>`. Refresh the active session's reviewed issue prefix only after actually reviewing the added event. Use `recurrence` for an existing BM ID and `new_issue` for a new ID; add its durable prevention to LESSONS.md.

At closeout, retain failed attempts and report tested SHA/run/artifact, actual images inspected, outstanding gaps, five simulated lenses and next action. A resolved engineering error does not resolve an art rejection. Do not infer approval or delete history.

## Limits
The automated gate validates records, history and scope; it cannot prove a reader looked at pixels or decide visual fidelity. It is not branch protection and cannot prevent arbitrary local editing. Policies apply on branches containing these changes; main is deliberately untouched until an owner-authorised integration. No automatic recurring schedule is created by this function.
