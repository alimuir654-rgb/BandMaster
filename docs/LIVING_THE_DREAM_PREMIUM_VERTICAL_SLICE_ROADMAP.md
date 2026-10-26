# Living the Dream — Premium Vertical Slice Roadmap
Approved 26 October 2026. This supersedes incremental cosmetic-polish priorities. Player-facing game: Living the Dream; BandMaster is internal.

## Direction
Combine management clarity, narrative atmosphere and energetic transitions with an original British independent-music identity. Preserve existing gameplay, save files and once-only financial settlement. Treat the first five seconds, action hierarchy and first playable journey as the quality benchmark.

## Sprint A: Band HQ component comparison
Create two playable Band HQ variants: current native/WoldUI design revised and a researched alternative if compatible with actual Godot version, licence and API. Do not introduce incompatible dependencies. Prototype primary/secondary/tertiary/destructive/disabled buttons, hover/pressed/focus, iconography, typography, navigation, photo scrims and meaningful motion. Show a real before/after contact sheet at phone 390x844, tablet 720x1280 and landscape 1280x720. Require clear dominant action, no clipping, keyboard focus, adequate contrast and minimum 44px targets. Select a winner on screenshots and interaction evidence.

## Sprint B: Flagship songwriting experience
Rebuild four-stage songwriting and rehearsal using winning components and existing owner photographs, without replacing underlying state or persistence. Upgrade bandmate choices, action feedback and transitions with reduced-motion support. Preserve no-cost backward navigation and exactly-once song commit. Test disk reload, progression and three viewport screenshots.

## Sprint C: Gig and world rollout
Extend validated components to van loading, UK road, venue arrival, soundcheck, backstage, showtime, band HQ, gear, relationships, finance and scrapbook. Replace unconvincing non-UK travel photography, verify permissions for individual images, remove overcrowded panels and repeated button farms. Execute uninterrupted formation -> songwriting -> booking -> van -> venue -> gig -> scrapbook -> save/reload, including exactly-once reward and regressions. Make owner test build only after all gates pass.

## Mandatory simulated reviews each sprint
Creative director: originality/composition.
Principal UI engineer: shared components, responsiveness and consistency.
Interaction designer: pacing, animation and action feedback.
British musician: geographic, equipment and venue authenticity.
First-time player/game critic: instant clarity, engagement and polish.
Godot QA: input, clipping, save/load, performance, CI and economic safety.

Log concrete screenshot-linked findings as blockers/major/minor, fixing blockers and major defects before rollout. Explicitly carry failed review findings to the next sprint with code fix, tests and recapture. Simulated reviews do not mean external specialist approval. Green CI alone never constitutes visual approval.

## Production evidence
GitHub PR #182 remains the art-integration branch, preserving the prior PR chain #177 -> #178 -> #180 -> #181 -> #182. At last confirmed inspection there were 30 owner originals, 60 processed WebP variants and 14 photo scene pairs. Verify current files and photo rights, and inspect fresh populated screenshots. Avoid new planning-only PRs; ship code, screenshot artifacts and tests. Hold release until owner judges the visual step-change acceptable.
