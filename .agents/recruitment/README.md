# Reusable role instructions — not live agents

These five files are **instruction contracts**. A future coding agent or automated run can read the assigned file and act through the tools it actually has, but placing Markdown in a repo does not launch parallel autonomous agents. Each role must read root `AGENTS.md`, `docs/recruitment_recovery/00_SINGLE_SOURCE_OF_TRUTH.md` and the current `RECOVERY_STATE.json` first.

Recommended one-role-per-run sequence: `SPRINT_CONTROLLER.md` prepares → `ART_DIRECTOR.md` directs → `ASSET_PRODUCER.md` creates/intakes → `GODOT_INTEGRATOR.md` builds → `VISUAL_QA.md` verifies → controller closes. If one session plays multiple roles, keep the checks **separate and explicitly simulated**, without pretending they were independent human signoffs.

Do not auto-schedule, auto-merge, or upgrade tooling merely because role files exist.
