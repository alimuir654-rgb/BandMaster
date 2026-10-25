# BandMaster photography sourcing

Use photography to establish the world of each genre: rehearsal rooms, small venues, backstage corridors, recording gear, UK night streets, and touring. Portraits of fictional recurring musicians require separate consistent character artwork.

## Rules for sourced photography

1. Select an individual image and check the original photo page (not just a search thumbnail).
2. Record its exact source URL, photographer, asset identifier, acquisition date, license and derivative filename. Never assume an Unsplash+ item uses the standard license.
3. Check for recognizable people, visible logos, promotional posters and other third-party rights before using a photo in commercially distributed gameplay.
4. Download via an appropriate permitted workflow; do not scrape Unsplash. If using the Unsplash API, follow its hotlink, download tracking and attribution rules. Prefer an offline game pack rather than runtime API use.
5. Convert approved images to WebP, inspect crop and colour grade at 390x844 and 1280x800, and retain the original provenance record.
6. Images from Unsplash remain third-party licensed material; the public GitHub repository does not make them original BandMaster artwork or change their license.

## Asset locations

- Art/Backgrounds/<genre>/studio.webp
- Art/Backgrounds/<genre>/backstage.webp
- Art/Backgrounds/<genre>/gigs.webp
- Art/Backgrounds/<genre>/promotion.webp
- Art/Backgrounds/<genre>/home.webp
- Art/Backgrounds/shared/<scene>.webp

## Photo register

Maintain `Art/photo_sources.csv`, one row per *approved imported image*, with:
`asset_path,source_url,photographer,license,acquired_on,review_status,notes`.

Do not put hypothetical candidate images in this register. Record newly sourced images before including them in release builds.

## Useful starting searches

- [Rehearsal room](https://unsplash.com/s/photos/rehearsal-room)
- [Live music venue](https://unsplash.com/s/photos/live-music-venue)
- [Recording studio](https://unsplash.com/s/photos/recording-studio)
- [Band backstage](https://unsplash.com/s/photos/backstage-music)

License: https://unsplash.com/license
API guidance: https://help.unsplash.com/en/articles/2511245-unsplash-api-guidelines
Third-party rights: https://help.unsplash.com/en/articles/14224409-what-if-there-is-a-brand-logo-in-an-image-on-unsplash
