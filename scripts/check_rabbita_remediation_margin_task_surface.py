#!/usr/bin/env python3
"""Execute Rabbita UI and check MoonClaw remediation-margin task evidence."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from rabbita_ui_harness import extract_json_script, rabbita_app_script, run_rabbita_vm

ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-task"
ENTRY_KIND = "MoonClawTask"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-task.json"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/task"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
SUMMARY_TERMS = [
  "3 active remediation margins",
  *MARGIN_IDS,
  "3 blockers",
  "moonmoon-safety-gate-only",
  "hardware-denied",
]


SNAPSHOT_JS = r"""
const rows = document.getElementById('mission-evidence-queue').children.map(row => ({
  entry_id: row.attributes['data-entry-id'],
  family: row.attributes['data-evidence-family'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
const summary = document.getElementById('mission-evidence-summary').children.map(row => ({
  value: row.children[0].textContent,
  label: row.children[1].textContent
}));
return { rows, summary };
"""


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
  if primary["active_margin_count"] != 3:
    raise AssertionError(primary["active_margin_count"])
  if primary["active_margin_ids"] != MARGIN_IDS:
    raise AssertionError(primary["active_margin_ids"])
  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])

  artifacts = {artifact["artifact_id"]: artifact for artifact in primary["artifacts"]}
  if set(artifacts) != set(MARGIN_IDS):
    raise AssertionError(artifacts)
  for margin_id in MARGIN_IDS:
    if artifacts[margin_id]["ready"] is not False:
      raise AssertionError(artifacts[margin_id])


def assert_surface(rendered: dict[str, Any]) -> None:
  if len(rendered["rows"]) != 24:
    raise AssertionError(rendered)
  row = next((row for row in rendered["rows"] if row["entry_id"] == ENTRY_ID), None)
  if row is None:
    raise AssertionError(rendered)
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if "evidence-row" not in row["className"]:
    raise AssertionError(row)
  if row["family"] != "remediation":
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
  if "Mission Evidence Queue" not in html:
    raise AssertionError("missing mission evidence queue section")
  app_script = rabbita_app_script()
  if "function renderMissionEvidenceQueue()" not in app_script:
    raise AssertionError("missing mission evidence queue renderer")

  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
  assert_embedded_book(book)
  assert_workspace_payload()
  rendered = run_rabbita_vm(
    view,
    book,
    SNAPSHOT_JS,
    prefix="moonmoon-rabbita-remediation-task-ui-",
  )
  assert_surface(rendered)
  print("checked Rabbita remediation margin task surface")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
