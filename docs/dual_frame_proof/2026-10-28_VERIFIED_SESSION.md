# Verified dual-frame experiment — 28 October 2026

Owner approval: false. Production merge: prohibited. Scope: isolated two-material experiment; no production save changes.

## Evidence
- Baseline: df571c08b0c9a5b5e00ec7952c6570e5ff6abf3d, run 40773334203, artifact 12853732118. Downloaded and opened: all four supposed notepaper images were byte-identical to flightcase images. The original script-only rename left serialized .tscn properties unchanged.
- First repair: 116f43d0a46e7140b68abcb7e15e890d173557c7, run 40774373776. Actual 32-state capture and functional assertions passed. Pixel inspection found notebook binding/text overlap and unused candidate column. Audio fallback also produced a nonfatal engine ERROR; corrected in second run.
- Final tested source: 981bbdcd8908049ddc72f71606461676520e8630.
- Final native CI: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40774811897
- Final artifact: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40774811897/artifacts/12854331611
- Engine: Godot 4.7.2-stable official, ed1daf0bf001b61586d9930840f2f1394092c079. X11 / OpenGL compatibility / Mesa llvmpipe, NOT headless dummy rendering. Audio deliberately Dummy; sole final log warning concerns unsupported V-Sync mode.
- 32 screenshots: two materials x four sizes (390x844, 720x1280, 1280x720, 1600x900) x four states (Alex, Nia, recruited, refunded with keyboard focus). results.json has zero test failures. All 32 downloaded PNG hashes matched manifest.json.

## Corrections
Repaired both .gd export and .tscn bindings, used orientation-capable BoxContainer, kept both phone candidates visible, added texture-backed states and nine-patch frames, moved six passive statistics directly below portrait, applied contrasting paper ink, corrected notebook binding inset and added source-backed desktop biographies. Canonical data is read from catalogue commit c084690f7ccde4625eaebf68b89ae476fd08724d; original invented stat labels/prices removed. Alex costs 51 talent; Nia 45. Both use 200 starting talent. Nia recruit/remove returns 200 -> 155 -> 200.

Assertions cover theme identity, referenced texture, physical orientation, candidate identity, visible control bounds and >=44px target sizes, candidate button signals, recruitment/refund, keyboard focus without spending, live resize without selection/budget loss and exact screenshot dimensions. Python verifies actual material image differences and source SHA. Rendering timeout and explicit error-log failures replace hanging tests. Assertions do not establish artistic quality or complete manual accessibility coverage.

## Source trace
Repository change: .github/workflows/dual-frame-native-proof.yml. It deterministically extracts the owner-uploaded ZIP, repairs scene/frame_demo.gd and BOTH scene/*.tscn, copies pinned Scripts/recruitment_catalogue_v3.gd and formation_catalogue.gd, writes tests/native_proof.gd and updated README, then packages the corrected testable project. Corrected source is in the artifact project ZIP; it is not yet an independently checked-in source directory. Do not confuse generated build source with production recruitment code.

## Simulated specialist verdicts (not human approvals)
1. Engineering: PASS for executed experiment checks. Monitoring now uses repository actions/runs with head_sha, not the connector's pull-request-only query.
2. UX: IMPROVED. Phone candidates accessible; portrait/tablet layouts stack; landscape uses columns. Excess empty tablet space remains.
3. Art direction: FAIL. Existing source plates are procedural technical rasters, not the premium photographic target. No new portraits produced.
4. Technical art: PARTIAL. Actual independent frames and texture-based native controls work. Material scale/stretch and rectangular button appearance remain weak.
5. QA/accessibility: TESTS PASS, VISUAL GATE BLOCKED. Notebook ruling still intersects some dossier text; tablet density and phone type size need art-directed resolution. Native outputs inspected, not merely counted.

## Next ONE P0
Replace the two provisional raster plates with independently authored, high-quality reusable material kits, then run this same verified native harness. Do not resume speculative workflow patches, invent portrait identities, use a flattened UI as the screen, or claim production readiness.

## Guidance retained
https://docs.godotengine.org/en/stable/classes/class_boxcontainer.html — only BoxContainer supports changing vertical; HBox/VBox orientation is fixed.
https://docs.godotengine.org/en/stable/classes/class_renderingserver.html — headless disables rendering; await frame_post_draw for screenshots under a real renderer.
https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html — texture-backed nine-patch states with native text.

To repeat from the artifact project: mkdir -p proof-shots; then run godot --rendering-method gl_compatibility --audio-driver Dummy --path . --script res://tests/native_proof.gd (use xvfb-run on a displayless Linux runner). Normal manual review: open project.godot in Godot 4.7.2 and run each scene. Only the two vocal candidates are populated; other role tabs deliberately report this limitation.
