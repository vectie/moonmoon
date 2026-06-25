#!/usr/bin/env python3
"""Check MoonClaw reviewed remediation-margin work item receipt output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ITEMS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json"
)
RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json"
)
RECEIPTS_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.md"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_STATUS = "ReviewedWorkItemPendingFreshEvidence"
EXPECTED_STATE = "ReviewedWorkItemsCarriedForward"
EXPECTED_CHECKS = {
  "source-work-item-accepted",
  "review-provenance-preserved",
  "work-item-accounting-complete",
  "result-paths-present",
  "no-automatic-refresh-loop",
  "simulation-consumption-blocked",
  "hardware-denial-preserved",
  "fresh-evidence-still-pending",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_receipts(
  items: list[dict[str, Any]],
  receipts: list[dict[str, Any]],
) -> None:
  require(len(receipts) == 3, "expected three reviewed work item receipts")
  by_work_item = {item["work_item_id"]: item for item in items}
  receipt_by_work_item = {
    receipt["source_work_item_id"]: receipt for receipt in receipts
  }
  require(
    set(receipt_by_work_item) == set(by_work_item),
    "receipt source work items diverge from reviewed work items",
  )
  for work_item_id, item in by_work_item.items():
    receipt = receipt_by_work_item[work_item_id]
    result = receipt["work_item_result"]
    require(
      receipt["receipt"]["receipt_id"] == f"{work_item_id}/receipt",
      f"{work_item_id} receipt id changed",
    )
    require(
      receipt["receipt"]["proposal_id"] == PLAN_ID,
      f"{work_item_id} proposal changed",
    )
    require(receipt["receipt"]["status"] == "Accepted", f"{work_item_id} status")
    require(receipt["source_plan_id"] == PLAN_ID, f"{work_item_id} plan")
    require(
      receipt["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{work_item_id} review transition",
    )
    require(
      receipt["source_review_decision"] == "Accept",
      f"{work_item_id} review decision",
    )
    require(
      receipt["source_work_item_state"] == "Accepted",
      f"{work_item_id} source state",
    )
    require(
      receipt["result_state"] == EXPECTED_STATE,
      f"{work_item_id} result state",
    )
    require(
      result["status"] == EXPECTED_STATUS,
      f"{work_item_id} result status",
    )
    for key in (
      "rank",
      "margin_id",
      "refresh_id",
      "blocker_domain",
      "disposition",
      "required_evidence",
      "target_artifact_path",
      "command",
      "acceptance_check",
    ):
      require(result[key] == item[key], f"{work_item_id} result {key} diverges")
    require(
      result["evidence_path"] == item["target_artifact_path"],
      f"{work_item_id} evidence path diverges",
    )
    require(
      "pending fresh evidence" in result["current_state"],
      f"{work_item_id} current state missing pending evidence",
    )
    require(
      "pending fresh evidence" in receipt["next_action"]
      or "Attach fresh evidence" in receipt["next_action"],
      f"{work_item_id} next action missing fresh evidence",
    )
    require(
      receipt["may_consume_simulation"] is False,
      f"{work_item_id} may consume simulation",
    )
    require(
      receipt["simulation_state"] == "SimulationBlocked",
      f"{work_item_id} simulation state",
    )
    require(
      receipt["automatic_refresh_loop_allowed"] is False,
      f"{work_item_id} automatic refresh loop",
    )
    require(
      receipt["hardware_state"] == "HardwareDenied",
      f"{work_item_id} hardware state",
    )
    require(
      receipt["hardware_authority"] == "moonmoon-safety-gate-only",
      f"{work_item_id} hardware authority",
    )
    require(
      receipt["hardware_authority_change"] is False,
      f"{work_item_id} hardware authority change",
    )
    require(receipt["hardware_denied"] is True, f"{work_item_id} hardware denial")
    checks = {check["validation_id"]: check for check in receipt["validation_checks"]}
    require(set(checks) == EXPECTED_CHECKS, f"{work_item_id} checks changed")
    failed = [check for check in checks.values() if not check["passed"]]
    require(not failed, f"{work_item_id} has failed checks: {failed!r}")
    notes = receipt["receipt"]["validation_notes"]
    require(len(notes) == len(EXPECTED_CHECKS), f"{work_item_id} note count")


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Reviewed Work Item Receipts",
    "work-item-1-terrain-northeast-stepout/receipt",
    "work-item-2-illumination-northeast-stepout/receipt",
    "work-item-3-energy-window/receipt",
    "ReviewedWorkItemPendingFreshEvidence",
    "review decision: Accept",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware authority change: false",
    "moonmoon-safety-gate-only",
    "EscalateToOperatorDecision",
    "RetryWithNewEvidence",
    "FreezeUntilNewSourceEvidence",
  ):
    require(token in markdown, f"markdown missing {token!r}")


def main() -> None:
  items = load_json(ITEMS_JSON)
  receipts = load_json(RECEIPTS_JSON)
  assert_receipts(items, receipts)
  assert_markdown(RECEIPTS_MD.read_text(encoding="utf-8"))
  print("checked MoonClaw remediation-margin reviewed work item receipts")


if __name__ == "__main__":
  main()
