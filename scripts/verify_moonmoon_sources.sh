#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/data/fixtures/first_trusted_square_dem.csv"
LOLA_GDR_CATALOG="$ROOT/data/sources/lro_lola/gdr_ds.cat"

EXPECTED_FIRST_TRUSTED_SQUARE_SHA256="45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7"
EXPECTED_LOLA_GDR_CATALOG_SHA256="f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8"
EXPECTED_LOLA_GDR_CATALOG_BYTES="5672"

actual="$(shasum -a 256 "$SOURCE" | awk '{print $1}')"

if [[ "$actual" != "$EXPECTED_FIRST_TRUSTED_SQUARE_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$SOURCE" >&2
  printf 'expected %s\n' "$EXPECTED_FIRST_TRUSTED_SQUARE_SHA256" >&2
  printf 'actual   %s\n' "$actual" >&2
  exit 1
fi

printf 'verified %s %s\n' "$actual" "$SOURCE"

catalog_actual="$(shasum -a 256 "$LOLA_GDR_CATALOG" | awk '{print $1}')"
catalog_bytes="$(wc -c < "$LOLA_GDR_CATALOG" | tr -d ' ')"

if [[ "$catalog_actual" != "$EXPECTED_LOLA_GDR_CATALOG_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_GDR_CATALOG" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_GDR_CATALOG_SHA256" >&2
  printf 'actual   %s\n' "$catalog_actual" >&2
  exit 1
fi

if [[ "$catalog_bytes" != "$EXPECTED_LOLA_GDR_CATALOG_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_GDR_CATALOG" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_GDR_CATALOG_BYTES" >&2
  printf 'actual   %s\n' "$catalog_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$catalog_actual" "$LOLA_GDR_CATALOG"
