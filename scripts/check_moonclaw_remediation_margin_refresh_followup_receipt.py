#!/usr/bin/env python3
"""Check MoonClaw remediation-margin refresh follow-up receipt evidence."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
)
TASK_PATH = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json"
)
PROJECTION_PATH = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
)
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = (
  "moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt"
)
ENTRY_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-refresh-followup-receipt.json"
)
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt"
)
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task"
)
PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
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
TARGETS = {
  "refresh-terrain-northeast-stepout": (
    "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"
  ),
  "refresh-illumination-northeast-stepout": (
    "output/mission/first_trusted_square_northeast_stepout_horizon.json"
  ),
  "refresh-energy-window": "output/mission/first_trusted_square_energy_remediation.json",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_receipt(
  receipt: dict[str, Any],
  task: dict[str, Any],
  projection: dict[str, Any],
) -> None:
  if receipt["receipt"]["receipt_id"] != RECEIPT_ID:
    raise AssertionError(receipt["receipt"]["receipt_id"])
  if receipt["receipt"]["proposal_id"] != PROJECTION_ID:
    raise AssertionError(receipt["receipt"]["proposal_id"])
  if receipt["receipt"]["status"] != "Accepted":
    raise AssertionError(receipt["receipt"]["status"])
  if receipt["source_task_id"] != TASK_ID:
    raise AssertionError(receipt["source_task_id"])
  if receipt["source_task_id"] != task["task_id"]:
    raise AssertionError("receipt source task diverges")
  if receipt["source_refresh_projection_id"] != projection["projection_id"]:
    raise AssertionError("receipt source projection diverges")
  if receipt["source_modeling_pass_id"] != projection["source_modeling_pass_id"]:
    raise AssertionError("receipt modeling pass diverges")
  if receipt["source_modeling_state"] != "AllRefreshesStillBlocking":
    raise AssertionError(receipt["source_modeling_state"])
  if receipt["source_modeling_state"] != projection["source_modeling_state"]:
    raise AssertionError("receipt modeling state diverges")
  if receipt["source_projection_status"] != "NoConsumeRefreshSimulationBlocked":
    raise AssertionError(receipt["source_projection_status"])
  if receipt["source_projection_status"] != projection["projection_status"]:
    raise AssertionError("receipt projection status diverges")
  if receipt["source_simulation_state"] != "SimulationBlocked":
    raise AssertionError(receipt["source_simulation_state"])
  if receipt["may_consume_simulation"] is not False:
    raise AssertionError(receipt["may_consume_simulation"])
  if receipt["may_consume_simulation"] != projection["may_consume_simulation"]:
    raise AssertionError("receipt may-consume diverges")
  if receipt["refresh_state"] != "FollowupRefreshesCarriedForward":
    raise AssertionError(receipt["refresh_state"])
  if receipt["blocking_refresh_ids"] != REFRESH_IDS:
    raise AssertionError(receipt["blocking_refresh_ids"])
  if receipt["blocking_refresh_ids"] != task["blocking_refresh_ids"]:
    raise AssertionError("receipt blocking refresh ids diverge from task")
  if receipt["blocking_margin_ids"] != MARGIN_IDS:
    raise AssertionError(receipt["blocking_margin_ids"])
  if receipt["blocking_margin_ids"] != task["blocking_margin_ids"]:
    raise AssertionError("receipt blocking margin ids diverge from task")
  if receipt["followup_action_count"] != 3:
    raise AssertionError(receipt["followup_action_count"])
  if receipt["refreshed_count"] != 0:
    raise AssertionError(receipt["refreshed_count"])
  if receipt["still_blocking_count"] != 3:
    raise AssertionError(receipt["still_blocking_count"])

  results = receipt["followup_results"]
  if len(results) != len(task["followup_actions"]):
    raise AssertionError(results)
  actions_by_refresh = {
    action["refresh_id"]: action for action in task["followup_actions"]
  }
  for index, refresh_id in enumerate(REFRESH_IDS, start=1):
    result = results[index - 1]
    action = actions_by_refresh[refresh_id]
    if result["rank"] != index:
      raise AssertionError(result)
    if result["refresh_id"] != refresh_id:
      raise AssertionError(result)
    if result["margin_id"] != MARGIN_IDS[index - 1]:
      raise AssertionError(result)
    if result["target_artifact_path"] != TARGETS[refresh_id]:
      raise AssertionError(result)
    if result["target_artifact_path"] != action["target_artifact_path"]:
      raise AssertionError("target diverges from action")
    if result["command"] != action["command"]:
      raise AssertionError("command diverges from action")
    if result["acceptance_check"] != action["acceptance_check"]:
      raise AssertionError("check diverges from action")
    if result["status"] != "FollowupRefreshStillBlocking":
      raise AssertionError(result)
    if result["evidence_path"] != result["target_artifact_path"]:
      raise AssertionError(result)

  if receipt["hardware_state"] != "HardwareDenied":
    raise AssertionError(receipt["hardware_state"])
  if receipt["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(receipt["hardware_authority"])
  if receipt["hardware_denied"] is not True:
    raise AssertionError(receipt["hardware_denied"])
  if receipt["hardware_state"] != task["hardware_state"]:
    raise AssertionError("hardware state diverges from task")
  if receipt["hardware_authority"] != task["hardware_authority"]:
    raise AssertionError("hardware authority diverges from task")

  notes = receipt["receipt"]["validation_notes"]
  for text in [
    "source-task-present: pass",
    "refresh-projection-source-present: pass",
    "followup-refresh-accounting-complete: pass",
    "hardware-denial-preserved: pass",
    "followup-refreshes-carried-forward: pass",
  ]:
    if not any(text in note for note in notes):
      raise AssertionError(f"missing validation note {text}")


def assert_workspace(receipt: dict[str, Any]) -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  entry_file = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  entry = entries.get(ENTRY_ID)
  if entry is None:
    raise AssertionError("MoonBook index has no follow-up receipt entry")
  if entry["kind"] != "MoonClawRemediationMarginRefreshFollowupReceipt":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "FollowupRefreshesCarriedForward",
    "3 still-blocking follow-up refreshes",
    *REFRESH_IDS,
    *MARGIN_IDS,
    "0 refreshed",
    TASK_ID,
    PROJECTION_ID,
    "simulation-blocked",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no follow-up receipt path")
  source_relpath = (
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
  )
  if source_relpath not in index["source_files"]:
    raise AssertionError("index source_files has no follow-up receipt source")
  if source_relpath not in readme:
    raise AssertionError("README has no follow-up receipt source")
  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper diverges from index entry")
  payload = entry_file["payload"]
  if payload["receipts"] != [receipt]:
    raise AssertionError("workspace receipt bundle diverges from source")
  if payload["primary_receipt"] != receipt:
    raise AssertionError("workspace primary receipt diverges from source")


def main() -> int:
  receipts = load_json(SOURCE_PATH)
  if len(receipts) != 1:
    raise AssertionError(receipts)
  tasks = load_json(TASK_PATH)
  if len(tasks) != 1:
    raise AssertionError(tasks)
  receipt = receipts[0]
  task = tasks[0]
  projection = load_json(PROJECTION_PATH)
  assert_receipt(receipt, task, projection)
  assert_workspace(receipt)
  print("checked MoonClaw remediation margin refresh follow-up receipt")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
