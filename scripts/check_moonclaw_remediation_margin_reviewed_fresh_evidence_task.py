#!/usr/bin/env python3
"""Check MoonClaw reviewed remediation-margin fresh evidence task output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json"
)
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json"
)
TASK_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.md"
)
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": {
    "rank": 1,
    "refresh_id": "refresh-terrain-northeast-stepout",
    "blocker_domain": "terrain",
    "disposition": "EscalateToOperatorDecision",
    "execution_mode": "operator-escalation",
    "check": "python3 scripts/check_selected_route_terrain_remediation.py",
  },
  "illumination-northeast-stepout": {
    "rank": 2,
    "refresh_id": "refresh-illumination-northeast-stepout",
    "blocker_domain": "local-horizon",
    "disposition": "RetryWithNewEvidence",
    "execution_mode": "bounded-regeneration",
    "check": "python3 scripts/check_selected_route_horizon_model.py",
  },
  "energy-window": {
    "rank": 3,
    "refresh_id": "refresh-energy-window",
    "blocker_domain": "energy",
    "disposition": "FreezeUntilNewSourceEvidence",
    "execution_mode": "manual-freeze-verification",
    "check": "python3 scripts/check_energy_margin_remediation.py",
  },
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_task(receipts: list[dict[str, Any]], tasks: list[dict[str, Any]]) -> None:
  require(len(tasks) == 1, "expected one reviewed fresh evidence task")
  task = tasks[0]
  require(task["task_id"] == TASK_ID, "task id changed")
  require(task["priority"] == "Critical", "task priority changed")
  require(task["state"] == "Accepted", "task state changed")
  require(task["source_plan_id"] == PLAN_ID, "source plan changed")
  require(
    task["source_review_transition_id"] == REVIEW_TRANSITION_ID,
    "review transition changed",
  )
  require(task["source_review_decision"] == "Accept", "review decision changed")
  require(task["source_receipt_count"] == len(receipts), "source count changed")
  require(task["pending_receipt_count"] == 3, "pending count changed")
  receipt_ids = [receipt["receipt"]["receipt_id"] for receipt in receipts]
  require(task["source_receipt_ids"] == receipt_ids, "receipt ids diverge")
  require(
    set(task["pending_margin_ids"]) == set(EXPECTED_ACTIONS),
    "pending margins changed",
  )
  require(
    set(task["pending_refresh_ids"])
    == {expected["refresh_id"] for expected in EXPECTED_ACTIONS.values()},
    "pending refresh ids changed",
  )
  require(task["may_consume_simulation"] is False, "may consume simulation")
  require(task["simulation_state"] == "SimulationBlocked", "simulation state")
  require(
    task["automatic_refresh_loop_allowed"] is False,
    "automatic refresh loop allowed",
  )
  require(task["hardware_state"] == "HardwareDenied", "hardware state")
  require(
    task["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority",
  )
  require(
    task["hardware_authority_change"] is False,
    "hardware authority changed",
  )
  require(task["hardware_denied"] is True, "hardware denial")
  require(
    "do not start an automatic refresh loop" in task["safety_gate"],
    "safety gate missing refresh-loop block",
  )
  require(
    "regenerate reviewed work item receipts" in task["next_action"],
    "next action missing receipt regeneration",
  )

  receipts_by_margin = {
    receipt["work_item_result"]["margin_id"]: receipt for receipt in receipts
  }
  actions = {
    action["margin_id"]: action for action in task["fresh_evidence_actions"]
  }
  require(set(actions) == set(EXPECTED_ACTIONS), "unexpected action margins")
  require(set(actions) == set(receipts_by_margin), "actions diverge from receipts")
  for margin_id, expected in EXPECTED_ACTIONS.items():
    action = actions[margin_id]
    receipt = receipts_by_margin[margin_id]
    result = receipt["work_item_result"]
    require(action["rank"] == expected["rank"], f"{margin_id} rank")
    require(
      action["source_receipt_id"] == receipt["receipt"]["receipt_id"],
      f"{margin_id} source receipt",
    )
    require(
      action["source_work_item_id"] == receipt["source_work_item_id"],
      f"{margin_id} source work item",
    )
    require(
      action["refresh_id"] == expected["refresh_id"],
      f"{margin_id} refresh",
    )
    require(
      action["blocker_domain"] == expected["blocker_domain"],
      f"{margin_id} domain",
    )
    require(
      action["disposition"] == expected["disposition"],
      f"{margin_id} disposition",
    )
    require(
      action["result_status"] == "ReviewedWorkItemPendingFreshEvidence",
      f"{margin_id} result status",
    )
    require(
      action["required_evidence"] == result["required_evidence"],
      f"{margin_id} required evidence",
    )
    require(
      action["target_artifact_path"] == result["target_artifact_path"],
      f"{margin_id} target",
    )
    require(action["evidence_path"] == result["evidence_path"], f"{margin_id} evidence")
    require(action["command"] == result["command"], f"{margin_id} command")
    require(
      action["acceptance_check"] == expected["check"],
      f"{margin_id} check",
    )
    require(
      action["execution_mode"] == expected["execution_mode"],
      f"{margin_id} execution mode",
    )


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Reviewed Fresh Evidence Tasks",
    "reviewed-fresh-evidence-task",
    "pending receipts: 3",
    "ReviewedWorkItemPendingFreshEvidence",
    "operator-escalation",
    "bounded-regeneration",
    "manual-freeze-verification",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware authority change: false",
    "moonmoon-safety-gate-only",
  ):
    require(token in markdown, f"markdown missing {token!r}")


def main() -> None:
  receipts = load_json(RECEIPTS_JSON)
  tasks = load_json(TASK_JSON)
  assert_task(receipts, tasks)
  assert_markdown(TASK_MD.read_text(encoding="utf-8"))
  print("checked MoonClaw remediation-margin reviewed fresh evidence task")


if __name__ == "__main__":
  main()
