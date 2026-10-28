# R1 art review ZIP source intake (one upload, no manual extraction)

The four new OpenAI-generated recruitment compositions exist as actual PNG bytes in the 28 October R1 review ZIP, but the ZIP is **not currently present in GitHub**. This is a deliberate source-of-truth distinction. The source images are *design-only*, not the 2 distinct ID-verified musician portrait masters required for the art gate.

## One-step import when source ZIP is available

On draft branch `first-pass-scene-sweep-2026-10-27` upload this **exact** file to the repository root:

`BandMaster_R1_Art_Direction_Explorations_2026-10-28.zip`

Expected SHA-256:
`5af8ab767fc7038b30569554c8211039c4dd1e2f8b5b06ffd6378d56b62fc943`

The existing workflow `.github/workflows/recruitment-r1-review-art-intake.yml` automatically:
1. Validates ZIP SHA, 10 exact members, no traversal/symlinks and every internal source hash.
2. Refuses overwrites when bytes differ.
3. Checks the art review explicitly says **art_target_pass=false, standalone_portrait_master_count=0, owner_visual_approval=false**.
4. Extracts under **`Art/References/RecruitmentR1/`**, not `Art/RecruitmentRecovery/`, then commits only those reference assets to this draft branch.

No action here approves portrait quality, gameplay, real photo rights or owner signature, and the source manifest stays unchanged. If the workflow fails, inspect its error rather than loosening the SHA/permission checks.

## What is missing before R1 can pass

Two independently generated or appropriately sourced full-resolution image masters for **actual catalogue IDs** `alex` and `nia_griffiths`; correctly authored desktop and phone target layouts; blank reusable material source layers; a clear independent portrait-rights record. Generated mockup characters and all fake prices/stats must be discarded as game data. Native character/role/cost fields remain bound to `Scripts/recruitment_catalogue_v3.gd`.

The archive linked in the active project chat is **the R1 design-review ZIP**, not a release deliverable. 
