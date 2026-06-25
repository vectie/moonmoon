#!/usr/bin/env python3
"""Check regenerated MoonClaw reviewed work item receipts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ACTION_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json"
)
REGENERATED_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
REGENERATED_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.md"
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
    "execution_mode": "operator-escalation",
    "disposition": "EscalateToOperatorDecision",
    "check": "python3 scripts/check_selected_route_terrain_remediation.py",
  },
  "illumination-northeast-stepout": {
    "execution_mode": "bounded-regeneration",
    "disposition": "RetryWithNewEvidence",
    "check": "python3 scripts/check_selected_route_horizon_model.py",
  },
  "energy-window": {
    "execution_mode": "manual-freeze-verification",
    "disposition": "FreezeUntilNewSourceEvidence",
    "check": "python3 scripts/check_energy_margin_remediation.py",
  },
}
EXPECTED_CHECKS = {
  "source-action-receipt-accepted",
  "source-receipt-provenance-preserved",
  "source-action-accounting-complete",
  "execution-mode-preserved",
  "result-paths-present",
  "no-automatic-refresh-loop",
  "simulation-consumption-blocked",
  "hardware-denial-preserved",
  "reviewed-work-item-still-pending",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_receipts(
  action_receipts: list[dict[str, Any]],
  regenerated: list[dict[str, Any]],
) -> None:
  require(len(action_receipts) == 3, "expected three action receipts")
  require(len(regenerated) == 3, "expected three regenerated receipts")
  actions_by_margin = {
    receipt["action_result"]["margin_id"]: receipt for receipt in action_receipts
  }
  regenerated_by_margin = {
    receipt["work_item_result"]["margin_id"]: receipt for receipt in regenerated
  }
  require(set(actions_by_margin) == set(EXPECTED_ACTIONS), "action margins changed")
  require(
    set(regenerated_by_margin) == set(EXPECTED_ACTIONS),
    "regenerated margins changed",
  )

  for margin_id, expected in EXPECTED_ACTIONS.items():
    source = actions_by_margin[margin_id]
    receipt = regenerated_by_margin[margin_id]
    action = source["action_result"]
    result = receipt["work_item_result"]
    require(
      receipt["receipt"]["receipt_id"]
      == f"{action['source_work_item_id']}/regenerated-receipt",
      f"{margin_id} receipt id",
    )
    require(receipt["receipt"]["proposal_id"] == TASK_ID, f"{margin_id} proposal")
    require(receipt["receipt"]["status"] == "Accepted", f"{margin_id} status")
    require(
      receipt["source_action_receipt_id"] == source["receipt"]["receipt_id"],
      f"{margin_id} source action receipt",
    )
    require(
      receipt["source_action_id"] == action["action_id"],
      f"{margin_id} source action id",
    )
    require(
      receipt["source_fresh_evidence_task_id"] == TASK_ID,
      f"{margin_id} task",
    )
    require(receipt["source_plan_id"] == PLAN_ID, f"{margin_id} plan")
    require(
      receipt["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{margin_id} review transition",
    )
    require(receipt["source_review_decision"] == "Accept", f"{margin_id} decision")
    require(receipt["source_receipt_count"] == 3, f"{margin_id} source count")
    require(
      receipt["source_receipt_ids"] == source["source_receipt_ids"],
      f"{margin_id} source receipt ids",
    )
    require(
      receipt["source_receipt_id"] == source["source_receipt_id"],
      f"{margin_id} source receipt",
    )
    require(
      receipt["source_work_item_id"] == source["source_work_item_id"],
      f"{margin_id} source work item",
    )
    require(
      receipt["source_action_state"] == "FreshEvidenceActionsRecorded",
      f"{margin_id} source action state",
    )
    require(
      receipt["result_state"] == "ReviewedWorkItemsCarriedForward",
      f"{margin_id} result state",
    )
    require(
      receipt["execution_mode"] == expected["execution_mode"],
      f"{margin_id} execution mode",
    )
    for key in (
      "rank",
      "margin_id",
      "refresh_id",
      "blocker_domain",
      "required_evidence",
      "target_artifact_path",
      "command",
      "acceptance_check",
      "evidence_path",
    ):
      require(result[key] == action[key], f"{margin_id} result {key}")
    require(result["disposition"] == expected["disposition"], f"{margin_id} disposition")
    require(
      result["status"] == "ReviewedWorkItemPendingFreshEvidence",
      f"{margin_id} result status",
    )
    require(result["acceptance_check"] == expected["check"], f"{margin_id} check")
    require(
      "consumed fresh-evidence action receipt" in result["current_state"],
      f"{margin_id} current state",
    )
    require(receipt["may_consume_simulation"] is False, f"{margin_id} consume")
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
    checks = {check["validation_id"]: check for check in receipt["validation_checks"]}
    require(set(checks) == EXPECTED_CHECKS, f"{margin_id} checks")
    require(
      all(check["passed"] for check in checks.values()),
      f"{margin_id} validation failed",
    )


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Regenerated Reviewed Work Item Receipts",
    "regenerated-receipt",
    "source action receipt:",
    "source-action-receipt-accepted",
    "source-receipt-provenance-preserved",
    "execution-mode-preserved",
    "ReviewedWorkItemPendingFreshEvidence",
    "ReviewedWorkItemsCarriedForward",
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
  assert_receipts(load_json(ACTION_RECEIPTS_JSON), load_json(REGENERATED_JSON))
  assert_markdown(REGENERATED_MD.read_text(encoding="utf-8"))
  print("checked MoonClaw regenerated reviewed work item receipts")


if __name__ == "__main__":
  main()
