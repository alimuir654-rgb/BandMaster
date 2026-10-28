# V4 Recruitment — Portrait Source Intake and Rights Hold
**27 October 2026, 21:00 Europe/London. P0 ART BLOCKER; owner visual approval not granted.** Draft PR #199 only. This is a source/casting brief, not a licence certificate or an instruction to swap faces.

## Verified repository inventory
The isolated recruitment model contains **36 distinct canonical person IDs**. Exactly four existing portrait files were found under `Art/Portraits/indie/`, each **160x160 WebP**, and **32 IDs have no portrait file**. These are legacy repository images, not independently verified commercial-photo rights or model releases.

| Canonical ID | File | Native dimensions | Git blob SHA-1 | File bytes |
|---|---|---|---|---:|
| `alex` | `Art/Portraits/indie/alex.webp` | 160x160 | `cb4aa38fbd9386855ab28d108dc5d7da7f90566e` | 1780 |
| `jo` | `Art/Portraits/indie/jo.webp` | 160x160 | `f625d50b7c98f71f27ca8de416bf9726a1498bbc` | 1778 |
| `sam` | `Art/Portraits/indie/sam.webp` | 160x160 | `95ec32de844746400bd130d921e24d101c092daf` | 1528 |
| `dev` | `Art/Portraits/indie/dev.webp` | 160x160 | `e2ca7c489c3e442963e9c5a9b614df4afd5b4cbc` | 1158 |

These Git SHA values verify repository identity, **not image usage rights**. The owner-approved 1536x1024 recruitment concept has SHA-256 `278998d5c7875557aab95ac6d225026481a29fddd23537a7c94ac99765caa223`, but its exact PNG is not present in the branch. Do not claim a pixel comparison without it.

## Minimum pilot before sourcing the remaining 32
Start with **Alex Vale** (`alex`), **Josh Bennett** (`josh_bennett`) and **Aisha Khan** (`aisha_khan`); review all three in the real V4 screen before commissioning the full roster. Next singer pilot: Tom Hargreaves, Nia Griffiths, Dan Mercer. If replacing Alex's legacy image with a different-looking person, obtain owner **recasting** approval; do not silently change a canonical identity.

Each approved source should be at least **1024x1024 native pixels** (prefer 1600x1600 or higher, with room for landscape and portrait crops), individually composed, UK grassroots musician/backstage character, varied gender/age, coherent warm stage/practice lighting, and no recognisable celebrity likeness. No upscaled 160px file may be represented as new high-resolution source art. No one person's face may be relabelled as another candidate.

## Mandatory per-person intake fields
- Canonical person ID and exact displayed name; image filename, original/master filename, photographer/creator and acquisition date.
- Source URL or internal original-work record; licence/commission terms granting commercial game use, modification/cropping, distribution and duration/territory; identifiable real-person model release or explicit permission when required.
- If generated rather than photographed, record the generator and prompt/process provenance, label it synthetic, and obtain owner acceptance before treating it as production casting. Never describe synthetic imagery as a photographed person.
- Source-file **SHA-256**, committed Git blob SHA-1, byte size, pixel dimensions, colour profile and crop/face anchor. Preserve the original master separately from game-optimised WebP.
- Rights reviewer, owner art reviewer, review date and status: `SOURCE PENDING`, `RIGHTS CHECKED`, `VISUAL REVIEW` or `APPROVED`.

## Visual and engineering acceptance
Use actual Godot 4.7.2 screenshots at **390x844, 720x1280, 1280x720, 1600x900**. Compare a minimum of three distinct identities; verify no face mismatch, no extreme cropping, no low-res enlargement, legible native dossier/meters, and proper focus/disabled/selected states. Only owner review can close the art gate. Until then, the V4 empty film contact explicitly says `PORTRAIT / ART PENDING`; it is **not a photograph**.

**Do not** add unrelated features, replace production saves, merge #199, restart S03-S07 or introduce paid/third-party image licences without owner approval. At/after 22:00 on 27 October, no new code; handover only.
