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
HTML_PATH = RABBITA_OUTPUT / "first_trusted_square.html"

MISSION_EVIDENCE_SNAPSHOT_JS = r"""
const rows = document.getElementById('mission-evidence-queue').children.map(row => ({
  family: row.attributes['data-evidence-family'],
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
const filters = document.getElementById('mission-evidence-filters').children.map(button => ({
  label: button.textContent,
  pressed: button.attributes['aria-pressed']
}));
const summary = document.getElementById('mission-evidence-summary').children.map(row => ({
  value: row.children[0].textContent,
  label: row.children[1].textContent
}));
return { rows, filters, summary };
"""


def extract_json_script(html: str, script_id: str) -> Any:
  pattern = (
    rf'<script id="{re.escape(script_id)}" type="application/json">\n'
    r"([\s\S]*?)\n</script>"
  )
  match = re.search(pattern, html)
  if not match:
    raise AssertionError(f"missing {script_id}")
  return json.loads(match.group(1))


def read_rabbita_page(path: Path = HTML_PATH) -> tuple[str, Any, Any]:
  html = path.read_text(encoding="utf-8")
  return (
    html,
    extract_json_script(html, "moonmoon-view-model"),
    extract_json_script(html, "moonmoon-moonbook"),
  )


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


def is_mission_evidence_entry(entry: dict[str, Any]) -> bool:
  entry_id = entry["entry_id"]
  return "/remediation-margin-" in entry_id or "/regenerated-receipt-readiness-" in entry_id


def mission_evidence_family(entry: dict[str, Any]) -> str:
  entry_id = entry["entry_id"]
  if (
    "projection" in entry_id
    or "cycle-closeout" in entry_id
    or "action-receipt-closeout" in entry_id
    or entry_id.endswith("/remediation-margin-regenerated-receipt-readiness")
  ):
    return "blocker"
  if "modeling" in entry_id:
    return "simulation"
  if "reviewed-action-plan" in entry_id or "reviewed-work-items" in entry_id:
    return "review"
  if "fresh-evidence-task" in entry_id or entry_id.endswith("-task"):
    return "remediation"
  if (
    "receipt" in entry_id
    or "receipts" in entry_id
    or "action-receipts" in entry_id
  ):
    return "receipt"
  return "remediation"


def expected_mission_evidence_entries(book: dict[str, Any]) -> list[dict[str, Any]]:
  return [entry for entry in book["entries"] if is_mission_evidence_entry(entry)]


def render_mission_evidence_queue(
  view: Any,
  book: Any,
  *,
  prefix: str = "moonmoon-rabbita-mission-evidence-",
) -> dict[str, Any]:
  return run_rabbita_vm(view, book, MISSION_EVIDENCE_SNAPSHOT_JS, prefix=prefix)


def assert_mission_evidence_queue(rendered: dict[str, Any], book: dict[str, Any]) -> None:
  expected = expected_mission_evidence_entries(book)
  rows = rendered["rows"]
  if len(expected) != 24:
    raise AssertionError(f"expected 24 mission evidence entries, got {len(expected)}")
  if len(rows) != len(expected):
    raise AssertionError(f"rendered {len(rows)} mission evidence rows for {len(expected)} entries")

  expected_counts = {"blocker": 0, "receipt": 0, "remediation": 0, "review": 0, "simulation": 0}
  for row, entry in zip(rows, expected):
    family = mission_evidence_family(entry)
    expected_counts[family] += 1
    if row["entry_id"] != entry["entry_id"]:
      raise AssertionError({"row": row["entry_id"], "entry": entry["entry_id"]})
    if row["family"] != family:
      raise AssertionError({"row": row, "expected_family": family})
    if "evidence-row" not in row["className"]:
      raise AssertionError(row)
    if row["summary"] != entry["summary"]:
      raise AssertionError({"row": row["summary"], "entry": entry["summary"]})
    expected_path = f"moonbook://moonmoon/first-trusted-square/{entry['path']}"
    if row["path"] != expected_path:
      raise AssertionError({"row": row["path"], "expected": expected_path})

  if expected_counts != {
    "blocker": 6,
    "receipt": 7,
    "remediation": 6,
    "review": 2,
    "simulation": 3,
  }:
    raise AssertionError(expected_counts)

  filters = {item["label"]: item["pressed"] for item in rendered["filters"]}
  if filters != {
    "All 24": "true",
    "Blockers 6": "false",
    "Work 6": "false",
    "Receipts 7": "false",
    "Simulation 3": "false",
    "Review 2": "false",
  }:
    raise AssertionError(filters)


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
