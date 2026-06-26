"""Shared helpers for Rabbita UI verification scripts."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
RABBITA_OUTPUT = ROOT / "output/ui/rabbita"
RABBITA_ASSETS = RABBITA_OUTPUT / "assets"


def extract_json_script(html: str, script_id: str) -> Any:
  pattern = (
    rf'<script id="{re.escape(script_id)}" type="application/json">\n'
    r"([\s\S]*?)\n</script>"
  )
  match = re.search(pattern, html)
  if not match:
    raise AssertionError(f"missing {script_id}")
  return json.loads(match.group(1))


def rabbita_app_script() -> str:
  """Return the browser app scripts in page load order for VM harnesses."""
  scripts = [
    RABBITA_ASSETS / "rabbita_evidence.js",
    RABBITA_ASSETS / "rabbita_app.js",
  ]
  missing = [path for path in scripts if not path.exists()]
  if missing:
    raise AssertionError(f"missing Rabbita assets: {missing}")
  return "\n".join(path.read_text(encoding="utf-8") for path in scripts)
