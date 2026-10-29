# C20 — reusable controls and frame library: verified closeout

## Owner scope and actual result
Latest direct owner instruction: defer scene backgrounds, inventory existing repository controls, reuse them, build missing reusable behaviours, and improve frames against the supplied component mockups. Character work is also deferred in this sprint. The finite programme is not extended, no merge is authorised, and owner_approved remains false.

A real drop-in library now exists under `components/control_atlas/`, not merely a mockup or a script-generated proposal. A separate standalone project is available in the native artifact. The module was tested inside a second host project before publication; it does not replace a game's project.godot.

## Evidence
- Tested source: `41511e3eb9d79d0580d6d640eaa615ae863c97be`.
- Published tested module: `1b2bcf0fcf1b6a9fac2f9986d60422904314a780`.
- Native run: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40901641892
- Artifact: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40901641892/artifacts/12909338595
- Downloaded artifact SHA256: `d6255c084ec2f49c9902e482612cca5c9eb95c7b09972b259d99dd13ccb367c4`.
- Godot4.7.2: 689 assertions, zero failures, 48 captures in the standalone gallery; the scoped drop-in version repeated those 689 assertions and 48 views inside a separate host project, also with zero failures. These are 48 distinct gallery views, not 96 distinct artworks.
- Four exact native sizes:390x844,720x1280,1280x720,1600x900. Controls/hardware/frames, two material looks, top and scrolled positions.
- Actual mouse click and Space-key activation, disabled mouse input, selection exclusivity, bounded stepper values, once-only changed signals, browse wrapping/clamping, physical44px targets, passive semantics, nine wrapper instances and live resize were exercised. This is component validation, not a full game playthrough.

Downloaded PNGs opened at original size include night controls1600x900, day frames1600x900, day controls390x844, night hardware720x1280 and1280x720. The native atlases were also opened and reviewed. Native images are separate from the earlier generated reference mockups.

## Inventory and reuse
- Existing action/tab/browse:36 original U18/U03 Lab07 state images copied byte-for-byte. Runtime skin downsampling is proportional; source files are retained.
- Existing passive meters:22 runtime zero-to-ten images copied byte-for-byte and independently compared to U18. No redesign, new input or focus. The original pre-existing atlas was not edited.
- Existing Lab08:58 image layers and standalone control source copied unchanged. The drop-in module changes resource prefixes only, not input/lighting logic; hashes of both code forms are retained.
- Newly reusable APIs:toggle, bounded integer stepper, exclusive segmented selector, wrap/bounded browser, pagination, selectable row adapter, passive value/price chip and glyph action buttons.
- Nine drop-in scenes:action,toggle,stepper,choices,browse,pagination,meter,panel,ticket. Hardware and row adapters are also exposed through the Kit factory.
- Four source-derived frame masters support six presets per look:panel,inset,portrait,ticket,header,modal. Complete fixed corners, controlled scaling, safe text insets and a vertical portrait format. The six presets are not falsely counted as six independent art masters.
- Scene allocation for recruitment, songwriting,rehearsal,touring,recording,gig/backstage and management is in CONTROL_INVENTORY_C20.md and the library README.

## Corrections made from real failures and pixels
The first pass exposed multiple selected buttons from a silent ButtonGroup update, horizontal phone overflow, repeated corner hardware and wrongly sliced source skins. These were corrected. Input tests were moved from overlapping native popup windows into the actual application window, after pointer diagnostics established the harness issue. Tests retain real mouse/key events rather than replacing interactions with signal emission. The last visual pass corrected paper-inset text touching its top edge and gave portrait frames proper vertical proportions. A repository structure failure was resolved by storing build templates as .in and publishing resource paths scoped under components/control_atlas, not by weakening the validator.

## Five simulated specialist assessments — not independent human approval
1. Art direction: the metal kit is materially more cohesive and the paper family is clean and legible, but heavy paper shadows and repeated rectangular silhouettes still make it simpler than the supplied premium mockups. Professional-finish status remains PARTIAL.
2. Technical art: four traceable frame masters scale without repeating screw heads; original button/meter/vendor pixels are retained. Safe margins and source hashes agree with the implementation. Hardware retains its original baked source captions; neutral variants are not falsely claimed.
3. UI/accessibility: actual mouse and keyboard activation, disabled controls,44px targets and narrow-screen scrolling pass. Native headers wrap at390px. The muted disabled-day label could be clearer; a gallery is not proof of each future scene's information hierarchy.
4. Godot engineering: reusable factory plus nine scene wrappers run both standalone and as a nested module without replacing project configuration. Programmatic and input-driven state updates are tested. Modal is currently a framed container, not a complete dialog focus-trap/controller.
5. QA/producer: the deliverable is now a functioning reusable library with native evidence, not another plan. Preserve the established meters. Do not declare all mockup types finished: passive ring gauge, bespoke pictograms, full modal controller and scene-specific bindings remain outside this delivery.

## Acceptance and next use
Engineering: PASS for the tested controls, source reuse and standalone/host integration.
Frames/materials: visibly improved, reusable baseline; professional visual target remains PARTIAL rather than silently approved.
Backgrounds/characters: unchanged and deferred by owner direction.
Production scenes, main, PR199 and save systems: not modified by this sprint.
Owner approval: false.

Review the real controls/frame atlas, then use this library for the next authorised scene assembly instead of rebuilding bespoke buttons or pursuing more character/background work. No automatic extension or merge.
