#!/usr/bin/env python3
"""Execute Rabbita UI and check regenerated receipt readiness evidence."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness"
ENTRY_KIND = "MoonroboRemediationMarginRegeneratedReceiptReadiness"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness.json"
GATE_ID = "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness"
SOURCE_BUNDLE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
SOURCE_WORKSPACE_ENTRY_PATH = (
  "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/"
  "remediation-margin-regenerated-reviewed-work-item-receipts.json"
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
EXECUTION_MODES = [
  "operator-escalation",
  "bounded-regeneration",
  "manual-freeze-verification",
]
SUMMARY_TERMS = [
  "RegeneratedReceiptsPendingFreshEvidence",
  "3 pending regenerated receipts",
  "0 ready receipts",
  *MARGIN_IDS,
  *REFRESH_IDS,
  *EXECUTION_MODES,
  "source action receipt provenance",
  "no automatic refresh loop",
  "no simulation consumption",
  "simulation-blocked",
  "may consume false",
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
  createElementNS(_namespace, tag) { return new Element(tag); },
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, new Element('div', id));
    return elements.get(id);
  }
};

document.getElementById('moonmoon-view-model').textContent = JSON.stringify(input.view);
document.getElementById('moonmoon-moonbook').textContent = JSON.stringify(input.book);

vm.runInNewContext(input.script, { document, navigator: {}, Blob, URL, console });

const rows = document.getElementById('remediation-margin-regenerated-receipt-readiness').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-regenerated-receipt-readiness-ui-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_regenerated_receipt_readiness_harness.cjs"
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
  if payload["readiness_gate_id"] != GATE_ID:
    raise AssertionError(payload["readiness_gate_id"])
  if payload["source_receipt_bundle_path"] != SOURCE_BUNDLE_PATH:
    raise AssertionError(payload["source_receipt_bundle_path"])
  if payload["source_workspace_entry_path"] != SOURCE_WORKSPACE_ENTRY_PATH:
    raise AssertionError(payload["source_workspace_entry_path"])
  if payload["source_receipt_count"] != 3:
    raise AssertionError(payload["source_receipt_count"])
  if payload["pending_receipt_count"] != 3:
    raise AssertionError(payload["pending_receipt_count"])
  if payload["ready_receipt_count"] != 0:
    raise AssertionError(payload["ready_receipt_count"])
  if payload["readiness_state"] != "RegeneratedReceiptsPendingFreshEvidence":
    raise AssertionError(payload["readiness_state"])
  if set(payload["pending_margin_ids"]) != set(MARGIN_IDS):
    raise AssertionError(payload["pending_margin_ids"])
  if set(payload["pending_refresh_ids"]) != set(REFRESH_IDS):
    raise AssertionError(payload["pending_refresh_ids"])
  if payload["execution_modes"] != EXECUTION_MODES:
    raise AssertionError(payload["execution_modes"])
  if len(payload["source_receipt_ids"]) != 3:
    raise AssertionError(payload["source_receipt_ids"])
  if len(payload["source_action_receipt_ids"]) != 3:
    raise AssertionError(payload["source_action_receipt_ids"])
  if payload["may_consume_simulation"] is not False:
    raise AssertionError(payload)
  if payload["simulation_state"] != "SimulationBlocked":
    raise AssertionError(payload["simulation_state"])
  if payload["automatic_refresh_loop_allowed"] is not False:
    raise AssertionError(payload)
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  if payload["hardware_denied"] is not True:
    raise AssertionError(payload["hardware_denied"])
  validation_ids = {check["validation_id"] for check in payload["validation_checks"]}
  expected_validation_ids = {
    "regenerated-receipts-present",
    "all-receipts-pending-fresh-evidence",
    "source-action-provenance-present",
    "execution-modes-preserved",
    "no-automatic-refresh-loop",
    "simulation-consumption-blocked",
    "hardware-denial-preserved",
  }
  if validation_ids != expected_validation_ids:
    raise AssertionError(validation_ids)
  if not all(check["passed"] for check in payload["validation_checks"]):
    raise AssertionError(payload["validation_checks"])


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "remediation-margin-regenerated-receipt-readiness-row" not in row["className"]:
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
  if "Remediation Margin Regenerated Receipt Readiness" not in html:
    raise AssertionError("missing regenerated receipt readiness section")
  if "function renderRemediationMarginRegeneratedReceiptReadiness()" not in html:
    raise AssertionError("missing regenerated receipt readiness renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita regenerated receipt readiness surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
