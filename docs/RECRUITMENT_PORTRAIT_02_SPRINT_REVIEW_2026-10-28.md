# 02:00 UK — Recruitment portrait quality spike (28 October 2026)
**Status: original art studies rendered; character differentiation improved; owner visual quality gate still FAILS.** Draft PR #199, do not merge. This report records actual inspected evidence, not human approval.

## What actually changed
- Two new 320×350 layered original SVG character studies: [Alex Vale](visual-proofs/recruitment_portrait_alex_ink_study.svg) and [Nia Morgan](visual-proofs/recruitment_portrait_nia_ink_study.svg). Different hair, face contour, skin palette, earrings, instrument cues, wardrobe, role, and local gig identifiers. They share the same ink-outline, warm paper, amber and dark-green halftone grammar.
- The Alex art was embedded in both **design-only** [1280×720](visual-proofs/recruitment_editorial_desktop_1280.svg) and [390×844](visual-proofs/recruitment_editorial_phone_390.svg) source artboards, replacing the earlier very generic smooth vector face. The artboard remains separately editable SVG geometry; no flattened clickable UI, no runtime claims.
- Editorial CI renders both portraits individually, a two-person contact sheet, and direct **330×276 desktop / 200×240 phone** physical-size comparisons, in addition to both updated full-screen artboards. These are real rendered PNG pixels from source vectors, not Godot captures.
- No new gameplay scene, no saves, no live Godot/Figma mutation, no purchased assets, no new animation dependency, no engine migration. Existing code and owner-approved reference remain untouched.

## Pixel inspection — deliberately adversarial
| Quality test | Observation | Gate |
|---|---|---|
| Two recognisably different people | Alex has black shag, lighter skin, guitar strap and mic; Nia has bleached short hair, dark skin, hoop, bass neck. Distinct at full size. | Limited improvement |
| Coherent visual grammar | Same flat ink contours, restricted palette, halftone, border, audition label, paper/gig backdrop. | PASS for *consistency*, not artistry |
| Desktop 330×276 | Larger portrait mass and detail are clearer than the original cartoon. But shapes are still clean and simplified; visual language reads like vector avatar rather than authored indie music editorial art. | **ART P0 FAIL** |
| Phone 200×240 | Expression and tiny ink hatching are lost. The face remains identifiable, but high-frequency dots/lettering can feel noisy; not a compelling premium portrait. | **ART P0 FAIL** |
| Recruitment hierarchy | Six read-only bars and decision remain visible, with large amber CTA and empty roster. Desktop bars are too vertically compressed and contact rail remains placeholder silhouettes. | UI P1 |
| Actual native Godot | Not implemented in this 02:00 run. Artboards are not game renders; controls remain static SVG shapes. | ENGINE PROOF OPEN |
| Rights / provenance | All new portrait shapes manually authored for this isolated code-based study, with no external photos, AI-generated photoreal faces, pack assets or licence claims. This does **not** confer human-art quality. | Source provenance recorded |

**Judgment:** the new studies are better than the first generic face and provide a consistent 2-character system, but they are not close enough to the owner-approved photographic/cinematic recruitment reference. Do **not** generate dozens more variants from this approach, or assert that 'AI-looking character' concern is solved. Avoid turning these into a production portrait pipeline without an owner art-direction decision.

## Verified external art alternatives (research only, not imported)
- [Kenney UI Pack](https://kenney.nl/assets/ui-pack): **430 assets, CC0** per official listing, suitable for studying reusable control states but **not** a character portrait solution. [Kenney licensing FAQ](https://kenney.nl/support) explicitly permits commercial reuse without attribution. No assets downloaded.
- [Hyptosis — Cyberpunk Portraits](https://opengameart.org/content/cyberpunk-portraits): the creator describes portraits from an old Flash game; OpenGameArt lists **CC0**. A [GDevelop listing](https://gdevelop.io/asset-store/free/cyberpunk-portraits-cyberpunk-portraits) lists 24 images. Potential consistent human-made character source, but science-fiction style likely wrong for British indie-gig world. The actual pack files have **not** been downloaded, evaluated at target sizes, or imported.
- [GatlingArt — 100 Sci-Fi RPG Faces](https://gatlingart.itch.io/100scifirpgfaces): artist explicitly says **no generative AI**, 100 grayscale 600×600 faces, **CC BY 4.0** with credit required, 'name your own price'. This is a plausible free/attribution-based *illustration* benchmark if download terms permit, but sci-fi wardrobe and in-game source editing need review. No pack assets downloaded.
- [Screaming Brain Studios — Portrait Frame Pack](https://screamingbrainstudios.itch.io/portrait-frame-pack): **CC0, no AI, 300 frames**, but does **not** include character portraits; not a solution to the current art P0.
- Three owner-supplied Figma Community kits remain **inspiration only**, with commercial export licences unverified. None copied.

## Next gate (04:00)
**Do not proliferate characters or screens.** A narrow native Godot 4.7.2 recruitment render is useful *only* as an art-handoff engineering benchmark: same artboard source layers, live native text/control overlay, six inert bars, 390+1280 screenshots, and no gameplay-save modifications. If this cannot be done without baking the whole SVG artboard into an interactive surface, instead document the technical blocker and leave the owner a truthful design-only comparison. If a human-made CC0/CC-BY portrait set cannot match the chosen indie editorial direction, the high-value next step is a dedicated character artist / original portrait commission, with a two-person sample and fixed art bible before scaling.

**Owner sign-off: NOT GIVEN. PR #199: DRAFT / UNMERGED.**
