# BandMaster asset-base production — owner-authorised 28–29 October 2026

## Authority and deadline
The owner has authorised overnight and daytime work on three workstreams: scene backgrounds/frames, direct controls/meters, and character artwork. The last two-material experiment is sufficient to continue, NOT approved finished artwork. The owner subsequently instructed: if visual quality is not on track for the 16:00 review, adjust the plan rather than continue an ineffective approach.

Review: **Thursday 29 October 2026, 16:00 Europe/London**. Preserve that deadline; change priorities, technique and breadth, not the quality standard. No routine approval requests. Ask only for genuinely necessary major decisions involving cost, destructive scope or a change of artistic direction. No purchases, engine migration, production save changes, main edits, merges or changes to PR #199.

This authority supersedes the earlier 28 October 19:00 stop and one-recruitment-only scope solely for an isolated reusable asset base and assembly demonstrations. It does not authorise broad gameplay work or production rollout. Use branch `dual-frame-proof-2026-10-28` as the sole writer branch.

## Operational schedule
The enabled automation `BandMaster asset production` has 17 finite hourly opportunities from approximately 23:00 on 28 October through 15:00 on 29 October. These are flexible-time scheduled invocations, not a continuously running worker and not a claim of 17 full hours of work. A separate enabled `BandMaster 16:00 review` task runs at the review deadline.

One controller/writer services the three workstreams. Do not launch three competing writers. At every invocation inspect live branch head, STATE, LEDGER, latest native CI and actual prior screenshots. Resume the next unfinished eligible deliverable; do not restart completed tasks. A delayed invocation evaluates all due quality checkpoints at its actual start time, in one review, without duplicating missed work.

## Retain the verified baseline
- Baseline branch head at authorisation: `cbed9cb222e44e7bfe4e1c3c5274b2ef5ba7fc68`.
- Tested implementation: `8efb9e547f6f147237179b4439a91566e3ceae68`.
- Native Godot 4.7.2 run: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40778019754
- Artifact: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40778019754/artifacts/12854794234
- Artifact SHA256: `db8b580c5b672196286b44e538ff28918045073e44bda9a87ffcf019dae7f3cd`.
- 32 captures and zero recorded assertion failures were reported and inspected in the previous experiment. That establishes a technical baseline, not current or future art acceptance.
- Read `docs/dual_frame_proof/2026-10-28_MATERIAL_EXPERIMENT.md` and `2026-10-28_VERIFIED_SESSION.md` before new work.
- Preserve `.github/workflows/art-material-proof.yml`, `experiments/art_material/prepare_art.py`, `refine_art.py` and the successful render/test path. Inspect actual source before editing; prefer maintained source files over blind workflow string replacement.

Known baseline gaps: no standalone Alex/Nia portraits; paper buttons too plain; uniformly heavy metal tabs; crowded phone safe insets; oversized tablet environment image. The room photo is an explicitly labelled environment study, never a musician portrait.

## Three workstreams and target deliverables
### C — Character artwork (first production slot)
First produce two genuinely different standalone documentary-photographic-style fictional musician masters for canonical Alex Vale (`alex`) and Nia Griffiths (`nia_griffiths`). Read the catalogue, including their identity/background, before art direction. Minimum 1024 pixels on the shorter source dimension; useful face and upper-body detail, coherent lighting/colour/photographic treatment, room for portrait and landscape crops. Derive thumbnails from each person's own source master.

The deliverable is the individual source image, not another recruitment UI concept. One subject per generation brief; no interface, labels, statistics, logos or collage. Do not crop faces from approved full-screen studies. Never upscale the 160px legacy image and call it a master, assign the same face to different IDs or misrepresent a stock model as a named real person. Store generation/source context and honest rights basis. If the actual scheduled runner lacks image generation, record that verified capability limit immediately; do not spend repeated slots announcing the same absence or fabricate source images. Use available authorised no-cost production routes and preserve the photographic direction. Extra cast members are secondary until the two anchors pass internal visual inspection.

### F — Scene backgrounds and frames
Develop two genuinely different reusable families: dark flight-case/backstage/night and light notepaper/rehearsal/day. Produce independently usable material surfaces, scale-safe borders/corners, portrait mounts and dossier panels. Reserve calm text-safe regions; preserve physical hardware proportions. Phone/tablet and landscape compositions must be deliberate, not cropped copies of one flat full-screen plate. Additional environment variants follow only after the anchor families look convincing in native Godot. Source filenames, dimensions, alpha, crop/safe areas, nine-slice margins and hashes are part of delivery.

### U — Direct controls and passive meters
Reuse source-verified Lab07/Lab08 inputs rather than redraw inferior defaults. Build a coherent core family of action buttons, tabs/segmented selectors, browse controls, linear/rotary inputs and separate read-only meters. Normal, hover, pressed, selected, disabled and keyboard-focus states must be deliberate where applicable. Keep native labels and real signals. Inputs need >=44 physical-pixel hit areas and keyboard behavior; read-only red/amber/green stats never accept focus or input. Light states must agree with values at 0/25/50/75/100 with no residual glow or slider lines. Test dark controls within a credible housing on a light day surface rather than floating on paper. Do not proliferate variants until core material quality passes.

## Adaptive visual checkpoints — mandatory decisions, not reports alone
At the first invocation on or after each time, open actual source and native image evidence, assess the five lenses below, then record the resulting priority change in STATE/LEDGER.

| Checkpoint, 29 October | Required evidence | Required adjustment when off track |
|---|---|---|
| 02:00 | Usable standalone character production route and tangible progress on both material families/core controls | Stop repeated failed generation or ingestion method; correct the route. Prioritise the missing dominant image/material over minor controls. Record a precise capability blocker if real; advance an unblocked stream while preserving the character gap. |
| 06:00 | Internally credible source kit spanning characters, frames and controls, with first integrated source-to-Godot comparison | Suspend extra scene variants and extra cast. Concentrate on the minimum convincing two-look, two-character core kit. Do not add decorative breadth while anchor quality is weak. |
| 10:00 | Both native looks readable and recognisably close to the chosen material targets; no placeholder presented as finished | Allocate remaining production slots to the largest observed visual gap. Replace/rework weak source assets rather than code-polish. Preserve verified successes and avoid a new infrastructure rebuild. |
| 12:00 | Review-candidate native images and working core assemblies with reproducible source links | Freeze optional families. Correct only dominant visual failures, import/layout/input defects and missing evidence. No late broad redesign. |
| 14:00 | Four-viewport proof and pack assembly | No new asset families. Validate, correct release-blocking defects, package source/state atlases and verify links. |
| 15:00 | Stable last-verified review candidate | Stop implementation writes. Final evidence/index updates only; preserve latest proven build if another CI run is unfinished. |
| 16:00 | Links-first owner review | Report proven results and remaining gaps honestly. No new code, automatic extension or merge. |

The minimum convincing kit is two material families, two distinct anchor characters, and a coherent core action/tab/browse/read-only-meter assembly, presented in real native layouts. Linear/rotary controls should reuse already proven assemblies where possible. Breadth is expendable; quality is not. A lower count of excellent reusable assets is preferable to a large provisional catalogue. Missing a core element remains an explicit partial/blocked result, never a reason to silently redefine success.

## Stop-loss and definition of done
- Every production invocation produces actual source artwork, an integrated component improvement or a concrete evidenced blocker. Planning/validator-only work is not visual progress.
- No more than one corrective continuation on the same family without demonstrable improvement in the opened images. After two ineffective attempts, change technique/decompose the source request or mark that path blocked and rotate. Do not re-run an unchanged blocked method every hour.
- Each artwork review compares target/source/native at useful physical size, including 390x844 and 1280x720. Also validate 720x1280 and 1600x900 for assemblies.
- Five simulated lenses: art direction (coherence/material/character presence), technical art (separation/crop/nine-slice), UI/accessibility (hierarchy/readability/focus), Godot engineering (signals/layout/state), QA/production (regression/source/evidence/priority). They are not separate human reviewers or independently deployed agents.
- Internal visual pass requires usable standalone source, coherent lighting/material treatment, legible live text, no stretched hardware, no missing/duplicate character substitution and observed native fidelity. Green CI, pixel-change percentage and asset counts do not confer art approval.
- Keep `owner_approved=false`. The owner authorised work, not final aesthetic acceptance.

## Persistence and reliable execution
Claim the writer slot with a conditional STATE blob update before asset/code writes. Include unique run ID, base head and lease time. Re-read head before the batch commit and use update_ref with expected_sha / non-force fast-forward. If head changes, fetch/reconcile; never force-overwrite. A lease alone is not proof a writer is alive; check latest commits and CI before reclaiming an expired slot. Record complete/partial/blocked plus source paths, tested SHA, CI run/artifact, images actually opened, remaining defect and next action for each stream.

Find PUSH CI using `GitHub.fetch` at `https://api.github.com/repos/alimuir654-rgb/BandMaster/actions/runs?head_sha=SHA&per_page=10`. The `fetch_commit_workflow_runs` wrapper filters pull-request events; an empty result there does not mean push CI is absent. Use actual run/jobs/artifact endpoints and download/open the PNGs. Binary `create_blob` supports base64; inspect real schemas before declaring image transfer impossible. Never put base64 into a file-parameter action. Keep scripts outside YAML where feasible, validate YAML/Python before commit and bound native tests so a parse failure cannot idle all night. Run screenshot capture with a real GL renderer/Xvfb, wait for frame_post_draw, verify both scene theme bindings and distinct images.

Consult retained official Godot guidance as needed: https://docs.godotengine.org/en/stable/tutorials/ui/index.html ; BoxContainer/containers and safe areas; StyleBoxTexture/NinePatchRect; texture imports/filtering; focus navigation; RenderingServer.frame_post_draw. Store implementation notes and source links, not unverified recollections. No migration from pinned Godot 4.7.2.

## Owner handover
By 16:00 provide a compact source/native comparison for both looks, control-state atlas, distinct-character contact sheet, runnable isolated Godot project, provenance/hashes and per-stream internal pass/partial/blocked verdict. Link only files and artifacts that exist. Preserve baseline comparison and separate new work from existing assets. Routine logs stay in the repository; do not ask the owner to find errors, repeat uploads or trigger CI. Capacity/source failures are disclosed, not disguised. This programme is finite and does not auto-extend.

## Owner direction — Thursday 29 October, 09:00 UK (verbatim)

> The progress here is reasonable. Keep it going till 4pm. I'm hoping for more progress and bigger ambition whilst retaining the quality. The meters look good.

This confirms the finite 16:00 review, *not* final artwork acceptance, merging or extension. Keep the liked six read-only red/amber/green meters unchanged absent a measured regression. Prioritise genuinely indie-credible individual Alex/Nia source masters; if no compliant source can be obtained without false rights/identity claims, keep P0 artwork HOLD and improve integrated two-look native composition instead. Reuse existing materials. Add only restrained native select/browse/recruit/remove feedback, not new systems. Evaluate 10/12/14/15/16 gates. Compare final native evidence with C12 and morning proof, disclose remaining weaknesses.
