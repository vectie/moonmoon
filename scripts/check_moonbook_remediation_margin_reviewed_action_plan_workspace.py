#!/usr/bin/env python3
"""Check MoonBook workspace materialization for reviewed MoonClaw action plan."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_PATH = (
  WORKSPACE
  / "moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan.json"
)
PLAN_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json"
)
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan"
ENTRY_KIND = "MoonClawRemediationMarginReviewedActionPlan"
SOURCE_FILE = (
  "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_ACTIONS = {
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
  entry_paths = set(manifest["entry_paths"])
  require(SOURCE_FILE in index["source_files"], "reviewed plan missing source file")
  require(
    "moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan.json"
    in entry_paths,
    "reviewed plan missing manifest entry path",
  )
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "reviewed plan missing index entry")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, "unexpected entry kind")
  require(
    entry["path"]
    == "moonclaw/first-trusted-square/remediation-margin-reviewed-action-plan.json",
    "unexpected entry path",
  )
  require("accepted" in entry["summary"], "summary missing accepted state")
  require("Accept closeout review" in entry["summary"], "summary missing review")
  require(
    "automatic refresh loop allowed false" in entry["summary"],
    "summary missing no-loop state",
  )
  require(
    "moonmoon-safety-gate-only" in entry["summary"],
    "summary missing hardware authority",
  )


def assert_workspace_payload() -> None:
  plan_source = load_json(PLAN_JSON)
  task_source = load_json(TASK_JSON)
  workspace_payload = load_json(ENTRY_PATH)
  require(workspace_payload["workspace"] == "moonbook://moonmoon/first-trusted-square", "workspace changed")
  require(workspace_payload["site_id"] == "first-trusted-square", "site changed")
  entry = workspace_payload["entry"]
  require(entry["entry_id"] == ENTRY_ID, "entry id changed")
  require(entry["kind"] == ENTRY_KIND, "entry kind changed")
  payload = workspace_payload["payload"]
  require(payload["primary_plan"] == plan_source[0], "primary plan diverges")
  require(payload["plans"] == plan_source, "plans diverge")
  require(payload["source_task"] == task_source[0], "source task diverges")
  plan = payload["primary_plan"]
  require(plan["plan_id"] == PLAN_ID, "plan id changed")
  require(plan["state"] == "Accepted", "plan state changed")
  require(plan["source_task_id"] == TASK_ID, "source task id changed")
  require(
    plan["source_review_transition_id"] == REVIEW_TRANSITION_ID,
    "review transition changed",
  )
  require(plan["source_review_decision"] == "Accept", "review decision changed")
  require(plan["may_consume_simulation"] is False, "may-consume changed")
  require(plan["simulation_state"] == "SimulationBlocked", "simulation changed")
  require(
    plan["automatic_refresh_loop_allowed"] is False,
    "automatic refresh loop was allowed",
  )
  require(plan["hardware_state"] == "HardwareDenied", "hardware changed")
  require(
    plan["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  require(
    plan["hardware_authority_change"] is False,
    "hardware authority change must remain false",
  )
  require(plan["hardware_denied"] is True, "hardware denial changed")
  actions = {action["margin_id"]: action for action in plan["actions"]}
  require(set(actions) == set(EXPECTED_ACTIONS), "unexpected reviewed actions")
  for margin_id, disposition in EXPECTED_ACTIONS.items():
    require(
      actions[margin_id]["disposition"] == disposition,
      f"{margin_id} disposition changed",
    )
  review = payload["review"]
  require(review["item_id"] == "moonclaw-remediation-margin-closeout-action-review", "review item changed")
  require(review["status"] == "Accepted", "review status changed")
  require(review["decision"] == "Accept", "review decision changed")
  require(
    review["transition"]["transition_id"] == REVIEW_TRANSITION_ID,
    "workspace review transition changed",
  )
  require(review["hardware_authority_change"] is False, "review hardware change")
  require(review["hardware_state"] == "HardwareDenied", "review hardware state")
  require(
    review["hardware_authority"] == "moonmoon-safety-gate-only",
    "review hardware authority changed",
  )


def main() -> None:
  assert_index_and_manifest()
  assert_workspace_payload()
  print("checked MoonBook reviewed remediation-margin action plan workspace")


if __name__ == "__main__":
  main()
