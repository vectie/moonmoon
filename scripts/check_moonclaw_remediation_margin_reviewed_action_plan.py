#!/usr/bin/env python3
"""Check MoonClaw reviewed remediation-margin action plan output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
PLAN_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json"
)
PLAN_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.md"
)
REVIEW_FIXTURE = ROOT / "data/fixtures/rabbita_closeout_action_review_accept.json"
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
REVIEW_ITEM_ID = "moonclaw-remediation-margin-closeout-action-review"
REVIEW_ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-closeout-action-task"
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": {
    "rank": 1,
    "disposition": "EscalateToOperatorDecision",
    "command": "manual: review DEM",
    "check": "python3 scripts/check_selected_route_terrain_remediation.py",
  },
  "illumination-northeast-stepout": {
    "rank": 2,
    "disposition": "RetryWithNewEvidence",
    "command": "python3 scripts/generate_selected_route_horizon.py --check",
    "check": "python3 scripts/check_selected_route_horizon_model.py",
  },
  "energy-window": {
    "rank": 3,
    "disposition": "FreezeUntilNewSourceEvidence",
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


def accepted_review(fixture: dict[str, Any]) -> dict[str, Any]:
  transitions = fixture.get("transitions", [])
  require(len(transitions) == 1, "expected exactly one review transition")
  transition = transitions[0]
  require(transition["item_id"] == REVIEW_ITEM_ID, "review item changed")
  require(transition["entry_id"] == REVIEW_ENTRY_ID, "review entry changed")
  require(transition["previous_status"] == "NeedsReview", "previous status changed")
  require(transition["decision"] == "Accept", "fixture must be accepted")
  require(transition["resulting_status"] == "Accepted", "resulting status changed")
  require(transition["append_only"] is True, "review must be append-only")
  require(
    transition["hardware_authority_change"] is False,
    "hardware authority changed",
  )
  require(transition["hardware_state"] == "HardwareDenied", "hardware state changed")
  require(
    transition["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  return transition


def assert_plan(
  task: dict[str, Any],
  review: dict[str, Any],
  plans: list[dict[str, Any]],
) -> dict[str, Any]:
  require(len(plans) == 1, "expected one reviewed action plan")
  plan = plans[0]
  require(plan["plan_id"] == PLAN_ID, "unexpected plan id")
  require(plan["state"] == "Accepted", "plan should be accepted")
  require(plan["priority"] == "Critical", "priority changed")
  require(plan["site_id"] == task["site_id"], "site id diverges")
  require(plan["route_id"] == task["route_id"], "route id diverges")
  require(plan["source_task_id"] == TASK_ID, "unexpected source task")
  require(plan["source_task_id"] == task["task_id"], "source task diverges")
  require(
    plan["source_review_transition_id"] == review["transition_id"],
    "review transition diverges",
  )
  require(
    plan["source_review_item_id"] == review["item_id"],
    "review item diverges",
  )
  require(plan["source_review_decision"] == "Accept", "review decision changed")
  require(plan["reviewer_id"] == review["reviewer_id"], "reviewer changed")
  require(
    plan["reviewed_at_utc"] == review["recorded_at_utc"],
    "review timestamp changed",
  )
  require(
    plan["source_evidence_refs"] == review["source_evidence_refs"],
    "source evidence refs diverge",
  )
  require(plan["may_consume_simulation"] is False, "may-consume changed")
  require(
    plan["may_consume_simulation"] == task["may_consume_simulation"],
    "may-consume diverges from task",
  )
  require(plan["simulation_state"] == "SimulationBlocked", "simulation changed")
  require(
    plan["simulation_state"] == task["simulation_state"],
    "simulation state diverges",
  )
  require(plan["refresh_cycle_count"] == 2, "refresh cycle count changed")
  require(
    plan["refresh_cycle_count"] == task["refresh_cycle_count"],
    "refresh count diverges",
  )
  require(plan["blocker_count"] == 3, "blocker count changed")
  require(plan["blocker_count"] == task["blocker_count"], "blocker count diverges")
  require(
    set(plan["blocking_refresh_ids"]) == set(task["blocking_refresh_ids"]),
    "blocking refresh ids diverge",
  )
  require(
    set(plan["blocking_margin_ids"]) == set(task["blocking_margin_ids"]),
    "blocking margin ids diverge",
  )
  require(
    plan["automatic_refresh_loop_allowed"] is False,
    "automatic refresh loop was allowed",
  )
  require(plan["hardware_state"] == "HardwareDenied", "hardware state changed")
  require(
    plan["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  require(
    plan["hardware_authority_change"] is False,
    "hardware authority change must remain false",
  )
  require(plan["hardware_denied"] is True, "hardware denial changed")
  require(
    plan["hardware_state"] == task["hardware_state"],
    "hardware state diverges from task",
  )
  require(
    plan["hardware_authority"] == task["hardware_authority"],
    "hardware authority diverges from task",
  )
  require(
    plan["hardware_denied"] == task["hardware_denied"],
    "hardware denial diverges from task",
  )
  require(
    "do not start an automatic refresh loop" in plan["safety_gate"],
    "safety gate does not forbid automatic loops",
  )
  require(
    "bounded reviewed work items" in plan["next_action"],
    "next action should schedule bounded reviewed work",
  )
  criteria = {
    criterion["criterion_id"] for criterion in plan["acceptance_criteria"]
  }
  require(
    criteria
    == {
      "accepted-review-required",
      "bounded-closeout-actions",
      "hardware-denial-preserved",
    },
    f"unexpected acceptance criteria {criteria}",
  )
  return plan


def assert_actions(task: dict[str, Any], plan: dict[str, Any]) -> None:
  task_actions = {action["margin_id"]: action for action in task["closeout_actions"]}
  plan_actions = {action["margin_id"]: action for action in plan["actions"]}
  require(set(plan_actions) == set(EXPECTED_ACTIONS), "unexpected plan actions")
  require(set(plan_actions) == set(task_actions), "plan actions diverge from task")
  for margin_id, expected in EXPECTED_ACTIONS.items():
    action = plan_actions[margin_id]
    task_action = task_actions[margin_id]
    require(action == task_action, f"{margin_id} diverges from closeout task")
    require(action["rank"] == expected["rank"], f"{margin_id} rank changed")
    require(
      action["disposition"] == expected["disposition"],
      f"{margin_id} disposition changed",
    )
    require(
      expected["command"] in action["command"],
      f"{margin_id} command changed",
    )
    require(
      action["acceptance_check"] == expected["check"],
      f"{margin_id} check changed",
    )


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Reviewed Action Plans",
    PLAN_ID,
    "review decision: Accept",
    "accepted",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware-denied",
    "moonmoon-safety-gate-only",
    "hardware authority change: false",
    "EscalateToOperatorDecision",
    "RetryWithNewEvidence",
    "FreezeUntilNewSourceEvidence",
    "manual: review DEM",
    "generate_selected_route_horizon.py --check",
    "manual: keep energy-window frozen",
    "accepted-review-required",
    "do not start an automatic refresh loop",
  ):
    require(token in markdown, f"markdown missing {token!r}")


def main() -> None:
  task_payload = load_json(TASK_JSON)
  task = task_payload[0]
  review = accepted_review(load_json(REVIEW_FIXTURE))
  plan = assert_plan(task, review, load_json(PLAN_JSON))
  assert_actions(task, plan)
  assert_markdown(PLAN_MD.read_text(encoding="utf-8"))
  print("MoonClaw remediation-margin reviewed action plan output is consistent")


if __name__ == "__main__":
  main()
