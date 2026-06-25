#!/usr/bin/env python3
"""Check MoonClaw remediation-margin refresh follow-up task evidence."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json"
)
PROJECTION_PATH = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
)
RABBITA_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-refresh-followup-task"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-refresh-followup-task.json"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task"
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
PROJECTION_SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
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


def assert_task(task: dict[str, Any], projection: dict[str, Any]) -> None:
  if task["task_id"] != TASK_ID:
    raise AssertionError(task["task_id"])
  if task["source_refresh_projection_id"] != PROJECTION_ID:
    raise AssertionError(task["source_refresh_projection_id"])
  if task["source_refresh_projection_path"] != PROJECTION_SOURCE_PATH:
    raise AssertionError(task["source_refresh_projection_path"])
  if task["source_refresh_projection_id"] != projection["projection_id"]:
    raise AssertionError("task source does not match refresh projection")
  if task["source_modeling_pass_id"] != projection["source_modeling_pass_id"]:
    raise AssertionError("modeling pass id diverges")
  if task["source_modeling_state"] != "AllRefreshesStillBlocking":
    raise AssertionError(task["source_modeling_state"])
  if task["source_modeling_state"] != projection["source_modeling_state"]:
    raise AssertionError("modeling state diverges")
  if task["source_projection_status"] != "NoConsumeRefreshSimulationBlocked":
    raise AssertionError(task["source_projection_status"])
  if task["source_projection_status"] != projection["projection_status"]:
    raise AssertionError("projection status diverges")
  if task["source_simulation_state"] != "SimulationBlocked":
    raise AssertionError(task["source_simulation_state"])
  if task["may_consume_simulation"] is not False:
    raise AssertionError(task)
  if task["may_consume_simulation"] != projection["may_consume_simulation"]:
    raise AssertionError("may-consume flag diverges")
  if task["blocking_refresh_count"] != 3:
    raise AssertionError(task["blocking_refresh_count"])
  if task["blocking_refresh_ids"] != REFRESH_IDS:
    raise AssertionError(task["blocking_refresh_ids"])
  if task["blocking_refresh_ids"] != projection["blocking_refresh_ids"]:
    raise AssertionError("blocking refresh ids diverge")
  if task["blocking_margin_ids"] != MARGIN_IDS:
    raise AssertionError(task["blocking_margin_ids"])
  if task["blocking_margin_ids"] != projection["blocking_margin_ids"]:
    raise AssertionError("blocking margin ids diverge")

  actions = task["followup_actions"]
  if len(actions) != len(REFRESH_IDS):
    raise AssertionError(actions)
  for index, refresh_id in enumerate(REFRESH_IDS, start=1):
    action = actions[index - 1]
    if action["rank"] != index:
      raise AssertionError(action)
    if action["refresh_id"] != refresh_id:
      raise AssertionError(action)
    if action["margin_id"] != MARGIN_IDS[index - 1]:
      raise AssertionError(action)
    if action["source_refresh_projection_path"] != PROJECTION_SOURCE_PATH:
      raise AssertionError(action)
    if action["target_artifact_path"] != TARGETS[refresh_id]:
      raise AssertionError(action)
    if not action["command"] or not action["acceptance_check"]:
      raise AssertionError(action)

  if task["hardware_state"] != "HardwareDenied":
    raise AssertionError(task["hardware_state"])
  if task["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(task["hardware_authority"])
  if task["hardware_denied"] is not True:
    raise AssertionError(task["hardware_denied"])
  if task["hardware_state"] != projection["hardware_state"]:
    raise AssertionError("hardware state diverges")
  if task["hardware_authority"] != projection["hardware_authority"]:
    raise AssertionError("hardware authority diverges")
  if "must not authorize MoonRobo simulation consumption" not in task["safety_gate"]:
    raise AssertionError(task["safety_gate"])


def assert_visibility() -> None:
  html = RABBITA_PATH.read_text(encoding="utf-8")
  for text in [
    "Remediation Margin Refresh Projection",
    "remediation-margin-refresh-projection",
    "moonrobo/first-trusted-square/remediation-margin-refresh-projection",
    "NoConsumeRefreshSimulationBlocked",
  ]:
    if text not in html:
      raise AssertionError(f"Rabbita does not expose {text}")


def assert_workspace(task: dict[str, Any]) -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  entry_file = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  entry = entries.get(ENTRY_ID)
  if entry is None:
    raise AssertionError("MoonBook index has no follow-up task entry")
  if entry["kind"] != "MoonClawRemediationMarginRefreshFollowupTask":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "NoConsumeRefreshSimulationBlocked",
    "AllRefreshesStillBlocking",
    "3 blocking refreshes",
    *REFRESH_IDS,
    *MARGIN_IDS,
    "simulation-blocked",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no follow-up task path")
  source_relpath = (
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json"
  )
  if source_relpath not in index["source_files"]:
    raise AssertionError("index source_files has no follow-up source")
  if PROJECTION_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files has no refresh projection")
  if source_relpath not in readme:
    raise AssertionError("README has no follow-up source")
  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper diverges from index entry")
  payload = entry_file["payload"]
  if payload["tasks"] != [task]:
    raise AssertionError("workspace task bundle diverges from source")
  if payload["primary_task"] != task:
    raise AssertionError("workspace primary task diverges from source")


def main() -> int:
  tasks = load_json(SOURCE_PATH)
  if len(tasks) != 1:
    raise AssertionError(tasks)
  task = tasks[0]
  projection = load_json(PROJECTION_PATH)
  assert_task(task, projection)
  assert_visibility()
  assert_workspace(task)
  print("checked MoonClaw remediation margin refresh follow-up task")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
