# Current verified opening polish (C32, 30 October 05:06 UTC)

**Native tested source:** 5991452688a467c4018986f035755ac0fe007c60; [run 41006002295](https://github.com/alimuir654-rgb/BandMaster/actions/runs/41006002295) SUCCESS, C26 gameplay52/52, opening88/88, four real-pointer complete 390x844/720x1280/1280x720/1600x900 journeys, explicit milestone widths and physical CTA targets. [Full native milestone screenshots/test pack](https://github.com/alimuir654-rgb/BandMaster/actions/runs/41006002295/artifacts/12955795872), SHA256 b54091fc35e7f0123d0f1872a6d8676edf0671ae822acb86dbfe1fedf4091f43. [Playable packaged Godot project](https://github.com/alimuir654-rgb/BandMaster/actions/runs/41006002295/artifacts/12954924877), outer ZIP SHA256 9333c8cbc0fe7bd39479ce2ab4fc9b24debfda5a696d59de7330d4984c626b8a, inner standalone ZIP SHA256 9e12e5fde546c295eecb2fcdec28bd6a1b644dbb61c1df1b972dfc0eadadaaf0. Extract inner ZIP, import project.godot into Godot4.7.2, Play. Isolated candidate; no merge, production save mutation or engine change.

Milestone1 and milestone2 now occupy legible deliberately centred source-backed flight-case panels rather than 180px portrait strips; C31 vs C32 same-state original native PNGs opened and visually compared at all four viewports. Original frame/button/meter/cast bytes untouched. Global artwork remains **PARTIAL / owner_approved=false**. The next highest-impact visually observed defect is the still-skinny portrait frame on the logo/vibe live preview on both390 and1280; C33 should address that only after its own preflight. C32 source and standalone checkpoint retained;08:00 implementation/art freeze,09:00 evidence-only review.

---

# Current verified opening checkpoint (C31, 30 October 04:16 UK)

**RUNNABLE ISOLATED GODOT 4.7.2 CANDIDATE — TECHNICAL PASS, VISUAL POLISH PARTIAL, OWNER NOT APPROVED.** Exact tested commit `e32ce6402ee9da2ab4816a785ce448722f9f5e2d`; native [run 41001787068](https://github.com/alimuir654-rgb/BandMaster/actions/runs/41001787068) SUCCESS; [all-stage four-viewport native PNGs/logs](https://github.com/alimuir654-rgb/BandMaster/actions/runs/41001787068/artifacts/12953681854) ZIP sha256 `edb5347ddfc79b31c46b849ab95d27c306107201e03b3eeaa629c4bddefe6058`. Re-ran 52 C26 gameplay, 88 opening state and four actual mouse complete opening routes with zero failures. The existing complete C30 source d5f71bbce0f4ea34cca256f87fb10f9c91ccba6a remains preserved as unpolished fallback.

**Playable standalone package now verified:** [project artifact](https://github.com/alimuir654-rgb/BandMaster/actions/runs/41001787068/artifacts/12952829399), outer ZIP sha256 `03319391fdb4e04d50e6ffd5852e653259585ff142f32643b3a2ca7d6e5d2fc7`; contains `livin-the-dream-isolated-godot-4.7.2.zip` inner SHA256 `763c4b36fc8078d5e19c60e1f658c8dcd37bec930be1f55982f0b2bbea7cfb2f`. Extract the inner ZIP to a folder, import `project.godot` in Godot 4.7.2 and press Play. The main scene is `experiments/playable_flightcase/opening.tscn`; native startup smoke passed, original art/controls and all required script dependencies included. This is isolated candidate work, not a production integration or game release. Continue uses separate `user://c27_opening_draft.json`, not production saves.

**Visible gains:** title now full readable LIVIN' THE DREAM on 1280/1600 (deliberate two lines at390); New/Continue/Settings/Quit visible, no clipped bottom action. Completed-band roster/source-backed panel now wide and readable, with center-aligned heading and action buttons. All four original native title/summary image pairs inspected; milestone1/2 still use weak skinny portrait mounts, wider recruitment/naming screens still require independent art judgement. The prior C31 gate failure run41001582542 was logged and corrected before final strict green checks. Avoid claiming final mockup art match.

Next: C32 gated polish: fix skinny milestone1 and milestone2 180px portrait frames with deliberate source-backed responsive celebration screens, preserve C31 tested checkpoint and native full journey. Keep the conditional completion gate, full native regression, 08:00 art/code freeze and09:00 evidence-only review.

---

# Current verified opening checkpoint (C30, 30 October 03:18 UK)

**PLAYABLE ISOLATED CANDIDATE — ENGINEERING GREEN, VISUAL QUALITY PARTIAL / OWNER NOT APPROVED.**
Source `d5f71bbce0f4ea34cca256f87fb10f9c91ccba6a`, [native workflow run 40996529020](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40996529020), [four-size complete opening screenshots and test logs](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40996529020/artifacts/12951901120), ZIP SHA256 `4a1172cf2908c76c0a1aba391607aea04f334f9ca57b57beede76ea6d5b8f11d`. Real Godot4.7.2: existing C26 52, extended opening88, native four-viewpoint stage-by-stage true-pointer playthrough all with zero assertion failures. This is an immutable fall-back test point for any optional visual polish; no production scene/real save edits, no merge.

To play: obtain isolated project from the workflow/source path `experiments/playable_flightcase/`, launch Godot4.7.2 with the required scoped components and approved cast, choose New Band → Genre → Guitar/Bass/Drums → Assign one vocalist → Complete Lineup → milestone1 → three suggested/custom name with Raw/Dark/Playful/Dreamy → one rethink → lock → milestone2 → logo/vibe → First Practice; Continue restores the isolated draft. The workflow assembles dependencies in /tmp/c27-opening; source repository alone is not yet a packaged standalone zip of the isolated project. C25 portrait crops are only small previews; C21 notebook rejected and parked.

Visual quality is explicitly NOT accepted: native title/summary layout weak, narrow central frames, cropped/orphaned brand, original owner mockup still artistic target. User condition authorises targeted polish on existing stages only until08:00 after this verified checkpoint, not new scope. See C30 session and issue #200.

---

## Prior cast and frame evidence (retained)

# Current review

Latest scoped result: [C25 approved cast imported and scored](../continuous_improvement/C25_REVIEW.md).

[Scored roster](../../Data/CharacterCast/SCORES.md) · [Approved reference and preview source manifest](../../Art/References/ApprovedCast20261029/README.md) · [Opt-in adapter](../../experiments/character_cast/catalogue.gd).

18 fictional profiles cover all five instruments/roles, including Bex and Sam as high-talent/high-friction choices. Exact approved contact sheet and18 small unscaled previews are committed; not independent full-resolution masters. Godot4.7.2 focused270checks pass at e11a89f7ad3f52b55c956d3bbc4a815aff218400; run40969779247; publication c330c1feb0cd3aa3df3a25bf7e8a44a6e5628482. Trait penalties remain metadata, not live career behaviour. Global owner_approved remains false; this casting reference is specifically approved.

Next: already-authorised overnight connected flight-case gameplay, not another frame or photo session. Read [current night direction](../continuous_improvement/OWNER_DIRECTION_2026-10-29_NIGHT.md) and the mandatory improvement checks. C25 writer release is recorded by its closeout receipt.

Retained history: [C24 reused-source dossier proof](../continuous_improvement/C24_REVIEW.md), [C22 frame recovery](../continuous_improvement/C22_REVIEW.md). C24 native tests passed but its final default publication was held after its expired lease; notebook work is now parked. No claim of owner approval for those frame candidates.
