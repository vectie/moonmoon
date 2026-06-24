#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$ROOT/data/sources/lro_lola"
TARGET="$TARGET_DIR/gdr_ds.cat"
URL="https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/catalog/gdr_ds.cat"
SELECTION_LABEL="$TARGET_DIR/ldem_875s_20m_float.xml"
SELECTION_LABEL_URL="https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.xml"

mkdir -p "$TARGET_DIR"
curl -L "$URL" -o "$TARGET"
curl -L "$SELECTION_LABEL_URL" -o "$SELECTION_LABEL"

bash "$ROOT/scripts/verify_moonmoon_sources.sh"
