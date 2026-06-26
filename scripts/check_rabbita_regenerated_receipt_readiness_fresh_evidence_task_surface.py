#!/usr/bin/env python3
"""Execute Rabbita UI and check regenerated readiness fresh-evidence task."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task"
)
ENTRY_KIND = "MoonClawRegeneratedReceiptReadinessFreshEvidenceTask"
ENTRY_PATH = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task.json"
)
TASK_ID = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task"
)
GATE_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness"
)
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
REFRESH_IDS = [
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
]
SUMMARY_TERMS = [
  "3 pending regenerated receipts",
  "0 ready receipts",
  "RegeneratedReceiptsPendingFreshEvidence",
  *MARGIN_IDS,
  *REFRESH_IDS,
  "terrain=operator-escalation",
  "local-horizon=bounded-regeneration",
  "energy=manual-freeze-verification",
  "source action receipt provenance",
  "source readiness gate",
  "no automatic refresh loop",
  "no simulation consumption",
  "simulation-blocked",
  "may consume false",
  "moonmoon-safety-gate-only",
  "hardware-denied",
]
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": (
    "terrain",
    "operator-escalation",
    "check_selected_route_terrain_remediation.py",
  ),
  "illumination-northeast-stepout": (
    "local-horizon",
    "bounded-regeneration",
    "check_selected_route_horizon_model.py",
  ),
  "energy-window": (
    "energy",
    "manual-freeze-verification",
    "check_energy_margin_remediation.py",
  ),
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
  createElementNS(_namespace, tag) { return new Element(tag); },
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, new Element('div', id));
    return elements.get(id);
  }
};

document.getElementById('moonmoon-view-model').textContent = JSON.stringify(input.view);
document.getElementById('moonmoon-moonbook').textContent = JSON.stringify(input.book);

vm.runInNewContext(input.script, { document, navigator: {}, Blob, URL, console });

const rows = document.getElementById('regenerated-receipt-readiness-fresh-evidence-task').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-regenerated-readiness-fresh-task-ui-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_regenerated_readiness_fresh_task_harness.cjs"
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
  task = payload["primary_task"]
  if task != payload["tasks"][0]:
    raise AssertionError(payload)
  if task["task_id"] != TASK_ID:
    raise AssertionError(task["task_id"])
  if task["source_readiness_gate_id"] != GATE_ID:
    raise AssertionError(task["source_readiness_gate_id"])
  if task["source_readiness_state"] != "RegeneratedReceiptsPendingFreshEvidence":
    raise AssertionError(task["source_readiness_state"])
  if payload["source_readiness"]["readiness_gate_id"] != GATE_ID:
    raise AssertionError(payload["source_readiness"])
  if len(payload["source_receipts"]) != 3:
    raise AssertionError(payload["source_receipts"])
  if len(payload["source_action_receipts"]) != 3:
    raise AssertionError(payload["source_action_receipts"])
  if task["pending_receipt_count"] != 3:
    raise AssertionError(task)
  if task["ready_receipt_count"] != 0:
    raise AssertionError(task)
  if task["pending_margin_ids"] != MARGIN_IDS:
    raise AssertionError(task["pending_margin_ids"])
  if task["pending_refresh_ids"] != REFRESH_IDS:
    raise AssertionError(task["pending_refresh_ids"])
  if task["may_consume_simulation"] is not False:
    raise AssertionError(task)
  if task["simulation_state"] != "SimulationBlocked":
    raise AssertionError(task)
  if task["automatic_refresh_loop_allowed"] is not False:
    raise AssertionError(task)
  if task["hardware_state"] != "HardwareDenied":
    raise AssertionError(task)
  if task["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(task)
  if task["hardware_authority_change"] is not False:
    raise AssertionError(task)
  if task["hardware_denied"] is not True:
    raise AssertionError(task)
  actions = {action["margin_id"]: action for action in task["fresh_evidence_actions"]}
  if set(actions) != set(EXPECTED_ACTIONS):
    raise AssertionError(actions)
  for margin_id, (domain, mode, check) in EXPECTED_ACTIONS.items():
    action = actions[margin_id]
    if action["blocker_domain"] != domain:
      raise AssertionError(action)
    if action["execution_mode"] != mode:
      raise AssertionError(action)
    if action["source_receipt_id"] not in task["source_receipt_ids"]:
      raise AssertionError(action)
    if action["source_action_receipt_id"] not in task["source_action_receipt_ids"]:
      raise AssertionError(action)
    if check not in action["acceptance_check"]:
      raise AssertionError(action)


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "regenerated-receipt-readiness-fresh-evidence-task-row" not in row["className"]:
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
  if "Regenerated Readiness Fresh Evidence Task" not in html:
    raise AssertionError("missing regenerated readiness fresh-evidence task section")
  if "function renderRegeneratedReceiptReadinessFreshEvidenceTask()" not in html:
    raise AssertionError("missing regenerated readiness fresh-evidence task renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita regenerated readiness fresh-evidence task surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
