#!/usr/bin/env python3
"""Check MoonClaw remediation-margin receipt is durable in MoonBook workspace."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import check_rabbita_transition_import
import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
WORKSPACE = Path("output/moonbook/workspaces/first-trusted-square")
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-receipt"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-receipt.json"
SOURCE_PATH = "output/moonclaw/first_trusted_square_remediation_margin_receipt.json"
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/current-receipt"
)
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_remediation_margin_receipt_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no remediation receipt")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonClawRemediationMarginReceipt":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "OpenMarginsCarriedForward",
    "3 remediation margins still blocking",
    "moonmoon-safety-gate-only",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no remediation receipt payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include remediation receipt")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name remediation receipt source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  payload = entry_file["payload"]
  if payload["receipts"] != source:
    raise AssertionError("workspace payload diverges from generated receipt bundle")
  primary = payload["primary_receipt"]
  if primary != source[0]:
    raise AssertionError("primary receipt diverges from generated source")
  if primary["receipt"]["receipt_id"] != RECEIPT_ID:
    raise AssertionError(primary["receipt"]["receipt_id"])
  if primary["remediation_state"] != "OpenMarginsCarriedForward":
    raise AssertionError(primary["remediation_state"])
  if primary["still_blocking_margin_count"] != 3:
    raise AssertionError(primary["still_blocking_margin_count"])
  if primary["cleared_margin_count"] != 0:
    raise AssertionError(primary["cleared_margin_count"])
  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])

  results = {result["margin_id"]: result for result in primary["margin_results"]}
  if set(results) != set(MARGIN_IDS):
    raise AssertionError(results)
  for margin_id in MARGIN_IDS:
    if results[margin_id]["status"] != "StillBlocking":
      raise AssertionError(results[margin_id])


def main() -> int:
  assert_remediation_margin_receipt_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-remediation-receipt-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_remediation_margin_receipt_workspace(tmp_root)
  print("checked MoonBook remediation margin receipt workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
