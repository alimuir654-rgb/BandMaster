# BandMaster — Scene Worlds & Eight-Sprint Visual Programme
Approved by game owner 26 October 2026 (night UK). Supersedes incremental cosmetic UI passes for presentation work. Gameplay roadmap remains valid.

## Design decision: ONE world, several believable workspaces
Approved hardware quality baseline: owner-approved Lab 07 photographic transport/pad/channel controls, Lab 05 photographic fader/knob language, Lab 08.4 value-driven knob ring accuracy. **Do not reproduce these as procedural gradients, excessive outlines, cheap SVG hero illustrations or over-scaled generic buttons.** Use separated image-backed surfaces for realism; editable Godot text/interaction overlays. Current Lab 08.4 was delivered as conversation ZIP, NOT established as committed repository assets. First sprint must inspect repo bytes and either properly import accessible source with provenance, or report exact asset-access blocker; do not claim integration or copy screenshots into shipped art.

### Mandatory day / dusk / night rule
- **Day is substantially LIGHTER** than night. Daytime band house, songwriting table, rehearsal and touring desk: warm ivory/paper/stone, natural indirect daylight, softer shadows, physically tactile light hardware. This is not a minor colour accent swap.
- Dusk/transition: warm gold, petrol blue and sunset ambience; travel arrivals, loading in, soundcheck, show anticipation. Preserve readability.
- Night: deep graphite/black, coloured stage practical lights, strong illuminated cues for gig, backstage, post-show.
- Switch appearance from **simulated game time / explicit scene state**, never from player's real-world clock. Every journey should show credible day-to-evening-to-night progression when the fiction changes. Light/dark backgrounds never change the semantics of action colours and safety/priority.
- Shared components retain geometry, sizing, focus states, interaction events, accessible contrast; *materials and lighting* vary by scene family and time-of-day. Night gig is atmospheric, not so dark it hides information. Test dusk transition for abrupt flashes, persisted game state and reduced-motion setting.

### Four scene families
| Family | Day | Dusk/night | Distinctive interaction visual |
| --- | --- | --- | --- |
| Tour logistics | Warm daylight touring office / road case, daylight maps/date board, tickets/passes on cream paper | Sunset transit and amber dashboard; hotel/van lights at night | Road-case latches, route/itinerary strip, booking and expense stamped modules; maps fictional unless geodata exists |
| Songwriting / arrangement | Sunlit rehearsal desk, tactile notebook/cards, tape strips, sequence blocks | Tungsten rehearsal evening, late-night idea session | Edit-safe lyrics/structure, draggable sequence only if tested, transport/pads/faders appropriate to instruments |
| Gig night / live show | Daytime load-in, soundcheck and equipment setup, neutral crew controls | Backstage dusk -> dark stage -> encore -> lit aftermath | cue lamps, stage GO/HOLD, setlist faders, crowd/energy signal; distinct lock and warning semantics |
| Studio / common career | Light rehearsal/daytime creation and management | Dark studio recording, after-hours career hub | Existing premium studio hardware controls; no universal dark panel on every scene |

### Interaction / design rules
- One dominant action per scene, 1–3 supporting actions, each with a defined consequence. Use music-specific controls because they express actual function, NOT as decoration.
- Reusable interaction model and state styles: normal, hover, keyboard-focus, pressed, selected/latched, disabled with reason; icons/text editable outside artwork; min 44 logical touch-target px, no unreadable baked-in labels.
- Source art must have actual license/provenance. Avoid identifiable real people/brands/third-party venue marks unless cleared. Confirm photo assets exist, do not rely on manifest naming.
- For every visual family, establish an *asset-sheet approval* and reference-screenshot comparison before implementing many screens.
- Portrait 390x844 / 720x1280, landscape 1280x720, plus 1600x900 desktop: screenshot of **running Godot actual scene** and static mock both, track mismatches. Geometry stability and state visual comparison.
- Current main-game save/load and deterministic economy protected; no modifying live saves in PoCs. Avoid conflicting PRs; resume open branch first.

## Eight overnight execution runs
**Run 1 — Foundation, time-of-day, typography starter.**
Inspect main and open PRs; confirm approved art assets source. Create shared scene-family x time-of-day token contract, preliminary font hierarchy and a lightweight runnable day/night comparison proof, preferably Godot native. Day backdrop must visibly lighten; no real-clock tie-in. Begin typography tests with *Barlow Condensed* for headlines, *IBM Plex Sans* body, *IBM Plex Mono* readouts (subject to OFL license and bundled files); sensible system fallbacks. Evidence: 3 actual screenshots + contrast / focus review.

**Run 2 — Tour Control Lab.**
Image-backed rugged road-case/route/tab/itinerary/booking controls with DAY white-paper + steel material treatment and dusk alternative. States validated. Distinct, premium material quality. Reuse approved component interaction logic; no generic styled rectangles.

**Run 3 — Tour Planning Scene PoC.**
Playable isolated itinerary > van/gear > accommodation/budget decision, preview consequences and routing; dawn/day to dusk journey demonstrated. Show real simulation values or clearly marked sample data. Meaningful choices and one primary action; 390x844 + 1280x720 captures.

**Run 4 — Songwriting & Arrangement Control Lab.**
Distinct sequence strips, verse/chorus/bridge blocks, editable lyric/idea controls, pads and controls set into LIGHT daytime rehearsal/notebook environment; after-hours studio light variant. Interactions cannot modify persistent songs until fully wired.

**Run 5 — Songwriting Scene PoC.**
Dedicated writing flow from jam > idea > lyric/structure > arrangement > decision/payoff. Playable staging and state preservation; compare daytime song-room with evening creative session. Do not claim advanced engine features beyond integrated evidence.

**Run 6 — Gig Night Control Lab.**
Live rig cue buttons, GO/HOLD/ENCORE with legible high-priority semantics, setlist tiles, segmented crowd/band meters, backstage safety/status indicators, day soundcheck vs dusk pre-show vs night stage materials. Warning/critical statuses never depend solely on genre tint.

**Run 7 — Gig Night Scene PoC.**
Playable coherent before/during/after show sequence, visual transitions day load-in > dusk soundcheck > night performance > aftermath, valid decision/confirmation and once-only consequences. Keep mature, grounded British live-music style.

**Run 8 — Convergence, typography & readiness gate.**
Consolidate approved tokens/components, compare the 3 standalone scene PoCs side-by-side, responsive/focus/state/a11y/godot runtime and save regression tests; typography production feasibility and license notice, asset manifest, source-of-truth module and gradual integration/rollback plan. Release HOLD and owner visual approval OPEN until owner actually tests and approves. Produce concise morning report with PRs, CI, screenshots, what changed, tests, open issues, next recommendation.

## Mandatory each-run quality gate (hard)
1. Inspect latest branch/PR, approved references, blockers and previous run's retro; resume unfinished work rather than parallel-conflicting changes.
2. Deliver **source code/assets plus runnable scene** (unless genuinely blocked); a concept or sprint plan alone is not a passing sprint.
3. Test with Godot headless where possible and ***visually inspect actual captured screenshots***. CI success by itself is insufficient; describe checks not run.
4. Show at least one clear **daylight** screenshot and one **night/dusk** screenshot whenever time-of-day applies; fail if both are simply dark variants.
5. Compare material detail to Lab 05/07/08.4 owner's approved quality; reject cheap UI, baked labels, mismatched genre theming or low-fidelity replacements.
6. Simulated adverse reviews: first-time player, touring musician, management-game veteran, UX/accessibility, Godot/release QA. Evidence-linked finding and corrective action; never fabricate human reviews.
7. Capture and record observed progress / completed checks / failing tests / screenshot artifact paths / blockers in `docs/SPRINT_EXECUTION_LOG.md` or on PR. If a pass cannot be verified, report FAIL/PENDING and carry forward rather than declaring completion.
8. CI-red PRs never merge, no auto-merge of visual HOLDs, no owner approval invented. Keep existing gameplay behaviour intact and no unlicensed artwork.

## Design-system rules and responsive typography starter
- Use three roles only: *editorial display*, *legible UI*, *instrument technical*. Size suggestions at 1280x720: display 30–42px; module heading 18–22px; actionable label 16–18px; body 15–17px; caption/readout 12–14px where legible. On 390x844 important actionable/body copy stays >=16px.
- Typeface shortlist: Barlow Condensed (headline), IBM Plex Sans (body), IBM Plex Mono (numbers and equipment readouts). **Shortlist only** until legally sourced font files, OFL.txt and runtime import test are committed; use Godot fallbacks rather than pretend assets exist.
- Night colours must pass 4.5:1 normal text contrast wherever possible; daylight charcoal on warm ivory needs equally good contrast. Genre palette accents may personalise indicators, never sacrifice contrast.
- Contrast and time-of-day must be assessed in final screenshots, not inferred from token values alone.
- Technical UI text must not duplicate labels already baked into reference PNGs. For future localisation, all mutable text should be engine-rendered.

## Dependencies and handoff
- Repo: alimuir654-rgb/BandMaster. Approved graphic baseline is user-reviewed in the 26 Oct 2026 project conversation; asset ZIPs Lab08.4 and Lab07 currently provided outside GitHub repo. Confirm actual binaries exist before any migration. Do not silently replace approved photographic quality with your own quick-drawn approximation.
- Existing repo may have open PR #183 premium career dashboard and #182 photo gate; avoid conflicts, don't merge provisional UI into main.
- Existing operational automated sprint playbook: `docs/AUTONOMOUS_SPRINT_PLAYBOOK.md`. Superseded for presentation focus by this document; regression/test guidance still applies.
- Scheduled sprints are at most 8 triggers, not guaranteed hour-long continuous coding; record actual execution and return truthful results.
