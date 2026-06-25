#!/usr/bin/env python3
"""Check MoonBook workspace materialization for reviewed fresh-evidence task."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_PATH = (
  WORKSPACE
  / "moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task.json"
)
TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json"
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
CLOSEOUT_TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
ENTRY_ID = (
  "moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task"
)
ENTRY_KIND = "MoonClawRemediationMarginReviewedFreshEvidenceTask"
ENTRY_REL_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-reviewed-fresh-evidence-task.json"
)
SOURCE_FILE = (
  "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json"
)
README_SOURCE = "Source MoonClaw remediation-margin reviewed fresh evidence task"
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-fresh-evidence-task"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
CLOSEOUT_TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
)
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": "operator-escalation",
  "illumination-northeast-stepout": "bounded-regeneration",
  "energy-window": "manual-freeze-verification",
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
  require(SOURCE_FILE in index["source_files"], "fresh task missing source file")
  require(ENTRY_REL_PATH in manifest["entry_paths"], "manifest missing fresh task")
  require(README_SOURCE in readme, "README missing fresh task source")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing fresh task entry")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, "unexpected fresh task entry kind")
  require(entry["path"] == ENTRY_REL_PATH, "unexpected fresh task entry path")
  for token in (
    "3 pending reviewed work item receipts",
    "fresh-evidence actions",
    "terrain=operator-escalation",
    "local-horizon=bounded-regeneration",
    "energy=manual-freeze-verification",
    "source receipt provenance",
    "accepted review provenance",
    "automatic refresh loop allowed false",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ):
    require(token in entry["summary"], f"summary missing {token!r}")


def assert_workspace_payload() -> None:
  generated_tasks = load_json(TASK_JSON)
  generated_receipts = load_json(RECEIPTS_JSON)
  generated_items = load_json(ITEMS_JSON)
  generated_plan = load_json(PLAN_JSON)[0]
  generated_closeout_task = load_json(CLOSEOUT_TASK_JSON)[0]
  wrapper = load_json(ENTRY_PATH)
  require(wrapper["workspace"] == "moonbook://moonmoon/first-trusted-square", "workspace changed")
  require(wrapper["site_id"] == "first-trusted-square", "site changed")
  entry = wrapper["entry"]
  require(entry["entry_id"] == ENTRY_ID, "entry id changed")
  require(entry["kind"] == ENTRY_KIND, "entry kind changed")
  payload = wrapper["payload"]
  require(payload["tasks"] == generated_tasks, "tasks diverge")
  require(payload["primary_task"] == generated_tasks[0], "primary task diverges")
  require(payload["source_receipts"] == generated_receipts, "source receipts diverge")
  require(payload["source_work_items"] == generated_items, "source work items diverge")
  require(payload["source_plan"] == generated_plan, "source plan diverges")
  require(payload["source_task"] == generated_closeout_task, "source task diverges")
  task = payload["primary_task"]
  require(task["task_id"] == TASK_ID, "task id changed")
  require(task["source_plan_id"] == PLAN_ID, "source plan id changed")
  require(
    payload["source_task"]["task_id"] == CLOSEOUT_TASK_ID,
    "closeout source task id changed",
  )
  require(
    task["source_review_transition_id"] == REVIEW_TRANSITION_ID,
    "task review transition changed",
  )
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

  receipt_ids = [receipt["receipt"]["receipt_id"] for receipt in generated_receipts]
  require(task["source_receipt_ids"] == receipt_ids, "source receipt ids diverge")
  require(task["pending_receipt_count"] == 3, "pending receipt count")
  require(set(task["pending_margin_ids"]) == set(EXPECTED_ACTIONS), "pending margins")
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
  require(task["hardware_authority_change"] is False, "hardware authority change")
  require(task["hardware_denied"] is True, "hardware denial")

  actions = {action["margin_id"]: action for action in task["fresh_evidence_actions"]}
  require(set(actions) == set(EXPECTED_ACTIONS), "fresh action margins")
  for margin_id, execution_mode in EXPECTED_ACTIONS.items():
    action = actions[margin_id]
    require(action["execution_mode"] == execution_mode, f"{margin_id} mode")
    require(action["source_receipt_id"] in receipt_ids, f"{margin_id} receipt")
    require(action["command"], f"{margin_id} command")
    require(action["acceptance_check"], f"{margin_id} check")


def main() -> None:
  assert_index_manifest_readme()
  assert_workspace_payload()
  print("checked MoonBook reviewed fresh evidence task workspace")


if __name__ == "__main__":
  main()
