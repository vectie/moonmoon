#!/usr/bin/env python3
"""Check the bounded MoonRobo remediation-margin modeling pass."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MODELING_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_modeling.json"
)
MODELING_MD = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_modeling.md"
)
RECEIPT_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_receipt.json"
)
WORKSPACE_ENTRY = (
  ROOT
  / "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/remediation-margin-modeling.json"
)
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass"
)
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-modeling"
ENTRY_KIND = "MoonroboRemediationMarginModeling"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-modeling.json"
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/task"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
COMMAND_TERMS = [
  "check_selected_route_terrain_remediation.py",
  "check_selected_route_horizon_model.py",
  "check_energy_margin_remediation.py",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_modeling_pass() -> None:
  modeling = load_json(MODELING_JSON)[0]
  receipt = load_json(RECEIPT_JSON)[0]
  workspace_entry = load_json(WORKSPACE_ENTRY)
  markdown = MODELING_MD.read_text(encoding="utf-8")

  if modeling["modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(modeling["modeling_pass_id"])
  if modeling["source_receipt_id"] != receipt["receipt"]["receipt_id"]:
    raise AssertionError("modeling pass does not consume generated receipt")
  if modeling["source_receipt_id"] != RECEIPT_ID:
    raise AssertionError(modeling["source_receipt_id"])
  if modeling["source_task_id"] != TASK_ID:
    raise AssertionError(modeling["source_task_id"])
  if modeling["source_task_id"] != receipt["source_task_id"]:
    raise AssertionError("modeling pass source task diverges from receipt")
  if modeling["source_remediation_state"] != receipt["remediation_state"]:
    raise AssertionError(modeling["source_remediation_state"])
  if modeling["state"] != "AllMarginsStillBlocking":
    raise AssertionError(modeling["state"])
  if modeling["route_id"] != receipt["route_id"]:
    raise AssertionError(modeling["route_id"])
  if modeling["hardware_state"] != "HardwareDenied" or not modeling["hardware_denied"]:
    raise AssertionError(modeling)
  if modeling["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(modeling["hardware_authority"])
  if modeling["hardware_state"] != receipt["hardware_state"]:
    raise AssertionError("modeling hardware state diverges from receipt")
  if modeling["hardware_authority"] != receipt["hardware_authority"]:
    raise AssertionError("modeling hardware authority diverges from receipt")

  receipt_results = {
    result["margin_id"]: result
    for result in receipt["margin_results"]
  }
  results = {
    result["margin_id"]: result
    for result in modeling["margin_results"]
  }
  if list(results) != MARGIN_IDS:
    raise AssertionError(results)
  if set(results) != set(receipt_results):
    raise AssertionError(results)
  if modeling["active_margin_count"] != len(MARGIN_IDS):
    raise AssertionError(modeling["active_margin_count"])
  if modeling["cleared_margin_count"] != 0:
    raise AssertionError(modeling["cleared_margin_count"])
  if modeling["still_blocking_margin_count"] != len(MARGIN_IDS):
    raise AssertionError(modeling["still_blocking_margin_count"])

  for margin_id, result in results.items():
    receipt_result = receipt_results[margin_id]
    if result["source_artifact_path"] != receipt_result["source_artifact_path"]:
      raise AssertionError(result)
    if result["modeling_evidence_path"] != receipt_result["evidence_path"]:
      raise AssertionError(result)
    if result["receipt_status"] != receipt_result["status"]:
      raise AssertionError(result)
    if result["current_state"] != receipt_result["current_state"]:
      raise AssertionError(result)
    if result["result_status"] != "MarginStillBlocking" or result["cleared"]:
      raise AssertionError(result)
    if not result["modeling_command"] or not result["result_rationale"]:
      raise AssertionError(result)
    if not result["next_action"]:
      raise AssertionError(result)

  commands = "\n".join(modeling["commands_evaluated"])
  for term in COMMAND_TERMS:
    if term not in commands:
      raise AssertionError(commands)

  for term in [
    "MoonRobo Remediation Margin Modeling Passes",
    "AllMarginsStillBlocking",
    *MARGIN_IDS,
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if term not in markdown:
      raise AssertionError(term)

  entry = workspace_entry["entry"]
  if entry["entry_id"] != ENTRY_ID:
    raise AssertionError(entry)
  if entry["kind"] != ENTRY_KIND:
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry)
  for term in [
    "AllMarginsStillBlocking",
    *MARGIN_IDS,
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if term not in entry["summary"]:
      raise AssertionError(entry["summary"])
  payload = workspace_entry["payload"]
  if payload["primary_modeling_pass"] != modeling:
    raise AssertionError("workspace primary modeling pass diverges")
  if payload["modeling_passes"] != [modeling]:
    raise AssertionError("workspace modeling pass bundle diverges")


def main() -> int:
  assert_modeling_pass()
  print("checked MoonRobo remediation margin modeling pass")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
