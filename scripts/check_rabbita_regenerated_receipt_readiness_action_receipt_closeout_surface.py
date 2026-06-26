#!/usr/bin/env python3
"""Execute Rabbita UI and check regenerated readiness closeout surface."""

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
  "moonrobo/first-trusted-square/"
  "regenerated-receipt-readiness-action-receipt-closeout"
)
ENTRY_KIND = "MoonroboRegeneratedReceiptReadinessActionReceiptCloseout"
ENTRY_PATH = (
  "moonrobo/first-trusted-square/"
  "regenerated-receipt-readiness-action-receipt-closeout.json"
)
SOURCE_PATH = (
  ROOT
  / "output/moonrobo"
  / "first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json"
)
ACTION_RECEIPTS_PATH = (
  ROOT
  / "output/moonclaw"
  / "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json"
)
READINESS_PATH = (
  ROOT
  / "output/moonrobo"
  / "first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
CLOSEOUT_ID = (
  "moonrobo/first-trusted-square/"
  "regenerated-receipt-readiness-v1/action-receipt-closeout"
)
GATE_ID = (
  "moonrobo/first-trusted-square/"
  "remediation-margin-v1/regenerated-receipt-readiness"
)
TASK_ID = (
  "moonclaw/first-trusted-square/"
  "regenerated-receipt-readiness-v1/fresh-evidence-task"
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
  "RegeneratedReceiptsStillPendingFreshEvidence",
  "RegeneratedReceiptsPendingFreshEvidence",
  "3 pending regenerated receipts",
  "0 ready receipts",
  "3 fresh-evidence action receipts",
  *MARGIN_IDS,
  *REFRESH_IDS,
  *EXECUTION_MODES,
  "source readiness gate",
  "source action receipt provenance",
  "no automatic refresh loop",
  "no simulation consumption",
  "simulation-blocked",
  "may consume false",
  "moonmoon-safety-gate-only",
  "hardware-denied",
]
VALIDATION_IDS = [
  "action-receipts-present",
  "source-readiness-gate-preserved",
  "source-action-provenance-present",
  "execution-modes-preserved",
  "fresh-evidence-still-pending",
  "no-automatic-refresh-loop",
  "simulation-consumption-blocked",
  "hardware-denial-preserved",
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

const rows = document.getElementById('regenerated-receipt-readiness-action-receipt-closeout').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-regenerated-readiness-closeout-ui-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_regenerated_readiness_closeout.cjs"
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


def assert_closeout(closeout: dict[str, Any], action_receipts: list[Any]) -> None:
  if closeout["closeout_id"] != CLOSEOUT_ID:
    raise AssertionError(closeout["closeout_id"])
  if closeout["source_readiness_gate_id"] != GATE_ID:
    raise AssertionError(closeout["source_readiness_gate_id"])
  if closeout["source_readiness_state"] != "RegeneratedReceiptsPendingFreshEvidence":
    raise AssertionError(closeout)
  if closeout["source_task_id"] != TASK_ID:
    raise AssertionError(closeout["source_task_id"])
  if closeout["closeout_state"] != "RegeneratedReceiptsStillPendingFreshEvidence":
    raise AssertionError(closeout)
  if closeout["source_action_receipt_count"] != len(action_receipts):
    raise AssertionError(closeout)
  if closeout["source_action_receipt_count"] != 3:
    raise AssertionError(closeout)
  if closeout["source_receipt_count"] != 3:
    raise AssertionError(closeout)
  if closeout["ready_receipt_count"] != 0:
    raise AssertionError(closeout)
  if closeout["pending_receipt_count"] != 3:
    raise AssertionError(closeout)
  if closeout["may_consume_simulation"] is not False:
    raise AssertionError(closeout)
  if closeout["simulation_state"] != "SimulationBlocked":
    raise AssertionError(closeout)
  if closeout["automatic_refresh_loop_allowed"] is not False:
    raise AssertionError(closeout)
  if closeout["hardware_state"] != "HardwareDenied":
    raise AssertionError(closeout)
  if closeout["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(closeout)
  if closeout["hardware_denied"] is not True:
    raise AssertionError(closeout)

  checks = closeout["validation_checks"]
  check_ids = [check["validation_id"] for check in checks]
  if check_ids != VALIDATION_IDS:
    raise AssertionError(check_ids)
  if not all(check["passed"] for check in checks):
    raise AssertionError(checks)

  text = json.dumps(closeout, sort_keys=True)
  for term in [*MARGIN_IDS, *REFRESH_IDS, *EXECUTION_MODES]:
    if term not in text:
      raise AssertionError(term)


def assert_workspace_payload() -> None:
  payload = json.loads(
    (
      ROOT
      / "output/moonbook/workspaces/first-trusted-square"
      / ENTRY_PATH
    ).read_text(encoding="utf-8")
  )["payload"]
  closeout = json.loads(SOURCE_PATH.read_text(encoding="utf-8"))
  action_receipts = json.loads(ACTION_RECEIPTS_PATH.read_text(encoding="utf-8"))
  readiness = json.loads(READINESS_PATH.read_text(encoding="utf-8"))
  if payload["closeout"] != closeout:
    raise AssertionError(payload["closeout"])
  if payload["source_action_receipts"] != action_receipts:
    raise AssertionError(payload["source_action_receipts"])
  if payload["source_readiness"] != readiness:
    raise AssertionError(payload["source_readiness"])
  assert_closeout(payload["closeout"], payload["source_action_receipts"])


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "regenerated-receipt-readiness-action-receipt-closeout-row" not in row["className"]:
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
  if "Regenerated Readiness Action Receipt Closeout" not in html:
    raise AssertionError("missing regenerated readiness closeout section")
  if "function renderRegeneratedReceiptReadinessActionReceiptCloseout()" not in html:
    raise AssertionError("missing regenerated readiness closeout renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita regenerated readiness action receipt closeout surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
