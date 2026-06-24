#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output/site"
TERRAIN_OUT="$ROOT/output/terrain"
MOONBOOK_OUT="$ROOT/output/moonbook"

mkdir -p "$OUT"
mkdir -p "$TERRAIN_OUT"
mkdir -p "$MOONBOOK_OUT"

cd "$ROOT"

bash scripts/verify_moonmoon_sources.sh
python3 scripts/generate_moonmoon_fixture.py

/Users/kq/.moon/bin/moon run cmd/main > "$OUT/first_trusted_square.md"
/Users/kq/.moon/bin/moon run cmd/main -- json > "$OUT/first_trusted_square.json"
/Users/kq/.moon/bin/moon run cmd/main -- terrain fixture > "$TERRAIN_OUT/first_trusted_square_grid.md"
/Users/kq/.moon/bin/moon run cmd/main -- terrain fixture json > "$TERRAIN_OUT/first_trusted_square_grid.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonbook dossier > "$MOONBOOK_OUT/first_trusted_square_book.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonbook dossier json > "$MOONBOOK_OUT/first_trusted_square_book.json"

printf 'wrote %s\n' "$OUT/first_trusted_square.md"
printf 'wrote %s\n' "$OUT/first_trusted_square.json"
printf 'wrote %s\n' "$TERRAIN_OUT/first_trusted_square_grid.md"
printf 'wrote %s\n' "$TERRAIN_OUT/first_trusted_square_grid.json"
printf 'wrote %s\n' "$MOONBOOK_OUT/first_trusted_square_book.md"
printf 'wrote %s\n' "$MOONBOOK_OUT/first_trusted_square_book.json"
