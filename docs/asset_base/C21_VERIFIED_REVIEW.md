# C21 — additional frame styling and hardening: verified review

## Authority and scope
Owner: "continue with some additional frame styling and hardening/improvement work. One hour".
Actual session began29October2026 at15:51:20 Europe/London; writer-claim commit ede9f362fd448b45f1363a1b94dd778e3006569d was recorded15:54:53. This direct request authorised this scoped follow-on, not continuation of the historical hourly programme. No scene-background, character, gameplay, save, main, PR199 or merge work. Owner artwork approval remains false.

## Verified native evidence
- Tested implementation: `a6e76b9b8f4094deefbc43cc2aa9d8b4a18f3a9a`.
- Published tested module: `acd4cd0441feb682237ac4a906daadf11d86a197`.
- Native Godot4.7.2 run: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40911368930
- Artifact: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40911368930/artifacts/12914490869
- Independently downloaded ZIP SHA256: `5847e39c38c54ebe0e86a3dc70eaeee6e8211026724ff1528dba226bada79d5a`.
- Original unchanged C20 suite:689 assertions,0 failures,48 native captures.
- Additional frame/focus suite:1368 assertions,0 failures,16 captures.
- Long-copy/resize/lifecycle suite:128 assertions,0 failures,8 captures.
- Total:2185 assertions with0 failures in the standalone project, repeated with0 failures in a separate installed host.72 distinct review views per project, not144 different artworks. Exact tested viewports390x844,720x1280,1280x720,1600x900; both visual families.
- Logs retain non-failing software-renderer VSync and inherited synthetic mouse-enter warnings. No claim of warning-free logs or full-game playthrough.

## Concrete styling deliverable
Twelve separate source-derived RGBA textures now provide six roles in each look: primary panel, recessed insert, vertical portrait mount, ticket/value strip, section plaque and decision-dialog frame. These replace six presets sharing four source masters; they are NOT twelve independently photographed or image-generated objects.

Flight-case derivatives retain proportionate Lab07 metal rails and corner hardware, with quieter insets and slim equipment plaques rather than nesting a large case frame around everything. Notepaper derivatives have offset sheets, softer short shadows, archive-photo corners, a perforated stub, tape-backed heading and folder-lip dialog. A final actual-pixel pass replaced grey tabs with warmer paper-stock detail and strengthened the original source fibre texture while retaining readable quiet centres. Native labels/signals remain separate from art.

Each source profile has dimensions, RGBA mode, SHA256, explicit nine-slice corners, safe content insets, minimum size and inherited provenance in `components/control_atlas/FRAME_STYLES_C21.json`. Digital compositing and manually authored relief/perforation details are disclosed. Rights basis remains inherited owner-supplied image-generated Lab07/Lab08 hardware and retained CC0 paper, not a newly asserted licence or a claim of hardware photography.

## Hardening delivered
`Kit.dialog(title,message,look)` now creates a real modal overlay, not just a decorative panel. Native Cancel/Confirm buttons provide mouse activation, Tab/Shift-Tab focus containment, Escape cancellation, once-only completion and previous-focus restoration. Long body copy scrolls within the available viewport while actions remain visible. PageUp/PageDown/Home/End operate the scroll area without losing action focus. Live orientation changes, reopening, duplicate-open calls, deleted invokers and disabled invokers are tested. The component deliberately supports a text body and two actions; arbitrary nested form controls or stacked modal orchestration are not claimed.

Frame application validates look/preset fallback, provides a fresh mutable StyleBoxTexture per instance, preserves native content when changing appearance, and keeps decorative frames out of keyboard focus. Original paper-disabled label colour was darkened for readability; this is a native text-colour change, not replacement of the existing button artwork.

## Preserved baseline — independently compared after download
-22 runtime passive-meter value PNGs:byte-identical to verified C20; read-only semantics unchanged.
-36 action/tab/browse state PNGs:byte-identical.
-58 Lab08 hardware image layers:byte-identical.
-Lab08 control logic and original C20 native_test.gd:byte-identical in standalone form; installed resource prefixes remain scoped as before.
-The source audit and per-file hashes accompany the portable review pack. A GitHub base-to-published-module comparison shows only isolated component/build/proof/documentation paths, not production scene or save paths.

## Actual pixels inspected
Original-size final images opened: notepaper frames1600x900; flightcase dialog390x844; notepaper controls390x844; flightcase frames720x1280; long-copy phone dialog. Also inspected the genuine C20 day-frame baseline, final night/day frame comparisons, the two-look native atlas and four-size contact sheet. Contact sheets assemble actual Godot PNGs; the separate source atlas is not represented as native output.

Visual changes are attributable to both newly differentiated frame textures AND the gallery removing redundant frame-within-frame surrounds. This is a reusable component demonstration, not an assembled production game screen.

## Five simulated specialist assessments — not human sign-off
1. Art direction: visibly cleaner than C20, with identifiable panel/ticket/header/photo roles and a brighter tactile paper family. Professional target remains PARTIAL: tabs and photo-corner details are restrained/simple rather than as richly art-directed as the mockup.
2. Technical art:12 unique hashed derivatives, retained originals, protected corners, documented safe insets and independent native labels PASS. Some metal highlights still reflect repeated use of the same source rail; these are deliberate derivatives, not independent photographs.
3. UI/accessibility:mouse/keyboard, explicit cancel focus, actual focus return, long-copy scrolling and four-size bounds PASS for tested interactions. Disabled text remains visually muted; no blanket accessibility-certification claim.
4. Godot engineering:original regression suite preserved; frame styles are instance-isolated and child-preserving; separate-host installation and modal lifecycle tests PASS. Nested modal stacks, gamepad-specific flows and arbitrary form bodies remain untested/outside scope.
5. QA/producer:substantive frame-family and dialog improvements delivered within the owner-authorised session. Three successful native iterations were inspected; final source finish is in the tested package. No character/background diversion or meter redesign. Counts and green CI do not confer artwork acceptance.

## Files and use
Authoring/build: `experiments/frame_hardening/{base_frames.py,style_frames.py,refine_paper.py,integrate.py,runtime/*.in}`; native workflow `.github/workflows/frame-hardening-proof.yml`. Published runtime: `components/control_atlas/{frame_styles.gd,frame_examples.gd,framed_dialog.gd,frame_test.gd,frame_stress_test.gd,kit.gd,gallery.gd,FRAME_STYLES_C21.json,art/frame_*_c21.png}` plus retained controls.

Open the verified standalone project's project.godot, run, select Frames, switch Day/Night and click Open dialog. Tab/Shift-Tab, Escape and mouse confirmation are interactive. The separate drop-in ZIP installs only components/control_atlas; do not replace an existing game's project.godot. Source and exact native PNGs are in the CI artifact.

Engineering verdict:PASS for the defined suites. Visual verdict:improved/PARTIAL against premium mockups. Owner approval:false. Next one action:use the differentiated frame kit in one representative scene assembly, once authorised, rather than another general atlas expansion. No automatic extension.
