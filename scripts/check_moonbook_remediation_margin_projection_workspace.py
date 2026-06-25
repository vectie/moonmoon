#!/usr/bin/env python3
"""Check MoonRobo remediation-margin projection is durable in MoonBook workspace."""

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
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-projection"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-projection.json"
SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
)
MODELING_SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_modeling.json"
)
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass"
)
MARGIN_IDS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_projection_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no projection entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonroboRemediationMarginProjection":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "NoConsumeSimulationBlocked",
    "AllMarginsStillBlocking",
    "3 still-blocking margins",
    "simulation-blocked",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no projection payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include projection")
  if MODELING_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include modeling source")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name projection source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if entry_file["payload"] != source:
    raise AssertionError("workspace payload diverges from projection source")

  payload = entry_file["payload"]
  if payload["projection_id"] != PROJECTION_ID:
    raise AssertionError(payload["projection_id"])
  if payload["source_modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(payload["source_modeling_pass_id"])
  if payload["source_modeling_path"] != MODELING_SOURCE_PATH:
    raise AssertionError(payload["source_modeling_path"])
  if payload["source_modeling_state"] != "AllMarginsStillBlocking":
    raise AssertionError(payload["source_modeling_state"])
  if payload["projection_status"] != "NoConsumeSimulationBlocked":
    raise AssertionError(payload["projection_status"])
  if payload["may_consume_simulation"]:
    raise AssertionError(payload)
  if payload["simulation_state"] != "SimulationBlocked":
    raise AssertionError(payload["simulation_state"])
  if payload["active_margin_count"] != 3:
    raise AssertionError(payload["active_margin_count"])
  if payload["cleared_margin_count"] != 0:
    raise AssertionError(payload["cleared_margin_count"])
  if payload["still_blocking_margin_count"] != 3:
    raise AssertionError(payload["still_blocking_margin_count"])
  if set(payload["blocking_margin_ids"]) != MARGIN_IDS:
    raise AssertionError(payload["blocking_margin_ids"])
  if set(payload["consumed_margin_result_ids"]) != MARGIN_IDS:
    raise AssertionError(payload["consumed_margin_result_ids"])
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  if payload["hardware_denied"] is not True:
    raise AssertionError(payload["hardware_denied"])
  if "no-consume projection" not in payload["reason"]:
    raise AssertionError(payload["reason"])


def main() -> int:
  assert_projection_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-remediation-projection-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_projection_workspace(tmp_root)
  print("checked MoonBook remediation margin projection workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
