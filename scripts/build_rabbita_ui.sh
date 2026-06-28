#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RABBITA_OUT="$ROOT/output/ui/rabbita"
RABBITA_ASSET_OUT="$RABBITA_OUT/assets"
RABBITA_ASSETS=(
  "southpole_10deg_print.jpg"
  "lunar_global_texture.jpg"
  "lunar_global_texture.source.json"
  "rabbita_moon.css"
  "rabbita_evidence.js"
  "noetix_rig_viewer.js"
  "rabbita_app.js"
  "moon_globe.js"
)

mkdir -p "$RABBITA_ASSET_OUT"
cd "$ROOT"

/Users/kq/.moon/bin/moon run cmd/main -- ui rabbita > "$RABBITA_OUT/first_trusted_square.html"
for RABBITA_ASSET in "${RABBITA_ASSETS[@]}"; do
  cp "$ROOT/src/ui/rabbita_moon/assets/$RABBITA_ASSET" "$RABBITA_ASSET_OUT/$RABBITA_ASSET"
done
python3 scripts/check_rabbita_bundle.py
python3 scripts/check_rabbita_runtime.py
python3 scripts/check_rabbita_mission_evidence_queue.py
python3 scripts/check_rabbita_noetix_walk.py

printf 'wrote %s\n' "$RABBITA_OUT/first_trusted_square.html"
for RABBITA_ASSET in "${RABBITA_ASSETS[@]}"; do
  printf 'wrote %s\n' "$RABBITA_ASSET_OUT/$RABBITA_ASSET"
done
