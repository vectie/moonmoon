#!/usr/bin/env python3
"""Check MoonBook workspace materialization for regenerated work item receipts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_PATH = (
  WORKSPACE
  / "moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json"
)
RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
ACTION_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json"
)
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json"
)
SOURCE_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json"
)
ITEMS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json"
)
PLAN_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json"
)
ENTRY_ID = (
  "moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts"
)
ENTRY_KIND = "MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipts"
ENTRY_REL_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json"
)
SOURCE_FILE = (
  "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
README_SOURCE = (
  "Source MoonClaw remediation-margin regenerated reviewed work item receipts"
)
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": "operator-escalation",
  "illumination-northeast-stepout": "bounded-regeneration",
  "energy-window": "manual-freeze-verification",
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


def assert_index_manifest_readme() -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")
  require(SOURCE_FILE in index["source_files"], "regenerated receipts missing source file")
  require(ENTRY_REL_PATH in manifest["entry_paths"], "manifest missing regenerated receipts")
  require(README_SOURCE in readme, "README missing regenerated receipts source")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing regenerated receipts entry")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, "unexpected regenerated receipts kind")
  require(entry["path"] == ENTRY_REL_PATH, "unexpected regenerated receipts path")
  for token in (
    "3 regenerated reviewed work item receipts",
    "terrain=ReviewedWorkItemPendingFreshEvidence",
    "local-horizon=ReviewedWorkItemPendingFreshEvidence",
    "energy=ReviewedWorkItemPendingFreshEvidence",
    "terrain=operator-escalation",
    "local-horizon=bounded-regeneration",
    "energy=manual-freeze-verification",
    "source action receipt provenance",
    "source receipt provenance",
    "accepted review provenance",
    "automatic refresh loop allowed false",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ):
    require(token in entry["summary"], f"summary missing {token!r}")


def assert_workspace_payload() -> None:
  generated_receipts = load_json(RECEIPTS_JSON)
  generated_action_receipts = load_json(ACTION_RECEIPTS_JSON)
  generated_task = load_json(TASK_JSON)[0]
  generated_source_receipts = load_json(SOURCE_RECEIPTS_JSON)
  generated_items = load_json(ITEMS_JSON)
  generated_plan = load_json(PLAN_JSON)[0]
  wrapper = load_json(ENTRY_PATH)
  require(wrapper["workspace"] == "moonbook://moonmoon/first-trusted-square", "workspace changed")
  require(wrapper["site_id"] == "first-trusted-square", "site changed")
  entry = wrapper["entry"]
  require(entry["entry_id"] == ENTRY_ID, "entry id changed")
  require(entry["kind"] == ENTRY_KIND, "entry kind changed")
  payload = wrapper["payload"]
  require(payload["receipts"] == generated_receipts, "receipts diverge")
  require(payload["primary_receipt"] == generated_receipts[0], "primary diverges")
  require(
    payload["source_action_receipts"] == generated_action_receipts,
    "source action receipts diverge",
  )
  require(payload["source_task"] == generated_task, "source task diverges")
  require(
    payload["source_receipts"] == generated_source_receipts,
    "source receipts diverge",
  )
  require(payload["source_work_items"] == generated_items, "work items diverge")
  require(payload["source_plan"] == generated_plan, "source plan diverges")
  require(payload["source_task"]["task_id"] == TASK_ID, "source task id changed")
  require(payload["source_plan"]["plan_id"] == PLAN_ID, "source plan id changed")
  review = payload["review"]
  require(review["status"] == "Accepted", "review status changed")
  require(review["decision"] == "Accept", "review decision changed")
  require(
    review["transition"]["transition_id"] == REVIEW_TRANSITION_ID,
    "review transition changed",
  )
  require(review["hardware_authority_change"] is False, "review hardware change")
  require(review["hardware_state"] == "HardwareDenied", "review hardware state")
  require(
    review["hardware_authority"] == "moonmoon-safety-gate-only",
    "review hardware authority",
  )

  by_margin = {
    receipt["work_item_result"]["margin_id"]: receipt
    for receipt in payload["receipts"]
  }
  require(set(by_margin) == set(EXPECTED_ACTIONS), "unexpected receipt margins")
  action_receipt_by_id = {
    receipt["receipt"]["receipt_id"]: receipt
    for receipt in generated_action_receipts
  }
  source_receipt_ids = {
    receipt["receipt"]["receipt_id"] for receipt in generated_source_receipts
  }
  for margin_id, execution_mode in EXPECTED_ACTIONS.items():
    receipt = by_margin[margin_id]
    result = receipt["work_item_result"]
    require(
      receipt["receipt"]["receipt_id"].endswith(f"{margin_id}/regenerated-receipt"),
      f"{margin_id} receipt id changed",
    )
    require(
      receipt["source_action_receipt_id"] in action_receipt_by_id,
      f"{margin_id} source action receipt",
    )
    source_action_receipt = action_receipt_by_id[
      receipt["source_action_receipt_id"]
    ]
    require(
      source_action_receipt["action_result"]["action_id"]
      == receipt["source_action_id"],
      f"{margin_id} source action id",
    )
    require(receipt["source_fresh_evidence_task_id"] == TASK_ID, f"{margin_id} task")
    require(receipt["source_plan_id"] == PLAN_ID, f"{margin_id} plan")
    require(
      receipt["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{margin_id} review transition",
    )
    require(receipt["source_review_decision"] == "Accept", f"{margin_id} decision")
    require(
      receipt["source_receipt_id"] in source_receipt_ids,
      f"{margin_id} source receipt",
    )
    require(
      receipt["source_action_state"] == "FreshEvidenceActionsRecorded",
      f"{margin_id} action state",
    )
    require(
      receipt["result_state"] == "ReviewedWorkItemsCarriedForward",
      f"{margin_id} result state",
    )
    require(
      result["status"] == "ReviewedWorkItemPendingFreshEvidence",
      f"{margin_id} result status",
    )
    require(receipt["execution_mode"] == execution_mode, f"{margin_id} mode")
    require(result["command"], f"{margin_id} command")
    require(result["acceptance_check"], f"{margin_id} check")
    require(result["evidence_path"], f"{margin_id} evidence path")
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
    require(set(checks) == EXPECTED_CHECKS, f"{margin_id} validation ids")
    require(all(check["passed"] for check in checks.values()), f"{margin_id} validation")


def main() -> None:
  assert_index_manifest_readme()
  assert_workspace_payload()
  print("checked MoonBook regenerated reviewed work item receipt workspace")


if __name__ == "__main__":
  main()
