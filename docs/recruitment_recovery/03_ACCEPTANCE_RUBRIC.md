# Visual acceptance rubric — fail loud, evidence first

A test passing is not a visual pass. Score every category with **PASS / FAIL / UNVERIFIED** based on specific *real Godot pixels* or linked art-target pixels. A portfolio of separate beautiful assets does not qualify as a unified screen. The art director may mark an **internal provisional pass** for isolated integration, but only the owner can approve a final look/merge.

| Gate | Concrete question / evidence | Severity |
|---|---|---|
| Identity | Do two subjects look like different real indie musicians *without seeing names*? Is character style uniform? No clip-art/stock-fantasy look? | P0 |
| World | Is it one credible roadcase/record-store dossier physical scene, not flat boxes? Is wear/luminosity/shadow direction consistent? | P0 |
| Hierarchy | Within 5 seconds: who, role, price, two trade-offs, remaining talent and next action? Is the portrait dominant? | P0 |
| Source fidelity | Real source layers, no flattened screenshot UI, clear asset/licence trail, no wrong-person portrait? | P0 |
| Phone | 390×844 native: identity, six bar cues, CTA/talent and roles discoverable; no overlap/overflow; >=44px touch targets? | P0 |
| Desktop | 1280×720 native: dossier readable, no clipped sixth attribute, first-fold candidate choices/actions? | P0 |
| Gameplay | 5 role tabs, 6 candidates per role/genre via source, hybrid role correctly counted; recruit/removal updates budget only once? | P0 before native proof |
| Read-only semantics | Six red-to-green bars reflect real values, no focus/click/drag on stat bars? | P0 before native proof |
| Focus and states | Five distinct input visual states, visible keyboard focus, predictable tab order, no accidental game actions? | P1 |
| Readability | Text crisp at actual physical pixel size; no 1px/tiny type; technical labels and paper body copy legible? | P1 |
| Material integration | Portrait/controls/paper correctly lit as a single object; control chrome remains subordinate? | P1 |
| Polish | Disabled captions, hover and selection differentiation, high-dpi scaling, alternate candidate differentiation? | P1 |

## Visual-review discipline

1. Open each actual native screenshot at original resolution; inspect phone and desktop separately (not just thumbnails).
2. Open target art image and real Godot screenshot side-by-side with SAME orientation and named origin. State if the original approved reference binary was unavailable.
3. Log **specific** regions: pixels/controls/labels/face shape, and the exact source to change. Reject generic recommendations like "more polished" without actions.
4. Record separate verdicts for designer, musician/player, accessibility, gameplay engineer and release QA. These are role simulations, **not independent human reviewers**.
5. Any P0 FAIL means no owner-acceptance claim, no merge, no next scene. P1 can remain open only if explicitly visible to owner as a defect in the single proof.

## Pass rule

- `prep`: file-level contract validated only.
- `art`: original two-portrait and target composition files confirmed with source checks, designer internal provisional evaluation and readable character/physical balance; **does not mean owner approved**.
- `native`: screenshot files verified at 390 and 1280; real Godot tests and source integrity reported; manual visual QA attached. Passing code evidence does **not** turn any P0 into PASS.
- `owner`: the actual owner explicitly signs off linked final native proof. A reviewer agent must never set this flag or forge a comment.

## Stop conditions

Stop if there is no strong portrait pair; provenance unclear; target composition materially weak; fake clickable artboard; native render diverges from target; a focus/stat input violation; or owner rejects. Document why and the one corrective action, not another new UI family.
