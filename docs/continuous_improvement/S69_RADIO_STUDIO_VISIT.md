# Radio studio visit contract for the next source sprint

Status: proposed implementation contract, 1 November 2026. S69 changes metadata and review artwork only. Verified game remains 47692162d7d68e0eca354760734f21d216e3a392. The owner's21:43 direction and checked Revise A05 supersede the old microphone-only presentation as the visual target.

## One complete pilot

Use one fictional local presenter, one actual released demo and two authored questions. Keep the original £20 / one career-day tariff. Starting, answering and acknowledging only checkpoint journey metadata; cost, campaign effects and Finance settle once at final wrap. Show that timing explicitly before entry.

Saved phases: arrival → introduction → question1 → reaction1 → question2 → reaction2 → wrap_ready → completed. This list is a proposal, not existing schema. Each reaction waits for a separate Continue. A first tap can complete the existing Ink reveal; it cannot also acknowledge or answer. Preserve12physical-pixel drag qualification. Reduced motion presents identical information with explicit acknowledgement. Reveals, fades, resize and redraw never mutate the career or phase.

Question1: “What should listeners remember about this record?” Craft/songwriting versus live energy. Question2: “What would you ask a new listener to do next?” Invite friends/support versus judge the recording's craft. Use actual demo/track facts for context; do not invent a past gig, appointment, airplay or audio playback.

## Proposed bounded policy

These are candidate modifiers to test, NOT shipped balance or owner art approval. Fields are Fans, Press, Buzz:

| Question | Answer ID | Fans | Press | Buzz |
|---|---|---:|---:|---:|
| focus | craft | 0 | +3 | -2 |
| focus | live_energy | 0 | -2 | +3 |
| invitation | invite | +2 | -2 | 0 |
| invitation | critical_craft | -1 | +2 | 0 |

All four combinations trade one outcome for another before caps. Combine the two vectors, then apply once to the original campaign's base result. Fans must remain a supported nonnegative whole value; Press/Buzz remain0–100. Recheck finite numeric limits and actual capped deltas. Preview and commit use ONE pure policy function. Native answer hints describe emphasis; the wrap's actual saved pills are authoritative. Never attribute the whole original campaign gain to one answer.

## Actual source and transaction constraints

Current promotion_rules.launch already calls OriginalCampaign → Story → Calendar → Life → Finance. DO NOT call it and then adjust choice effects: downstream milestones and Finance would already have run.

The future interview finish path must validate the exact released-demo ID/fingerprint/raw index; call original Scripts/release_campaigns.gd launch ONCE; apply bounded answer effects; keep the fresh campaign fan count and new journal wording truthful; then run Story.observe(campaign), Calendar.expire, Life.refresh and Finance.apply once. Preserve the original £20 Other outgoing and single closing day. Generate the complete receipt from actual before/after state, then the owner saves once for that committed phase before success is presented. Do not rewrite older campaign journals or lose unknown fields.

Use actual current APIs in promotion_rules.gd, recording_rules.gd, recording_desk.gd, career_desk.gd and opening_state.gd. Source code remains unchanged in S69; a fresh scoped production preflight/gate is required.

## Durable progression

Propose one versioned active visit OUTSIDE the selected recording/campaign. Putting progress in demo.campaigns.radio would mark the campaign complete; putting it elsewhere inside the demo changes RecordingRules.fingerprint. An optional career-level radio_visit_v1 object is a PROPOSAL, not an existing key.

Pin a stable journey ID, source demo ID/index/fingerprint, original presenter/content/policy version, fixed question IDs, phase and immutable answered choices. Begin resumes a valid active visit; it never resets answers. Back/Menu pauses it. Reopening shows the same reaction or question without rerolling. Do not permit unrelated paid actions to silently change the pending visit's day/context; revalidate actual cash/day, terminal state, booking and source before wrap. Cancellation policy must be explicit, costless before settlement and incapable of duplicating a reward.

At successful wrap preserve the canonical campaigns.radio completion marker and existing receipt_v1; add an optional versioned interview transcript with the actual chosen text/IDs and policy facts. Existing completed/legacy campaigns remain read-only and must not gain invented interviews. Validate consumed fields and preserve unrelated nested extensions/saveversion1.

Every phase write sets busy BEFORE dispatch, copies the whole career, saves through the current owner, and restores the entire prior career/phase on failure. Each phase may checkpoint once; Finance/cost/reward occurs only once at the final phase. Never advance through a render or tween callback.

## Artwork and presentation

Source proposal: /workspace/generated_images/exec-1cb53096-e5db-438d-aa16-249ab467fab9.png,1448x1086RGB, SHA86047904689849739358f312a6be396f5150dc3bf06b6ad17ac1e97d1bede51c. Provenance: /workspace/work/overnight-20261102/s69/art/radio-studio-presenter-proposal.json. One combined generated studio/presenter plate, not photography, a native screenshot, a separate character rig or approved production source.

Use the full4:3/contain composition on phone; place it beside native conversation on wide screens. Unrestricted16:9cover trims headphones/console. Keep all dialogue, answers, real costs, progress and metrics native outside pixels. Do not animate false VU/audio telemetry or pretend to play an unavailable track. A05v2 starts pending owner approval; preserve A05v1's checked revision request and images. A01/A02/A03 approvals do not approve this new source.

Build a small reusable presentation shell (art, speaker, Ink copy, choices, reaction, Continue) while keeping the resolver/save in the owning activity controller. Prove radio first; adapt the pattern to meaningful sessions instead of turning routine browsing into a long interview. Preserve printed16 captions, Caveat22/CLEAR16, safe area, fixed48px actions, scroll arbitration, genuine focus and lifecycle cancellation.

## Completion proof for the source sprint

Test all four answer combinations against an independent literal policy+original-chain oracle; caps, malformed/unknown/legacy fields, duplicate/stale IDs, terminal and due/upcoming/overdue show cases, low cash, every phase repeat/pause/reload and real save-failure rollback. Check every phase is0cost/0day until one final £20/1day application. Block duplicate wrap and repitch.

Changed integrated UI needs exact-source73gameplay/88opening/import/four genuine standard journeys, focused real pointer/key/device-indexed touch/save/retry/Menu/Continue at390x844/720x1280/1280x720/1600x900, manually empty all_error_lines, wholejourney flags and orphan checks. Start from the current379-source S68 runtime/audit and explicitly inventory additions. Do not repeat unchanged S68 suites for activity. Open actual originals and keep technical, visual and owner gates separate.

## Priority and deadlines

Radio journey first at22:15, target a finished pilot by01:15. Then F02→F01 result/next-goal cohesion; only a complete conditional F09 live-set/art pilot after the core is green. No new breadth after05:15; source freeze06:45; final07:15 wake readiness only; release07:30; all writes07:45; hardstop08:00Europe/London2November. SAME finite existing queue/thread, no APK/ZIP packaging, no new controller or automatic extension.

