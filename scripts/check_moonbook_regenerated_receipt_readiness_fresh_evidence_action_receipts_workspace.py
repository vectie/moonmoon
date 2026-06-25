#!/usr/bin/env python3
"""Check regenerated readiness action receipts are durable in MoonBook."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = (
  "moonclaw/first-trusted-square/"
  "regenerated-receipt-readiness-fresh-evidence-action-receipts"
)
ENTRY_KIND = "MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipts"
ENTRY_PATH = (
  "moonclaw/first-trusted-square/"
  "regenerated-receipt-readiness-fresh-evidence-action-receipts.json"
)
SOURCE_PATH = (
  "output/moonclaw/"
  "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json"
)
SOURCE_JSON = ROOT / SOURCE_PATH
TASK_PATH = (
  "output/moonclaw/"
  "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json"
)
TASK_JSON = ROOT / TASK_PATH
READINESS_PATH = (
  "output/moonrobo/"
  "first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
READINESS_JSON = ROOT / READINESS_PATH
SOURCE_RECEIPTS_PATH = (
  "output/moonclaw/"
  "first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
SOURCE_RECEIPTS_JSON = ROOT / SOURCE_RECEIPTS_PATH
SOURCE_ACTION_RECEIPTS_PATH = (
  "output/moonclaw/"
  "first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json"
)
SOURCE_ACTION_RECEIPTS_JSON = ROOT / SOURCE_ACTION_RECEIPTS_PATH
TASK_ID = (
  "moonclaw/first-trusted-square/"
  "regenerated-receipt-readiness-v1/fresh-evidence-task"
)
GATE_ID = (
  "moonrobo/first-trusted-square/"
  "remediation-margin-v1/regenerated-receipt-readiness"
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
  "terrain-northeast-stepout": ("terrain", "operator-escalation"),
  "illumination-northeast-stepout": ("local-horizon", "bounded-regeneration"),
  "energy-window": ("energy", "manual-freeze-verification"),
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
  generated_receipts = load_json(SOURCE_JSON)
  source_tasks = load_json(TASK_JSON)
  readiness = load_json(READINESS_JSON)
  source_receipts = load_json(SOURCE_RECEIPTS_JSON)
  source_action_receipts = load_json(SOURCE_ACTION_RECEIPTS_JSON)
  wrapper = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")

  require(len(generated_receipts) == 3, "expected three generated receipts")
  require(len(source_tasks) == 1, "expected one source task")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing regenerated action receipts")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, entry["kind"])
  require(entry["path"] == ENTRY_PATH, entry["path"])
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing entry")
  require(SOURCE_PATH in index["source_files"], "index missing receipt source")
  require(TASK_PATH in index["source_files"], "index missing task source")
  require(READINESS_PATH in index["source_files"], "index missing readiness source")
  require(
    SOURCE_RECEIPTS_PATH in index["source_files"],
    "index missing source receipts",
  )
  require(
    SOURCE_ACTION_RECEIPTS_PATH in index["source_files"],
    "index missing source action receipts",
  )
  require(SOURCE_PATH in readme, "README missing receipt source")

  for term in [
    "3 regenerated readiness fresh-evidence action receipts",
    "RegeneratedFreshEvidenceActionsRecorded",
    "RegeneratedReceiptsPendingFreshEvidence",
    *EXPECTED_MARGINS,
    *EXPECTED_REFRESHES,
    "terrain=operator-escalation",
    "local-horizon=bounded-regeneration",
    "energy=manual-freeze-verification",
    "source readiness gate",
    "source receipt provenance",
    "source action receipt provenance",
    "no automatic refresh loop",
    "no simulation consumption",
    "simulation-blocked",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    require(term in entry["summary"], f"summary missing {term!r}")

  require(wrapper["entry"] == entry, "wrapper entry diverges from index")
  require(
    wrapper["workspace"] == "moonbook://moonmoon/first-trusted-square",
    "workspace changed",
  )
  require(wrapper["site_id"] == "first-trusted-square", "site changed")
  require(
    wrapper["generated_by"] == "scripts/materialize_moonbook_workspace.py",
    "generator changed",
  )

  payload = wrapper["payload"]
  require(payload["primary_receipt"] == generated_receipts[0], "primary diverges")
  require(payload["receipts"] == generated_receipts, "receipts diverge")
  require(payload["source_task"] == source_tasks[0], "task source diverges")
  require(payload["source_readiness"] == readiness, "readiness source diverges")
  require(payload["source_receipts"] == source_receipts, "receipt source diverges")
  require(
    payload["source_action_receipts"] == source_action_receipts,
    "action receipt source diverges",
  )

  task = payload["source_task"]
  require(task["task_id"] == TASK_ID, task["task_id"])
  require(task["source_readiness_gate_id"] == GATE_ID, task["source_readiness_gate_id"])
  require(task["source_receipt_ids"] == readiness["source_receipt_ids"], "bad receipt ids")
  require(
    task["source_action_receipt_ids"] == readiness["source_action_receipt_ids"],
    "bad source action receipt ids",
  )

  receipts = {
    receipt["action_result"]["margin_id"]: receipt
    for receipt in payload["receipts"]
  }
  require(set(receipts) == set(EXPECTED_ACTIONS), "receipt margins changed")
  for rank, margin_id in enumerate(EXPECTED_MARGINS, start=1):
    receipt = receipts[margin_id]
    result = receipt["action_result"]
    domain, mode = EXPECTED_ACTIONS[margin_id]
    require(receipt["source_task_id"] == TASK_ID, receipt)
    require(receipt["source_readiness_gate_id"] == GATE_ID, receipt)
    require(
      receipt["source_readiness_state"]
      == "RegeneratedReceiptsPendingFreshEvidence",
      receipt,
    )
    require(receipt["source_receipt_count"] == 3, receipt)
    require(receipt["pending_receipt_count"] == 3, receipt)
    require(receipt["ready_receipt_count"] == 0, receipt)
    require(receipt["source_receipt_ids"] == task["source_receipt_ids"], receipt)
    require(
      receipt["source_action_receipt_ids"] == task["source_action_receipt_ids"],
      receipt,
    )
    require(receipt["source_receipt_id"] in task["source_receipt_ids"], receipt)
    require(
      receipt["source_action_receipt_id"] in task["source_action_receipt_ids"],
      receipt,
    )
    require(receipt["action_state"] == "RegeneratedFreshEvidenceActionsRecorded", receipt)
    require(result["rank"] == rank, result)
    require(result["margin_id"] == margin_id, result)
    require(result["refresh_id"] in EXPECTED_REFRESHES, result)
    require(result["blocker_domain"] == domain, result)
    require(result["execution_mode"] == mode, result)
    require(result["source_readiness_gate_id"] == GATE_ID, result)
    require(result["source_receipt_id"] == receipt["source_receipt_id"], result)
    require(
      result["source_action_receipt_id"] == receipt["source_action_receipt_id"],
      result,
    )
    require(result["required_evidence"], result)
    require(result["target_artifact_path"], result)
    require(result["evidence_path"], result)
    require(result["command"], result)
    require(result["acceptance_check"], result)
    require("readiness is recomputed" in result["current_state"], result)
    require(receipt["may_consume_simulation"] is False, receipt)
    require(receipt["simulation_state"] == "SimulationBlocked", receipt)
    require(receipt["automatic_refresh_loop_allowed"] is False, receipt)
    require(receipt["hardware_state"] == "HardwareDenied", receipt)
    require(receipt["hardware_authority"] == "moonmoon-safety-gate-only", receipt)
    require(receipt["hardware_authority_change"] is False, receipt)
    require(receipt["hardware_denied"] is True, receipt)
    require(
      all(check["passed"] for check in receipt["validation_checks"]),
      receipt,
    )

  print("checked MoonBook regenerated readiness action receipt workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
