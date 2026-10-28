# R1 visual layer + native data map — design handoff, NOT implementation acceptance

**Status:** Draft derived from the generated A-03 design-only roadcase study; original PNG is only in the separately prepared R1 review ZIP until exact upload/import. All measurements below are proposed for *future independently composed* art and actual Godot viewport captures, **not measured acceptance dimensions from an approved layout**. Owner art P0 remains OPEN.

## Asset ownership: what can legitimately be reused

| Needed visual | Confirmed existing GitHub source (draft branch) | Design/rights action |
|---|---|---|
| Photographic transport image button | `bandmaster_premium_controls_lab/assets/transport_studio_{idle,hover,pressed,active,disabled}.png` and corresponding punk/electronic states | Use only as actual photo-state input when visually matched to case; verify button pixel-size and focus |
| Original physical control references | `bandmaster_premium_dashboard_poc/assets/` includes `horizontal_base.png`, `horizontal_cap.png`, `meter_base.png`, focus and buzz ring + LED states | **Don't misuse input fader or rotor as a noninteractive statistic**; passive attribute meter is separately implemented |
| First-pass source-backed case / paper | `Art/UI/RecruitmentV4/case_roadcase{,_phone,_tablet}.svg` and `paper_personnel.svg` | ENGINEERING SOURCE ONLY; prior reviews found them too vector/flat; **not art accepted** |
| Metal tab and recruit button states | `Art/UI/RecruitmentV4/metal_tab_{idle,hover,pressed,selected,disabled}.svg` and `amber_key_{idle,hover,pressed,selected,disabled}.svg` | Inspect actual Godot pixels; replace with better source layers if below generated style; never silently downgrade |
| Candidate masters (Alex + Nia) | **MISSING**; prior four `Art/Portraits/indie/` and `docs/visual-proofs/recruitment_portrait_*.svg` do not meet agreed quality | Generate/export **two separate full-resolution original photo-like sources** with immutable IDs `alex` and `nia_griffiths` and honest provenance |
| New case and paper layers | **MISSING** at A-03 photo level | Create independently reusable source without baked live text; test nine-slice/rivet scale |
| Original owner visual reference | Spec + SHA only in `docs/RECRUITMENT_REFERENCE_LOCK.md` | Import exact binary before claiming pixel comparison; until then qualitative by contract |

## Intended 1280×720 **landscape** first-fold composition (unapproved proposal)

- Whole physical case: 16..1264 x, 20..704 y. Top band y20..89 sets **genre and band context** in native Labels.
- Role tabs (five): x30..188, y108..565 with 44+px actions in a continuous physical rail. Primary role may be a housing-tab row instead if composition improves.
- Candidate contacts: x202..285, y114..610, six separate visual identity photos/tiles, never six generic copies.
- Hero portrait: x300..695, y112..447; subject visually dominant; preserve source aspect and focal face from master.
- Read-only six attributes: x300..695, y460..626, six rows ~26–28px, labeled and native values. Label/glyph contrast tested at physical screenshot; **no focus, no drag, no value_changed**.
- Dossier paper: x710..1246, y108..625. Real native name, town, musical career, personality, frictions, ambition and trouble; editable/dynamic only as program-native text.
- Bottom dock: y637..703; clear source-backed action, canonical talent before/after and selected lineup. Do not make 44px controls visually 12px because of viewport scaling.
- Retain deliberate whitespace, matched light direction; rivets, paper corners and foil labels are decoration subordinate to portrait and decision.

## Intended **390×844 phone** first-fold composition (not a desktop downscale)

- Case/identity header y0..68 with current game phase, genre, role/person ID.
- Five-role horizontal rail y70..121, min 44px each **with horizontal scroll** and an explicit selected state if all five cannot fit legibly.
- Six candidate mini-contact rail y122..170, with explicit browse arrows and no reused faces; reachability test at physical 390.
- Portrait source, cropped independently for phone: x22..368, y172..406. Name, role and true price adjacent or over restrained physical ID strip.
- Six read-only meters: x22..368 y412..606 (~32px rows); native labels, integer values, at least one trade-off visible.
- Primary recruit action + remaining talent x22..368 y620..704, verified physical touch and keyboard states.
- Dossier opens a separate real native paper view from “FULL DOSSIER” action; don't squeeze long paragraphs into y704..744 and call them readable.
- Fixed roster/talent quick dock y760..844 with unobscured CTA. Audit notches/safe-area. No automatic whole-screen stretch.

## Actual game data v. art

Authoritative code: `Scripts/recruitment_catalogue_v3.gd`. Example: `alex` is Alex Vale, Bristol non-binary singer/guitarist, 24 years old, documented trial 51-point cost; `nia_griffiths` is Nia Griffiths, Cardiff singer, 23 years old. **Do not copy the image-generated fictional Nia Carter, £450/week or fabricated numeric stats.** One isolated selection and 200-point allocation model; owner has not signed off economy balancing. Read the source live before committing assertions.

All source masters: separate face/photo, blank paper, hardware skin/button states and inert meter texture. Treat image-generation artboards as references only; no one-piece UI image with clickable transparent overlays. Godot native text/focus and interactions must be real.

## Validation sequence / stop conditions

1. Register verified source portraits with real byte SHA and transparent statement of AI generation/licensing.
2. Art director visually compares two distinct IDs without captions. **Reject cloning / off-model faces.**
3. Art director reviews separately authored desktop and mobile targets, including six meters beneath portrait; source line-up/data slots must be realistic.
4. Only after R1 `provisional_pass` move to R2 decomposition; only after source pack validated move to isolated R3 native Godot code.
5. R3/R4 actual Godot captures at 390x844, 1280x720 (extend 720x1280,1600x900). CI verifies correct source and layout but does not confer visual pass.
6. The owner alone confirms final look. NO merge, no saves or wider scenes now.
