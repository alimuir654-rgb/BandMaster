# BandMaster — Premium Hardware: Eight Control-Family Sprints
**Owner correction, 27 October 2026. Status: implementation HOLD pending actual image-backed quality and visual review.**

## Decision and correction
The eight scene-world runs (#185–#192) built acceptable *layouts and page structures* but did **not** deliver the photoreal, tactile controls approved in **Lab 05 (precision faders / hardware), Lab 07 (transport and pad actions), and Lab 08.4 (value-driven luminous rotary rings)**. The current tour road-case, songwriting paper and gig controls are provisional visual studies. Do not call them premium/approved or prioritize more scene/page development. **One control family per sprint**; no whole-scene redesigns, feature-creep or production integration until owner sees and approves the actual Godot controls.

Existing good page structure, warm bright DAY, intermediate DUSK, atmospheric NIGHT, gameplay state, and core game/save must remain intact. No wall-clock theming.

## P0 asset and source verification
The original Lab 05/07/08.4 **separated PNG / source bundles** were supplied in prior project chats, but the 26–27 October visual sprint audits explicitly found them **absent from GitHub's Art/UI**. The files available in the current review context are Godot screenshots and demonstrator ZIPs, **not** editable or clean sprite source for those premium hardware controls. A screenshot is NOT production sprite art. Every sprint checks actual binary bytes and SHA-256; where the source cannot be accessed it must **report BLOCKED** instead of drawing a cheap procedural imitation or claiming fidelity. **27 October 08:57 update:** The owner HAS supplied all three original ZIPs, audited in `docs/PREMIUM_HARDWARE_RECEIVED_SOURCE_AUDIT_2026_10_27.md`. Do **not** ask for reattachment. The remaining P0 is transfer of the 129-file repo-import ZIP's extracted binaries to GitHub, plus obtaining *genuinely separated fader layers* not present in the flattened Lab05 reference archive. Until then continue only with asset-intake tooling, tests and honest BLOCKED reports; never manufacture a cheap visual substitute. Do not silently replace approval baseline.

Approved assets must be imported with provenance, alpha-state separation, appropriate texture sampling, 9-patch handling where needed, and licence/ownership manifest. Keep live labels/text/icon semantics engine-rendered. Do not cut up flattened screenshot composites.

## Eight successive control-family deliverables
Each sprint produces a **standalone Godot interactive gallery for only its family** with normal, hover, focused, pressed, latched/selected, disabled, and DAY/DUSK/NIGHT when relevant. Characteristic audible click/feedback only if actual rights-safe audio exists; never block on audio. Use same reference geometry and physically plausible depth/lighting.

| Sprint | Control family | Scene applications | Acceptance emphasis |
|---|---|---|---|
| 01 | **Precision linear faders**: machined caps, rails, ticks, illuminated level strip | Songwriting energy/arrangement, stage channel levels, studio | Accurate thumb/track, drag & keyboard, no residual slider line, true off state |
| 02 | **Rotary encoders and illuminated halos**: segmented arc tracking exact value | Song vibe, budget/risk, soundcheck mix | Original Lab 08.4 halo accuracy; no residual buzz light, stable partial illumination |
| 03 | **Transport keys**: play/pause/stop/record, recessed metal keycaps | Rehearsal/demo/songwriting transport | Lab 07 photographic tactility, mechanical depth and mutually exclusive states |
| 04 | **Backlit sampler and sequence pads**: tactile square pads, section markers | Verse/chorus/studio/gig cue sequencing | Individual pad presses, backlit latched state, coherent bank selection, no false audio |
| 05 | **Rugged mechanical toggles/latches**: guarded switches, load/secure | Van loading, crew/gear readiness, amp power | Clearly distinct safe/unsafe, robust hit target, not a generic rectangular button |
| 06 | **Segmented selector and route controls**: mechanical tabs / short-throw rocker | Venues, route, travel/rest, tour day | Distinct choices + crisp selection/lock states; warm daylight finish |
| 07 | **High-priority stage cue buttons**: GO/HOLD/ENCORE | Day load-in checks, dusk soundcheck, night stage | Illuminated physical switch, arm/interlock, high-contrast text, disabled reason, never colour-only |
| 08 | **Utility/action keys and confirmation hardware**: inset ticket/booking/commit, icon keys, LED/status lamps | Budget confirm, song save, tour booking, common chrome | Complete hardware vocabulary, responsive consistency and final side-by-side gallery; **this sprint still only authors this family**, with a cross-family *review* but no gameplay rollout |

### Definition of DONE for each sprint (must satisfy all)
1. **Source reality:** hardware PNGs/sprite sheet plus a source/asset manifest and exact version/rights; distinguish approved original art vs unapproved new candidate. No unlabeled SVG/gradient stand-ins.
2. **Functional test bed:** isolated Godot 4.x scene, live handlers and value semantics; drag/click/toggle, mouse + keyboard, focus + disabled states; no edits to live career/saves/economy.
3. **Physical visual fidelity:** side-by-side compare against reference Lab art at native scale; lighting follows state and value; pressed depth/normal edge; no dead pixels, off-state leakage, glow seams, track remnants, stretched textures or text baked into hardware.
4. **Phase skins:** visibly light DAY in warm natural materials; DUSK tungsten/petrol; NIGHT dark with meaningful practical lights. Preserves one game's art direction across separate materials.
5. **Real renderer evidence:** capture *actual Godot* at 390×844, 720×1280, 1280×720 and 1600×900; show off/on/partial/disabled where appropriate. Inspect every image manually; don't infer quality from CI alone. 44px targets, contrast, no clipping.
6. **Adversarial checks:** simulated first-time player, touring musician, UI/material artist, accessibility, Godot engineer; record concrete defects and correction. These are NOT real human approval.
7. **Engineering:** focused input-state/geometry tests, existing Godot regression, licence checks; links to commit, PR, screenshot artifact, green/red outcomes and owner approval **OPEN**. If blocked, label BLOCKED and carry issue forward; don't mark sprint complete.
8. **No unsafe merges:** separate drafts on top of existing visual PoC branch (#192), never merge art to main without owner seeing and approving the actual image-backed controls. Respect PR #182 (photo gate) and #183 (dashboard isolation).

## Control asset intake contract
Expected from approved ZIP: original PNG images per family (clean isolated normal/off/on/pressed/selected material layers), control scene/GDScript when available, source provenance and resolution. On receipt: ZIP inventory, SHA-256, pixel-alpha integrity, duplicate search, source manifest, native-scale sprite inspection, import to Art/UI/PremiumHardware/<family>, build Godot TextureButton/TextureRect interaction wrappers or TextureProgressBar/Control where appropriate. Use engine-rendered labels and native accessible action semantics. Reference screenshots alone are for comparison and are not asset source.

## Band-growth and story enrichment backlog — research, NOT sprint displacement
Source: London Guitar Institute, "From Garage to Stage: Tips for Starting a Band", 12 Jan 2024, https://www.londonguitarinstitute.co.uk/from-garage-to-stage-tips-for-starting-a-band/ . The following are *game design proposals* inspired by its recommendations; they are NOT features implemented by this PR.

1. **Recruit and align members**: instrument coverage, skill, commitment and tastes; hire/tryout with trade-off between virtuosity vs shared vision. Trust and band agreement decisions create later event consequences.
2. **Find a shared sound through jams**: rehearsal unlocks influences/identity and combination traits; jam chemistry alters cohesion and idea quality; occasional musical disagreement resolved with meaningful relationship stakes.
3. **Earn the stage**: early covers and timing practice build tightness and stage confidence; first local/open-mic events occur before major gigs; readiness requirements avoid jumping instantly to success.
4. **Write originals deliberately**: jams generate riff/lyric seeds, bandmates claim co-writing credits and compete for leadership. Three-session song creation remains authoritative; progress from covers to original repertoire; a dozen originals can be an aspirational milestone, not an arbitrary hard gate.
5. **Career identity**: name, visual style, demo recording, instrument upgrades and promotion choices trade off money/time/morale/reputation; don't introduce features as mere instant-click checklists.
6. **Credible relationships**: a band agreement on duties and credits has downstream impact; gig socialising/networking after shows grows local promoters/fans and seeds realistic opportunities.

Gameplay integration after owner visual approval: map proposals against existing models (band formation, Practice.compose, social/trust, GigCalendar, UKGigCircuit, media/promotion, gear inventory). Prefer small stateful choices with persisted consequences over invented meters; use real in-game time costs, save compatibility and once-only event settlement. Do not spend any of these eight control-family sprints implementing story systems.

## Execution ledger (fill honestly)
| Sprint | Status | PR | Actual renderer evidence | Owner gate |
|---|---|---|---|---|
| 01 Faders | **P0 BLOCKED** — owner source received; separated fader layers absent from GitHub and Lab05 ZIP is flattened reference only | [#194](https://github.com/alimuir654-rgb/BandMaster/pull/194) | **None**; no fake hardware render. Input/source-gate tests pending CI | OPEN / FAIL |
| 02 Rotary | QUEUED | — | — | OPEN |
| 03 Transport | QUEUED | — | — | OPEN |
| 04 Pads | QUEUED | — | — | OPEN |
| 05 Latches | QUEUED | — | — | OPEN |
| 06 Selectors | QUEUED | — | — | OPEN |
| 07 Stage cues | QUEUED | — | — | OPEN |
| 08 Utility keys | QUEUED | — | — | OPEN |

**Owner decision needed before any acceptance:** review actual source-backed Godot screenshots; page layouts alone do not meet this control-art gate.
