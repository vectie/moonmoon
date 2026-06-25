#!/usr/bin/env python3
"""Check selected-route energy remediation is durable in MoonBook workspace."""

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
ENTRY_ID = "energy-remediation/first-trusted-square/northeast-stepout"
ENTRY_PATH = "mission/first-trusted-square/energy-remediation.json"
SOURCE_PATH = "output/mission/first_trusted_square_energy_remediation.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_energy_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no energy remediation entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "EnergyRemediationEvidence":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no energy remediation payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include energy source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if entry_file["payload"] != source:
    raise AssertionError("workspace energy payload diverges from mission output")
  payload = entry_file["payload"]
  if payload["decision"] != "Block":
    raise AssertionError(payload["decision"])
  if payload["bounded_margin_wh"] >= 0:
    raise AssertionError(payload)
  if payload["margin_gap_wh"] <= 0:
    raise AssertionError(payload)
  if payload["selected_route_count"] != 1:
    raise AssertionError(payload)


def main() -> int:
  assert_energy_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-energy-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_energy_workspace(tmp_root)
  print("checked selected-route energy MoonBook workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
