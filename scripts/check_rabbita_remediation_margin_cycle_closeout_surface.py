#!/usr/bin/env python3
"""Execute Rabbita UI and check MoonRobo cycle closeout policy evidence."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy"
ENTRY_KIND = "MoonroboRemediationMarginCycleCloseoutPolicy"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json"
POLICY_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy"
)
REFRESH_PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
)
FOLLOWUP_PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection"
)
REFRESH_IDS = [
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
]
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
SUMMARY_TERMS = [
  "NoConsumeCycleClosedForPolicy",
  "2 refresh cycles",
  "3 terrain/horizon/energy blockers",
  *REFRESH_IDS,
  *MARGIN_IDS,
  "terrain=EscalateToOperatorDecision",
  "local-horizon=RetryWithNewEvidence",
  "energy=FreezeUntilNewSourceEvidence",
  "simulation-blocked",
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

const rows = document.getElementById('remediation-margin-cycle-closeout').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-remediation-cycle-closeout-ui-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_cycle_closeout_harness.cjs"
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
  if payload["policy_id"] != POLICY_ID:
    raise AssertionError(payload["policy_id"])
  if payload["source_refresh_projection_id"] != REFRESH_PROJECTION_ID:
    raise AssertionError(payload["source_refresh_projection_id"])
  if payload["source_refresh_projection_status"] != "NoConsumeRefreshSimulationBlocked":
    raise AssertionError(payload["source_refresh_projection_status"])
  if payload["source_followup_projection_id"] != FOLLOWUP_PROJECTION_ID:
    raise AssertionError(payload["source_followup_projection_id"])
  if (
    payload["source_followup_projection_status"]
    != "NoConsumeFollowupRefreshSimulationBlocked"
  ):
    raise AssertionError(payload["source_followup_projection_status"])
  if payload["closeout_status"] != "NoConsumeCycleClosedForPolicy":
    raise AssertionError(payload["closeout_status"])
  if payload["may_consume_simulation"] is not False:
    raise AssertionError(payload)
  if payload["simulation_state"] != "SimulationBlocked":
    raise AssertionError(payload["simulation_state"])
  if payload["refresh_cycle_count"] != 2:
    raise AssertionError(payload["refresh_cycle_count"])
  if payload["blocker_count"] != 3:
    raise AssertionError(payload["blocker_count"])
  if set(payload["blocking_refresh_ids"]) != set(REFRESH_IDS):
    raise AssertionError(payload["blocking_refresh_ids"])
  if set(payload["blocking_margin_ids"]) != set(MARGIN_IDS):
    raise AssertionError(payload["blocking_margin_ids"])
  dispositions = {
    item["margin_id"]: item for item in payload["dispositions"]
  }
  expected = {
    "terrain-northeast-stepout": ("terrain", "EscalateToOperatorDecision"),
    "illumination-northeast-stepout": (
      "local-horizon",
      "RetryWithNewEvidence",
    ),
    "energy-window": ("energy", "FreezeUntilNewSourceEvidence"),
  }
  if set(dispositions) != set(expected):
    raise AssertionError(dispositions)
  for margin_id, (domain, disposition) in expected.items():
    item = dispositions[margin_id]
    if item["blocker_domain"] != domain:
      raise AssertionError(item)
    if item["disposition"] != disposition:
      raise AssertionError(item)
    if item["attempt_count"] != 2:
      raise AssertionError(item)
    if not item["required_evidence"]:
      raise AssertionError(item)
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  if payload["hardware_denied"] is not True:
    raise AssertionError(payload["hardware_denied"])


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "remediation-margin-cycle-closeout-row" not in row["className"]:
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
  if "Remediation Margin Cycle Closeout" not in html:
    raise AssertionError("missing remediation margin cycle closeout section")
  if "function renderRemediationMarginCycleCloseout()" not in html:
    raise AssertionError("missing remediation margin cycle closeout renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita remediation margin cycle closeout surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
