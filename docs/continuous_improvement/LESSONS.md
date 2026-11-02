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

S63 extension: measure the longest unbroken word using the actual native Label font and size, then subtract the real button housing margins from the available card width. RECONDITIONED needed131px at16px, while the narrow two-column card had116px of clear housing width. Child containers do not automatically enlarge a Button's minimum. Change a narrow gallery to horizontal art/text rows when the full word cannot fit; preserve type size, complete names and native prices. Guard deferred responsive layout against freed/out-of-tree owners and keep the fit idempotent. The repaired lower drum card was then captured through genuine Tab navigation, with full-word, housing, input and save guards.

S68 extension: a short numeric status chip must provide its full native text minimum. Inheriting WORD_SMART from the generic paper-label factory while shrinking a GridContainer reduced three panels to their margins and wrapped letters vertically. Nonwrapping printed16 labels restored natural text-plus-padding widths at phone and wide sizes; retain complete values and wrap whole chips if a future supported set does not fit. A naturally fitted tall Details page is valid: verify its full copy and zero-scroll gesture, then resize the same retained view for the original strict overflow/touch proof and restore it before paid actions. Do not add fake padding, shrink text or require overflow where all content is visible.

S71 extension to BM-22: naturally small positive overflow is a third case between a fitted page and a long scroll. Record the actual clip, page and content range. Exercise the available small movement without demanding an impossible 24px change, then resize the same retained view to a genuinely overflowing window and retain the original strict range/drag proof. Restore its original size before paid actions; do not add padding or shrink type to satisfy a fixture.

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

S71 extension to BM-30: successful engine execution can precede failed artifact copying when the workspace fills. Persist phase results before copying, preserve partial targets and original captures, and resume only the missing step from the same verified source and required fixture. Reproducible import caches may be cleared only from a precomputed closed-run allowlist with a persisted intent and a bound checked BEFORE deletion; never include source, original images, saves, logs, packages or keys. A cleanup loop's limit checked after mutation does not enforce that limit; disclose the actual completed deletions and stop.

### BM-31
**What went wrong:** Templates referenced res://gallery.gd at the wrong project root; standalone success did not prove drop-in reuse.
**Prevent:** Separate templates from importable scenes and scope module resources. Test in another host without replacing its project.godot.
**Proof:** Repository reference checks and standalone AND independent-host native tests. Sources: C20.

### BM-32
**What went wrong:** Overlapping native windows caused pointer-test failures in the harness; emitting signals would have hidden actual input faults.
**Prevent:** Diagnose window/viewport focus and event routing. Exercise genuine events in the application window, not synthetic signal-only success.
**Proof:** Pointer/keyboard diagnostics and once-only action assertions. Sources: C20.

S71 extension to BM-24/BM-32: reduced-motion replacement can put a legitimate new acknowledgement exactly beneath the previous action coordinate. Trace the actual GUI receiver and unchanged transaction/save counts before labelling the second input a duplicate-settlement bug. Freeze immutable receiver identity and geometry before dispatch: a pressed callback can free the node, so a later node-null comparison is not reliable evidence that the event was unarmed. Preserve both fresh result inspection and the old-coordinate input proof.

### BM-33
**What went wrong:** Blind regex/source injection and stale transformed path assertions broke later integrations.
**Prevent:** Read current source. Prefer stable functions/configuration and precise patches. Distinguish an obsolete assertion from a product failure with evidence; never weaken checks to get green.
**Proof:** Negative tests, clean import and preserved relevant regressions. Sources: C08, C15, C20.

S63 extension: a genuine touch fling can leave scroll and target geometry moving after release. A fixed eight-draw settlement window is not a quiescence proof. Preserve the failed probe and observe actual integer/fractional scroll values and target/clip rectangles across completed draws, with a finite deadline and unchanged clip/input/save assertions. Current wide proof observed55 changes before154ms stationary; the observer never cancelled motion or assigned scroll. The earlier failure's inertia explanation remains inferred because the card composition changed separately before the new run; do not turn that hypothesis into a proven product or engine defect.

S68 extension: calling a geometry assertion immediately after a real Menu/Continue view rebuild can inspect live nodes before any native allocation. The same product showed a 0×0 scroll clip and margin-only pill panels before drawing, then identical valid geometry at two completed draws. Record the initial rectangles and bounded postdraw samples, reacquire current targets and retain every original clipping/value/paid/save assertion. A later failure PNG already waits for draw and cannot establish the earlier assertion geometry by itself.

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

S69 source-intake clarification: an adapter that already applies Story/milestones and Finance is a completed transaction, not an intermediate campaign result. New interview choices must be composed before those downstream steps, using the original campaign once and truthful fresh campaign/journal/receipt facts. Do not call an already-accounted launch and then add bonuses. This is a source-audited prevention rule for the proposed radio visit, not a claimed implemented or runtime-tested journey.

S71 verified extension: keep unfinished activity metadata outside a fingerprinted demo and outside the canonical completed-campaign flag. Lock the original index as well as ID/fingerprint, revalidate at final wrap, and save each explicit phase with whole-career rollback. Compose answer effects before Story/Finance, record truthful signed capped outcomes, and retain the legacy direct API only when no active visit exists. Exact509 native four-view journeys and the independently reused 48-input model closure verify this radio implementation; presentation/reveal/reload never resolves the activity.

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

## 31 October native-image review clarification — BM-34

Repeated heading and ordinal content was interpreted as missing during image review, but the saved PNG regions were pixel-identical. Before changing rendering resources for suspected missing content, compare the original full-resolution pixel regions at the same state and bounds. Check actual ink/alpha pixels as well as node properties. An image-view interpretation alone does not establish a renderer, driver or product defect. Events 223/226/227 are superseded by the raw-pixel correction in event 228; the unsupported fixes were removed while preserving their history.


## 1 November meaningful hardware integration — BM-20, BM-17 and BM-36

Source inspection of the original Lab08 controls shows that `set_level()` emits `level_changed` for programmatic hydration as well as player changes. A gameplay host must guard hydration and let value callbacks edit a free draft only; explicit confirmation owns model dispatch/save. Do not connect every fader/rotary change to spending, time, a reward or settlement. Preview and commit need the same bounded policy, with a visibly distinct purpose for each control.

The complete source plates contain baked captions such as CREATIVE FOCUS, MORALE or HYPE LEVEL. Preserve the original bytes and audit the actual rendered wording before assigning a different meaning. Use a measured neutral face/channel region with recorded crop coordinates and native captions, or retain the original honest meaning; do not overlay a contradictory label. Keep the six recruitment PassiveMeter outputs separate and inert.

Existing hardware checks cover programmatic bounds/rendering. They do not establish real touch, drag, keyboard, multitouch, scroll arbitration or resize/hide/release behaviour. Those are required integration proofs before promotion. Missing touch-index/cancel handling is a source-audited risk, not a claimed reproduced device defect. This clarification records inspection and prevention; no hardware/gameplay repair or new native pass is claimed by S50.


## 1 November default-path and native-touch verification — BM-26, BM-30 and BM-32

Godot 4.7.2 logs an error for a missing `get_meta(name, null)` read: a null fallback does not make it a silent optional lookup. Use `has_meta()` before reading an optional value. Exercise the ordinary path with no test override as well as the injected fixture. In S51, all journey assertions passed while that ordinary path emitted 28 errors; the checkpoint was held and the premature zero-error commentary corrected. Require an empty `all_error_lines` list at each runner step, not only parse failures, exit status or the final result marker. Preserve the rejected run.

Native ScrollContainer touch tests on desktop need a working plain-text scrolling control and recorded touch-emulation capability before interpreting a product failure. Preserve/restore the in-memory emulation flags; size the fixture for the actual viewport rather than weakening its scroll-range requirement. Test touch and mouse cancellation independently: emulated touch can otherwise mask the real mouse branch. Tap-to-complete notes must qualify on release, allow a drag to propagate, cancel on secondary/canceled/internal releases and invalidate stale gestures when a reveal restarts. Runtime engine input is useful evidence, not a physical-phone test.

S66 made the capability requirement concrete on Godot4.7.2: `Input.emulate_mouse_from_touch=true` with `emulate_touch_from_mouse=false` left `DisplayServer.is_touchscreen_available()` false. The same unprimed indexed six-drag sequence moved both a stock Label scroll and the actual radio paper0px; setting the second flag true made capability true and moved both76px, their exact available range. The fixed commit button still moved0px and never committed. Record and require the effective capability for the mobile-gesture fixture, then restore both flags; a directly injected ScreenTouch does not establish it by itself. Preserve the failed fixture and causal paired-control evidence; do not fix product scroll code when the unchanged product and stock control respond identically.

## 1 November readable saved notes and held days — BM-13, BM-22, BM-24, BM-25, BM-26 and BM-34

Reduced motion removes animation, not essential information or the player's separate acknowledgement. Keep meaningful DAY cards visible until a real input; acknowledge/resize/reopen must never resolve or save again. A visible acknowledgement may fade, but hiding the owner must clear the presentation immediately rather than leave its busy guard waiting for that fade.

Test font coverage with system fallback disabled. The engine's embedded OpenSans alone lacked the arrow and tick used in our diagnostic; explicit licensed DejaVu fallback fixed the native chain. `Font.has_char()` includes fallback faces, so a passing chain check does not prove that the primary face contains the glyph. Preserve original font/licence bytes and actual native text comparisons. Caveat22 worked for narrative prose; applying it indiscriminately to compact photo captions displaced morale at1280. Separate printed16 captions from full22 prose, and compose short landscape score fields beside the voices rather than repeatedly shrinking fonts or portraits. Inspect numeric ink too: a wrapped signed value can fail the visual gate while old node assertions pass.

An autowrapped Label added at zero width can acquire an oversized hit box before a later manual size assignment. Give direct-control fixtures their width before entering the tree; use actual GUI receiver/rectangle traces before blaming a missed button. S52's QA note covered Back with a1629px rectangle; the production Back needed no repair. A modal's generic focus owner can also be a non-Button: `TypedArray[Button].find(Label)` raises an engine error. Use type-safe identity matching and test recovery, not only the ordinary button path.

Evidence must describe the state actually captured. The CLEAR keyboard proof deliberately collapsed the ledger again; its final screenshot filename did not make that image an expanded ledger. Recover the actual canonical expanded original with provenance, or capture the missing state. Directory modification time is not creation time: adding the final receipt changes it. Use a recorded start or verified filesystem birth time, and retain failed provenance checks. Isolated gray component images do not establish paper-background contrast; inspect the actual screen at a deliberate, settled reading position. Native input and source hashes remain separate from artistic acceptance and physical-phone verification.


## 1 November owned hardware event routing — BM-20, BM-24, BM-29, BM-32 and BM-36

A custom control cannot assume that every release reaches `_gui_input`. Native S53 testing showed Godot's internal mouse release can update `Input.is_mouse_button_pressed` without delivering that release to the GUI. Watch physical mouse state only while a mouse gesture is owned, then cancel the free draft once. For touch, match both device and finger index: with both emulation directions enabled, a generated device-1 touch can reuse a real device0 finger's index. After a qualified GUI press, route only that owned touch's drag/release/cancel through scoped `_input`; disable the handler on release, hide, resize, hydration or exit. Other fingers and page scrolling must remain available. Preserve the original hardware bytes; all callbacks remain free draft edits, never model/save operations.

Assert process-driven cancellation after an actual post-draw boundary, not a guessed number of fast native frames. Preserve failed positive controls and distinguish the earlier assertion from the state captured later in the same frame. A scrollbar is native chrome: a content clip that intentionally excludes the scrollbar strip cannot also prove the bar itself visible. Test real Tab/End focus and chrome bounds separately while keeping all content ancestor clips. `is_instance_valid` is insufficient during exit; check an acknowledgement is still inside the tree before `release_focus`.

Evidence: S53 events330–339, hardware-ownedinput phone/wide253 checks each, and the first complete native phone journey861 checks with actual failed-save rollback/retry, resize, normal/reduced replay and disk Continue. These are engine-event proofs, not physical Android-device verification. S53 event342 corrects prior BM45 lifecycle mislabelling without rewriting the append-only history.

## 1 November data-only reuse and touch propagation — BM-21, BM-26, BM-31 and BM-32

A pure method can live in a file with an impure dependency closure. S54's saved-song description imported a protected sleeve whose file-level UI preload required an unavailable legacy global class. Import alone passed; the script check logged errors despite exit0. Preserve the original file and use an owned data-only formatter with independent literal-field tests when the rest of that UI is not part of the curated runtime. Validate the known scalar fields actually consumed, including nested writing-session dates; absent dates retain their original neutral defaults and unknown extensions are not discarded.

For mobile scrolling, test the whole ancestor route. A plain Label positive control is insufficient if the actual view adds a decorative PanelContainer or a Button with MOUSE_FILTER_STOP. S54's traced same-view reversal measured0px with original/STOP filters,96px with PASS, then0px after restoration; paper and button blockers were isolated separately. Change the owned integration properties, preserve the raw control/art bytes, and prove real drag cancellation, zero button callbacks or saves, and subsequent genuine taps. Desktop touch tests need the proven emulation/capability control; this remains native-engine evidence, not a physical Android test.

Keep decision rows compact and the full saved dossier separate. Actual phone pixels rejected a technically passing selection whose writing history buried ADD, and an archive whose release status followed every track's history. Preserve full titles, credits and history while putting the selection or saved release facts and costed action before that dossier. Screenshot filenames do not establish the reading position; capture and inspect the actual first fold and selected order.


## 1 November release manifests and protected extraction — BM-30, BM-31 and BM-33

Validate the actual Android binary manifest structure rather than one summary line from aapt badging. The official template uses an enabled, exported activity-alias targeting its prior-declared enabled activity; MAIN and LAUNCHER must belong to the same nested intent filter, and HOME must be absent. A missing badging launchable-activity line alone did not establish a defect: actual V5 and V6 XML contained the valid alias. Preserve the failed audit and add structural/negative checks instead of weakening to unrelated string presence. Static launch metadata and matching update identity are not physical installation or save-retention proof.

For an isolated package, protect the tested runtime path from the actual receipt, even when the package checkpoint is a separate directory. Also protect explicitly declared prior runtimes before extraction. Inventory exact Git/runtime/image inputs before temporary ZIP writes, verify CRC and bytes, release atomically, then use a fresh extracted project and scratch data for configured-entry smoke. Read real receipt field types; keep helper display/guard failures distinct from game, package and engine failures.


## 1 November calendar facts and exact runtime copies — BM-25, BM-33, BM-34 and BM-35

A booking journal entry records when arrangements were made; its day is not the scheduled show day. Use the actual pending booking for a future calendar marker, keep recent saved notes separate, and never turn itinerary guidance into appointments. A read-only calendar must not expire, cancel or settle anything. On a due show day, the existing owner Continue may already open the live desk: follow the actual visible native navigation rather than targeting a hidden practice button.

Read the real runner argument schema. Its --copy option takes one nargs-list; repeating that option replaced earlier lists. The nominal repository_head and seven green steps did not prove the calendar host had been copied. Source audit held the mixed342-input run; a complete343-source base was verified before the corrected single-list run and then independently bound afterward. Preserve real-but-wrong-runtime results as held history. Count tracked Scripts explicitly:54total equals51gd plus3UIDs, not54gd plus3.


## 1 November identity layout and source proof — BM-10, BM-22, BM-24, BM-33 and BM-35

Budget a poster from the actual safe Root dimensions, original frame content margins and native wrapped-font heights, including role rows and footer copy. Let the figure row use the remainder; do not shrink fonts or hide copy to make a clipped surround pass. Check phone insets and tall tablets as distinct compositions. A fixed header minimum does not preserve its old layout: S57's original audition header was44px, while a wrapped legacy band name made its play header55px. Retaining the original native layout slots and replacing only their ink restored every audition pixel and every report pixel below the header.

Native text, role credits and input hierarchy are part of a component contract. Keep real role labels with their selected lineup, rather than adding hidden test labels. When an approved redesign intentionally moves actions outside a poster, commit the new contract before updating the old case-width check; retain physical/safe enclosure, minimum size, fixed placement, non-overlap and genuine click/save checks. Allocate branch-owned nodes only in the branch that parents them, and query viewport geometry only after entering the tree. Actual orphan names and one/two/three-render deltas identified S57's otherwise unused phone VBox.

A materialized runtime and copied .godot cache are not an import receipt: explicitly import before GL. Read actual receipt types and source-specific game APIs; C27 instrumental-vocal preparation is not the legacy Game.launch contract. After repeated helper schema assumptions, stop redundant child lookups and use the verified parser. Reuse proofs only with explicit byte/dependency binding, and distinguish current executions from earlier checks. Four selectable font directions are real bundled fonts; the liked splash wordmark remains RGBA artwork. Three six-person generated atlases are shared-origin full-length sources, not18 independent masters or owner-approved new likenesses.


## 1 November native minimums and metadata heads — BM-22 and BM-33

Control.custom_minimum_size is a minimum, not a fixed final allocation. S59’s long two-line native Label remained61px after four process frames and three real postdraw samples, although its custom minimum was56 and Font.get_multiline_string_size reported55. The complete19px text, venue, facts and acknowledgement were visibly correct. Preserve that source; replace the false QA constant with actual combined-native-minimum, complete glyph/line/font-floor, safe clipping, non-overlap and useful notes-viewport checks. Keep the failed probe and diagnostic originals. More waiting cannot fix a persistent native minimum, and shrinking correct text just to force a test constant reduces quality.

A validation receipt can accurately record a newer metadata repository HEAD while explicitly copying every game input from the tested source SHA. Retain both identities: verify every curated runtime byte against exact Git, the complete single copy list/source refs and sole isolated-entry exception, and prove the observed-head delta contains metadata only. Do not rewrite the original receipt or rerun unchanged engine suites after a wrapper-only assertion. Historical protected Git paths and curated shipping inputs are separate inventories; read explicitly declared nonshipping protection paths from Git rather than omitting or packaging them.


## 1 November freed-owner waits and bounded poster layout — BM-20, BM-24, BM-32 and BM-36

An epoch check after an instance-owned await cannot run when the script owner has already been freed. S60's immediate-free firstlook passed its assertions yet exposed an actual old CareerDesk focus-wait engine error; hold the source on any ERROR. Replace the suspended instance continuation with bounded bound one-shot callbacks that automatically disconnect on owner free while preserving semantic focus/scroll/generation checks. Do not add a QA wait to hide the lifetime defect.

The first new-view deferred postdraw chain then failed to create its poster despite a stable visible body and epoch. Preserve the zero-alpha original and actual20postdraw diagnostic, and do not invent an engine-bug cause. After two ineffective integrations, change method: a finite live-node process state machine driven by completed draws can budget native layout in at most two correction passes, stop processing once ready and abort on hide/free. Current four-size input/state/source proofs and the unchanged immediate-free probe pass without extra waits. Current-member identity mapping must use candidate_id rather than numeric roster id, preserve actual order and lead, and use whole-text fallback rather than compositing a partially guessed lineup.


## 1 November private delivery identity and connector size — BM-30 and BM-33

Private compiled-APK permission does not identify an unspecified connected Drive account. Before upload, read the current connector profile, destination owner/ACL and exact folder identity; use the observed parent explicitly. S61's current chair@lovewelluk.com profile/root and matching V6 parent resolved the ownership concern without switching service, account or publication scope. Compiled code remains potentially recoverable; the source/history public-upload block remains separate.

Check the actual connector's file-size limit before assuming a completed build can be delivered. V7's119,910,540-byte universalAPK exceeded its104,857,600-byte pre-action limit; no remote file was created. A standard outerZIP saved only0.7MB because the engine libraries and imported resource payloads were already compressed. Preserve the verified artifact and state the gap; do not silently remove an ABI, substitute fonts/art, reset a career, weaken checks, split installation files or use an unapproved channel. A device-specific update requires the actual phone/OS compatibility and a separately bounded packaging contract.


S62 completed the device-specific repair only after the owner identified a Pixel9. A known verified universal APK can provide a stricter parent than a fresh export: remove exactly the two unused ARMv7 library entries, regenerate only the exact three JAR signature members, and require all779 other uncompressed payloads and compression methods to remain identical. Re-sign with the same existing key and independently check the new APK's CRC, alignment, certificate, actual ABI, manifest/permissions and all684 assets before private delivery. Whole-APK hashes necessarily change after signing/alignment; that does not justify ignoring unexpected member differences. Record the eight actual packaging/SDK steps separately from the reused nine parent export steps. A JAR verification at minSDK23 is a signature probe, not a claim that the API24 app supports Android6. No new gameplay tests, source ZIP or artwork pass is implied by an ABI-only artifact repair.


## 2 November expanded Details and actual scrollbar keys — BM-22, BM-32 and BM-33

An unchanged response loop can become unreadable after moving into a disclosure. S72's first candidate passed its behavioural checks but rendered STEADY and STRAINED one letter per line beside passive meters. Hold technical green on that actual visual failure. Give short native captions their full natural width and explicit nonwrapping contract, preserve the original meter bytes and values, and inspect every caption at actual expanded reading positions in all four sizes. A screenshot filename is not proof of its scroll position. Reusing it at another visit overwrites the earlier pixels: count unique persisted files separately from capture-write events and give future phase captures unique names before writing. Do not rerender a past state and describe it as the lost original.

A native scrollbar can accept Tab, Home and End without owning every later arrow key. The timing-preserving phone trace proved that Up moved focus to the narrative and scrolled to it; neither a fixed wait nor a product repair was warranted. Preserve the failed probe, inspect actual focus/bar identity/event/scroll/frame facts, then change the reading method: genuine wheel events over the body with measured direction, range and bounded postdraw settlement. Keep full-word/font/clip/meter/state/save guards; remove only the disproven per-arrow ownership assumption.

With tight persistent storage, immutable raw art/font inputs may be hardlinked only when they will never be overwritten and exact source/runtime hashes are verified before and after import. Every mutable import cache must remain private to its runtime; S72 used fresh /tmp caches while retaining all originals, failure logs and receipts in the workspace. This is a storage method, not permission to purge history or weaken source inventory.
