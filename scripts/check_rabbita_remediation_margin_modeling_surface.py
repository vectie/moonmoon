#!/usr/bin/env python3
"""Execute Rabbita UI and check MoonRobo remediation-margin modeling evidence."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-modeling"
ENTRY_KIND = "MoonroboRemediationMarginModeling"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-modeling.json"
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass"
)
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/task"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
SUMMARY_TERMS = [
  "AllMarginsStillBlocking",
  *MARGIN_IDS,
  "moonmoon-safety-gate-only",
  "hardware-denied",
]


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

const rows = document.getElementById('remediation-margin-modeling').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-remediation-modeling-ui-"
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_remediation_modeling_harness.cjs"
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
  entry = entries.get(ENTRY_ID)
  if entry is None:
    raise AssertionError(f"missing MoonBook entry {ENTRY_ID}")
  if entry["kind"] != ENTRY_KIND:
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry)
  for term in SUMMARY_TERMS:
    if term not in entry["summary"]:
      raise AssertionError(entry)


def assert_workspace_payload() -> None:
  payload = json.loads(
    (
      ROOT
      / "output/moonbook/workspaces/first-trusted-square"
      / ENTRY_PATH
    ).read_text(encoding="utf-8")
  )["payload"]
  primary = payload["primary_modeling_pass"]
  if primary["modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(primary["modeling_pass_id"])
  if primary["source_receipt_id"] != RECEIPT_ID:
    raise AssertionError(primary["source_receipt_id"])
  if primary["source_task_id"] != TASK_ID:
    raise AssertionError(primary["source_task_id"])
  if primary["source_remediation_state"] != "OpenMarginsCarriedForward":
    raise AssertionError(primary["source_remediation_state"])
  if primary["state"] != "AllMarginsStillBlocking":
    raise AssertionError(primary["state"])
  if primary["active_margin_count"] != 3:
    raise AssertionError(primary["active_margin_count"])
  if primary["cleared_margin_count"] != 0:
    raise AssertionError(primary["cleared_margin_count"])
  if primary["still_blocking_margin_count"] != 3:
    raise AssertionError(primary["still_blocking_margin_count"])
  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])

  results = {result["margin_id"]: result for result in primary["margin_results"]}
  if set(results) != set(MARGIN_IDS):
    raise AssertionError(results)
  for margin_id in MARGIN_IDS:
    result = results[margin_id]
    if result["result_status"] != "MarginStillBlocking":
      raise AssertionError(result)
    if result["cleared"] is not False:
      raise AssertionError(result)
    if not result["modeling_command"]:
      raise AssertionError(result)
    if not result["modeling_evidence_path"]:
      raise AssertionError(result)
    if not result["current_state"]:
      raise AssertionError(result)


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "remediation-margin-modeling-row" not in row["className"]:
    raise AssertionError(row)
  if ENTRY_KIND not in row["title"]:
    raise AssertionError(row)
  if ENTRY_PATH not in row["path"]:
    raise AssertionError(row)
  if "moonbook://moonmoon/first-trusted-square/" not in row["path"]:
    raise AssertionError(row)
  for term in SUMMARY_TERMS:
    if term not in row["summary"]:
      raise AssertionError(row)


def main() -> int:
  html = HTML_PATH.read_text(encoding="utf-8")
  if "Remediation Margin Modeling" not in html:
    raise AssertionError("missing remediation margin modeling section")
  if "function renderRemediationMarginModeling()" not in html:
    raise AssertionError("missing remediation margin modeling renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita remediation margin modeling surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
