#!/usr/bin/env python3
"""Check MoonClaw remediation-margin refresh task packet."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TASK_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json"
)
TASK_MD = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.md"
)
PROJECTION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task"
PROJECTION_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
)
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


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_refresh_task(task: dict[str, Any], projection: dict[str, Any]) -> None:
  if task["task_id"] != TASK_ID:
    raise AssertionError(task["task_id"])
  if task["source_projection_id"] != projection["projection_id"]:
    raise AssertionError(task["source_projection_id"])
  if task["source_projection_path"] != PROJECTION_PATH:
    raise AssertionError(task["source_projection_path"])
  if task["source_modeling_pass_id"] != projection["source_modeling_pass_id"]:
    raise AssertionError(task["source_modeling_pass_id"])
  if task["source_projection_status"] != "NoConsumeSimulationBlocked":
    raise AssertionError(task["source_projection_status"])
  if task["source_projection_status"] != projection["projection_status"]:
    raise AssertionError("projection status diverges")
  if task["source_simulation_state"] != projection["simulation_state"]:
    raise AssertionError(task["source_simulation_state"])
  if task["may_consume_simulation"]:
    raise AssertionError(task)
  if task["may_consume_simulation"] != projection["may_consume_simulation"]:
    raise AssertionError("may-consume flag diverges")
  if task["blocking_margin_count"] != len(MARGIN_IDS):
    raise AssertionError(task["blocking_margin_count"])
  if task["ranked_margin_ids"] != MARGIN_IDS:
    raise AssertionError(task["ranked_margin_ids"])
  if task["ranked_margin_ids"] != projection["blocking_margin_ids"]:
    raise AssertionError("refresh ranking diverges from projection blockers")

  actions = task["refresh_actions"]
  if len(actions) != len(MARGIN_IDS):
    raise AssertionError(actions)
  for index, margin_id in enumerate(MARGIN_IDS, start=1):
    action = actions[index - 1]
    if action["rank"] != index:
      raise AssertionError(action)
    if action["margin_id"] != margin_id:
      raise AssertionError(action)
    if action["source_projection_path"] != PROJECTION_PATH:
      raise AssertionError(action)
    if action["target_artifact_path"] != TARGETS[margin_id]:
      raise AssertionError(action)
    if not action["command"]:
      raise AssertionError(action)
    if not action["acceptance_check"]:
      raise AssertionError(action)
    if not action["reason"]:
      raise AssertionError(action)

  commands = "\n".join(action["command"] for action in actions)
  checks = "\n".join(action["acceptance_check"] for action in actions)
  for term in [
    "generate_selected_route_terrain_remediation.py --check",
    "generate_selected_route_horizon.py --check",
    "check_energy_margin_remediation.py",
  ]:
    if term not in commands:
      raise AssertionError(commands)
  for term in [
    "check_selected_route_terrain_remediation.py",
    "check_selected_route_horizon_model.py",
    "check_energy_margin_remediation.py",
  ]:
    if term not in checks:
      raise AssertionError(checks)

  if task["hardware_state"] != "HardwareDenied":
    raise AssertionError(task["hardware_state"])
  if task["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(task["hardware_authority"])
  if task["hardware_denied"] is not True:
    raise AssertionError(task["hardware_denied"])
  if task["hardware_state"] != projection["hardware_state"]:
    raise AssertionError("hardware state diverges from projection")
  if task["hardware_authority"] != projection["hardware_authority"]:
    raise AssertionError("hardware authority diverges from projection")

  criteria = {criterion["criterion_id"] for criterion in task["acceptance_criteria"]}
  for criterion_id in [
    "projection-consumed",
    "ranked-refresh-actions",
    "hardware-denial-preserved",
  ]:
    if criterion_id not in criteria:
      raise AssertionError(criteria)


def assert_markdown(markdown: str) -> None:
  for term in [
    "MoonClaw Remediation Margin Refresh Tasks",
    "NoConsumeSimulationBlocked",
    "may consume simulation: false",
    "simulation-blocked",
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "hardware authority: moonmoon-safety-gate-only",
    "generate_selected_route_terrain_remediation.py --check",
    "generate_selected_route_horizon.py --check",
    "check_energy_margin_remediation.py",
  ]:
    if term not in markdown:
      raise AssertionError(term)


def main() -> int:
  tasks = load_json(TASK_JSON)
  projection = load_json(PROJECTION_JSON)
  markdown = TASK_MD.read_text(encoding="utf-8")
  if len(tasks) != 1:
    raise AssertionError(tasks)
  assert_refresh_task(tasks[0], projection)
  assert_markdown(markdown)
  print("checked MoonClaw remediation margin refresh task")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
