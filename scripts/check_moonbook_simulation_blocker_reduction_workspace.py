#!/usr/bin/env python3
"""Check MoonRobo simulation blocker reduction is durable in MoonBook workspace."""

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
ENTRY_ID = "moonrobo/first-trusted-square/simulation-blocker-reduction"
ENTRY_PATH = "moonrobo/first-trusted-square/simulation-blocker-reduction.json"
SOURCE_PATH = "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_reduction_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no blocker reduction entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonroboSimulationBlockerReduction":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "2 closed non-margin blockers",
    "1 active non-margin blockers",
    "3 remediation margins still blocking",
    "hardware authority denied at HardwareDenied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no blocker reduction payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include blocker reduction")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name blocker reduction source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if entry_file["payload"] != source:
    raise AssertionError("workspace payload diverges from blocker reduction source")

  payload = entry_file["payload"]
  if payload["reduction_id"] != "moonrobo-simulation-blocker-reduction/northeast-stepout":
    raise AssertionError(payload["reduction_id"])
  if payload["source_decision_id"] != (
    "moonrobo-simulation-review-decision/first-trusted-square/northeast-stepout"
  ):
    raise AssertionError(payload["source_decision_id"])
  if payload["original_non_margin_blocker_count"] != 3:
    raise AssertionError(payload["original_non_margin_blocker_count"])
  if payload["closed_non_margin_blocker_count"] != 2:
    raise AssertionError(payload["closed_non_margin_blocker_count"])
  if payload["active_non_margin_blocker_count"] != 1:
    raise AssertionError(payload["active_non_margin_blocker_count"])
  if set(payload["closed_non_margin_blockers"]) != {
    "corridor-scan-best-window",
    "moonbook-review",
  }:
    raise AssertionError(payload["closed_non_margin_blockers"])
  if payload["active_non_margin_blockers"] != ["robot-simulation"]:
    raise AssertionError(payload["active_non_margin_blockers"])
  if payload["blocking_margin_count"] != 3:
    raise AssertionError(payload["blocking_margin_count"])
  if payload["decision_after_reduction"] != "SimulationBlocked":
    raise AssertionError(payload["decision_after_reduction"])
  if payload["may_consume_after_reduction"]:
    raise AssertionError(payload)
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  closeouts = {item["check_id"]: item for item in payload["blocker_closeouts"]}
  if closeouts["robot-simulation"]["closeout_state"] != "StillActive":
    raise AssertionError(closeouts["robot-simulation"])
  for check_id in ["corridor-scan-best-window", "moonbook-review"]:
    if closeouts[check_id]["closeout_state"] != "ClosedByExistingEvidence":
      raise AssertionError(closeouts[check_id])


def main() -> int:
  assert_reduction_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-blocker-reduction-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_reduction_workspace(tmp_root)
  print("checked MoonBook simulation blocker reduction workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
