# Next autonomous run: R1 art proof only

**Single assignment:** Create *actual* source artwork for two distinct fictional UK indie musicians and one high-quality recruiting-screen visual target in landscape and a separately composed phone format. **Do not create new GDScript or control SVGs in this run.**

### Preconditions

- Read `AGENTS.md`, owner V4 contract/reference, current state, 28 Oct native art failure, the art director and asset producer role instructions.
- Check branch head and any concurrent writer. Preserve all already imported original photographic control sources.
- Verify the original owner reference PNG is available before pixel comparison; if absent, use textual V4 contract and label the comparison *qualitative*.
- Choose one coherent visual method (documentary fictional musician portraits or cohesive fully authored illustration). Do not mash them together.

### Produce

1. Two different **real full-resolution image files** of fictional musicians, at least one frontperson and one contrasting source-catalogue ID. The two must be distinguishable with names hidden. Character source identity, generator/type and rights captured accurately.
2. One complete **1280×720 design-only** target with credible case, papers, existing photographic controls, dominant portrait and readable hierarchy; one **390×844 independently composed** design-only target. Do not bake this image into Godot gameplay. If generated images contain gibberish text, correct through native-text overlays in design review, not via in-game screenshots.
3. A separate layer/asset plan: source masters, paper, case, controls, read-only meters, native text fields, explicit cropping rules.
4. Record actual images and source hashes using `tools/register_recruitment_asset.py` once the files exist. Do not change the manifest to `ready` before genuine bytes exist.
5. Inspect actual art at physical size. Art director marks `provisional_pass` only if all art P0s are eliminated and exact files/provenance are recorded. Otherwise R1 remains blocked with one precise correction.

### Explicit stop condition

If only clip-art/vector mockups or inconsistent performer images can be produced, **STOP** and log P0 FAIL; do not advance to an isolated Godot scene or restart broad research. If image generation/file delivery is unavailable to the executing agent, record that tooling blocker instead of pretending to produce art.

### Handoff (owner not required at this stage)

Append to `05_SPRINT_LEDGER.md`, update `RECOVERY_STATE.json`, report exact image paths, dimensions, source SHA, true art verdict and one next action. Neither CI nor a simulated art director can confer owner approval.
