#!/usr/bin/env python3
"""Check MoonRobo regenerated readiness action receipt closeout."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CLOSEOUT_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json"
)
CLOSEOUT_MD = (
  ROOT
  / "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.md"
)
ACTION_RECEIPTS_PATH = (
  "output/moonclaw/"
  "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json"
)
ACTION_RECEIPTS_JSON = ROOT / ACTION_RECEIPTS_PATH
WORKSPACE_PATH = (
  "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/"
  "regenerated-receipt-readiness-fresh-evidence-action-receipts.json"
)
CLOSEOUT_ID = (
  "moonrobo/first-trusted-square/"
  "regenerated-receipt-readiness-v1/action-receipt-closeout"
)
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
EXPECTED_MODES = [
  "operator-escalation",
  "bounded-regeneration",
  "manual-freeze-verification",
]
EXPECTED_VALIDATIONS = {
  "action-receipts-present",
  "source-readiness-gate-preserved",
  "source-action-provenance-present",
  "execution-modes-preserved",
  "fresh-evidence-still-pending",
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
  closeout = load_json(CLOSEOUT_JSON)
  action_receipts = load_json(ACTION_RECEIPTS_JSON)
  markdown = CLOSEOUT_MD.read_text(encoding="utf-8")

  require(closeout["closeout_id"] == CLOSEOUT_ID, closeout["closeout_id"])
  require(closeout["site_id"] == "first-trusted-square", closeout["site_id"])
  require(closeout["route_id"] == "northeast-stepout", closeout["route_id"])
  require(
    closeout["source_action_receipt_bundle_path"] == ACTION_RECEIPTS_PATH,
    "bad source action receipt path",
  )
  require(closeout["source_workspace_entry_path"] == WORKSPACE_PATH, "bad workspace path")
  require(closeout["source_readiness_gate_id"] == GATE_ID, "bad gate id")
  require(
    closeout["source_readiness_state"]
    == "RegeneratedReceiptsPendingFreshEvidence",
    closeout["source_readiness_state"],
  )
  require(closeout["source_task_id"] == TASK_ID, closeout["source_task_id"])
  require(
    closeout["closeout_state"]
    == "RegeneratedReceiptsStillPendingFreshEvidence",
    closeout["closeout_state"],
  )
  require(closeout["source_action_receipt_count"] == len(action_receipts) == 3, "bad action count")
  require(closeout["source_receipt_count"] == 3, "bad receipt count")
  require(closeout["ready_receipt_count"] == 0, "ready count changed")
  require(closeout["pending_receipt_count"] == 3, "pending count changed")
  require(closeout["margin_ids"] == EXPECTED_MARGINS, "margin ids changed")
  require(closeout["refresh_ids"] == EXPECTED_REFRESHES, "refresh ids changed")
  require(closeout["execution_modes"] == EXPECTED_MODES, "execution modes changed")
  require(not closeout["may_consume_simulation"], "simulation consumption opened")
  require(closeout["simulation_state"] == "SimulationBlocked", "simulation changed")
  require(not closeout["automatic_refresh_loop_allowed"], "refresh loop opened")
  require(closeout["hardware_state"] == "HardwareDenied", "hardware changed")
  require(
    closeout["hardware_authority"] == "moonmoon-safety-gate-only",
    closeout["hardware_authority"],
  )
  require(closeout["hardware_denied"], "hardware no longer denied")

  receipts_by_margin = {
    receipt["action_result"]["margin_id"]: receipt for receipt in action_receipts
  }
  require(set(receipts_by_margin) == set(EXPECTED_MARGINS), "receipt margins changed")
  require(
    closeout["source_receipt_ids"]
    == [
      receipts_by_margin[margin]["source_receipt_id"]
      for margin in EXPECTED_MARGINS
    ],
    "source receipt ids diverge",
  )
  require(
    closeout["source_action_receipt_ids"]
    == [
      receipts_by_margin[margin]["source_action_receipt_id"]
      for margin in EXPECTED_MARGINS
    ],
    "source action receipt ids diverge",
  )

  for margin_id, mode, refresh_id in zip(
    EXPECTED_MARGINS,
    EXPECTED_MODES,
    EXPECTED_REFRESHES,
    strict=True,
  ):
    receipt = receipts_by_margin[margin_id]
    result = receipt["action_result"]
    require(receipt["source_task_id"] == TASK_ID, margin_id)
    require(receipt["source_readiness_gate_id"] == GATE_ID, margin_id)
    require(
      receipt["source_readiness_state"]
      == "RegeneratedReceiptsPendingFreshEvidence",
      margin_id,
    )
    require(receipt["action_state"] == "RegeneratedFreshEvidenceActionsRecorded", margin_id)
    require(result["refresh_id"] == refresh_id, margin_id)
    require(result["execution_mode"] == mode, margin_id)
    require("remains pending" in result["current_state"], margin_id)
    require("readiness is recomputed" in result["current_state"], margin_id)
    require(not receipt["may_consume_simulation"], margin_id)
    require(receipt["simulation_state"] == "SimulationBlocked", margin_id)
    require(not receipt["automatic_refresh_loop_allowed"], margin_id)
    require(receipt["hardware_state"] == "HardwareDenied", margin_id)
    require(receipt["hardware_authority"] == "moonmoon-safety-gate-only", margin_id)
    require(not receipt["hardware_authority_change"], margin_id)
    require(receipt["hardware_denied"], margin_id)

  validations = {
    check["validation_id"]: check for check in closeout["validation_checks"]
  }
  require(set(validations) == EXPECTED_VALIDATIONS, "validation ids changed")
  for validation_id, check in validations.items():
    require(check["passed"], f"{validation_id} failed")
    require(check["note"], f"{validation_id} missing note")

  for term in [
    "MoonRobo Regenerated Receipt Readiness Action Receipt Closeout",
    "RegeneratedReceiptsStillPendingFreshEvidence",
    "RegeneratedReceiptsPendingFreshEvidence",
    "3",
    *EXPECTED_MARGINS,
    *EXPECTED_REFRESHES,
    *EXPECTED_MODES,
    "simulation-blocked",
    "hardware-denied",
    "moonmoon-safety-gate-only",
  ]:
    require(term in markdown, f"missing markdown term {term!r}")

  print("checked MoonRobo regenerated readiness action receipt closeout")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
