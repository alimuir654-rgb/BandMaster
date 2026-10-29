# Continuous improvement: lessons that must govern every task

**The goal is the mockups.** A working approximation, a larger asset count and green CI are not the visual target.

Consolidated 29 October 2026 from 125 tracked Markdown records / 87 unique versions across the current component, main and recruitment-recovery branches, supplemented by the available 23–29 October owner conversation. All unique records were surveyed for policies and recorded failures; critical lesson registers, reviews, root-cause analysis and current frame source were inspected in detail. Historical tests were not rerun by this audit. This is the known recorded failure register, not a claim to recover every unrecorded incident. Source keys resolve in SOURCE_AUDIT.md.

**Current acceptance:** C21 notepaper is an owner-rejected visual regression. Preserve its functional hardening; C20 is the recovery baseline, not the ultimate goal. Preserve owner-liked meters. Backgrounds and character production are deferred. Expired portrait-first queues do not govern the current frame task.

Read this and CHECK_BEFORE_WORK.md before every task. Review all new ISSUES.jsonl events. Preserve history, append new occurrences, and require evidence to resolve a defect.

## Art direction and acceptance

### BM-01
**What went wrong:** Native screens repeatedly passed tests while remaining far below the approved mockups, including V3, V4 and recruitment recovery.
**Prevent:** Keep engineering, visual fidelity and owner acceptance as independent gates. Technical success cannot close an art defect.
**Proof:** Native target/baseline/candidate comparisons with explicit material, composition, readability and interaction-state verdicts. Sources: V4, ROOT, RUBRIC.

### BM-02
**What went wrong:** Photographic/tactile targets were replaced by flat StyleBoxFlat/SVG surfaces, procedural shapes and isolated decorative metal fragments.
**Prevent:** Produce suitable independent source art first. Godot handles layout, live text and input; it must not supply a cheap imitation of missing material.
**Proof:** Inspect source art at intended display density and the integrated native screen, not just code or texture filenames. Sources: V4, ROOT, RESEARCH.

### BM-03
**What went wrong:** C21 paper reconstruction discarded the previous edges and depth, replacing them with regular sheets, drawn corners and tape-like patches. The owner judged it worse.
**Prevent:** Preserve the strongest existing construction. Branch a candidate instead of replacing the visual baseline. Source-backed describes provenance, not quality.
**Proof:** Same-size/content/background/state comparison of mockup, C20, rejected C21 and candidate. Never promote a regression. Sources: C21, OWNER.

### BM-04
**What went wrong:** Reducing heavy shadows flattened the paper; warming its grain later did not restore convincing edge construction.
**Prevent:** Change one diagnosed property at a time. Preserve contact shadow, layered thickness and irregular edges while reducing only excessive cast shadow.
**Proof:** Edge inspection at 100% and native phone/desktop size; explicitly judge depth and separation. Sources: C21, OWNER.

### BM-05
**What went wrong:** Gallery layout, content and proportions changed alongside artwork, making before/after comparisons misleading.
**Prevent:** Hold viewport, background, content, state and frame bounds constant for component A/B tests. Gallery cleanup is a separate change.
**Proof:** Controlled A/B capture manifest. Broader scene screenshots supplement, rather than replace, it. Sources: C20, C21, OWNER.

### BM-06
**What went wrong:** Asset/commit/screenshot counts, pixel-change percentages and labels such as cleaner or premium substituted for visible quality.
**Prevent:** Judge distance to the mockup, not activity. Image difference measures change, not artistic merit.
**Proof:** Name exact improved and failing regions. Keep owner_approved=false until explicit acceptance of that result. Sources: ROOT, RECOVERY, ASSET.

### BM-07
**What went wrong:** Unrelated material packs, repeated heavy surrounds and dark controls floating on light paper weakened cohesion.
**Prevent:** Use one deliberate material/light language per look and purpose-specific frames. DAY must be genuinely lighter; night is not an excuse for empty black panels. Game phase, not the user's clock, controls game lighting.
**Proof:** Native day/night composition review: coherent light, edge scale, hierarchy, hardware housing and contrast. Sources: SWEEP, SCENES.

## Source artwork, import and reuse

### BM-08
**What went wrong:** Whole-screen generated mockups were mistaken for, or delivered instead of, segmented production assets.
**Prevent:** References remain design-only. Keep independent frame/control/portrait textures separate from native data and labels. Never ship a screenshot with invisible click targets.
**Proof:** Manifest differentiates reference, source layer, derivative and native capture. Sources: ASSET_BIBLE, R1, ROOT.

### BM-09
**What went wrong:** Standalone-portrait attempts repeatedly returned annotated UI collages; essentially the same unsuccessful route was retried across runs.
**Prevent:** Record actual tool/output failures. After two ineffective attempts change the production method or explicitly hold that source and move to authorised unblocked work. Do not speculate that Instant/Pro/model tier caused it.
**Proof:** Inspect output type and retain attempt/method-change history. A new prompt is not a finished asset. Sources: ASSET, C08, OWNER.

### BM-10
**What went wrong:** 160px portraits were enlarged; 512px paired-origin studies were still not independent high-resolution masters.
**Prevent:** Record true source dimensions and origin. No enlargement passed off as detail, cloned faces, UI-cropped portraits or paired-origin derivatives labelled independent masters.
**Proof:** Identity/source/crop hashes and label-free identity review at intended sizes. Sources: PORTRAIT, V4, C15.

### BM-11
**What went wrong:** 1024px corporate-looking headshots met resolution checks but failed the UK indie-musician brief; grading could not repair casting.
**Prevent:** Assess brief fit, wardrobe/context, distinctive identity and style before resolution/variants. Replace an unsuitable source rather than repeatedly grade it.
**Proof:** Compare with the approved direction and gritty provisional reference before integration. Sources: C15, ASSET, OWNER.

### BM-12
**What went wrong:** Wide portrait frames cropped out faces; tablet photographs dominated decisions.
**Prevent:** Use focal-safe crops and deliberate aspect-specific layouts, not unrestricted cover-stretch everywhere.
**Proof:** Both identities at four viewports, live resizing and first-fold decision review. Sources: C08, C15, ASSET.

### BM-13
**What went wrong:** Chat ZIPs, repository ZIPs and extracted resources were conflated. Patch-only Lab08 bundles lacked neutral bases and required earlier sources.
**Prevent:** Verify bytes, SHA, extracted paths and patch dependencies in the actual branch. A ZIP at root is not an imported res:// resource. Do not request an accessible upload again.
**Proof:** Source-intake manifest and clean import of the complete dependency chain. Sources: INTAKE, LAB08.

### BM-14
**What went wrong:** Source descriptions could confuse image-generated photorealism, real photographs, CC0 synthetic people and procedural composites.
**Prevent:** Record actual source type/provider, known rights basis, original hash and transforms. Never invent licences, model releases or claims of photography.
**Proof:** Traceable provenance retained with derivatives; unresolved rights remain a block. Sources: INTAKE, PHOTO, C15.

### BM-15
**What went wrong:** Assets and verified logic on another branch were assumed present, causing broken paths or duplicate implementation.
**Prevent:** Check branch-specific trees and reuse known good sources by pinned commit. Do not replace working Lab07/Lab08 controls with weaker newly built alternatives.
**Proof:** Inventory of reused paths, source commits, dependencies and protected hashes. Sources: SWEEP, C20, INTAKE.

### BM-16
**What went wrong:** Mockups contained invented names/prices/stats, including Nia Carter; sample environments could be mistaken for character evidence.
**Prevent:** Use the real catalogue: Alex Vale/alex, Nia Griffiths/nia_griffiths, five roles and 200 initial talent where recruitment is exercised. Keep values/native text out of source art.
**Proof:** Data-to-view assertions and honest sample/provisional labels. Sources: DATA, R1.

## Controls, layout and accessibility

### BM-17
**What went wrong:** Passive outcome/stat meters risked being treated as editable faders/knobs.
**Prevent:** Passive meters receive no input, focus or value-changing signal. Preserve the owner-liked artwork unless fixing a demonstrated defect; do not redesign it to fill a sprint.
**Proof:** Original byte hashes plus native mouse/key/focus tests. Sources: SWEEP, C20, OWNER.

### BM-18
**What went wrong:** Moving faders left residual lines; rotary lights had stray segments, inaccurate maxima and release flashes.
**Prevent:** Use neutral off bases, separate caps/pointers and independent illumination layers. Distinguish a fixed position indicator from value-dependent light.
**Proof:** Native zero/partial/maximum and release captures, not just numeric assertions. Sources: SWEEP, LAB08.

### BM-19
**What went wrong:** Nine-slice scaling stretched screw heads and buttons or repeated corner hardware.
**Prevent:** Preserve fixed source detail, consistent slice/content margins and proportional artwork. Never stretch a fixed-size object across an edge.
**Proof:** Native minimum/maximum aspect ratios, alpha edges, margin metadata and source review. Sources: C20, MATERIAL.

### BM-20
**What went wrong:** Silent ButtonGroup updates allowed multiple selections; selected-hover, disabled and focus states were confused.
**Prevent:** Test exclusive and latched selection, hover, press, focus and disabled independently. Each input produces one signal and one state change.
**Proof:** Real mouse/key events, programmatic changes and a visual state atlas. Sources: SWEEP, C20.

### BM-21
**What went wrong:** Large banners/portraits and repeated status cards hid useful actions; tablet/desktop compositions wasted space.
**Prevent:** Put context, cost/consequence, one primary action and return route in the first fold. Phone is an intentional composition, not scaled desktop.
**Proof:** Reading-order/native first-fold review at 390x844,720x1280,1280x720,1600x900. Sources: UX, V29, ASSET.

### BM-22
**What went wrong:** Long labels and zero-width autowrap expanded containers, overlapped neighbours or pushed actions offscreen. In-bounds text was not necessarily readable.
**Prevent:** Bound long content, reserve safe insets and use scrolling where needed. Test long names/text and physical readability, not only node rectangles.
**Proof:** Long-copy, narrow-width, larger-text and live-resize captures with visible actions. Sources: SWEEP, C21, UX.

### BM-23
**What went wrong:** Logical-coordinate tap checks missed parent scaling: 44 logical units were not necessarily 44 physical pixels.
**Prevent:** Measure transformed target bounds in the rendered window. Keep 44px physical minimum targets and sensible body text; regression font floors are not design goals.
**Proof:** Real-renderer physical geometry tests at actual viewport dimensions. Sources: SWEEP, RESEARCH.

### BM-24
**What went wrong:** Modal-looking panels lacked actual modal behaviour; focus/scroll/return continuity and lifecycle were incomplete.
**Prevent:** Test Tab/Shift-Tab, Escape, focus ownership/restoration, background input, repeated opening and an invalid/disabled invoker. State unsupported behaviours.
**Proof:** C21 dialog/lifecycle tests and separate-host integration. Arbitrary forms/stacked dialogs remain outside the verified contract. Sources: C20, C21, UX.

### BM-25
**What went wrong:** Actions felt disconnected and instantaneous; some OPEN labels implied navigation that did not exist.
**Prevent:** Reuse real browse/select/recruit/remove flows with restrained feedback and clear disabled remedies. Do not add animation to disguise bad art or fake actions to imply completion.
**Proof:** Complete stateful interaction journey; a static atlas is not scene acceptance. Sources: UX, SWEEP, OWNER.

## Godot, CI and evidence reliability

### BM-26
**What went wrong:** A Control script redeclared built-in material, causing parse failure; missing mobile was a downstream cascade.
**Prevent:** Check inherited API names and fix the first parse error before chasing dependent symptoms.
**Proof:** Clean import with explicit script-error detection and successful scene instantiation. Sources: OWNER, DUAL.

### BM-27
**What went wrong:** Code attempted to change HBoxContainer orientation and failed in native rendering.
**Prevent:** Use the appropriate container type or deliberate separate layouts. Verify the actual engine API instead of borrowing assumptions from another framework.
**Proof:** Native portrait/landscape/resize tests without orientation errors. Sources: OWNER, DUAL.

### BM-28
**What went wrong:** GDScript phone and 12 or 16 returned Boolean logic, producing a 1px font despite green geometry tests.
**Prevent:** Use GDScript conditional syntax and explicit types where inference is hazardous. Parse success does not validate intended values.
**Proof:** Computed font/value assertions plus actual caption inspection. Sources: NATIVE04.

### BM-29
**What went wrong:** Dummy headless rendering returned null textures; save_png was called on null and capture stalled.
**Prevent:** Use real GL/Mesa/Xvfb for images, await frame_post_draw and validate the texture/image. Treat headless import as a separate test.
**Proof:** Nonblank original PNGs, correct dimensions, renderer/version logs and bounded exit status. Sources: OWNER, DUAL.

### BM-30
**What went wrong:** Invalid YAML blocked workflows; smoke tests continued after errors or hung; a green structure check was mistaken for the relevant result.
**Prevent:** Validate YAML, fail on relevant logs, bound commands/jobs and inspect the correct native workflow at the exact SHA.
**Proof:** Required steps, assertions and downloadable artifacts from the correct successful run. Sources: OWNER, DUAL.

### BM-31
**What went wrong:** Templates referenced res://gallery.gd at the wrong project root; standalone success did not prove drop-in reuse.
**Prevent:** Separate templates from importable scenes and scope module resources. Test in another host without replacing its project.godot.
**Proof:** Repository reference checks and standalone AND independent-host native tests. Sources: C20.

### BM-32
**What went wrong:** Overlapping native windows caused pointer-test failures in the harness; emitting signals would have hidden actual input faults.
**Prevent:** Diagnose window/viewport focus and event routing. Exercise genuine events in the application window, not synthetic signal-only success.
**Proof:** Pointer/keyboard diagnostics and once-only action assertions. Sources: C20.

### BM-33
**What went wrong:** Blind regex/source injection and stale transformed path assertions broke later integrations.
**Prevent:** Read current source. Prefer stable functions/configuration and precise patches. Distinguish an obsolete assertion from a product failure with evidence; never weaken checks to get green.
**Proof:** Negative tests, clean import and preserved relevant regressions. Sources: C08, C15, C20.

### BM-34
**What went wrong:** Old successful runs, untested HEAD and publication commits could be confused; a pull-request-only wrapper missed push runs.
**Prevent:** Query by exact SHA/event. Distinguish tested source, published module and documentation commits. Download/hash artifacts before claiming pixel inspection.
**Proof:** Run ID, tested SHA, artifact/digest, original PNG names/dimensions and images actually opened. Sources: ASSET, C20, C21.

## Gameplay and save safety

### BM-35
**What went wrong:** Early reload failures and coexisting intro/career loops risked broken handoff or destructive migration.
**Prevent:** Preserve schema and old-save fixtures; use additive idempotent handoff. Never reset saves to hide bugs or let isolated proofs mutate production user:// data.
**Proof:** New/legacy/mid-action save-load round trips and no duplicate introductory reward. Sources: STATE, V22, OWNER.

### BM-36
**What went wrong:** Booking, performance, recruitment and writing could spend before validation, settle twice or diverge between preview and commit.
**Prevent:** Reuse authoritative pure models; validate before spending; copy preview state; make completion/refund/remove idempotent.
**Proof:** Repeated/cancelled actions, insufficient resources, invalid/duplicate titles and prior-state immutability. Sources: V22, ROADMAP, SWEEP.

### BM-37
**What went wrong:** Campaign simulations passed invariants while exposing unrealistic song throughput and profitable low-risk gig exploits.
**Prevent:** Separate deterministic execution, balance and player experience. Preserve credible formation, social, writing and rehearsal preparation before gigs.
**Proof:** Outcome thresholds and player-experience review; no release claim from simulations alone. Sources: V22.

## Work control, ownership and reporting

### BM-38
**What went wrong:** Research and persona objections were repeatedly recorded but did not trigger stop conditions or changed priorities.
**Prevent:** Every issue needs a responsible role, preventive check, evidence and closure condition. Recurrence escalates; unrelated polishing does not resolve an art P0.
**Proof:** Current issue-linked preflight and closeout, recurrence log and one next action. Sources: ROOT, SWEEP, ASSET.

### BM-39
**What went wrong:** Hours of micro-polish and optional breadth displaced the largest visible gap.
**Prevent:** Choose one meaningful material/player-facing outcome, cap ineffective corrective continuations at one, reduce breadth before quality and retain completed work.
**Proof:** Obvious before/after improvement or an explicit changed-method/hold decision. Sources: PLAYBOOK, ASSET, OWNER.

### BM-40
**What went wrong:** Repeated stops asked the owner to inspect logs, re-upload accessible assets or make routine implementation choices.
**Prevent:** Retrieve available evidence and complete the implement-test-render-inspect-correct loop independently. Escalate only necessary major, cost, destructive or owner-only decisions.
**Proof:** Review-ready native evidence and a factual result, not another vague plan or promise. Sources: OWNER, PLAYBOOK.

### BM-41
**What went wrong:** Overlapping writers and multiple queues risked duplicate work and overwriting newer results.
**Prevent:** One writer; live head/lease checks; non-force expected-SHA publication. Preserve active work and reconcile moved heads.
**Proof:** Scoped diff, writer identity, base/tested/published SHAs and explicit release. Sources: PLAYBOOK, ASSET.

### BM-42
**What went wrong:** Hourly invocations could be described as continuous work; model tier and capabilities were overinterpreted.
**Prevent:** Verify tool/scheduler outcomes. Claim only executed work; no imaginary agents/models or background progress. Preserve finite deadlines unless directly reauthorised.
**Proof:** Actual scheduler/run outcomes and timestamps; precise capability blockers without speculative causes. Sources: PRO, PLAYBOOK, OWNER.

### BM-43
**What went wrong:** Stale portrait-first instructions, multiple ledgers and old PASS labels obscured current frame priorities and later rejection.
**Prevent:** One canonical preflight and append-only issue history. Latest owner scope wins; archive superseded instructions and append corrections without rewriting history.
**Proof:** Policy hashes, exact owner direction, pinned source records and current acceptance status. Sources: AGENTS, ASSET, OWNER.

### BM-44
**What went wrong:** Simulated personas and permission to continue could be confused with independent expert review or final approval.
**Prevent:** Label simulated lenses honestly. Approval of direction, first pass or meters does not approve every asset, release or merge.
**Proof:** Separate engineering, internal visual and owner verdicts; owner_approved=false by default. Sources: RUBRIC, C20, C21, OWNER.

### BM-45
**What went wrong:** Tiny commits, repeated full-suite rebuilds and redundant documentation consumed production capacity.
**Prevent:** Batch related changes, reuse the verified pipeline, run focused tests then integration checkpoints. Documentation must change behaviour, not substitute for production.
**Proof:** Scoped change/evidence audit and a useful deliverable; repeated identical screenshots are not new work. Sources: PLAYBOOK, C20.

### BM-46
**What went wrong:** Tool/plugin/research suggestions distracted from known source-art gaps or implied licence/API support without verification.
**Prevent:** Reuse available assets/tooling first. Verify a concrete missing capability and rights/API. No paid plugin, engine migration or runtime dependency without owner authority.
**Proof:** Specific need and compatibility/source evidence, not more speculative research. Sources: RESEARCH, FIGMA, PRO.

## Continuous learning loop

Before the next implementation iteration, append every new failure/recurrence to ISSUES.jsonl with expected/observed behaviour, evidence, severity, cause confidence, affected files, responsible role, prevention, verification and next action. Reuse an existing BM ID for recurrence. After two ineffective attempts change the method or hold the work. Never delete failed attempts, silently change an accepted visual baseline or infer owner approval. Keep engineering, internal visual and owner verdicts independent.
