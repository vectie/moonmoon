#!/usr/bin/env python3
"""Execute Rabbita UI and check fresh-evidence action receipt evidence."""

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
  "moonclaw/first-trusted-square/remediation-margin-fresh-evidence-action-receipts"
)
ENTRY_KIND = "MoonClawRemediationMarginFreshEvidenceActionReceipts"
ENTRY_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-fresh-evidence-action-receipts.json"
)
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
SUMMARY_TERMS = [
  "3 accepted fresh-evidence action receipts",
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
  "terrain=operator-escalation",
  "local-horizon=bounded-regeneration",
  "energy=manual-freeze-verification",
  "source receipt provenance",
  "reviewed work items remain pending fresh evidence",
  "automatic refresh loop allowed false",
  "simulation-blocked",
  "may consume false",
  "moonmoon-safety-gate-only",
  "hardware-denied",
]
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": "operator-escalation",
  "illumination-northeast-stepout": "bounded-regeneration",
  "energy-window": "manual-freeze-verification",
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

const rows = document.getElementById('remediation-margin-fresh-evidence-action-receipts').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-fresh-evidence-action-receipts-ui-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_fresh_evidence_action_receipts_harness.cjs"
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
  source_task = payload["source_task"]
  if source_task["task_id"] != TASK_ID:
    raise AssertionError(source_task["task_id"])
  if payload["source_plan"]["plan_id"] != PLAN_ID:
    raise AssertionError(payload["source_plan"]["plan_id"])
  if payload["review"]["status"] != "Accepted":
    raise AssertionError(payload["review"])
  if payload["review"]["decision"] != "Accept":
    raise AssertionError(payload["review"])
  if payload["review"]["transition"]["transition_id"] != REVIEW_TRANSITION_ID:
    raise AssertionError(payload["review"])
  if len(payload["source_receipts"]) != 3:
    raise AssertionError(payload["source_receipts"])
  if len(payload["receipts"]) != 3:
    raise AssertionError(payload["receipts"])
  source_receipt_ids = {
    receipt["receipt"]["receipt_id"] for receipt in payload["source_receipts"]
  }
  receipts = {
    receipt["action_result"]["margin_id"]: receipt for receipt in payload["receipts"]
  }
  if set(receipts) != set(EXPECTED_ACTIONS):
    raise AssertionError(receipts)
  for margin_id, execution_mode in EXPECTED_ACTIONS.items():
    receipt = receipts[margin_id]
    result = receipt["action_result"]
    if receipt["source_task_id"] != TASK_ID:
      raise AssertionError(receipt)
    if receipt["source_plan_id"] != PLAN_ID:
      raise AssertionError(receipt)
    if receipt["source_review_transition_id"] != REVIEW_TRANSITION_ID:
      raise AssertionError(receipt)
    if receipt["source_review_decision"] != "Accept":
      raise AssertionError(receipt)
    if receipt["source_receipt_id"] not in source_receipt_ids:
      raise AssertionError(receipt)
    if result["execution_mode"] != execution_mode:
      raise AssertionError(result)
    if result["result_status"] != "ReviewedWorkItemPendingFreshEvidence":
      raise AssertionError(result)
    if not result["command"]:
      raise AssertionError(result)
    if not result["acceptance_check"]:
      raise AssertionError(result)
    if receipt["may_consume_simulation"] is not False:
      raise AssertionError(receipt)
    if receipt["automatic_refresh_loop_allowed"] is not False:
      raise AssertionError(receipt)
    if receipt["simulation_state"] != "SimulationBlocked":
      raise AssertionError(receipt)
    if receipt["hardware_state"] != "HardwareDenied":
      raise AssertionError(receipt)
    if receipt["hardware_authority"] != "moonmoon-safety-gate-only":
      raise AssertionError(receipt)
    if receipt["hardware_authority_change"] is not False:
      raise AssertionError(receipt)
    if receipt["hardware_denied"] is not True:
      raise AssertionError(receipt)
    if not all(check["passed"] for check in receipt["validation_checks"]):
      raise AssertionError(receipt)


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "remediation-margin-fresh-evidence-action-receipts-row" not in row["className"]:
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
  if "Remediation Margin Fresh Evidence Action Receipts" not in html:
    raise AssertionError("missing action receipts section")
  if "function renderRemediationMarginFreshEvidenceActionReceipts()" not in html:
    raise AssertionError("missing action receipts renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita remediation margin fresh evidence action receipt surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
