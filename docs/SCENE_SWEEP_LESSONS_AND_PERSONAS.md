# Livin’ The Dream — Persona Reviews and Lessons (append-only)
All reviews below are **simulated adversarial lenses**, not external expert or human feedback. Read before any code change. Never infer owner art approval from CI.

| ID | Persona | Prior observed failure / lesson | Required guard |
|---|---|---|---|
| C01 | Owner/art direction | Flat vector controls after photographic Lab05/07/08.4 were rejected | Actual source-backed photo controls and reference screenshot comparison |
| C02 | Owner/player | Faders/knobs are EDITABLE inputs; results/stats must use inert meters | No input handling, keyboard focus or player-value signal on passive stats |
| C03 | Art direction | Dark photo hardware floating on light DAY looks incongruous | Sympathetic physically plausible road-case / mixer housing |
| C04 | Accessibility | Landscape under-scaled rack; mobile captions collided | 390/720/1280/1600 native screenshots, ≥44 physical px, no clipped labels |
| C05 | Engineering | Original fader at 0 drew a residual line; ring overlays had stray LEDs | Real 0/50/100 image checks, true off, no release flash |
| C06 | Player/UX | Unconnected buttons create instantaneous unmotivated progression | Clear primary action with stage and consequential feedback |
| C07 | Musician | No credible path from band formation to gigs | Build early jams, socialising, rehearsal, covers, songwriting first |
| C08 | Owner | DAY must be substantially lighter than stage NIGHT | Game-state-driven phase, not user clock; real dusk |
| C09 | QA | Green initial transport CI yet overlapping readout and selectors | Manually inspect actual Godot captures and add collision assertions |
| C10 | Material artist | Target art (rotary, planning papers, showboard) is reference quality, not shippable scene/sprite | Use layered materials and native dynamic values; never crop full static target |
| C11 | Release | #192 scene journey branch separate from #198 hardware source | Verify paths in actual branch; no missing cross-branch scene path |
| C12 | Branding | Display name is Livin’ The Dream, not BandMaster | Correct new UI strings without changing repository/save namespace |

## Simulated PRE-FLIGHT S01 — 27 Oct 2026
**Player:** need context/next step rather than 6 unrelated buttons. **Working musician:** band and rehearsal before gig; studios not the only interface. **Material art director:** WebP scene photos help but cannot represent full target paper textures; mark gap. **Accessibility:** proper 44 physical px nav on 390×844, readable text, scroller. **Godot release:** no save writes, no nonexistent #192 paths, test four viewports.

## Next: add POST-RUN S01 findings after checking actual screenshot evidence. Every subsequent sprint reads most recent review and updates this file before development.
## POST-RUN S01 review — 27 Oct ~11:45 UK (simulated lenses; not human sign-off)
- **Player | P1:** six world tabs + fixed action dock convey career shape, but REVIEW BRIEF calls are placeholders. Never convert them to "OPEN" until the exact functional scene exists. Repro: go to FORMATION/TOUR/GIG and press primary.
- **Working musician | P1 (fixed):** initial Songwriting/Studio previews mistakenly showed an on-road van, Tour showed a music shop. Fixed repo-photo scene mapping after inspecting 48 actual Godot screenshots. S02 needs musician-plausible early-band room and meaningful rehearsal consequences rather than static backdrop.
- **Material/UI art director | P0 (OPEN):** current S01 shell is clean and responsive but **far below owner-approved target quality** of tactile paper, cork, marker writing, real studio metal/knob housing. WebP photography is only supportive contextual visual, not target-scene completion. The target view ZIP is claimed uploaded by owner but not verified GitHub bytes on PR198/S01 at first check; verify every sprint.
- **Accessibility | P1:** mobile 390×844 3×2 navigation and dock do fit; 44+ physical action targets tested. 11px provenance/secondary copy is too small for normal interaction; keep functional copy at ≥15px physical in actual scenes. Need test screen-reader semantics/focus continuity before release.
- **Godot/release | PASS isolated:** Godot 4.7.2 compile, six model context state changes, real 48 screenshots (run 40497305354), no save/economy mutation, no broken cross-branch paths. Warning: original #192 scene journeys absent on S01 branch; S02 must inspect and reuse safely.
- **Process lesson | P1:** initial CI correctly failed its own PRE-FLIGHT detection because ledger heading was "S00 / S01", not exact "S01". Corrected and re-tested; keep future gates exact. Another failed geometry gate measured raw label size without the parent canvas scale; fixed with world-transform device-pixel calculation. Green first photo run did not spot conceptual wrong-image assignments; retain *human-style image review* before claiming quality.
**Carry forward:** no cheap generic tiles sold as studio controls, no wrong-world photos, no direct stat edits via faders, no fake ownership of target PNGs, and S02+ must append their own five lenses after inspecting actual Godot images.
