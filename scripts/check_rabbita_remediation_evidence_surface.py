#!/usr/bin/env python3
"""Execute Rabbita UI and check selected-route remediation evidence rows."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
REMEDIATION_ENTRIES = {
  "terrain-remediation/first-trusted-square/northeast-stepout": {
    "kind": "TerrainRemediationEvidence",
    "path": "mission/first-trusted-square/northeast-stepout-terrain-remediation.json",
    "summary_terms": ["grade margin", "roughness margin"],
  },
  "local-horizon/first-trusted-square/northeast-stepout": {
    "kind": "LocalHorizonEvidence",
    "path": "mission/first-trusted-square/northeast-stepout-horizon.json",
    "summary_terms": ["terrain-shadow margin"],
  },
  "energy-remediation/first-trusted-square/northeast-stepout": {
    "kind": "EnergyRemediationEvidence",
    "path": "mission/first-trusted-square/energy-remediation.json",
    "summary_terms": ["bounded margin", "margin gap"],
  },
}


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

const rows = document.getElementById('selected-route-remediation').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(prefix="moonmoon-rabbita-remediation-ui-") as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_remediation_harness.cjs"
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


def assert_embedded_book(book: dict[str, Any]) -> None:
  entries = {entry["entry_id"]: entry for entry in book["entries"]}
  for entry_id, expected in REMEDIATION_ENTRIES.items():
    entry = entries.get(entry_id)
    if entry is None:
      raise AssertionError(f"missing MoonBook entry {entry_id}")
    if entry["kind"] != expected["kind"]:
      raise AssertionError(entry)
    if entry["path"] != expected["path"]:
      raise AssertionError(entry)
    for term in expected["summary_terms"]:
      if term not in entry["summary"]:
        raise AssertionError(entry)


def assert_remediation_surface(rendered: dict[str, Any]) -> None:
  rows = {row["entry_id"]: row for row in rendered["rows"]}
  if set(rows) != set(REMEDIATION_ENTRIES):
    raise AssertionError(rows)
  for entry_id, expected in REMEDIATION_ENTRIES.items():
    row = rows[entry_id]
    if expected["kind"] not in row["title"]:
      raise AssertionError(row)
    if expected["path"] not in row["path"]:
      raise AssertionError(row)
    if "moonbook://moonmoon/first-trusted-square/" not in row["path"]:
      raise AssertionError(row)
    for term in expected["summary_terms"]:
      if term not in row["summary"]:
        raise AssertionError(row)


def main() -> int:
  html = HTML_PATH.read_text(encoding="utf-8")
  if "Selected Route Remediation Evidence" not in html:
    raise AssertionError("missing remediation evidence section")
  if "function renderRemediationEvidence()" not in html:
    raise AssertionError("missing remediation renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_remediation_surface(rendered)
  print("checked Rabbita remediation evidence surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
