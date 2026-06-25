#!/usr/bin/env python3
"""Check MoonClaw remediation-margin task packet."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TASK_PATH = ROOT / "output/moonclaw/first_trusted_square_remediation_margin_task.json"
MARKDOWN_PATH = ROOT / "output/moonclaw/first_trusted_square_remediation_margin_task.md"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/task"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_task(task: dict[str, Any], markdown: str) -> None:
  if task["task_id"] != TASK_ID:
    raise AssertionError(task["task_id"])
  if task["proposal_id"] != "moonclaw/first-trusted-square/remediation-margin-v1":
    raise AssertionError(task["proposal_id"])
  if task["site_id"] != "first-trusted-square":
    raise AssertionError(task["site_id"])
  if task["route_id"] != "northeast-stepout":
    raise AssertionError(task["route_id"])
  if task["priority"] != "Critical":
    raise AssertionError(task["priority"])
  if task["state"] != "Accepted":
    raise AssertionError(task["state"])
  if task["active_margin_count"] != 3:
    raise AssertionError(task["active_margin_count"])
  if task["active_margin_ids"] != MARGIN_IDS:
    raise AssertionError(task["active_margin_ids"])
  if task["hardware_state"] != "HardwareDenied":
    raise AssertionError(task["hardware_state"])
  if task["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(task["hardware_authority"])
  if not task["hardware_denied"]:
    raise AssertionError(task["hardware_denied"])

  artifacts = {artifact["artifact_id"]: artifact for artifact in task["artifacts"]}
  if set(artifacts) != set(MARGIN_IDS):
    raise AssertionError(artifacts)
  for margin_id in MARGIN_IDS:
    artifact = artifacts[margin_id]
    if artifact["ready"]:
      raise AssertionError(artifact)
    if not artifact["blocking_reason"]:
      raise AssertionError(artifact)
    if not artifact["validation_gate"]:
      raise AssertionError(artifact)

  if "grade margin" not in artifacts["terrain-northeast-stepout"]["current_state"]:
    raise AssertionError(artifacts["terrain-northeast-stepout"])
  if "terrain-shadow margin" not in artifacts["illumination-northeast-stepout"]["current_state"]:
    raise AssertionError(artifacts["illumination-northeast-stepout"])
  if "margin gap" not in artifacts["energy-window"]["current_state"]:
    raise AssertionError(artifacts["energy-window"])

  commands = "\n".join(task["commands"])
  for command in [
    "generate_selected_route_terrain_remediation.py --check",
    "generate_selected_route_horizon.py --check",
    "check_energy_margin_remediation.py",
    "check_moonrobo_simulation_blocker_reduction.py",
  ]:
    if command not in commands:
      raise AssertionError(commands)

  criteria = {criterion["criterion_id"] for criterion in task["acceptance_criteria"]}
  for criterion_id in [
    "all-active-margins-preserved",
    "ranked-remediation-work",
    "hardware-denial-preserved",
  ]:
    if criterion_id not in criteria:
      raise AssertionError(criteria)

  for term in [
    "MoonClaw Remediation Margin Tasks",
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "hardware authority: moonmoon-safety-gate-only",
    "ready: false",
  ]:
    if term not in markdown:
      raise AssertionError(term)


def main() -> int:
  tasks = load_json(TASK_PATH)
  markdown = MARKDOWN_PATH.read_text(encoding="utf-8")
  if len(tasks) != 1:
    raise AssertionError(tasks)
  assert_task(tasks[0], markdown)
  print("checked MoonClaw remediation margin task")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
