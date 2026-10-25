# Indie artwork integration contract

The production artwork gap is a release blocker, not a green-check substitute. The current packaged crop candidates live outside GitHub until approved and imported.

## Canonical paths

- `Art/Portraits/indie/jo.webp`
- `Art/Portraits/indie/alex.webp`
- `Art/Portraits/indie/sam.webp`
- `Art/Portraits/indie/dev.webp`
- `Art/Backgrounds/indie/formation.webp`
- `Art/Backgrounds/indie/studio.webp`
- `Art/Backgrounds/indie/backstage.webp`
- `Art/Backgrounds/indie/gigs.webp`

Portraits resolve by the saved character identifier, then sanitized display name, with a shared-art fallback. Existing saves are unchanged.

## Approval bar

- Each portrait: purpose-made consistent character image, at least 512 x 640 px recommended, WebP, no embedded UI text, no source-concept crop artifacts.
- Environment shots: at least 1600 x 900 px, reserve central safe crop for portrait phones.
- Verify dimensions, colour consistency, identity, safe crops and filename collisions before commit.
- Verify all assets from the Godot renderer, particularly phone 390 x 844 and desktop 1280 x 800.
- Do not promote the existing 256 x 256 candidate crops as production artwork. They may be installed for internal proof-of-integration only.

## Release gate

Godot script and screenshot checks prove loading and rendering, not art direction. Mark the v6.0 visual milestone complete only after artwork is integrated and visually signed off in screenshots.
