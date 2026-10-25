#!/usr/bin/env bash
# One-off, controlled import of three verified free Unsplash photographic assets.
# Execute only after confirming each photo page still says free under Unsplash License.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p Art/Photography/approved
download() {
 local id="$1" name="$2" source="$3"
 local target="Art/Photography/approved/$name.jpg"
 if [ -s "$target" ]; then echo "Already imported: $target"; return; fi
 local tmp
 tmp="$(mktemp)"
 # Unsplash download API often requires an authenticated session (401).
 # Resolve the image via the public photo page og:image metadata instead.
 local html
 html="$(mktemp)"
 curl --fail --show-error --silent --location --retry 2 --max-time 90 "$source" -o "$html"
 local photo_url
 photo_url="$(python3 - "$html" <<'PY'
import html, re, sys
source = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)', source)
if not match:
    match = re.search(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image', source)
print(html.unescape(match.group(1)) if match else "")
PY
)"
 rm -f "$html"
 if [[ "$photo_url" != https://images.unsplash.com/* ]]; then
  echo "Could not obtain verified Unsplash image URL from $source" >&2
  rm -f "$tmp"
  exit 1
 fi
 curl --fail --show-error --silent --location --retry 2 --max-time 90 "$photo_url&fm=jpg&w=1280&q=78" -o "$tmp"
 local mime
 mime="$(file --brief --mime-type "$tmp")"
 if [ "$mime" != "image/jpeg" ]; then
  echo "Unexpected type $mime for $source; refusing to rename it as JPEG" >&2
  rm -f "$tmp"
  exit 1
 fi
 if [ "$(wc -c <"$tmp")" -lt 10000 ]; then
  echo "Suspiciously small download: $source" >&2
  rm -f "$tmp"
  exit 1
 fi
 mv "$tmp" "$target"
 echo "Imported $target from $source"
}
download "lEwyj4FiHHU" "gear-pedals-hjortshoj" "https://unsplash.com/photos/selective-focus-photo-of-guitar-pedals-lEwyj4FiHHU"
download "-BCuXpA1tNc" "gear-pedals-austin" "https://unsplash.com/photos/several-guitar-effect-pedals-on-a-towel--BCuXpA1tNc"
download "5aiRb5f464A" "hq-corkboard-szczepanska" "https://unsplash.com/photos/sticky-notes-on-corkboard-5aiRb5f464A"
echo "Imported images: verify crop, quality, photographer and trademarks in Art/ASSET_MANIFEST.md before promoting into game scenes."
