#!/usr/bin/env python3
"""Check MoonClaw regenerated readiness fresh-evidence action receipts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json"
)
RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json"
)
RECEIPTS_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.md"
)
TASK_ID = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task"
)
GATE_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness"
)
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": {
    "rank": 1,
    "refresh_id": "refresh-terrain-northeast-stepout",
    "blocker_domain": "terrain",
    "execution_mode": "operator-escalation",
    "check": "python3 scripts/check_selected_route_terrain_remediation.py",
  },
  "illumination-northeast-stepout": {
    "rank": 2,
    "refresh_id": "refresh-illumination-northeast-stepout",
    "blocker_domain": "local-horizon",
    "execution_mode": "bounded-regeneration",
    "check": "python3 scripts/check_selected_route_horizon_model.py",
  },
  "energy-window": {
    "rank": 3,
    "refresh_id": "refresh-energy-window",
    "blocker_domain": "energy",
    "execution_mode": "manual-freeze-verification",
    "check": "python3 scripts/check_energy_margin_remediation.py",
  },
}
EXPECTED_VALIDATIONS = {
  "source-task-accepted",
  "source-readiness-gate-preserved",
  "source-receipt-provenance-preserved",
  "action-accounting-complete",
  "execution-mode-recorded",
  "result-paths-present",
  "no-automatic-refresh-loop",
  "simulation-consumption-blocked",
  "hardware-denial-preserved",
  "regenerated-receipt-still-pending",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise AssertionError(message)


def assert_receipts(tasks: list[dict[str, Any]], receipts: list[dict[str, Any]]) -> None:
  require(len(tasks) == 1, "expected one regenerated readiness task")
  task = tasks[0]
  require(task["task_id"] == TASK_ID, "task id changed")
  require(task["source_readiness_gate_id"] == GATE_ID, "gate id changed")
  require(
    task["source_readiness_state"] == "RegeneratedReceiptsPendingFreshEvidence",
    "source readiness state changed",
  )
  require(len(receipts) == 3, "expected three regenerated readiness action receipts")
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
      f"{margin_id} receipt id changed",
    )
    require(receipt["receipt"]["proposal_id"] == TASK_ID, f"{margin_id} proposal")
    require(receipt["receipt"]["status"] == "Accepted", f"{margin_id} status")
    require(receipt["source_task_id"] == TASK_ID, f"{margin_id} task")
    require(receipt["source_readiness_gate_id"] == GATE_ID, f"{margin_id} gate")
    require(
      receipt["source_readiness_state"] == "RegeneratedReceiptsPendingFreshEvidence",
      f"{margin_id} readiness state",
    )
    require(receipt["source_receipt_count"] == 3, f"{margin_id} source count")
    require(receipt["pending_receipt_count"] == 3, f"{margin_id} pending count")
    require(receipt["ready_receipt_count"] == 0, f"{margin_id} ready count")
    require(
      receipt["source_receipt_ids"] == task["source_receipt_ids"],
      f"{margin_id} source receipt ids",
    )
    require(
      receipt["source_action_receipt_ids"] == task["source_action_receipt_ids"],
      f"{margin_id} source action receipt ids",
    )
    require(
      receipt["source_receipt_id"] == action["source_receipt_id"],
      f"{margin_id} source receipt",
    )
    require(
      receipt["source_action_receipt_id"] == action["source_action_receipt_id"],
      f"{margin_id} source action receipt",
    )
    require(
      receipt["action_state"] == "RegeneratedFreshEvidenceActionsRecorded",
      f"{margin_id} action state",
    )
    require(result["rank"] == expected["rank"], f"{margin_id} rank")
    require(result["action_id"] == action["action_id"], f"{margin_id} action id")
    require(result["source_readiness_gate_id"] == GATE_ID, f"{margin_id} result gate")
    require(
      result["source_receipt_id"] == action["source_receipt_id"],
      f"{margin_id} result source receipt",
    )
    require(
      result["source_action_receipt_id"] == action["source_action_receipt_id"],
      f"{margin_id} result source action receipt",
    )
    require(result["refresh_id"] == expected["refresh_id"], f"{margin_id} refresh")
    require(
      result["blocker_domain"] == expected["blocker_domain"],
      f"{margin_id} domain",
    )
    require(
      result["execution_mode"] == expected["execution_mode"],
      f"{margin_id} execution mode",
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
      "readiness is recomputed" in result["current_state"],
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
      f"{margin_id} validation failed",
    )
    validation_ids = {check["validation_id"] for check in receipt["validation_checks"]}
    require(validation_ids == EXPECTED_VALIDATIONS, f"{margin_id} validation ids")


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Regenerated Receipt Readiness Fresh Evidence Action Receipts",
    "RegeneratedFreshEvidenceActionsRecorded",
    "RegeneratedReceiptsPendingFreshEvidence",
    "source-readiness-gate-preserved",
    "source-receipt-provenance-preserved",
    "action-accounting-complete",
    "regenerated-receipt-still-pending",
    "operator-escalation",
    "bounded-regeneration",
    "manual-freeze-verification",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware authority change: false",
    "moonmoon-safety-gate-only",
  ):
    require(token in markdown, f"markdown missing {token!r}")


def main() -> int:
  assert_receipts(load_json(TASK_JSON), load_json(RECEIPTS_JSON))
  assert_markdown(RECEIPTS_MD.read_text(encoding="utf-8"))
  print("checked MoonClaw regenerated readiness fresh-evidence action receipts")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
