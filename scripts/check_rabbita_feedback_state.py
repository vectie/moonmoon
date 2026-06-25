#!/usr/bin/env python3
"""Execute Rabbita's generated review UI against imported mixed state."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_mixed.json"


def extract_json_script(html: str, script_id: str) -> Any:
  pattern = (
    rf'<script id="{re.escape(script_id)}" type="application/json">\n'
    r"([\s\S]*?)\n</script>"
  )
  match = re.search(pattern, html)
  if not match:
    raise AssertionError(f"missing {script_id}")
  return json.loads(match.group(1))


def extract_app_script(html: str) -> str:
  matches = re.findall(r"<script>\n([\s\S]*?)\n</script>", html)
  if not matches:
    raise AssertionError("missing Rabbita app script")
  return matches[-1]


def run_rabbita_script(view: Any, book: Any, script: str) -> dict[str, Any]:
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
}

const elements = new Map();
const document = {
  createElement(tag) { return new Element(tag); },
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, new Element('div', id));
    return elements.get(id);
  }
};

document.getElementById('moonmoon-view-model').textContent = JSON.stringify(input.view);
document.getElementById('moonmoon-moonbook').textContent = JSON.stringify(input.book);

vm.runInNewContext(input.script, { document, navigator: {}, Blob, URL, console });

const rows = document.getElementById('clearance-review').children.map(row => ({
  decision: row.attributes['data-review-decision'],
  status: row.attributes['data-review-status'],
  title: row.children[0].textContent,
  note: row.children[1].textContent,
  buttons: row.children[2].children.map(button => ({
    label: button.textContent,
    pressed: button.attributes['aria-pressed']
  }))
}));
const exported = JSON.parse(document.getElementById('transition-export').value);
console.log(JSON.stringify({ rows, exported }, null, 2));
"""
  with tempfile.TemporaryDirectory(prefix="moonmoon-rabbita-ui-") as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_feedback_harness.cjs"
    input_path = tmp_dir / "input.json"
    harness_path.write_text(harness, encoding="utf-8")
    input_path.write_text(
      json.dumps({"view": view, "book": book, "script": script}),
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


def assert_feedback_state(rendered: dict[str, Any]) -> None:
  decisions = {row["title"].split(" - ", 1)[0]: row for row in rendered["rows"]}
  expected = {
    "clear-terrain-grade-northeast-stepout": ("Accept", "Accepted"),
    "clear-illumination-confidence-northeast-stepout": ("Reject", "Rejected"),
    "clear-energy-margin": ("RequestEvidence", "NeedsEvidence"),
    "clear-moonbook-review-northeast-stepout": ("Accept", "Accepted"),
  }
  for item_id, (decision, status) in expected.items():
    row = decisions[item_id]
    if row["decision"] != decision or row["status"] != status:
      raise AssertionError(row)
    pressed = [
      button["label"] for button in row["buttons"] if button["pressed"] == "true"
    ]
    label = {
      "Accept": "Accept",
      "Reject": "Reject",
      "RequestEvidence": "Need evidence",
    }[decision]
    if pressed != [label]:
      raise AssertionError(row["buttons"])

  exported = {
    transition["item_id"]: transition["decision"]
    for transition in rendered["exported"]["transitions"]
  }
  if exported != {item_id: value[0] for item_id, value in expected.items()}:
    raise AssertionError(exported)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-rabbita-feedback-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    html = (tmp_root / "output/ui/rabbita/first_trusted_square.html").read_text(
      encoding="utf-8",
    )
  rendered = run_rabbita_script(
    extract_json_script(html, "moonmoon-view-model"),
    extract_json_script(html, "moonmoon-moonbook"),
    extract_app_script(html),
  )
  assert_feedback_state(rendered)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
