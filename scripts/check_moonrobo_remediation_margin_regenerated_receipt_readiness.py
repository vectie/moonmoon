#!/usr/bin/env python3
"""Check the MoonRobo regenerated receipt readiness gate."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
GATE_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
GATE_MD = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.md"
)
RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
WORKSPACE_ENTRY = (
  ROOT
  / "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json"
)
GATE_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/regenerated-receipt-readiness"
)
RECEIPTS_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
WORKSPACE_PATH = (
  "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/remediation-margin-regenerated-reviewed-work-item-receipts.json"
)
EXPECTED_MODES = {
  "terrain-northeast-stepout": "operator-escalation",
  "illumination-northeast-stepout": "bounded-regeneration",
  "energy-window": "manual-freeze-verification",
}
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
  gate = load_json(GATE_JSON)
  receipts = load_json(RECEIPTS_JSON)
  workspace_entry = load_json(WORKSPACE_ENTRY)
  markdown = GATE_MD.read_text(encoding="utf-8")

  require(gate["readiness_gate_id"] == GATE_ID, gate["readiness_gate_id"])
  require(gate["site_id"] == "first-trusted-square", gate["site_id"])
  require(gate["route_id"] == "northeast-stepout", gate["route_id"])
  require(gate["source_receipt_bundle_path"] == RECEIPTS_PATH, "bad source path")
  require(gate["source_workspace_entry_path"] == WORKSPACE_PATH, "bad workspace path")
  require(gate["source_receipt_count"] == len(receipts) == 3, "bad receipt count")
  require(gate["ready_receipt_count"] == 0, "ready receipts must remain zero")
  require(gate["pending_receipt_count"] == 3, "pending receipts must remain three")
  require(
    gate["readiness_state"] == "RegeneratedReceiptsPendingFreshEvidence",
    gate["readiness_state"],
  )
  require(not gate["may_consume_simulation"], "gate may consume simulation")
  require(gate["simulation_state"] == "SimulationBlocked", "simulation changed")
  require(
    not gate["automatic_refresh_loop_allowed"],
    "automatic refresh loop opened",
  )
  require(gate["hardware_state"] == "HardwareDenied", "hardware changed")
  require(
    gate["hardware_authority"] == "moonmoon-safety-gate-only",
    gate["hardware_authority"],
  )
  require(gate["hardware_denied"], "hardware no longer denied")

  receipt_by_margin = {
    receipt["work_item_result"]["margin_id"]: receipt for receipt in receipts
  }
  require(set(receipt_by_margin) == set(EXPECTED_MODES), receipt_by_margin)
  require(gate["pending_margin_ids"] == list(EXPECTED_MODES), "bad margins")
  require(
    gate["pending_refresh_ids"]
    == [receipt_by_margin[margin]["work_item_result"]["refresh_id"] for margin in EXPECTED_MODES],
    "bad refresh ids",
  )
  require(
    gate["source_receipt_ids"]
    == [receipt_by_margin[margin]["source_receipt_id"] for margin in EXPECTED_MODES],
    "bad source receipt ids",
  )
  require(
    gate["source_action_receipt_ids"]
    == [receipt_by_margin[margin]["source_action_receipt_id"] for margin in EXPECTED_MODES],
    "bad source action receipt ids",
  )
  require(gate["execution_modes"] == list(EXPECTED_MODES.values()), "bad modes")

  for margin_id, expected_mode in EXPECTED_MODES.items():
    receipt = receipt_by_margin[margin_id]
    require(receipt["result_state"] == "ReviewedWorkItemsCarriedForward", margin_id)
    require(
      receipt["work_item_result"]["status"]
      == "ReviewedWorkItemPendingFreshEvidence",
      margin_id,
    )
    require(receipt["execution_mode"] == expected_mode, margin_id)
    require(not receipt["may_consume_simulation"], margin_id)
    require(receipt["simulation_state"] == "SimulationBlocked", margin_id)
    require(not receipt["automatic_refresh_loop_allowed"], margin_id)
    require(receipt["hardware_state"] == "HardwareDenied", margin_id)
    require(receipt["hardware_authority"] == "moonmoon-safety-gate-only", margin_id)
    require(not receipt["hardware_authority_change"], margin_id)
    require(receipt["hardware_denied"], margin_id)

  validations = {check["validation_id"]: check for check in gate["validation_checks"]}
  require(set(validations) == EXPECTED_VALIDATIONS, validations)
  for validation_id, check in validations.items():
    require(check["passed"], validation_id)
    require(check["note"], validation_id)

  workspace_payload = workspace_entry["payload"]
  require(
    workspace_payload["receipts"] == receipts,
    "workspace receipt payload diverges",
  )
  for term in [
    "MoonRobo Remediation Margin Regenerated Receipt Readiness",
    "RegeneratedReceiptsPendingFreshEvidence",
    "simulation-blocked",
    "hardware-denied",
    *EXPECTED_MODES,
    *EXPECTED_MODES.values(),
  ]:
    require(term in markdown, f"missing markdown term {term!r}")

  print("checked MoonRobo regenerated receipt readiness gate")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
