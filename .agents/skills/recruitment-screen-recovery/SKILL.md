---
name: recruitment-screen-recovery
description: Art-led BandMaster recruitment one-screen production and native Godot screenshot quality gates. Use for tasks on the recruitment recovery draft branch, never wider game features.
---

# Portable project-local skill definition (manual loading)

This skill is provided as a file **for agents that support project-local skills**; its presence does not install a live plugin, register a tool, start background work or guarantee auto-discovery.

**Required reading:** root `AGENTS.md`, `docs/ART_DIRECTION_PRODUCTION_CONTRACT_V4.md`, `docs/RECRUITMENT_REFERENCE_LOCK.md`, `docs/recruitment_recovery/00_SINGLE_SOURCE_OF_TRUTH.md`, `docs/recruitment_recovery/RECOVERY_STATE.json`, then one role in `.agents/recruitment/`.

**Goal:** two genuinely good musicians, one coherent art target, one faithful interactable Godot recruitment proof. Never propagate failed vector character art across scenes.

**Execute:** follow `04_SPRINT_PLAYBOOK.md`; record in `05_SPRINT_LEDGER.md`; validate with `python3 tools/recruitment_quality_gate.py --root . --stage prep`. Run appropriate actual Godot screenshot and mechanical tests when the code exists. Human owner art approval remains separate and binding.

**Stop:** any art P0, rights gap, hidden identity mismatch, fake native screenshot or wider scene request. Do not claim pass based on CI alone. Never change production saves or merge PR #199.
