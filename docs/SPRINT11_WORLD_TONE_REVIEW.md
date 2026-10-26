# Sprint C — art-led world tone, cinematic composition and release gate
**Date:** 2026-10-26. **PR:** #180, stacked on #178 and #177. **Status:** code delivered; visual approval and full release gates outstanding.

## Actual implementation
- Three new original 1600x900 vector environments: band rehearsal room, gear workshop and local music-scene streets, with manifest provenance.
- CareerHub now chooses distinct environmental art and materials for HOME, STUDIO, GIGS, BAND, GEAR and SCENE; no gameplay text baked into images.
- Landscape (>=960px) writing and show-day journeys now use art-left/story-right compositions instead of narrow floating forms; phones/tablets retain linear vertical scenes.
- Three-viewport world identity regression; show journey landscape assertion; full new continuous writing → booking → rest → five show scenes → once-only gig → scrapbook → disk reload acceptance test.
- Screenshot workflow expanded from 42 to at least 60 PNGs, including all six career tabs at 390x844, 720x1280 and 1280x720. A screenshot job producing files does not itself prove visual quality.
- Existing WoldUI/SceneSheet, authoritatively settled gig mechanics, legacy saves and reduced-motion controls preserved.

## Five adversarial simulated persona reviews — NOT human playtesting
| Persona | Current verdict | Concrete evidence / action |
|---|---|---|
| **First-time player** | CONDITIONAL PASS | Distinct locations and five-step show route improve wayfinding; old GIGS and songwriting panels remain below journey entry and still make first screens dense. Next action: remove/accordion classic controls only after complete regression and owner review. |
| **Working musician** | CONDITIONAL PASS | Song concept → vibe → band jam → session and van → road → venue → soundcheck → stage are plausible, with existing economics. Loading and arrival are still mostly observational rather than choices. Next action: add a genuine crew/gear decision tied to existing state without a fabricated extra day. |
| **Game critic** | CHANGES NEEDED | More environmental identities and split cinematic composition, but original vector art is still schematic and reused on ambient layers; the journey does not yet deliver a premium, immersive production look. Next action: owner-approved illustrated/photographic key art and distinctive character/venue beats, then re-review. |
| **UI/UX/accessibility specialist** | PENDING FINAL PNG REVIEW | Three viewport code gates and >=44px primary controls, scroll-safe story, focus and reduced motion. Landscape two-plane composition directly addresses Sprint B issue #179. Must inspect actual populated captures for clipped text, contrast, awkward whitespace and story width. |
| **Godot/release QA** | PENDING LATEST HEAD CI | Tests added for art import, six worlds, cinematic layout and one uninterrupted career from finishing a song through a gig and reload. Existing PR stack unmerged. Latest-head CI and #170 resource/RID investigation required before release. |

**Stop/go:** any CI failure or screenshot clipping is a blocking defect. Fix and rerun; do not merge until all required checks pass. A CHANGES NEEDED critic verdict remains a release blocker even if CI is green.

## Explicit carry-forward
1. Human owner visual sign-off is not recorded.
2. Three original SVGs are production-integrated *interim artwork*, not final premium art. Unsplash photo binaries remain absent.
3. Dense classic GIGS and inline songwriting controls are still present for save/feature regression; progressive disclosure/removal requires separate tested change.
4. Main-tab navigation currently uses a fade-in reveal, while journeys use true fade-out/fade-in; unify the main navigation transition with safe input blocking.
5. Formation has its own existing lifecycle test, but the new continuous career test begins with an already formed band. A single uninterrupted band-builder-to-show fixture remains outstanding.
6. Resource/RID warning issue #170 needs root-cause evidence.
7. PR dependency chain: #177 → #178 → #180; retarget/recheck after parent merges, never merge a red head.

## Screenshot and CI evidence
- Sprint B actual 15 populated show PNGs (before Sprint C split): run 40304730434; observed wide landscape had narrow central content and passive art.
- Sprint C latest screenshot artifact and 5 workflow conclusions must be recorded after runs complete. No claim of human visual approval.
