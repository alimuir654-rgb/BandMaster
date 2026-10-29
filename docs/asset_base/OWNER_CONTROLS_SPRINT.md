# C20: owner-directed controls and frames sprint

Latest explicit owner instruction (29 October 2026, after V19):
> Ok, leave the scene backgrounds for now.
> Focus on building out re-usable controls based on the mockups. These are a good enough start.
> Remember the previously built controls that are already in the repository - they can probably be re-used.
> 1. Check what controls are in the rep
> 2. Build what's missing
> 3. improve the existing frames to pro level
> That should be do-able in the next sprint.

This new direct request authorises one scoped controls/frame implementation sprint despite the preceding programme's optional-family freeze. It does NOT extend scheduled work, permit merges, authorise new backgrounds or character generation, or approve finished art. Retain the 16:00 review and disclose anything still unverified.

Sole writer is C20-reusable-control-library; check CONTROL_SPRINT_LOCK.json before another writer claims STATE. STATE.writer was null at the inspected baseline14bf4d55. The dedicated lock avoids replacing the large historical STATE while inventory and reusable source are prepared. All branch updates must be non-force with an expected head. Original STATE/history remains intact until the verified closeout records this new scope.

Reuse the U18 action/tab/browse sprite states, C01 passive meter bytes, source-backed frame corners/surfaces, and unchanged Lab08 linear/rotary source. Missing deliverables are reusable public APIs and native scenes for toggle, bounded stepper, segmented choices, browse/pagination, selectable rows, passive badges and a coherent frame preset system. No backgrounds or characters are to be redesigned. Use existing textures and native labels/signals. No PNG from a full mockup is imported as a screen.

Acceptance: runnable isolated library gallery; 44px targets; mouse/keyboard interactions; explicit disabled/selected/focus states; bounded values and once-only signals; immutable passive-meter source hashes and inert semantics; phone/tablet/landscape native captures; scale-safe frames with source manifest; actual pixel review. Green CI is engineering evidence only. owner_approved remains false.
