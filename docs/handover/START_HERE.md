# BandMaster — resume here
<!-- session: SONG56 -->
<!-- status: active -->

Repository: `alimuir654-rgb/BandMaster` · Branch: `feature/playtest-polish-v20`.

## Current task

Finish **SONG56**, the owner-requested visual Songbook/Demo revision, plus the approved continuity cleanup. One writer: `root-SONG56`. R2 is proposed; it is not part of this pass.

**Next action:** Complete the SONG56 archive-thumbnail repair and four-profile native review, verify compact continuity records, then publish the evidence and close this session.

## Read only what this pass needs

1. Run `python3 tools/project_context.py start` for current state, evidence pointers and review cursor.
2. Read relevant lessons with `python3 tools/project_context.py lessons --ids BM-22 BM-41 BM-43 BM-45`; add `--full` when the task needs the detailed extensions.
3. Run `python3 tools/project_context.py issues` for events after the session's verified review cursor. Reading never marks them reviewed.
4. Follow `AGENTS.md`, the applicable check-before-work rules and the existing [session](../continuous_improvement/sessions/SONG56.json). Commit any fresh or extended preflight before implementation.

## Verified checkpoint and remaining work

Source `5be37ae` passed early phone/short native [run43524469210](https://github.com/alimuir654-rgb/BandMaster/actions/runs/43524469210). Downloaded artifact14084761866 was verified by SHA256; originals were inspected. Cards, meters and the compact archive improve the presentation. A landscape thumbnail caption clips and is being repaired. Final four-profile proof and closeout are pending. This is not an owner acceptance or APK-delivery claim.

[Roadmap](../ROADMAP_LINKED_SONGS_AND_BAND_LIFE.md) · [Sole execution queue](../continuous_improvement/S80_EXECUTION_QUEUE.md) · [Current state](../continuous_improvement/CURRENT.json).

## Finish and hand off

Run the existing improvement gate and `python3 tools/project_context.py check`; complete relevant native/visual checks. Record exact tested source, evidence, issues, verdicts and one next action; release the writer and publish with expected-head, non-force verification. Report **changed / checked / remaining / next**, with selected evidence links. Checkpoint meaningful progress before a chat ends.

Full prior records are preserved in [the history manifest](archive/SONG56_5be37ae/MANIFEST.json). Open historical files only for a specific unresolved question; they do not supersede current scope. The issue log remains append-only.
