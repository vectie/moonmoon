#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/data/fixtures/first_trusted_square_dem.csv"
LOLA_GDR_CATALOG="$ROOT/data/sources/lro_lola/gdr_ds.cat"
LOLA_GDR_SELECTION_LABEL="$ROOT/data/sources/lro_lola/ldem_875s_20m_float.xml"
LOLA_FIRST_TRUSTED_SQUARE="$ROOT/data/sources/lro_lola/first_trusted_square_dem.csv"
LOLA_WEST_CONTOUR="$ROOT/data/sources/lro_lola/first_trusted_square_west_contour_dem.csv"
LOLA_NORTH_RIM="$ROOT/data/sources/lro_lola/first_trusted_square_north_rim_dem.csv"
LOLA_SOUTHWEST_BYPASS="$ROOT/data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv"
LOLA_SOUTH_STEPOUT="$ROOT/data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv"
LOLA_CORRIDOR_SCAN="$ROOT/data/sources/lro_lola/first_trusted_square_corridor_scan.csv"
LUNAR_EPHEMERIS_POWER_WINDOW="$ROOT/data/sources/lunar_ephemeris/first_trusted_square_power_window.json"

EXPECTED_FIRST_TRUSTED_SQUARE_SHA256="45981303392c9be40ce224143409cb675d1a62bb541420a782c4397cce8fbdf7"
EXPECTED_LOLA_GDR_CATALOG_SHA256="f7b1af88b345ca57f088cf484fc491f9c9cc614fd24575ccbe5b0cb83b2373d8"
EXPECTED_LOLA_GDR_CATALOG_BYTES="5672"
EXPECTED_LOLA_GDR_SELECTION_LABEL_SHA256="10d62a66364276d544168949a11a93580e748aaff78f8cf946837d98d077ff53"
EXPECTED_LOLA_GDR_SELECTION_LABEL_BYTES="11629"
EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_SHA256="7d296f65efc1df9544c043e5e59d6fcba9774d39c481814b5bb9a37288fec98c"
EXPECTED_LOLA_FIRST_TRUSTED_SQUARE_BYTES="636"
EXPECTED_LOLA_WEST_CONTOUR_SHA256="1beb22d539285fe1cf1c83cedb268368e9ed67bd47919c75525e46639e0aa4f6"
EXPECTED_LOLA_WEST_CONTOUR_BYTES="844"
EXPECTED_LOLA_NORTH_RIM_SHA256="40b0ad0e3d85dc6cb9e98a35973efe42d892370a1a3494e66e4af3e200035b28"
EXPECTED_LOLA_NORTH_RIM_BYTES="796"
EXPECTED_LOLA_SOUTHWEST_BYPASS_SHA256="c47b837a8ed5bb818c865782396d44dae01b15b03a2a6a83c372548092c1ace5"
EXPECTED_LOLA_SOUTHWEST_BYPASS_BYTES="908"
EXPECTED_LOLA_SOUTH_STEPOUT_SHA256="dde783fcf74ac0567bb2d6bb8eead6c2f83b620603319690aa51011486d7a19c"
EXPECTED_LOLA_SOUTH_STEPOUT_BYTES="860"
EXPECTED_LOLA_CORRIDOR_SCAN_SHA256="11430a5e4a83040027eaabd7bdcd2706fbbe9cf8c219de0b24787141256f6896"
EXPECTED_LOLA_CORRIDOR_SCAN_BYTES="4813"
EXPECTED_LUNAR_EPHEMERIS_POWER_WINDOW_SHA256="0163e018ed383615f595de564f474238aa6161b1df93d7a8fa0b456df6f453aa"
EXPECTED_LUNAR_EPHEMERIS_POWER_WINDOW_BYTES="810"

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

west_csv_actual="$(shasum -a 256 "$LOLA_WEST_CONTOUR" | awk '{print $1}')"
west_csv_bytes="$(wc -c < "$LOLA_WEST_CONTOUR" | tr -d ' ')"

if [[ "$west_csv_actual" != "$EXPECTED_LOLA_WEST_CONTOUR_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_WEST_CONTOUR" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_WEST_CONTOUR_SHA256" >&2
  printf 'actual   %s\n' "$west_csv_actual" >&2
  exit 1
fi

if [[ "$west_csv_bytes" != "$EXPECTED_LOLA_WEST_CONTOUR_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_WEST_CONTOUR" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_WEST_CONTOUR_BYTES" >&2
  printf 'actual   %s\n' "$west_csv_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$west_csv_actual" "$LOLA_WEST_CONTOUR"

north_csv_actual="$(shasum -a 256 "$LOLA_NORTH_RIM" | awk '{print $1}')"
north_csv_bytes="$(wc -c < "$LOLA_NORTH_RIM" | tr -d ' ')"

if [[ "$north_csv_actual" != "$EXPECTED_LOLA_NORTH_RIM_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_NORTH_RIM" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_NORTH_RIM_SHA256" >&2
  printf 'actual   %s\n' "$north_csv_actual" >&2
  exit 1
fi

if [[ "$north_csv_bytes" != "$EXPECTED_LOLA_NORTH_RIM_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_NORTH_RIM" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_NORTH_RIM_BYTES" >&2
  printf 'actual   %s\n' "$north_csv_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$north_csv_actual" "$LOLA_NORTH_RIM"

southwest_csv_actual="$(shasum -a 256 "$LOLA_SOUTHWEST_BYPASS" | awk '{print $1}')"
southwest_csv_bytes="$(wc -c < "$LOLA_SOUTHWEST_BYPASS" | tr -d ' ')"

if [[ "$southwest_csv_actual" != "$EXPECTED_LOLA_SOUTHWEST_BYPASS_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_SOUTHWEST_BYPASS" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_SOUTHWEST_BYPASS_SHA256" >&2
  printf 'actual   %s\n' "$southwest_csv_actual" >&2
  exit 1
fi

if [[ "$southwest_csv_bytes" != "$EXPECTED_LOLA_SOUTHWEST_BYPASS_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_SOUTHWEST_BYPASS" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_SOUTHWEST_BYPASS_BYTES" >&2
  printf 'actual   %s\n' "$southwest_csv_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$southwest_csv_actual" "$LOLA_SOUTHWEST_BYPASS"

south_csv_actual="$(shasum -a 256 "$LOLA_SOUTH_STEPOUT" | awk '{print $1}')"
south_csv_bytes="$(wc -c < "$LOLA_SOUTH_STEPOUT" | tr -d ' ')"

if [[ "$south_csv_actual" != "$EXPECTED_LOLA_SOUTH_STEPOUT_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_SOUTH_STEPOUT" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_SOUTH_STEPOUT_SHA256" >&2
  printf 'actual   %s\n' "$south_csv_actual" >&2
  exit 1
fi

if [[ "$south_csv_bytes" != "$EXPECTED_LOLA_SOUTH_STEPOUT_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_SOUTH_STEPOUT" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_SOUTH_STEPOUT_BYTES" >&2
  printf 'actual   %s\n' "$south_csv_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$south_csv_actual" "$LOLA_SOUTH_STEPOUT"

corridor_scan_actual="$(shasum -a 256 "$LOLA_CORRIDOR_SCAN" | awk '{print $1}')"
corridor_scan_bytes="$(wc -c < "$LOLA_CORRIDOR_SCAN" | tr -d ' ')"

if [[ "$corridor_scan_actual" != "$EXPECTED_LOLA_CORRIDOR_SCAN_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LOLA_CORRIDOR_SCAN" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_CORRIDOR_SCAN_SHA256" >&2
  printf 'actual   %s\n' "$corridor_scan_actual" >&2
  exit 1
fi

if [[ "$corridor_scan_bytes" != "$EXPECTED_LOLA_CORRIDOR_SCAN_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LOLA_CORRIDOR_SCAN" >&2
  printf 'expected %s\n' "$EXPECTED_LOLA_CORRIDOR_SCAN_BYTES" >&2
  printf 'actual   %s\n' "$corridor_scan_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$corridor_scan_actual" "$LOLA_CORRIDOR_SCAN"

power_window_actual="$(shasum -a 256 "$LUNAR_EPHEMERIS_POWER_WINDOW" | awk '{print $1}')"
power_window_bytes="$(wc -c < "$LUNAR_EPHEMERIS_POWER_WINDOW" | tr -d ' ')"

if [[ "$power_window_actual" != "$EXPECTED_LUNAR_EPHEMERIS_POWER_WINDOW_SHA256" ]]; then
  printf 'checksum mismatch for %s\n' "$LUNAR_EPHEMERIS_POWER_WINDOW" >&2
  printf 'expected %s\n' "$EXPECTED_LUNAR_EPHEMERIS_POWER_WINDOW_SHA256" >&2
  printf 'actual   %s\n' "$power_window_actual" >&2
  exit 1
fi

if [[ "$power_window_bytes" != "$EXPECTED_LUNAR_EPHEMERIS_POWER_WINDOW_BYTES" ]]; then
  printf 'byte count mismatch for %s\n' "$LUNAR_EPHEMERIS_POWER_WINDOW" >&2
  printf 'expected %s\n' "$EXPECTED_LUNAR_EPHEMERIS_POWER_WINDOW_BYTES" >&2
  printf 'actual   %s\n' "$power_window_bytes" >&2
  exit 1
fi

printf 'verified %s %s\n' "$power_window_actual" "$LUNAR_EPHEMERIS_POWER_WINDOW"
