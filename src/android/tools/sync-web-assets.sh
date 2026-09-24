#!/usr/bin/env bash
# Optimizer V.4.0 - bundle the web dashboard into the APK assets.
# -----------------------------------------------------------------------------
# The dashboard ships as a perchance page (index.html + src/*.js|*.css) AND as an Android APK.
# This script copies that exact web layer into app/src/main/assets/www/ and wraps the
# body-only index.html into a full HTML document for the WebView.
#
# Run it from anywhere:   ./tools/sync-web-assets.sh
# It must run before the first Gradle build (and after every web-layer change).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"     # .../src/android
out="$here/app/src/main/assets/www"

web=""
for cand in "$here/../.." "$here" "$here/.."; do
  if [ -f "$cand/index.html" ] && [ -d "$cand/src" ]; then web="$(cd "$cand" && pwd)"; break; fi
done

if [ -z "$web" ]; then
  echo "ERROR: could not find the web layer (index.html + src/)." >&2
  echo "       Expected it at $here/../.. (the generator root)." >&2
  echo "       Download the whole generator - index.html, src/ and src/android/ - then re-run." >&2
  exit 1
fi

echo "web layer : $web"
echo "assets    : $out"

rm -rf "$out"
mkdir -p "$out/src"

copied=0
for f in "$web"/src/*.js "$web"/src/*.css "$web"/src/*.png; do
  [ -e "$f" ] || continue
  cp "$f" "$out/src/"
  copied=$((copied + 1))
done

{
  printf '%s\n' '<!doctype html>'
  printf '%s\n' '<html lang="en"><head>'
  printf '%s\n' '<meta charset="utf-8">'
  printf '%s\n' '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
  printf '%s\n' '<meta name="color-scheme" content="dark light">'
  printf '%s\n' '<meta name="theme-color" content="#05070f">'
  printf '%s\n' '<title>Optimizer V.4.0</title>'
  printf '%s\n' '</head><body>'
  cat "$web/index.html"
  printf '\n%s\n' '</body></html>'
} > "$out/index.html"

echo "copied $copied module files + index.html"
echo "done - now run:  ./gradlew assembleDebug"
