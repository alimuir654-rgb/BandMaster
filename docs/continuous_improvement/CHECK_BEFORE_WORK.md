# Mandatory check before every work session

**Goal: reproduce the quality and visual language of the owner-approved mockups in usable native components. Do not lower the target to the current implementation.**

1. **Authority and continuity.** Read the latest owner request, AGENTS.md, CURRENT.json and the latest session/ledger. Confirm branch/head and exclusive writer. Historical queues/deadlines do not override a newer direct request; a new request is not permission to merge or alter saves.
2. **Lessons and recurrence.** Read LESSONS.md and every new ISSUES.jsonl event since the last session. Select the relevant lesson IDs, the single dominant issue and its prevention checks. Do not repeat failed methods or restart completed work.
3. **Target and baseline.** Actually open the relevant mockup and latest native failure. Pin original reference identity/hash, baseline code and source assets. A textual target alone is not evidence of viewed reference pixels; record a blocker when a required source is absent.
4. **Reuse and safety.** Inventory existing assets/APIs first. Confirm true source type, rights, dimensions, complete dependencies and canonical data. List protected art/logic/saves. Keep mockup composites out of production textures.
5. **Controlled hypothesis.** State exactly what should visibly improve and why. Keep A/B content, viewport, state, background and frame bounds constant. Define what would count as regression and the method-change/stop condition.
6. **Commit preflight before implementation.** Create/update a scoped session with current document hashes, the reviewed issue-log prefix, target, baseline, paths and tests. Run `python3 tools/improvement_gate.py check --session docs/continuous_improvement/sessions/<ID>.json`. The record must be committed before code/art changes. Do not tick without evidence.
7. **Execute and inspect.** Implement, run clean import/behaviour tests, render native 390x844/720x1280/1280x720/1600x900, open original PNGs, compare to the mockup and baseline. Keep technical, visual and owner gates separate. Do not alter tests/goldens to disguise defects.
8. **Log immediately.** On every new failure or recurrence, append an event to ISSUES.jsonl BEFORE the next implementation iteration; give expected/observed, evidence, severity, cause confidence, corrective action, prevention and verification. Reuse existing lesson IDs. Two ineffective attempts require a changed method or explicit hold.
9. **Close honestly.** Record exact files, tested SHA/run/artifact, images opened, remaining gaps, five simulated review lenses and ONE next action; update the live state/ledger and release the writer. Keep `owner_approved=false` unless the owner explicitly approves the specific result. No automatic extension or merge.

## Enforcement boundary
The gate validates a current, scoped, source-linked record and append-only issue history. It cannot prove someone read an image or automatically judge artistic quality. Native pixel inspection and owner acceptance remain separate. CI cannot prevent a local edit, and branch-protection settings are not changed by this policy.
