#!/usr/bin/env python3
"""Check MoonClaw remediation-margin closeout action task output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CLOSEOUT_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
)
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
TASK_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.md"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
POLICY_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy"
)
POLICY_PATH = "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": {
    "rank": 1,
    "refresh_id": "refresh-terrain-northeast-stepout",
    "blocker_domain": "terrain",
    "disposition": "EscalateToOperatorDecision",
    "target": "operator/rabbita-remediation-margin-cycle-closeout#terrain-escalation",
    "command": "manual: review DEM",
    "check": "python3 scripts/check_selected_route_terrain_remediation.py",
  },
  "illumination-northeast-stepout": {
    "rank": 2,
    "refresh_id": "refresh-illumination-northeast-stepout",
    "blocker_domain": "local-horizon",
    "disposition": "RetryWithNewEvidence",
    "target": "output/mission/first_trusted_square_northeast_stepout_horizon.json",
    "command": "python3 scripts/generate_selected_route_horizon.py --check",
    "check": "python3 scripts/check_selected_route_horizon_model.py",
  },
  "energy-window": {
    "rank": 3,
    "refresh_id": "refresh-energy-window",
    "blocker_domain": "energy",
    "disposition": "FreezeUntilNewSourceEvidence",
    "target": "operator/rabbita-remediation-margin-cycle-closeout#energy-freeze",
    "command": "manual: keep energy-window frozen",
    "check": "python3 scripts/check_energy_margin_remediation.py",
  },
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_task_against_policy(
  policy: dict[str, Any],
  tasks: list[dict[str, Any]],
) -> dict[str, Any]:
  require(len(tasks) == 1, "expected one closeout action task")
  task = tasks[0]
  require(task["task_id"] == TASK_ID, "unexpected task id")
  require(task["state"] == "NeedsReview", "task should require operator review")
  require(task["priority"] == "Critical", "task priority changed")
  require(task["source_policy_id"] == POLICY_ID, "unexpected policy id")
  require(task["source_policy_id"] == policy["policy_id"], "policy id diverges")
  require(task["source_policy_path"] == POLICY_PATH, "unexpected policy path")
  require(
    task["source_closeout_status"] == "NoConsumeCycleClosedForPolicy",
    "unexpected closeout status",
  )
  require(
    task["source_closeout_status"] == policy["closeout_status"],
    "closeout status diverges",
  )
  require(
    task["source_refresh_projection_id"] == policy["source_refresh_projection_id"],
    "refresh projection source diverges",
  )
  require(
    task["source_refresh_projection_status"]
    == policy["source_refresh_projection_status"],
    "refresh projection status diverges",
  )
  require(
    task["source_followup_projection_id"]
    == policy["source_followup_projection_id"],
    "follow-up projection source diverges",
  )
  require(
    task["source_followup_projection_status"]
    == policy["source_followup_projection_status"],
    "follow-up projection status diverges",
  )
  require(task["may_consume_simulation"] is False, "may-consume changed")
  require(
    task["may_consume_simulation"] == policy["may_consume_simulation"],
    "may-consume diverges",
  )
  require(task["simulation_state"] == "SimulationBlocked", "simulation changed")
  require(
    task["simulation_state"] == policy["simulation_state"],
    "simulation state diverges",
  )
  require(task["refresh_cycle_count"] == 2, "refresh cycle count changed")
  require(
    task["refresh_cycle_count"] == policy["refresh_cycle_count"],
    "refresh cycle count diverges",
  )
  require(task["blocker_count"] == 3, "blocker count changed")
  require(task["blocker_count"] == policy["blocker_count"], "blocker count diverges")
  require(
    set(task["blocking_refresh_ids"]) == set(policy["blocking_refresh_ids"]),
    "blocking refresh ids diverge",
  )
  require(
    set(task["blocking_margin_ids"]) == set(policy["blocking_margin_ids"]),
    "blocking margin ids diverge",
  )
  require(task["hardware_state"] == "HardwareDenied", "hardware state changed")
  require(
    task["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  require(task["hardware_denied"] is True, "hardware denial changed")
  require(task["hardware_state"] == policy["hardware_state"], "hardware diverges")
  require(
    task["hardware_authority"] == policy["hardware_authority"],
    "hardware authority diverges",
  )
  require(
    task["hardware_denied"] == policy["hardware_denied"],
    "hardware denial diverges",
  )
  require(
    "must not emit another automatic follow-up refresh loop" in task["safety_gate"],
    "safety gate does not block automatic loops",
  )
  require(
    "operator pass" in task["next_action"],
    "next action should route operator review",
  )

  criteria = {
    criterion["criterion_id"] for criterion in task["acceptance_criteria"]
  }
  require(
    criteria
    == {
      "closeout-policy-consumed",
      "one-action-per-disposition",
      "hardware-denial-preserved",
    },
    f"unexpected acceptance criteria {criteria}",
  )
  return task


def assert_actions(policy: dict[str, Any], task: dict[str, Any]) -> None:
  actions = {
    action["margin_id"]: action for action in task["closeout_actions"]
  }
  require(set(actions) == set(EXPECTED_ACTIONS), "unexpected closeout actions")
  policy_items = {
    item["margin_id"]: item for item in policy["dispositions"]
  }
  for margin_id, expected in EXPECTED_ACTIONS.items():
    action = actions[margin_id]
    policy_item = policy_items[margin_id]
    require(action["rank"] == expected["rank"], f"{margin_id} rank changed")
    require(
      action["refresh_id"] == expected["refresh_id"],
      f"{margin_id} refresh changed",
    )
    require(
      action["blocker_domain"] == expected["blocker_domain"],
      f"{margin_id} domain changed",
    )
    require(
      action["disposition"] == expected["disposition"],
      f"{margin_id} disposition changed",
    )
    require(
      action["disposition"] == policy_item["disposition"],
      f"{margin_id} disposition diverges",
    )
    require(
      action["required_evidence"] == policy_item["required_evidence"],
      f"{margin_id} required evidence diverges",
    )
    require(
      action["target_artifact_path"] == expected["target"],
      f"{margin_id} target changed",
    )
    require(
      expected["command"] in action["command"],
      f"{margin_id} command changed",
    )
    require(
      action["acceptance_check"] == expected["check"],
      f"{margin_id} check changed",
    )
    require(
      "unbounded refresh loop" in action["reason"],
      f"{margin_id} reason changed",
    )


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Closeout Action Tasks",
    TASK_ID,
    "needs-review",
    "NoConsumeCycleClosedForPolicy",
    "NoConsumeRefreshSimulationBlocked",
    "NoConsumeFollowupRefreshSimulationBlocked",
    "may consume simulation: false",
    "simulation-blocked",
    "hardware-denied",
    "moonmoon-safety-gate-only",
    "EscalateToOperatorDecision",
    "RetryWithNewEvidence",
    "FreezeUntilNewSourceEvidence",
    "manual: review DEM",
    "generate_selected_route_horizon.py --check",
    "manual: keep energy-window frozen",
    "must not emit another automatic follow-up refresh loop",
    "operator pass",
  ):
    require(token in markdown, f"markdown missing {token}")


def main() -> int:
  policy = load_json(CLOSEOUT_JSON)
  tasks = load_json(TASK_JSON)
  markdown = TASK_MD.read_text(encoding="utf-8")
  task = assert_task_against_policy(policy, tasks)
  assert_actions(policy, task)
  assert_markdown(markdown)
  print("checked MoonClaw remediation margin closeout action task")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
