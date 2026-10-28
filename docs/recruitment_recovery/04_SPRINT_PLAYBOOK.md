# Art-first sprint playbook — bounded, owner-low-touch

## Mode of operation

- Work in draft PR #199 branch or a new feature branch based on it; check remote head and active writers before any commit. Do not merge or alter production saves.
- Every run is assigned **one role, one artifact and one quality gate**. The sprint controller provides the exact previous verdict and one unblocker. No restart at sprint 0 because a new conversation begins.
- Timebox is a planning limit, not an excuse to claim 60 minutes of work when execution ran for seconds. Record actual elapsed duration when known; if unavailable, say "not measured".
- Maintain a *single* active state in `RECOVERY_STATE.json`; append preflight/result/lesson entries in `05_SPRINT_LEDGER.md`. A transient chat response is not a durable handoff.
- Progress without owner attendance: art director may issue **internal provisional** go/no-go to produce an isolated proof only. Collect **one final review packet** for the owner rather than asking at every intermediate step. The human visual/merge gate never transfers to an automated agent.

## Sprint sequence (dependency graph)

| ID | Owner | Deliverable | Precondition | Exit / stop |
|---|---|---|---|---|
| R0 | Sprint controller | This plan, source index, grounded role contracts, preflight test | None | Plan validator passes; art remains blocked |
| R1 | Art director + asset producer | One desktop + one intentionally different phone *target* composition and two distinct source portraits | Owner reference contract read; one coherent visual style chosen | Designer provisional P0 pass with exact files, or stop on faces/materials |
| R2 | Asset producer | Lossless, individually addressable portrait, paper, case, controls + rights/source manifests | R1 provisonal pass | Real layer sources with verified SHA/rights; no flattened UI |
| R3 | Godot integrator | ONE native scene representing target at 390 and 1280; 5 role tabs, 6 passive meters, real recruit state | R2 files confirmed | Actual Godot render + deterministic tests; no saves |
| R4 | Visual QA | Side-by-side, physical-size pixel inspection, specific P0 fixes, honest final report | R3 screenshot artifact | All P0 internally PASS or HOLD; prepare owner review |
| R5 | Owner | Review final real Godot screenshot/gameplay video or build; approve/reject visually | R4 report | Only explicit owner approval can unfreeze next screen/merge |

## Mandatory PRE-FLIGHT (before changing code/art)

1. Fetch latest branch head and check concurrent writer status.
2. Read root `AGENTS.md`, source V4 contract, reference lock, latest failed/native comparison, current state and last sprint ledger entry.
3. Name exactly ONE unresolved P0 that this work fixes. If no P0 exists, no hidden refactor.
4. Verify source art originals/manifest rights; distinguish real images, SVG code and design-only mockup.
5. State deliverable path, test command and expected screenshot sizes. Refuse to start broad work if missing.

## Art sprint delivery

- Capture actual image output (do not submit prompts alone as output); label design target clearly; subject-specific identity IDs; record generator/use conditions and rights basis without making unverifiable copyright claims.
- Produce real separate usable source layers, not one image with cropped labels; estimate/verify pixels before transfer.
- Compare two distinct characters without text names; if they read as one face, reject and correct before scaling candidate catalogue.

## Native sprint delivery

- Inspect `project.godot`, real existing nodes, source role data and existing test/capture scripts. Keep all native names, costs, roster and stats dynamic.
- Proven quality controls: reuse original photographic Lab07/08 sources where available; five states, manual focus, no game actions on inert meters.
- Run current CI and capture real 390×844 and 1280×720; extend to 720×1280 and 1600×900. Open the PNGs, not just a filename list.
- Check return-from-recruit and remove-once, candidate switching, 3–6 player hybrid role mechanics if exercised; no writes to `user://`.

## Mandatory POST-RUN

Append the single sprint ledger with: date/time, branch+head, actual changes, visual proof URLs and exact source screenshot filenames, what was tested versus not, P0/P1 findings, five simulated persona viewpoints, quality gate status, the next ONE corrective action and why. Update `RECOVERY_STATE.json` with honest stage and evidenced status. If no art was generated, say so. Do not mark `owner_approved` true.

## Failed run policy

If art P0 fails, next run stays at R1/portrait-art correction. If Godot art fidelity P0 fails, next run stays at R3/R4 regional correction; not feature breadth. If external assets remain unavailable, mark blocked with exact file/rights requirement, not a substitute vector. Do not repeat more research after the sources are already identified unless a concrete licence or tool blocker requires it.
