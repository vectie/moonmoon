#!/usr/bin/env python3
"""Check MoonClaw receipt generated for remediation-margin task."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
RECEIPT_PATH = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_receipt.json"
)
MARKDOWN_PATH = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_receipt.md"
)
TASK_PATH = ROOT / "output/moonclaw/first_trusted_square_remediation_margin_task.json"
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/task"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_receipt(receipt: dict[str, Any], task: dict[str, Any], markdown: str) -> None:
  if receipt["receipt"]["receipt_id"] != RECEIPT_ID:
    raise AssertionError(receipt["receipt"]["receipt_id"])
  if receipt["source_task_id"] != TASK_ID:
    raise AssertionError(receipt["source_task_id"])
  if receipt["source_task_id"] != task["task_id"]:
    raise AssertionError("receipt does not consume generated task")
  if receipt["route_id"] != "northeast-stepout":
    raise AssertionError(receipt["route_id"])
  if receipt["remediation_state"] != "OpenMarginsCarriedForward":
    raise AssertionError(receipt["remediation_state"])
  if receipt["hardware_state"] != "HardwareDenied":
    raise AssertionError(receipt["hardware_state"])
  if receipt["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(receipt["hardware_authority"])
  if receipt["hardware_denied"] is not True:
    raise AssertionError("receipt does not preserve hardware denial")
  if receipt["active_margin_count"] != 3:
    raise AssertionError(receipt["active_margin_count"])
  if receipt["cleared_margin_count"] != 0:
    raise AssertionError(receipt["cleared_margin_count"])
  if receipt["still_blocking_margin_count"] != 3:
    raise AssertionError(receipt["still_blocking_margin_count"])

  task_artifacts = {artifact["artifact_id"]: artifact for artifact in task["artifacts"]}
  results = {result["margin_id"]: result for result in receipt["margin_results"]}
  if list(results) != MARGIN_IDS:
    raise AssertionError(results)
  if set(task_artifacts) != set(results):
    raise AssertionError(results)
  for margin_id, result in results.items():
    if result["status"] != "StillBlocking":
      raise AssertionError(result)
    if result["evidence_path"] != task_artifacts[margin_id]["path"]:
      raise AssertionError(result)
    if result["source_artifact_path"] != task_artifacts[margin_id]["path"]:
      raise AssertionError(result)
    if result["current_state"] != task_artifacts[margin_id]["current_state"]:
      raise AssertionError(result)
    if not result["next_action"]:
      raise AssertionError(result)

  checks = {check["validation_id"]: check for check in receipt["validation_checks"]}
  for check_id in [
    "source-task-present",
    "margin-accounting-complete",
    "result-paths-present",
    "hardware-denial-preserved",
    "still-blocking-margins-carried-forward",
  ]:
    if not checks.get(check_id, {}).get("passed"):
      raise AssertionError(checks)

  notes = "\n".join(receipt["receipt"]["validation_notes"])
  if "hardware-denial-preserved: pass" not in notes:
    raise AssertionError(notes)
  for term in [
    "MoonClaw Remediation Margin Receipts",
    "OpenMarginsCarriedForward",
    "still blocking margins: 3",
    "terrain-northeast-stepout: StillBlocking",
    "illumination-northeast-stepout: StillBlocking",
    "energy-window: StillBlocking",
    "moonmoon-safety-gate-only",
  ]:
    if term not in markdown:
      raise AssertionError(term)


def main() -> int:
  receipts = load_json(RECEIPT_PATH)
  task = load_json(TASK_PATH)[0]
  markdown = MARKDOWN_PATH.read_text(encoding="utf-8")
  if len(receipts) != 1:
    raise AssertionError(receipts)
  assert_receipt(receipts[0], task, markdown)
  print("checked MoonClaw remediation margin receipt")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
