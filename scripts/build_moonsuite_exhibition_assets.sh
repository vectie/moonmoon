#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
PDFTOPPM_BIN="${PDFTOPPM_BIN:-pdftoppm}"

cd "$ROOT_DIR"

"$PYTHON_BIN" scripts/make_moonsuite_exhibition_pdf.py

mkdir -p output/pdf
"$PDFTOPPM_BIN" \
  -f 6 \
  -l 6 \
  -png \
  -r 300 \
  output/pdf/moonsuite_exhibition_profile.pdf \
  output/pdf/moonsuite_display_generated_20x30cm_300dpi

echo "Generated:"
echo "  output/pdf/moonsuite_exhibition_profile.pdf"
echo "  output/pdf/moonsuite_display_generated_20x30cm_300dpi-6.png"
