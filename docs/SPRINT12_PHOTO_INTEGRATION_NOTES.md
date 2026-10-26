# Sprint 12 — photo-first journey integration, truthful release gate
**26 October 2026 — PR #182 — NOT RELEASE-READY**

## Delivered code (actual repository changes)
- Player-visible exact title **LIVING THE DREAM** in `Scripts/main_menu.gd`, export/application name `Living the Dream` in `project.godot`. BandMaster remains internal repo only.
- `Scripts/journey_photo.gd`: deterministic offline, independent image slot for each of four songwriting and five show-day stages; preserves existing SVG illustration when approved photo is absent. No save-schema changes or runtime network dependency.
- `Scripts/songwriting_journey.gd` and `Scripts/show_day_journey_view.gd`: photo-first scene rendering. The wide 1600×900 crop is used for the actual scene artwork, while mobile/tablet ambient layers select the 900×1400 portrait crop. Minimum journey copy increased to 16px following 390×844 review.
- `scripts/prepare_living_dream_upload.py`: owner-supplied AVIF/JPEG/PNG/WebP conversion, 16 strict scene names, EXIF orientation, input and output validation, 1600×900 and 900×1400 WebP, SHA-256, original dimensions and per-photo rights status. Never fabricates a human sign-off.
- `scripts/test_prepare_living_dream_upload.py`: three actual Pillow tests: AVIF decoding and two crops, duplicate slot rejection, missing provenance failure. **Local 3/3 PASS.**
- GitHub photo workflow now runs owner AVIF conversion tests and real Godot photo routing tests on PRs. A photo intake job requiring Unsplash network is **manual only**, because automatic direct requests returned HTTP 401. Successful CI is not evidence of shipped photographs.

## Source and asset status
At inspection of the PR tree there were **zero** `Art/Photography/approved/*.webp` files. Actual photo retrieval attempt: [photo-intake workflow run 40339676333](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40339676333) — **FAIL: HTTP 401 Unauthorized** when retrieving Unsplash photo data; no audit or WebP outputs. The `photo_sources.json` entries are **candidates only**. We must not treat those URLs as imported/cleared images. Existing SVGs are active fallback; generated AI planning art is not shipping.

## Actual populated screenshot inspection (pre-photo baseline)
[GitHub screenshots run 40339676447](https://github.com/alimuir654-rgb/BandMaster/actions/runs/40339676447), artifact 12657522767: 60 actual Godot PNGs. Inspected `song-journey-0`, `show-journey-0`, and `show-journey-3` at **390×844**, **720×1280**, and **1280×720**. Observed: clear stage titles, accessible fixed footer and no observed CTA clipping in these nine captures. However the artwork is still geometric vector, the 390px load scene is text-dense, the mobile ambient background occupies excessive passive space, and 1280px story text is visually small. Subsequent code raised text floor and separated portrait ambient/wide art; **fresh latest-head screenshots are still required to verify these fixes**. No claim of production-quality artwork or owner approval.

## Five simulated persona reviews (not human playtesting)
| Persona | Verdict | Concrete observation / next change |
|---|---|---|
| New player | CONDITIONAL PASS | Stage order and primary footer actions legible; small secondary copy and loading gear text need another latest-head 390px review. |
| Working British musician | CHANGES NEEDED | Existing abstract van and soundcheck are not credible real British grassroots settings; need UK panel van, actual small venue, and source-specific arrival art. |
| Game critic | **FAIL** | Schematic SVGs and reused tinted backgrounds do not meet the photographic art brief. Release blocked until actual distinct images and visual inspection. |
| UI/UX/accessibility | **CHANGES NEEDED** | Pre-fix 390px supporting text too small; min 16px code fix pending new screenshot inspection, plus reduced-motion and keyboard focus regression. |
| Godot/release QA | CONDITIONAL PASS | Prior photo-routing/AVIF workflow 40340113998 passed both Python and Godot jobs; verify all workflows on the **latest** head and actual WebP imports. No save-schema changes. |

## Mandatory next actions
1. Obtain owner-uploaded Unsplash AVIF files in named scene folders (the user has offered to provide them), with original photo URL/photographer/license. Do not use AI-generated van image as shipping art without owner approval.
2. Run `python scripts/prepare_living_dream_upload.py --incoming Art/Photography/incoming --output Art/Photography/approved --register scene_asset_register.csv --strict-provenance`; inspect both crops and commit **real** image binaries plus audit.
3. Verify 390×844, 720×1280 and 1280×720 populated screenshots *with photos actually rendered*, including UK authenticity, faces/logos and readable overlays. Rework failed persona gates.
4. Run uninterrupted band creation → song → booking → show → exactly-once settlement → disk save/reload, inspect warnings #170, re-run latest-head CI. Do not merge stacked PRs #177/#178/#180/#181/#182 on red CI or failed art review.
