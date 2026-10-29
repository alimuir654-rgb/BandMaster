# C23 — reuse-first asset acquisition shortlist

Reviewed 29 October 2026 against repository head ad3bca76e70cc3c75f7f581317d62b82db64e748. This is the owner's requested sourcing decision, not an implementation sprint or schedule extension. No purchases, asset imports, game-code changes or new native tests occurred. Owner approval remains false.

## Decision
Keep the existing native controls/meters and C21 dialog behaviour. Do not acquire another general GUI theme. External sourcing should address missing physical construction: paper sheets, layered edges, mounting clips and label tape. The mockup is the goal; C20 is only a recovery baseline and C21 paper remains owner-rejected.

Verification boundary: official creator pages, available formats and published licences were checked. The frame mockup and C22 target/native comparison were opened. Several external preview-image endpoints failed; external original-file pixel quality, alpha, layers, actual dimensions and Godot suitability remain unverified. Proposed artistic fit is an inference from the target and publisher descriptions, not a claim of inspected source pixels. No external binary SHA is invented.

## Keep from the repository
- Lab07/U03/U18 action/tab/browse source states and existing native adapters under components/control_atlas.
- Lab08 horizontal/vertical faders and Focus/Buzz rotaries, source bases/caps/light layers and input logic.
- All 22 runtime passive-meter state images and read-only behaviour. No redesign or focus/input.
- Toggle, bounded stepper, exclusive choices, browsing/pagination, selectable rows and value chips already exist. Reuse them rather than importing another behavioural framework.
- C21 framed_dialog.gd and lifecycle behaviour; visual frame replacement must not rebuild focus/close logic.
- C20 paper edges/leaf and existing metal rims/corners as retained source baselines, not final art approval.
- Art/Icons contains actions/band/gear/gigs/home/scene SVGs. docs/ART_SHORTLIST_AND_ICON_IMPLEMENTATION.md already chooses Lucide and a compatible icon API. The origin of those six files was not independently audited here; do not relabel them Lucide without provenance.

Existing inventory: docs/asset_base/CONTROL_INVENTORY_C20.md. Current visual status: docs/continuous_improvement/C22_REVIEW.md.

## Exact acquisition queue

| Priority / source | Useful part | Published specification / licence | Decision |
|---|---|---|---|
| A1: Poly Haven Clipboard — https://polyhaven.com/a/clipboard | Physical metal clip and board-edge construction for dossier/portrait mounts | Blend/glTF/USD/FBX model options; maps up to 8K; author ProgrammerOnCoffee; CC0 | First source candidate. Requires an offline front-facing transparent render, not a drop-in 2D frame. Inspect/remove any engraved mark in derived art. Keep the fastening as a separate fixed-size layer. |
| A2: Poly Haven Office Notepads — https://polyhaven.com/a/office_notepads | Blank sheets, index cards and pad-edge thickness | Blend/glTF/USD/FBX model options; maps up to 4K; author Ulan Cabanilla; CC0 | Second source candidate. Prefer blank paper and use the same light as A1. Do not flatten live text into the artwork. |
| A3: Lucide — https://lucide.dev/icons/ | Missing role/function pictograms: guitar, drum, mic, music keyboard, ticket, calendar, route and transport | SVG; ISC plus MIT notices for Feather-derived icons | Extend the existing documented family with a small subset; preserve the icon API and complete notices. No new runtime library. |
| A4: Kenney Input Prompts — https://kenney-assets.itch.io/input-prompts | Tab/Space/Escape, mouse and generic controller hints | Bitmap/vector; listed kenney_input-prompts_1.4.zip 4.2 MB; CC0 | Reserve until bindings actually need visible hints; not a replacement for the game's button art. |
| A5: ambientCG Paper001 — https://ambientcg.com/view?id=Paper001 | Quiet paper surface already used in project provenance | JPG/PNG maps 1K/2K/4K; CC0; technique Approximation | Reuse existing source. Do not count reacquisition as new art. It supplies surface, not sheet edges, thickness or fastening. |
| A6: Poly Haven Metal Plate 02 — https://polyhaven.com/a/metal_plate_02 | Optional worn-metal surface variation | PBR maps up to 8K; CC0 | Low priority. Keep existing Lab07 rims/corners. Reject if rust/grunge contradicts the stage-equipment target; not a complete frame. |

Poly Haven licence: https://polyhaven.com/license — asset redistribution is expressly permitted; website example renders are separately excluded. Download actual assets and produce our own renders, not catalogue-preview textures. A1/A2 are offline art-source candidates; no 3D gameplay system, new engine or paid plugin is proposed. An actual render/tool test is still required.
Lucide licence: https://lucide.dev/license — retain ISC and applicable Feather MIT notices.
ambientCG licence: https://docs.ambientcg.com/license/ — raw files may be included in projects.

## Attractive but not cleared for public source/component distribution

| Candidate | Possible use | Hold reason |
|---|---|---|
| Texturelabs Details122: https://texturelabs.org/textures/details_122/ | Masking tape strips; PNG listed up to 6350x4860 | Free finished-game use is listed, but resource redistribution is prohibited. Not cleared for a public repo/reusable library. |
| Texturelabs Details169: https://texturelabs.org/textures/details_169/ | White console label tape; PNG up to 6362x4243 | Same restriction. Good subject match is not sufficient licensing clearance. |
| Texturelabs Paper369: https://texturelabs.org/textures/paper_369/ | Torn cut-paper source; JPG up to 6056x4645 | Same restriction; not supplied as a transparent PNG. |
| Fuzzimo clips: https://www.fuzzimo.com/free-vector-binder-paper-clips-images/ | High-resolution scans of silver paper clips/black binder clips; images ZIP listed 12 MB | https://www.fuzzimo.com/about/ prohibits redistribution and making redistributable design resources. Not cleared for our public kit. |
| Erin Brume Paper GUI: https://erinbrume.itch.io/paper-gui | Cut watercolour-paper assets and spritesheets | Listed USD5; no purchase authorised/made. Commercial-project use is listed, but raw/modified asset redistribution prohibited. Paid reserve, not first path. |

Texturelabs terms https://texturelabs.org/terms/ also prohibit using resources to train or assist AI image generation. Do not feed their textures into image generation. A licence for a finished game is not automatically a licence to publish raw sources or a reusable component pack. No restricted resources were acquired or committed.

## Do not acquire for this task
Generic flat/vector or low-resolution pixel-art GUI packs do not solve the photographic frame target. Admurin Paper Theme (https://admurin.itch.io/ui-paper-theme) is pixel art; LoudEyes Paper UI (https://loudeyes.itch.io/paper-ui-pack-for-games) lists a flat/minimalist direction and prohibits raw-file redistribution. Neither is recommended as the main frame source. Do not wholesale-switch to Game-icons.net when Lucide is already the documented choice. Keep backgrounds/characters deferred. Do not replace working meter/control behaviour or select packs by asset count.

## Next concrete evaluation
Acquire A1/A2 originals plus licence records; inspect source geometry, blank-paper options, marks and actual detail; record hashes only after download. Produce one fixed-light, front-facing transparent PNG proof, separating paper/clip/contact shadow and using existing available rendering capability. If execution is unavailable, record the real blocker. Judge the source proof against the locked mockup before any Godot integration. Then use one existing panel, with identical content/bounds/background/state, and fix the already logged phone-caption defect before reuse of the comparison harness. Start with a focused 390x844/1280x720 comparison; perform full four-size/regression checks when worth promoting. Keep all protected controls and hardening unchanged. No new pipeline or family rollout to conceal an inadequate source.

## Improvement findings and simulated lenses
BM-14: record commercial use and public source redistribution separately; hold ambiguous/restrictive licences. BM-15/BM-46: the prior broad suggestion duplicated an existing icon policy and treated generic kits as useful without targeting the actual missing layer. Source-page verification is not asset acquisition or pixel acceptance.
Simulated art direction: physical source construction is the useful gap. Technical art: original-file/render proof pending. UI: preserve live labels and existing controls. Engineering: no new runtime/framework. QA/producer: distinguish listing/terms verified, downloaded, imported, natively tested and visually accepted. These are simulated findings, not human sign-off.
