#!/usr/bin/env python3
"""Check regenerated readiness action receipt closeout is durable in MoonBook."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = (
  "moonrobo/first-trusted-square/"
  "regenerated-receipt-readiness-action-receipt-closeout"
)
ENTRY_KIND = "MoonroboRegeneratedReceiptReadinessActionReceiptCloseout"
ENTRY_PATH = (
  "moonrobo/first-trusted-square/"
  "regenerated-receipt-readiness-action-receipt-closeout.json"
)
SOURCE_PATH = (
  "output/moonrobo/"
  "first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json"
)
SOURCE_JSON = ROOT / SOURCE_PATH
ACTION_RECEIPTS_PATH = (
  "output/moonclaw/"
  "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json"
)
ACTION_RECEIPTS_JSON = ROOT / ACTION_RECEIPTS_PATH
READINESS_PATH = (
  "output/moonrobo/"
  "first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
READINESS_JSON = ROOT / READINESS_PATH
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
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  source = load_json(SOURCE_JSON)
  action_receipts = load_json(ACTION_RECEIPTS_JSON)
  readiness = load_json(READINESS_JSON)
  wrapper = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "index missing closeout entry")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, entry["kind"])
  require(entry["path"] == ENTRY_PATH, entry["path"])
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing closeout")
  require(SOURCE_PATH in index["source_files"], "index missing closeout source")
  require(
    ACTION_RECEIPTS_PATH in index["source_files"],
    "index missing action receipt source",
  )
  require(READINESS_PATH in index["source_files"], "index missing readiness source")
  require(SOURCE_PATH in readme, "README missing closeout source")

  for term in [
    "RegeneratedReceiptsStillPendingFreshEvidence",
    "RegeneratedReceiptsPendingFreshEvidence",
    "3 pending regenerated receipts",
    "0 ready receipts",
    "3 fresh-evidence action receipts",
    *EXPECTED_MARGINS,
    *EXPECTED_REFRESHES,
    *EXPECTED_MODES,
    "source readiness gate",
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
  require(payload["closeout"] == source, "closeout payload diverges")
  require(
    payload["source_action_receipts"] == action_receipts,
    "action receipt payload diverges",
  )
  require(payload["source_readiness"] == readiness, "readiness payload diverges")

  closeout = payload["closeout"]
  require(closeout["closeout_state"] == "RegeneratedReceiptsStillPendingFreshEvidence", "state changed")
  require(
    closeout["source_readiness_state"]
    == "RegeneratedReceiptsPendingFreshEvidence",
    "source readiness state changed",
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

  receipt_by_margin = {
    receipt["action_result"]["margin_id"]: receipt for receipt in action_receipts
  }
  require(set(receipt_by_margin) == set(EXPECTED_MARGINS), "receipt margins changed")
  require(
    closeout["source_receipt_ids"]
    == [
      receipt_by_margin[margin]["source_receipt_id"]
      for margin in EXPECTED_MARGINS
    ],
    "source receipt ids diverge",
  )
  require(
    closeout["source_action_receipt_ids"]
    == [
      receipt_by_margin[margin]["source_action_receipt_id"]
      for margin in EXPECTED_MARGINS
    ],
    "source action receipt ids diverge",
  )

  validations = {
    check["validation_id"]: check for check in closeout["validation_checks"]
  }
  require(set(validations) == EXPECTED_VALIDATIONS, "validation ids changed")
  for validation_id, check in validations.items():
    require(check["passed"], f"{validation_id} failed")
    require(check["note"], f"{validation_id} missing note")

  print("checked MoonBook regenerated readiness action receipt closeout workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
