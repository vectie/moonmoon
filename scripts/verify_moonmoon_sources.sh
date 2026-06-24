#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/data/fixtures/first_trusted_square_dem.csv"
LOLA_GDR_CATALOG="$ROOT/data/sources/lro_lola/gdr_ds.cat"
LOLA_GDR_SELECTION_LABEL="$ROOT/data/sources/lro_lola/ldem_875s_20m_float.xml"
LOLA_FIRST_TRUSTED_SQUARE="$ROOT/data/sources/lro_lola/first_trusted_square_dem.csv"

EXPECTED_FIRST_TRUSTED_SQUARE_SHA256="45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7"
EXPECTED_LOLA_GDR_CATALOG_SHA256="f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8"
EXPECTED_LOLA_GDR_CATALOG_BYTES="5672"
EXPECTED_LOLA_GDR_SELECTION_LABEL_SHA256="10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53"
EXPECTED_LOLA_GDR_SELECTION_LABEL_BYTES="11629"
EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_SHA256="7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c"
EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_BYTES="636"

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

label_actual="$(shasum -a 256 "$LOLA_GDR_SELECTION_LABEL" | awk '{print $1}')"
label_bytes="$(wc -c < "$LOLA_GDR_SELECTION_LABEL" | tr -d ' ')"

if [[ "$label_actual" != "$EXPECTED_LOLA_GDR_SELECTION_LABEL_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_GDR_SELECTION_LABEL" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_GDR_SELECTION_LABEL_SHA256" >&2
  printf 'actual   %s\n' "$label_actual" >&2
  exit 1
fi

if [[ "$label_bytes" != "$EXPECTED_LOLA_GDR_SELECTION_LABEL_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_GDR_SELECTION_LABEL" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_GDR_SELECTION_LABEL_BYTES" >&2
  printf 'actual   %s\n' "$label_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$label_actual" "$LOLA_GDR_SELECTION_LABEL"

lola_csv_actual="$(shasum -a 256 "$LOLA_FIRST_TRUSTED_SQUARE" | awk '{print $1}')"
lola_csv_bytes="$(wc -c < "$LOLA_FIRST_TRUSTED_SQUARE" | tr -d ' ')"

if [[ "$lola_csv_actual" != "$EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_FIRST_TRUSTED_SQUARE" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_SHA256" >&2
  printf 'actual   %s\n' "$lola_csv_actual" >&2
  exit 1
fi

if [[ "$lola_csv_bytes" != "$EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_FIRST_TRUSTED_SQUARE" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_BYTES" >&2
  printf 'actual   %s\n' "$lola_csv_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$lola_csv_actual" "$LOLA_FIRST_TRUSTED_SQUARE"
