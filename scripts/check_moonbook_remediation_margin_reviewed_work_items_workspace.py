#!/usr/bin/env python3
"""Check MoonBook workspace materialization for reviewed MoonClaw work items."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_PATH = (
  WORKSPACE
  / "moonclaw/first-trusted-square/remediation-margin-reviewed-work-items.json"
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
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-reviewed-work-items"
ENTRY_KIND = "MoonClawRemediationMarginReviewedWorkItems"
ENTRY_REL_PATH = "moonclaw/first-trusted-square/remediation-margin-reviewed-work-items.json"
SOURCE_FILE = (
  "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_ITEMS = {
  "terrain-northeast-stepout": "EscalateToOperatorDecision",
  "illumination-northeast-stepout": "RetryWithNewEvidence",
  "energy-window": "FreezeUntilNewSourceEvidence",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_index_and_manifest() -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  require(SOURCE_FILE in index["source_files"], "work items missing source file")
  require(ENTRY_REL_PATH in manifest["entry_paths"], "manifest missing work items")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing work items entry")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, "unexpected work items entry kind")
  require(entry["path"] == ENTRY_REL_PATH, "unexpected work items entry path")
  for token in (
    "3 accepted reviewed work items",
    "terrain=EscalateToOperatorDecision",
    "local-horizon=RetryWithNewEvidence",
    "energy=FreezeUntilNewSourceEvidence",
    "automatic refresh loop allowed false",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ):
    require(token in entry["summary"], f"summary missing {token!r}")


def assert_workspace_payload() -> None:
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
  require(payload["work_items"] == generated_items, "work items diverge")
  require(payload["primary_work_item"] == generated_items[0], "primary item diverges")
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

  by_margin = {item["margin_id"]: item for item in payload["work_items"]}
  require(set(by_margin) == set(EXPECTED_ITEMS), "unexpected work item margins")
  for margin_id, disposition in EXPECTED_ITEMS.items():
    item = by_margin[margin_id]
    require(item["plan_id"] == PLAN_ID, f"{margin_id} plan changed")
    require(item["state"] == "Accepted", f"{margin_id} state changed")
    require(item["disposition"] == disposition, f"{margin_id} disposition changed")
    require(
      item["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{margin_id} review transition changed",
    )
    require(item["source_review_decision"] == "Accept", f"{margin_id} decision")
    require(item["may_consume_simulation"] is False, f"{margin_id} may-consume")
    require(
      item["simulation_state"] == "SimulationBlocked",
      f"{margin_id} simulation",
    )
    require(
      item["automatic_refresh_loop_allowed"] is False,
      f"{margin_id} refresh loop",
    )
    require(item["hardware_state"] == "HardwareDenied", f"{margin_id} hardware")
    require(
      item["hardware_authority"] == "moonmoon-safety-gate-only",
      f"{margin_id} hardware authority",
    )
    require(
      item["hardware_authority_change"] is False,
      f"{margin_id} hardware authority change",
    )
    require(item["hardware_denied"] is True, f"{margin_id} hardware denial")


def main() -> None:
  assert_index_and_manifest()
  assert_workspace_payload()
  print("checked MoonBook reviewed remediation-margin work items workspace")


if __name__ == "__main__":
  main()
