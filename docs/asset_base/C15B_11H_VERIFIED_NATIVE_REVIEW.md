# C15B verified source/native comparison — 29 October 2026, ~11:20 UK

**Reviewer status:** INTERNAL SIMULATED art review; `owner_approved=false`. The owner's morning feedback prioritises stronger complete native looks and specifically approves the **existing meter appearance** as a baseline, not final art. All images and paths below are from source and real Godot X11 captures, not generated UI mockups.

## Exact verified build

- Branch: `dual-frame-proof-2026-10-28`; tested implementation: `b704e0393485fa60d9ea7b03c70e117eadaa6825`.
- Native Godot 4.7.2 real X11 GL/OpenGL llvmpipe: [run 40863989717](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40863989717), **SUCCESS**.
- Artifact: [12892717495](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40863989717/artifacts/12892717495), ZIP SHA256 `ab30f658ea2216e5715bfccd0f9bb21abd5d70ee16093ecce090fd753be61574`.
- Verified `proof-shots/results.json`: **32** native screenshots, zero recorded failures. `proof-shots/u04-results.json`: **20** genuine hardware-state captures, zero failures.
- Same SHA structure run [40863989481](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40863989481) SUCCESS; headless [40863989461](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40863989461) SUCCESS.
- Earlier same-workstream CI [40863348556](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40863348556) rendered but failed eight *stale C08 photo-path assertions*. Follow-on [40863647758](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40863647758) failed earlier in path-match patching because C13 had already transformed `portrait_provisional` to `portrait_doc_`. Corrected the true transformed source anchor, **then** ran 40863989717 successfully. Never call failed runs successful.
- **C12 direct compare:** native [run 40837105664](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40837105664), artifact12880838182; **C14 direct compare:** native [run 40848431365](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40848431365), artifact12886141655. Opened before/current PNGs, not pixel statistics as substitute for inspection.
- Testable isolated project: artifact file `proof-shots/BandMaster_testable_project.zip`, SHA256 `9a54e1c4979e96037ca5ccf5a54b34d529cdf76c8444ef8d32263daf1d8b27e5`.
- Exact source implementation: `experiments/art_material/c15_indie_identity.py` and `.github/workflows/art-material-proof.yml`. Source origin/detail/rights per `proof-shots/C15_INDIE_SOURCE_MANIFEST.json`, SHA256 `91bd19e49ce609e826284adf310d1fc1dfdfaa7725f92d6e4378263b93caad8e`.
- No production saves, main, PR#199, paid/runtime deps or meter code changed.

## Character source truth

| Character | Look | Native isolated asset under `assets/characters/` | Dimensions | SHA256 |
|---|---|---|---|---|
| `alex` | day | `alex_portrait_indie_day_source512.webp` | 512×690 | `9e7ef9d03a3311b485531227928d1eca21e45a0ee82ad8da2e128e5339ecb2c5` |
| `alex` | night | `alex_portrait_indie_night_source512.webp` | 512×690 | `7abe4bdaf6e8bb899571957bbef23bd6ef57f6fa2ee777a4b8d6c07f150462bc` |
| `nia_griffiths` | day | `nia_griffiths_portrait_indie_day_source512.webp` | 512×690 | `29fa1cc0de7516c3d90602358bbbbe91e6214049596dc5be14c6f3bbf83b9e76` |
| `nia_griffiths` | night | `nia_griffiths_portrait_indie_night_source512.webp` | 512×690 | `a73e556687363d1f21b7898df1a474ab2d9aa9aeaeecebb94b4e572bf28178df` |

Each photograph is one isolated character with **no baked UI, stats, names, controls or collage**. Existing C05 512px previews were *derived from a single paired-origin AI-generated portrait-only plate*, NOT two independently requested/generateable >=1024pixel masters. Lighting, contrast, vignette and grain are edited at native 512×690 without upscaling the subject. Synthetic source with in-chat generation basis; no unverified photographer, stock model, or model-release assertion. The independent 1024px C11 CC0 corporate-looking sources and C13 grades remain archived. C15 looks substantially more plausible as UK indie musicians, but still fails the **independent original high-resolution master** quality criterion. `owner_approved=false`.

## Genuine native PNGs opened and SHA256

All artifact paths are `proof-shots/<filename>`:

- `flightcase-390x844-alex.png` — `01eeadfa64d74b0c7944a4a376085a99b0ec77139c20a2105cd0f9c329f6ac23`
- `notepaper-390x844-nia.png` — `ee9b15f2508bbf992445d20ce82e06649a4fe6e0d14a6a6cce56600a0ac06db2`
- `flightcase-720x1280-nia.png` — `ab792547c5a8345d45a834b1edaf0c274e4e591a9a64929e16d8b7796d97e7ca`
- `notepaper-720x1280-alex.png` — `5d29c56d7505bf55f1ef535fc769e8f866005de3d3183f9bd3f33212b16de7b1`
- `flightcase-1280x720-alex.png` — `51076db1e9f7866d751a62f728a9a361b6447bc7494249702b8062d174067737`
- `notepaper-1280x720-nia.png` — `d2f1180e011bff2824e037fb07ff04371499f55d229c5a6eb0cb529ffc1d5854`
- `flightcase-1600x900-nia.png` — `84fe8d6dd88635dd326138d0f4a8e82bde732e07540746ef3e2572ed6bf208a0`
- `notepaper-1600x900-alex.png` — `b8e939477b62528ed5f190b2ea47c54b8461d3b44ad550678a90de4d66e17624`

Inspected 1280×720 C12→C14→C15 night/Alex and day/Nia at useful physical size; opened current 390px phone, 720px tablet, 1280px landscape, 1600px desktop across both materials; assembled local review comparison and four-viewport contact sheet **only from original native captures**. New portraits visually correct the corporate-headshot character mismatch more than the prior background-feathering work did. The 1600 landscape panels still leave unused space; paper-on-cork has some thin tape/rectangular-photo impression and physically heavy tabs on daylight. Existing photo-study captions remain non-production approval warnings.

## Owner-liked meter regression

All **23** files matching `passive_meter_*.png` inside the C12, C14 and C15 native artifacts are **byte-identical by SHA256** across all three revisions. Source PASSIVE_METER_MANIFEST/atlas retained. Six stat bars remain passive `mouse_filter=IGNORE`, `focus_mode=NONE`; zero/max lighting is source-verifiable. Do not redesign these.

## Five SIMULATED specialist lenses — NOT independent humans

1. **Art director — VISUAL IMPROVEMENT, overall PARTIAL/HOLD:** Compared images show true indie character wardrobe/hair/attitude versus studio-corporate faces. Strongest gain in night Alex, day Nia. Still a synthetic studio feel and lack of artistically approved independent source masters. At 1600, hierarchy does not use the abundant width with deliberate intention.
2. **Technical artist — modular PASS, original-master BLOCKED:** Two IDs × two original-size true photo finishes, one source per image and different source hashes; per-character photo independent of all controls, native captions, paper/case shells and source-backed ambience. C05 paired-original limitation is explicit, no 1024 master invention or 160px legacy upscale.
3. **UI/accessibility — FUNCTIONAL PASS, ART PARTIAL:** Phone first fold retains portrait, all six RAG stats, role tabs, selected candidate and recruit/roster. Day selected hardware has low-contrast text in some sizes and tabs remain dense on 390; desktop has excess negative space. Controls remain native and focus/press/select states checked.
4. **Godot engineering — NATIVE PASS:** Official Godot 4.7.2 + X11/OpenGL; 32 true recruitment native captures and 20 input-hardware captures zero assertion failures, plus three same-SHA green workflows. Live resize selects current day/night source; Nia cost45, Alex51, initial200 talent, reversible recruit/remove, two canonical IDs, six passive stat read-only, interaction motion regression.
5. **QA/producer — PASS for isolated proof, professional art HOLD:** Captured and corrected two actual stale-source assertions before successful native proof; C12/C14/C15 artifact sources and source hashes independently opened/compared; 23 meter hashes unchanged. No merges/purchases/save changes. Do not equate green CI with owner acceptance.

## Next gate and stream ownership

Before **12:00** keep optional cast/scenes suspended. At/after 12:00 inspect this actual C15 four-viewport proof against C12 morning images, freeze optional asset families and correct only dominant visible layout/import/input defects; do not ruin better indie portraits or liked meters. F: tame spacious 1600 layout/paper mounting. U: preserved owner-liked meters and native button states, change only measured defects. C: qualified independent >=1024 musician originals still missing; stop re-running the repeatedly failed UI-collage generation path. At/after14:00 validate/package, after15:00 evidence/index writes only, at16:00 owner review no implementation.
