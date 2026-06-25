#!/usr/bin/env python3
"""Check MoonRobo gap modeling materialization in imported MoonBook workspace."""

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
ENTRY_ID = "moonrobo/first-trusted-square/gap-remediation-modeling-pass"
ENTRY_PATH = "moonrobo/first-trusted-square/gap-remediation-modeling.json"
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/moonrobo-gap-remediation-v1/modeling-pass"
)


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_modeling_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  modeling_bundle = load_json(
    root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json",
  )
  modeling_entry = load_json(workspace / ENTRY_PATH)

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no modeling pass entry")
  entry = entries[ENTRY_ID]
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no modeling pass payload path")

  payload = modeling_entry["payload"]
  if modeling_entry["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if payload["primary_modeling_pass"]["modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(payload["primary_modeling_pass"]["modeling_pass_id"])
  if payload["modeling_passes"] != modeling_bundle:
    raise AssertionError("workspace payload diverges from generated modeling pass")
  if payload["primary_modeling_pass"]["state"] != "AllGapsStillBlocked":
    raise AssertionError(payload["primary_modeling_pass"]["state"])
  if payload["primary_modeling_pass"]["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["primary_modeling_pass"]["hardware_state"])
  if not payload["primary_modeling_pass"]["gap_results"]:
    raise AssertionError("modeling pass lost gap results")
  if (
    "output/moonrobo/first_trusted_square_gap_remediation_modeling.json"
    not in index["source_files"]
  ):
    raise AssertionError("index source_files does not include modeling pass")


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-gap-modeling-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_modeling_workspace(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
