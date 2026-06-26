"""Shared helpers for Rabbita UI verification scripts."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
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


def run_rabbita_vm(
  view: Any,
  book: Any,
  snapshot_js: str,
  *,
  prefix: str = "moonmoon-rabbita-ui-",
) -> dict[str, Any]:
  """Execute Rabbita assets in a minimal DOM and return a JSON snapshot."""
  harness = r"""
const fs = require('fs');
const vm = require('vm');
const input = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

class Element {
  constructor(tagName, id = '') {
    this.tagName = tagName;
    this.id = id;
    this.children = [];
    this.attributes = {};
    this.eventListeners = {};
    this.className = '';
    this.textContent = '';
    this.value = '';
    this.style = { setProperty: (key, value) => { this.style[key] = String(value); } };
  }
  setAttribute(key, value) { this.attributes[key] = String(value); }
  append(child) { this.children.push(child); }
  replaceChildren(...children) { this.children = children; }
  addEventListener(type, handler) { this.eventListeners[type] = handler; }
  click() { if (this.eventListeners.click) this.eventListeners.click(); }
}

const elements = new Map();
const document = {
  createElement(tag) { return new Element(tag); },
  createElementNS(_namespace, tag) { return new Element(tag); },
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, new Element('div', id));
    return elements.get(id);
  }
};

document.getElementById('moonmoon-view-model').textContent = JSON.stringify(input.view);
document.getElementById('moonmoon-moonbook').textContent = JSON.stringify(input.book);

const downloads = [];
const context = {
  document,
  window: {},
  navigator: {},
  Blob,
  URL: {
    createObjectURL(blob) { downloads.push(blob); return 'blob:rabbita-export'; },
    revokeObjectURL() {}
  },
  console
};

vm.runInNewContext(input.script, context);
const snapshot = vm.runInNewContext(`(() => { ${input.snapshot_js} })()`, {
  document,
  downloads,
  console
});
console.log(JSON.stringify(snapshot, null, 2));
"""
  with tempfile.TemporaryDirectory(prefix=prefix) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_harness.cjs"
    input_path = tmp_dir / "input.json"
    harness_path.write_text(harness, encoding="utf-8")
    input_path.write_text(
      json.dumps(
        {
          "view": view,
          "book": book,
          "script": rabbita_app_script(),
          "snapshot_js": snapshot_js,
        },
      ),
      encoding="utf-8",
    )
    result = subprocess.run(
      ["node", str(harness_path), str(input_path)],
      check=True,
      cwd=ROOT,
      capture_output=True,
      text=True,
    )
  return json.loads(result.stdout)
