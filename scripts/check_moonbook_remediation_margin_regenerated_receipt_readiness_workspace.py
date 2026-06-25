#!/usr/bin/env python3
"""Check MoonRobo regenerated receipt readiness is durable in MoonBook."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = (
  "moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness"
)
ENTRY_KIND = "MoonroboRemediationMarginRegeneratedReceiptReadiness"
ENTRY_PATH = (
  "moonrobo/first-trusted-square/remediation-margin-regenerated-receipt-readiness.json"
)
SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
SOURCE_JSON = ROOT / SOURCE_PATH
SOURCE_RECEIPTS_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
SOURCE_RECEIPTS_JSON = ROOT / SOURCE_RECEIPTS_PATH
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
EXPECTED_MODES = [
  "operator-escalation",
  "bounded-regeneration",
  "manual-freeze-verification",
]
EXPECTED_VALIDATIONS = {
  "regenerated-receipts-present",
  "all-receipts-pending-fresh-evidence",
  "source-action-provenance-present",
  "execution-modes-preserved",
  "no-automatic-refresh-loop",
  "simulation-consumption-blocked",
  "hardware-denial-preserved",
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
  source = load_json(SOURCE_JSON)
  source_receipts = load_json(SOURCE_RECEIPTS_JSON)
  wrapper = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing regenerated receipt readiness")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, entry["kind"])
  require(entry["path"] == ENTRY_PATH, entry["path"])
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing entry path")
  require(SOURCE_PATH in index["source_files"], "index missing source file")
  require(SOURCE_RECEIPTS_PATH in index["source_files"], "index missing receipts")
  require(SOURCE_PATH in readme, "README missing readiness source")

  for term in [
    "RegeneratedReceiptsPendingFreshEvidence",
    "3 pending regenerated receipts",
    "0 ready receipts",
    *EXPECTED_MARGINS,
    *EXPECTED_REFRESHES,
    *EXPECTED_MODES,
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
  require(wrapper["workspace"] == "moonbook://moonmoon/first-trusted-square", "workspace changed")
  require(wrapper["site_id"] == "first-trusted-square", "site changed")
  payload = wrapper["payload"]
  require(payload == source, "workspace payload diverges from MoonRobo source")
  require(payload["readiness_gate_id"] == source["readiness_gate_id"], "gate id changed")
  require(payload["readiness_state"] == "RegeneratedReceiptsPendingFreshEvidence", "state changed")
  require(payload["source_receipt_bundle_path"] == SOURCE_RECEIPTS_PATH, "bad source bundle")
  require(payload["source_workspace_entry_path"].endswith("remediation-margin-regenerated-reviewed-work-item-receipts.json"), "bad source workspace path")
  require(payload["source_receipt_count"] == len(source_receipts) == 3, "bad source count")
  require(payload["ready_receipt_count"] == 0, "ready count changed")
  require(payload["pending_receipt_count"] == 3, "pending count changed")
  require(payload["pending_margin_ids"] == EXPECTED_MARGINS, "margin ids changed")
  require(payload["pending_refresh_ids"] == EXPECTED_REFRESHES, "refresh ids changed")
  require(payload["execution_modes"] == EXPECTED_MODES, "execution modes changed")
  require(not payload["may_consume_simulation"], "simulation consumption opened")
  require(payload["simulation_state"] == "SimulationBlocked", "simulation state changed")
  require(not payload["automatic_refresh_loop_allowed"], "automatic refresh loop opened")
  require(payload["hardware_state"] == "HardwareDenied", "hardware state changed")
  require(payload["hardware_authority"] == "moonmoon-safety-gate-only", "authority changed")
  require(payload["hardware_denied"], "hardware no longer denied")

  validations = {check["validation_id"]: check for check in payload["validation_checks"]}
  require(set(validations) == EXPECTED_VALIDATIONS, "validation ids changed")
  for validation_id, check in validations.items():
    require(check["passed"], f"{validation_id} failed")
    require(check["note"], f"{validation_id} missing note")

  receipt_source_ids = [receipt["source_receipt_id"] for receipt in source_receipts]
  action_receipt_source_ids = [
    receipt["source_action_receipt_id"] for receipt in source_receipts
  ]
  require(payload["source_receipt_ids"] == receipt_source_ids, "source receipt ids diverge")
  require(
    payload["source_action_receipt_ids"] == action_receipt_source_ids,
    "source action receipt ids diverge",
  )

  print("checked MoonBook regenerated receipt readiness workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
