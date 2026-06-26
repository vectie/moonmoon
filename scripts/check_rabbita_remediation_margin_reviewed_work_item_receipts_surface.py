#!/usr/bin/env python3
"""Execute Rabbita UI and check reviewed MoonClaw work item receipt evidence."""

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
  "moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts"
)
ENTRY_KIND = "MoonClawRemediationMarginReviewedWorkItemReceipts"
ENTRY_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts.json"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
SUMMARY_TERMS = [
  "3 accepted reviewed work item receipts",
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
  "terrain=ReviewedWorkItemPendingFreshEvidence",
  "local-horizon=ReviewedWorkItemPendingFreshEvidence",
  "energy=ReviewedWorkItemPendingFreshEvidence",
  "pending fresh evidence",
  "accepted review provenance",
  "automatic refresh loop allowed false",
  "simulation-blocked",
  "may consume false",
  "moonmoon-safety-gate-only",
  "hardware-denied",
]
EXPECTED_MARGINS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
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

const rows = document.getElementById('remediation-margin-reviewed-work-item-receipts').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-reviewed-work-item-receipts-ui-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_reviewed_work_item_receipts_harness.cjs"
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
  if payload["source_plan"]["plan_id"] != PLAN_ID:
    raise AssertionError(payload["source_plan"]["plan_id"])
  if payload["review"]["status"] != "Accepted":
    raise AssertionError(payload["review"])
  if payload["review"]["decision"] != "Accept":
    raise AssertionError(payload["review"])
  if payload["review"]["transition"]["transition_id"] != REVIEW_TRANSITION_ID:
    raise AssertionError(payload["review"])
  if len(payload["source_work_items"]) != 3:
    raise AssertionError(payload["source_work_items"])
  receipts = payload["receipts"]
  if len(receipts) != 3:
    raise AssertionError(receipts)
  by_margin = {
    receipt["work_item_result"]["margin_id"]: receipt for receipt in receipts
  }
  if set(by_margin) != EXPECTED_MARGINS:
    raise AssertionError(by_margin)
  for margin_id, receipt in by_margin.items():
    result = receipt["work_item_result"]
    if receipt["receipt"]["status"] != "Accepted":
      raise AssertionError(receipt)
    if receipt["source_plan_id"] != PLAN_ID:
      raise AssertionError(receipt)
    if receipt["source_review_transition_id"] != REVIEW_TRANSITION_ID:
      raise AssertionError(receipt)
    if receipt["source_review_decision"] != "Accept":
      raise AssertionError(receipt)
    if receipt["result_state"] != "ReviewedWorkItemsCarriedForward":
      raise AssertionError(receipt)
    if result["status"] != "ReviewedWorkItemPendingFreshEvidence":
      raise AssertionError(receipt)
    if result["margin_id"] != margin_id:
      raise AssertionError(receipt)
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
    if not all(check["passed"] for check in receipt["validation_checks"]):
      raise AssertionError(receipt)


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "remediation-margin-reviewed-work-item-receipts-row" not in row["className"]:
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
  if "Remediation Margin Reviewed Work Item Receipts" not in html:
    raise AssertionError("missing reviewed work item receipts section")
  if "function renderRemediationMarginReviewedWorkItemReceipts()" not in html:
    raise AssertionError("missing reviewed work item receipts renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita remediation margin reviewed work item receipts surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
