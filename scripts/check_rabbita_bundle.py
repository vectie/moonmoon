#!/usr/bin/env python3
"""Check that the generated Rabbita UI bundle is complete and source-synced."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ASSETS = ROOT / "src/ui/rabbita_moon/assets"
BUNDLE = ROOT / "output/ui/rabbita"
HTML_PATH = BUNDLE / "first_trusted_square.html"
ASSET_DIR = BUNDLE / "assets"

REQUIRED_ASSETS = {
  "southpole_10deg_print.jpg",
  "lunar_global_texture.jpg",
  "lunar_global_texture.source.json",
  "rabbita_moon.css",
  "rabbita_evidence.js",
  "rabbita_app.js",
  "moon_globe.js",
}


def sha256(path: Path) -> str:
  return hashlib.sha256(path.read_bytes()).hexdigest()


def html_asset_refs(html: str) -> set[str]:
  refs = set()
  for attr in ("href", "src", "data-texture"):
    pattern = rf'{attr}="assets/([^"]+)"'
    refs.update(re.findall(pattern, html))
  return refs


def main() -> None:
  if not HTML_PATH.exists():
    raise AssertionError(f"missing Rabbita HTML: {HTML_PATH}")

  html = HTML_PATH.read_text(encoding="utf-8")
  refs = html_asset_refs(html)
  expected = REQUIRED_ASSETS | refs
  missing_refs = refs - REQUIRED_ASSETS
  if missing_refs:
    raise AssertionError(f"HTML references unmanaged Rabbita assets: {sorted(missing_refs)}")

  script_order = [
    'assets/rabbita_evidence.js',
    'assets/rabbita_app.js',
    'assets/moon_globe.js',
  ]
  script_positions = [html.find(f'src="{script}"') for script in script_order]
  if any(pos < 0 for pos in script_positions) or script_positions != sorted(script_positions):
    raise AssertionError("Rabbita scripts must load evidence, app, then globe")

  for asset in sorted(expected):
    source = SOURCE_ASSETS / asset
    bundled = ASSET_DIR / asset
    if not source.exists():
      raise AssertionError(f"missing source asset: {source}")
    if not bundled.exists():
      raise AssertionError(f"missing bundled asset: {bundled}")
    if sha256(source) != sha256(bundled):
      raise AssertionError(f"bundled asset is not source-synced: {asset}")

  texture_metadata = json.loads((ASSET_DIR / "lunar_global_texture.source.json").read_text())
  if texture_metadata.get("trust_boundary") != "visual-context-only":
    raise AssertionError("lunar texture metadata must stay visual-context-only")

  print(f"checked Rabbita bundle: {HTML_PATH}")


if __name__ == "__main__":
  main()
