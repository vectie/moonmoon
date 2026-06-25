#!/usr/bin/env python3
"""Execute Rabbita UI and check MoonClaw remediation-margin refresh task evidence."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-refresh-task"
ENTRY_KIND = "MoonClawRemediationMarginRefreshTask"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-refresh-task.json"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task"
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
TARGETS = {
  "terrain-northeast-stepout": (
    "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"
  ),
  "illumination-northeast-stepout": (
    "output/mission/first_trusted_square_northeast_stepout_horizon.json"
  ),
  "energy-window": "output/mission/first_trusted_square_energy_remediation.json",
}
SUMMARY_TERMS = [
  "NoConsumeSimulationBlocked",
  "3 ranked refreshes",
  *MARGIN_IDS,
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
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, new Element('div', id));
    return elements.get(id);
  }
};

document.getElementById('moonmoon-view-model').textContent = JSON.stringify(input.view);
document.getElementById('moonmoon-moonbook').textContent = JSON.stringify(input.book);

vm.runInNewContext(input.script, { document, navigator: {}, Blob, URL, console });

const rows = document.getElementById('remediation-margin-refresh-task').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
console.log(JSON.stringify({ rows }, null, 2));
"""
  with tempfile.TemporaryDirectory(prefix="moonmoon-rabbita-remediation-refresh-ui-") as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_remediation_refresh_harness.cjs"
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
  primary = payload["primary_task"]
  if primary["task_id"] != TASK_ID:
    raise AssertionError(primary["task_id"])
  if primary["source_projection_id"] != PROJECTION_ID:
    raise AssertionError(primary["source_projection_id"])
  if primary["source_projection_status"] != "NoConsumeSimulationBlocked":
    raise AssertionError(primary["source_projection_status"])
  if primary["source_simulation_state"] != "SimulationBlocked":
    raise AssertionError(primary["source_simulation_state"])
  if primary["may_consume_simulation"] is not False:
    raise AssertionError(primary)
  if primary["blocking_margin_count"] != 3:
    raise AssertionError(primary["blocking_margin_count"])
  if primary["ranked_margin_ids"] != MARGIN_IDS:
    raise AssertionError(primary["ranked_margin_ids"])

  actions = primary["refresh_actions"]
  if len(actions) != 3:
    raise AssertionError(actions)
  for index, margin_id in enumerate(MARGIN_IDS, start=1):
    action = actions[index - 1]
    if action["rank"] != index:
      raise AssertionError(action)
    if action["margin_id"] != margin_id:
      raise AssertionError(action)
    if action["target_artifact_path"] != TARGETS[margin_id]:
      raise AssertionError(action)
    if not action["command"] or not action["acceptance_check"]:
      raise AssertionError(action)

  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 1:
    raise AssertionError(rendered)
  row = rendered["rows"][0]
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "remediation-margin-refresh-task-row" not in row["className"]:
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
  if "Remediation Margin Refresh Task" not in html:
    raise AssertionError("missing remediation margin refresh task section")
  if "function renderRemediationMarginRefreshTask()" not in html:
    raise AssertionError("missing remediation margin refresh task renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_script(view, book, extract_app_script(html))
  assert_surface(rendered)
  print("checked Rabbita remediation margin refresh task surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
