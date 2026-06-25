#!/usr/bin/env python3
"""Check MoonBook workspace materialization for reviewed work item receipts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_PATH = (
  WORKSPACE
  / "moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts.json"
)
RECEIPTS_JSON = (
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
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
ENTRY_ID = (
  "moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts"
)
ENTRY_KIND = "MoonClawRemediationMarginReviewedWorkItemReceipts"
ENTRY_REL_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-reviewed-work-item-receipts.json"
)
SOURCE_FILE = (
  "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json"
)
README_SOURCE = (
  "Source MoonClaw remediation-margin reviewed work item receipts"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_MARGINS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
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
  require(SOURCE_FILE in index["source_files"], "receipts missing source file")
  require(ENTRY_REL_PATH in manifest["entry_paths"], "manifest missing receipts")
  require(README_SOURCE in readme, "README missing receipts source")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing receipts entry")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, "unexpected receipts entry kind")
  require(entry["path"] == ENTRY_REL_PATH, "unexpected receipts entry path")
  for token in (
    "3 accepted reviewed work item receipts",
    "pending fresh evidence",
    "terrain=ReviewedWorkItemPendingFreshEvidence",
    "local-horizon=ReviewedWorkItemPendingFreshEvidence",
    "energy=ReviewedWorkItemPendingFreshEvidence",
    "accepted review provenance",
    "automatic refresh loop allowed false",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ):
    require(token in entry["summary"], f"summary missing {token!r}")


def assert_workspace_payload() -> None:
  generated_receipts = load_json(RECEIPTS_JSON)
  generated_items = load_json(ITEMS_JSON)
  generated_plan = load_json(PLAN_JSON)[0]
  generated_task = load_json(TASK_JSON)[0]
  wrapper = load_json(ENTRY_PATH)
  require(wrapper["workspace"] == "moonbook://moonmoon/first-trusted-square", "workspace changed")
  require(wrapper["site_id"] == "first-trusted-square", "site changed")
  entry = wrapper["entry"]
  require(entry["entry_id"] == ENTRY_ID, "entry id changed")
  require(entry["kind"] == ENTRY_KIND, "entry kind changed")
  payload = wrapper["payload"]
  require(payload["receipts"] == generated_receipts, "receipts diverge")
  require(payload["primary_receipt"] == generated_receipts[0], "primary diverges")
  require(payload["source_work_items"] == generated_items, "work items diverge")
  require(payload["source_plan"] == generated_plan, "source plan diverges")
  require(payload["source_task"] == generated_task, "source task diverges")
  require(payload["source_plan"]["plan_id"] == PLAN_ID, "source plan id changed")
  require(payload["source_task"]["task_id"] == TASK_ID, "source task id changed")
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
  require(set(by_margin) == EXPECTED_MARGINS, "unexpected receipt margins")
  for margin_id, receipt in by_margin.items():
    result = receipt["work_item_result"]
    require(
      receipt["receipt"]["receipt_id"].endswith(f"{margin_id}/receipt"),
      f"{margin_id} receipt id changed",
    )
    require(receipt["source_plan_id"] == PLAN_ID, f"{margin_id} plan")
    require(
      receipt["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{margin_id} review transition",
    )
    require(receipt["source_review_decision"] == "Accept", f"{margin_id} decision")
    require(
      receipt["result_state"] == "ReviewedWorkItemsCarriedForward",
      f"{margin_id} result state",
    )
    require(
      result["status"] == "ReviewedWorkItemPendingFreshEvidence",
      f"{margin_id} status",
    )
    require(receipt["may_consume_simulation"] is False, f"{margin_id} may-consume")
    require(
      receipt["simulation_state"] == "SimulationBlocked",
      f"{margin_id} simulation",
    )
    require(
      receipt["automatic_refresh_loop_allowed"] is False,
      f"{margin_id} refresh loop",
    )
    require(receipt["hardware_state"] == "HardwareDenied", f"{margin_id} hardware")
    require(
      receipt["hardware_authority"] == "moonmoon-safety-gate-only",
      f"{margin_id} hardware authority",
    )
    require(
      receipt["hardware_authority_change"] is False,
      f"{margin_id} hardware authority change",
    )
    require(receipt["hardware_denied"] is True, f"{margin_id} hardware denial")
    require(
      all(check["passed"] for check in receipt["validation_checks"]),
      f"{margin_id} failed validation check",
    )


def main() -> None:
  assert_index_manifest_readme()
  assert_workspace_payload()
  print("checked MoonBook reviewed work item receipt workspace")


if __name__ == "__main__":
  main()
