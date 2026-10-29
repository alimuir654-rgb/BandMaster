# C21 — directly authorised frame styling and hardening

Owner instruction: "continue with some additional frame styling and hardening/improvement work. One hour". Received 29 October 2026, approximately15:51 UK. This is one scoped follow-on session; it supersedes the previous15:00 implementation freeze for frame/library work only, not the recurring programme or production rollout. No merge, main, PR199, save, character or scene-background changes. Preserve original meter and hardware artwork. Dedicated CONTROL_SPRINT_LOCK identifies the sole writer until release, with expiry16:51:20 UK.

Retain C20 as the verified baseline. Develop distinct panel/inset/portrait/ticket/header/modal source-derived frame profiles, reduce heavy paper shadows, and harden focus and safe-content behavior. Preserve existing C20 native regression tests; add source/style independence, theme-change, reflow and actual mouse/keyboard modal tests at390x844,720x1280,1280x720,1600x900, both standalone and a separate installed host.

Official implementation guidance consulted29October2026:
- https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html — separate texture margins/content insets; protect corner pixels rather than repeat hardware.
- https://docs.godotengine.org/en/stable/classes/class_control.html — focus ownership, mouse filtering and explicit handling.
- https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html — let containers size child controls.

Native execution remains pinned to Godot4.7.2. A green check is not visual approval. Final actual pixel findings belong in C21_VERIFIED_REVIEW.md. owner_approved=false.
