#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/data/fixtures/first_trusted_square_dem.csv"

EXPECTED_FIRST_TRUSTED_SQUARE_SHA256="45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7"

actual="$(shasum -a 256 "$SOURCE" | awk '{print $1}')"

if [[ "$actual" != "$EXPECTED_FIRST_TRUSTED_SQUARE_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$SOURCE" >&2
  printf 'expected %s\n' "$EXPECTED_FIRST_TRUSTED_SQUARE_SHA256" >&2
  printf 'actual   %s\n' "$actual" >&2
  exit 1
fi

printf 'verified %s %s\n' "$actual" "$SOURCE"
