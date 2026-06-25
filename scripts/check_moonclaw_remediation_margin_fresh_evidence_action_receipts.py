#!/usr/bin/env python3
"""Check MoonClaw remediation-margin fresh-evidence action receipts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json"
)
RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json"
)
RECEIPTS_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.md"
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


def assert_receipts(tasks: list[dict[str, Any]], receipts: list[dict[str, Any]]) -> None:
  require(len(tasks) == 1, "expected one fresh-evidence task")
  task = tasks[0]
  require(task["task_id"] == TASK_ID, "task id changed")
  require(len(receipts) == 3, "expected three fresh-evidence action receipts")
  actions = {action["margin_id"]: action for action in task["fresh_evidence_actions"]}
  receipt_by_margin = {
    receipt["action_result"]["margin_id"]: receipt for receipt in receipts
  }
  require(set(actions) == set(EXPECTED_ACTIONS), "task actions changed")
  require(set(receipt_by_margin) == set(EXPECTED_ACTIONS), "receipt margins changed")

  for margin_id, expected in EXPECTED_ACTIONS.items():
    action = actions[margin_id]
    receipt = receipt_by_margin[margin_id]
    result = receipt["action_result"]
    require(
      receipt["receipt"]["receipt_id"]
      == f"{TASK_ID}/action-{expected['rank']}-{margin_id}/receipt",
      f"{margin_id} receipt id",
    )
    require(receipt["receipt"]["proposal_id"] == TASK_ID, f"{margin_id} proposal")
    require(receipt["receipt"]["status"] == "Accepted", f"{margin_id} status")
    require(receipt["source_task_id"] == TASK_ID, f"{margin_id} task")
    require(receipt["source_plan_id"] == PLAN_ID, f"{margin_id} plan")
    require(
      receipt["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{margin_id} review transition",
    )
    require(receipt["source_review_decision"] == "Accept", f"{margin_id} decision")
    require(receipt["source_receipt_count"] == 3, f"{margin_id} source count")
    require(
      receipt["source_receipt_ids"] == task["source_receipt_ids"],
      f"{margin_id} source receipt ids",
    )
    require(
      receipt["source_receipt_id"] == action["source_receipt_id"],
      f"{margin_id} source receipt",
    )
    require(
      receipt["source_work_item_id"] == action["source_work_item_id"],
      f"{margin_id} source work item",
    )
    require(
      receipt["action_state"] == "FreshEvidenceActionsRecorded",
      f"{margin_id} action state",
    )
    require(result["rank"] == expected["rank"], f"{margin_id} rank")
    require(result["action_id"] == action["action_id"], f"{margin_id} action id")
    require(result["refresh_id"] == expected["refresh_id"], f"{margin_id} refresh")
    require(
      result["blocker_domain"] == expected["blocker_domain"],
      f"{margin_id} domain",
    )
    require(
      result["disposition"] == expected["disposition"],
      f"{margin_id} disposition",
    )
    require(
      result["result_status"] == "ReviewedWorkItemPendingFreshEvidence",
      f"{margin_id} result status",
    )
    require(
      result["required_evidence"] == action["required_evidence"],
      f"{margin_id} required evidence",
    )
    require(
      result["target_artifact_path"] == action["target_artifact_path"],
      f"{margin_id} target",
    )
    require(result["evidence_path"] == action["evidence_path"], f"{margin_id} evidence")
    require(result["command"] == action["command"], f"{margin_id} command")
    require(result["acceptance_check"] == expected["check"], f"{margin_id} check")
    require(
      result["execution_mode"] == expected["execution_mode"],
      f"{margin_id} execution mode",
    )
    require(
      "reviewed work item remains pending" in result["current_state"],
      f"{margin_id} current state",
    )
    require(receipt["may_consume_simulation"] is False, f"{margin_id} may consume")
    require(receipt["simulation_state"] == "SimulationBlocked", f"{margin_id} sim")
    require(
      receipt["automatic_refresh_loop_allowed"] is False,
      f"{margin_id} refresh loop",
    )
    require(receipt["hardware_state"] == "HardwareDenied", f"{margin_id} hardware")
    require(
      receipt["hardware_authority"] == "moonmoon-safety-gate-only",
      f"{margin_id} authority",
    )
    require(
      receipt["hardware_authority_change"] is False,
      f"{margin_id} authority change",
    )
    require(receipt["hardware_denied"] is True, f"{margin_id} denied")
    require(
      all(check["passed"] for check in receipt["validation_checks"]),
      f"{margin_id} validation",
    )
    validation_ids = {check["validation_id"] for check in receipt["validation_checks"]}
    for validation_id in (
      "source-task-accepted",
      "source-receipt-provenance-preserved",
      "action-accounting-complete",
      "execution-mode-recorded",
      "no-automatic-refresh-loop",
      "simulation-consumption-blocked",
      "hardware-denial-preserved",
      "reviewed-work-item-still-pending",
    ):
      require(validation_id in validation_ids, f"{margin_id} missing {validation_id}")


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Fresh Evidence Action Receipts",
    "FreshEvidenceActionsRecorded",
    "operator-escalation",
    "bounded-regeneration",
    "manual-freeze-verification",
    "source-receipt-provenance-preserved",
    "action-accounting-complete",
    "simulation-consumption-blocked",
    "hardware-denial-preserved",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware authority change: false",
    "ReviewedWorkItemPendingFreshEvidence",
  ):
    require(token in markdown, f"markdown missing {token!r}")


def main() -> None:
  assert_receipts(load_json(TASK_JSON), load_json(RECEIPTS_JSON))
  assert_markdown(RECEIPTS_MD.read_text(encoding="utf-8"))
  print("checked MoonClaw remediation-margin fresh evidence action receipts")


if __name__ == "__main__":
  main()
