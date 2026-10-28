# Source-material integration experiment — 28 October 2026

## Verified evidence
- Tested implementation: `8efb9e547f6f147237179b4439a91566e3ceae68`.
- Successful native Godot 4.7.2 run: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40778019754
- Downloaded artifact: https://github.com/alimuir654-rgb/BandMaster/actions/runs/40778019754/artifacts/12854794234
- Downloaded ZIP SHA256: `db8b580c5b672196286b44e538ff28918045073e44bda9a87ffcf019dae7f3cd`.
- 32 genuine rendered captures, zero assertion failures. Both materials, four viewport sizes, Alex/Nia/recruited/focused-refunded states. Tests verify canonical identities, Nia cost45, 200 -> 155 -> 200, button bounds/minimum44, stat bounds and live resize. This is not a complete human-input playthrough.
- Original 390x844 and 1280x720 images opened for both looks. 720x1280 and 1600x900 reviewed on a labelled contact sheet. Native logs/results and per-image hashes retained in artifact.

## Scope and exact implementation files
- `.github/workflows/art-material-proof.yml`
- `experiments/art_material/prepare_art.py`
- `experiments/art_material/refine_art.py`

The pipeline consumes the pinned successful baseline `981bbdcd8908049ddc72f71606461676520e8630` and source assets/catalogue from `c084690f7ccde4625eaebf68b89ae476fd08724d`. No main edits, original PR #199 changes, production saves or merges.

## Artwork actually integrated
Eleven separately addressable source-backed resources with hashes and provenance: blank metal frame, case surface, metal key, amber key, paper frame, paper surface, paper key, amber paper key, original room image and two graded room variants. Native Godot labels, six passive stats and interactions remain separate. No complete-screen composite is used as the interface.

Lab07 hardware is owner-supplied image-generated photorealistic artwork, not falsely claimed real photography. Paper001 from ambientCG is a CC0 approximation material, not a claimed scan. Existing Pexels room/cork source manifest is retained. Neither environment photo is represented as Alex or Nia. Dedicated musician portraits remain missing.

## Observed correction loop
The first successful source-material render exposed stretched screw heads and elongated side-rim details. The second run corrected nine-slice source dimensions, replaced unsuitable side sections, improved key scaling, added an offset paper leaf/cork border, moved the caption to the image bottom and expanded content into previously empty space. Tests still passed after these corrections.

## Acceptance verdict
Technical reusable-material integration: PASS.
Visual improvement: observed, strongest in metal hardware and removal of notebook ruling.
Full professional recruitment art target: NOT PASSED.
Owner approval: false. Overnight authorisation: not granted by this report.

Remaining visual defects: paper controls still too plain; metal tabs too uniform/heavy; tablet image dominates; phone flight-case header/footer crowd the physical rail despite viewport-bounds success. The clearly labelled room environment is not a substitute for the missing character portraits. Approved concepts retain much stronger character presence and hierarchy.

## Five simulated review lenses
1. Art director: materials improved; reject full premium screen acceptance until source artwork and composition match the creative target.
2. Technical artist: native nine-slice reuse works after correction; dedicated aspect-ratio control masters are still needed rather than stretching one family.
3. UI/UX: both mobile candidates are accessible and six attributes legible; tablet hierarchy and phone safe insets need work.
4. Godot engineer: texture-backed components preserve tested state and resize behavior; only vocals are populated in this isolated proof.
5. QA/producer: native evidence is real, but green CI is not art approval; do not turn conditional overnight approval into permission.

## Next single P0
Visually accept a coherent standalone portrait-and-control source kit before expanding scene families. Retain these material primitives, but do not label the current screens a finished scene baseline.

## Machine-readable scoped state
```json
{"schema_version":1,"experiment":"source_material_integration","tested_code_sha":"8efb9e547f6f147237179b4439a91566e3ceae68","run_id":40778019754,"artifact_id":12854794234,"engine":"4.7.2","native_screenshots":32,"assertion_failures":0,"technical_pass":true,"art_acceptance":"not_passed","owner_approved":false,"overnight_authorised":false,"next_single_p0":"Accept coherent standalone portrait and control source kit before scene expansion"}
```
