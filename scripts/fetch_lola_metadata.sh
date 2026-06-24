#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$ROOT/data/sources/lro_lola"
TARGET="$TARGET_DIR/gdr_ds.cat"
URL="https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat"

mkdir -p "$TARGET_DIR"
curl -L "$URL" -o "$TARGET"

bash "$ROOT/scripts/verify_moonmoon_sources.sh"
