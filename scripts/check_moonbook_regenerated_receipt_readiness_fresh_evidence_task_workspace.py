#!/usr/bin/env python3
"""Check MoonClaw regenerated readiness fresh-evidence task is durable in MoonBook."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task"
)
ENTRY_KIND = "MoonClawRegeneratedReceiptReadinessFreshEvidenceTask"
ENTRY_PATH = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-fresh-evidence-task.json"
)
SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json"
)
SOURCE_JSON = ROOT / SOURCE_PATH
READINESS_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
READINESS_JSON = ROOT / READINESS_PATH
SOURCE_RECEIPTS_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
SOURCE_RECEIPTS_JSON = ROOT / SOURCE_RECEIPTS_PATH
SOURCE_ACTION_RECEIPTS_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json"
)
SOURCE_ACTION_RECEIPTS_JSON = ROOT / SOURCE_ACTION_RECEIPTS_PATH
TASK_ID = (
  "moonclaw/first-trusted-square/regenerated-receipt-readiness-v1/fresh-evidence-task"
)
GATE_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness"
)
EXPECTED_MARGINS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
EXPECTED_REFRESHES = [
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


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise AssertionError(message)


def main() -> int:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  source_tasks = load_json(SOURCE_JSON)
  readiness = load_json(READINESS_JSON)
  source_receipts = load_json(SOURCE_RECEIPTS_JSON)
  source_action_receipts = load_json(SOURCE_ACTION_RECEIPTS_JSON)
  wrapper = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")

  require(isinstance(source_tasks, list), "source tasks must be a list")
  require(len(source_tasks) == 1, "expected one source task")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing regenerated readiness task")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, entry["kind"])
  require(entry["path"] == ENTRY_PATH, entry["path"])
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing entry path")
  require(SOURCE_PATH in index["source_files"], "index missing source task")
  require(READINESS_PATH in index["source_files"], "index missing readiness source")
  require(SOURCE_RECEIPTS_PATH in index["source_files"], "index missing source receipts")
  require(
    SOURCE_ACTION_RECEIPTS_PATH in index["source_files"],
    "index missing source action receipts",
  )
  require(SOURCE_PATH in readme, "README missing task source")

  for term in [
    "RegeneratedReceiptsPendingFreshEvidence",
    "3 pending regenerated receipts",
    "0 ready receipts",
    *EXPECTED_MARGINS,
    *EXPECTED_REFRESHES,
    "terrain=operator-escalation",
    "local-horizon=bounded-regeneration",
    "energy=manual-freeze-verification",
    "source action receipt provenance",
    "source readiness gate",
    "no automatic refresh loop",
    "no simulation consumption",
    "simulation-blocked",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    require(term in entry["summary"], f"summary missing {term!r}")

  require(wrapper["entry"] == entry, "wrapper entry diverges from index")
  require(wrapper["workspace"] == "moonbook://moonmoon/first-trusted-square", "workspace changed")
  require(wrapper["site_id"] == "first-trusted-square", "site changed")
  require(
    wrapper["generated_by"] == "scripts/materialize_moonbook_workspace.py",
    "generator changed",
  )

  payload = wrapper["payload"]
  require(payload["primary_task"] == source_tasks[0], "primary task diverges")
  require(payload["tasks"] == source_tasks, "task list diverges")
  require(payload["source_readiness"] == readiness, "readiness source diverges")
  require(payload["source_receipts"] == source_receipts, "receipt source diverges")
  require(
    payload["source_action_receipts"] == source_action_receipts,
    "source action receipt source diverges",
  )

  task = payload["primary_task"]
  require(task["task_id"] == TASK_ID, task["task_id"])
  require(task["source_readiness_gate_id"] == GATE_ID, task["source_readiness_gate_id"])
  require(
    task["source_readiness_state"] == "RegeneratedReceiptsPendingFreshEvidence",
    task["source_readiness_state"],
  )
  require(task["source_receipt_count"] == 3, task["source_receipt_count"])
  require(task["pending_receipt_count"] == 3, task["pending_receipt_count"])
  require(task["ready_receipt_count"] == 0, task["ready_receipt_count"])
  require(task["pending_margin_ids"] == EXPECTED_MARGINS, task["pending_margin_ids"])
  require(task["pending_refresh_ids"] == EXPECTED_REFRESHES, task["pending_refresh_ids"])
  require(task["source_receipt_ids"] == readiness["source_receipt_ids"], "bad receipt ids")
  require(
    task["source_action_receipt_ids"] == readiness["source_action_receipt_ids"],
    "bad source action receipt ids",
  )
  require(task["may_consume_simulation"] is False, "simulation consumption opened")
  require(task["simulation_state"] == "SimulationBlocked", task["simulation_state"])
  require(
    task["automatic_refresh_loop_allowed"] is False,
    "automatic refresh loop opened",
  )
  require(task["hardware_state"] == "HardwareDenied", task["hardware_state"])
  require(task["hardware_authority"] == "moonmoon-safety-gate-only", task)
  require(task["hardware_authority_change"] is False, task)
  require(task["hardware_denied"] is True, task)
  require(len(task["acceptance_criteria"]) == 5, "criteria changed")

  actions = {action["margin_id"]: action for action in task["fresh_evidence_actions"]}
  require(set(actions) == set(EXPECTED_ACTIONS), "action margins changed")
  for rank, margin_id in enumerate(EXPECTED_MARGINS, start=1):
    action = actions[margin_id]
    domain, mode, check = EXPECTED_ACTIONS[margin_id]
    require(action["rank"] == rank, action)
    require(action["source_receipt_id"] in task["source_receipt_ids"], action)
    require(
      action["source_action_receipt_id"] in task["source_action_receipt_ids"],
      action,
    )
    require(action["refresh_id"] in EXPECTED_REFRESHES, action)
    require(action["blocker_domain"] == domain, action)
    require(action["execution_mode"] == mode, action)
    require(check in action["acceptance_check"], action)

  print("checked MoonBook regenerated readiness fresh-evidence task workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
