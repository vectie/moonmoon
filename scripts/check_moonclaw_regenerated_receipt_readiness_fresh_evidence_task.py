#!/usr/bin/env python3
"""Check MoonClaw fresh-evidence task from regenerated receipt readiness."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TASK_PATH = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json"
)
MARKDOWN_PATH = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.md"
)
READINESS_PATH = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
TASK_ID = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task"
)
GATE_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness"
)
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
REFRESH_IDS = [
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
]
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": (
    "terrain",
    "operator-escalation",
    "check_selected_route_terrain_remediation.py",
  ),
  "illumination-northeast-stepout": (
    "local-horizon",
    "bounded-regeneration",
    "check_selected_route_horizon_model.py",
  ),
  "energy-window": (
    "energy",
    "manual-freeze-verification",
    "check_energy_margin_remediation.py",
  ),
}


def require(condition: bool, message: str) -> None:
  if not condition:
    raise AssertionError(message)


def load_json(path: Path) -> Any:
  return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
  tasks = load_json(TASK_PATH)
  readiness = load_json(READINESS_PATH)
  markdown = MARKDOWN_PATH.read_text(encoding="utf-8")

  require(isinstance(tasks, list), "task output must be a list")
  require(len(tasks) == 1, "expected one regenerated readiness fresh-evidence task")
  task = tasks[0]
  require(task["task_id"] == TASK_ID, task["task_id"])
  require(task["site_id"] == "first-trusted-square", task["site_id"])
  require(task["route_id"] == "northeast-stepout", task["route_id"])
  require(task["priority"] == "Critical", task["priority"])
  require(task["state"] == "Accepted", task["state"])
  require(task["source_readiness_gate_id"] == GATE_ID, task["source_readiness_gate_id"])
  require(
    task["source_readiness_state"] == "RegeneratedReceiptsPendingFreshEvidence",
    task["source_readiness_state"],
  )
  require(
    task["source_receipt_bundle_path"]
    == readiness["source_receipt_bundle_path"],
    task["source_receipt_bundle_path"],
  )
  require(
    task["source_workspace_entry_path"]
    == readiness["source_workspace_entry_path"],
    task["source_workspace_entry_path"],
  )
  require(task["source_receipt_count"] == 3, task["source_receipt_count"])
  require(task["pending_receipt_count"] == 3, task["pending_receipt_count"])
  require(task["ready_receipt_count"] == 0, task["ready_receipt_count"])
  require(task["pending_margin_ids"] == MARGIN_IDS, task["pending_margin_ids"])
  require(task["pending_refresh_ids"] == REFRESH_IDS, task["pending_refresh_ids"])
  require(
    task["source_receipt_ids"] == readiness["source_receipt_ids"],
    task["source_receipt_ids"],
  )
  require(
    task["source_action_receipt_ids"] == readiness["source_action_receipt_ids"],
    task["source_action_receipt_ids"],
  )
  require(task["may_consume_simulation"] is False, task)
  require(task["simulation_state"] == "SimulationBlocked", task["simulation_state"])
  require(task["automatic_refresh_loop_allowed"] is False, task)
  require(task["hardware_state"] == "HardwareDenied", task["hardware_state"])
  require(task["hardware_authority"] == "moonmoon-safety-gate-only", task)
  require(task["hardware_authority_change"] is False, task)
  require(task["hardware_denied"] is True, task)
  require(len(task["acceptance_criteria"]) == 5, task["acceptance_criteria"])

  actions = {action["margin_id"]: action for action in task["fresh_evidence_actions"]}
  require(set(actions) == set(EXPECTED_ACTIONS), actions)
  for rank, margin_id in enumerate(MARGIN_IDS, start=1):
    action = actions[margin_id]
    domain, mode, check = EXPECTED_ACTIONS[margin_id]
    require(action["rank"] == rank, action)
    require(action["action_id"].endswith(margin_id), action)
    require(action["source_receipt_id"] in task["source_receipt_ids"], action)
    require(
      action["source_action_receipt_id"] in task["source_action_receipt_ids"],
      action,
    )
    require(action["refresh_id"] in REFRESH_IDS, action)
    require(action["blocker_domain"] == domain, action)
    require(action["execution_mode"] == mode, action)
    require(action["required_evidence"], action)
    require(action["target_artifact_path"], action)
    require(action["evidence_path"], action)
    require(action["command"], action)
    require(check in action["acceptance_check"], action)
    require("pending" in action["next_action"], action)

  for term in [
    "MoonClaw Regenerated Receipt Readiness Fresh Evidence Tasks",
    "RegeneratedReceiptsPendingFreshEvidence",
    "pending receipts: 3",
    "ready receipts: 0",
    "source action receipt",
    "operator-escalation",
    "bounded-regeneration",
    "manual-freeze-verification",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware authority change: false",
    "moonmoon-safety-gate-only",
  ]:
    require(term in markdown, f"markdown missing {term}")

  print("checked MoonClaw regenerated receipt readiness fresh-evidence task")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
