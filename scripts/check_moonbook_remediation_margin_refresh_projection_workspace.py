#!/usr/bin/env python3
"""Check MoonRobo remediation-margin refresh projection is durable in MoonBook."""

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
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-refresh-projection"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-refresh-projection.json"
SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
)
MODELING_SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json"
)
PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
)
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass"
)
SOURCE_PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
REFRESH_IDS = {
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
}
MARGIN_IDS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_refresh_projection_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  modeling = load_json(root / MODELING_SOURCE_PATH)[0]
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no refresh projection entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonroboRemediationMarginRefreshProjection":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "NoConsumeRefreshSimulationBlocked",
    "AllRefreshesStillBlocking",
    "3 still-blocking refreshes",
    "refresh-terrain-northeast-stepout",
    "refresh-illumination-northeast-stepout",
    "refresh-energy-window",
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "simulation-blocked",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no refresh projection payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh projection")
  if MODELING_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh modeling")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name refresh projection source")
  if MODELING_SOURCE_PATH not in readme:
    raise AssertionError("README does not name refresh modeling source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve indexed entry")
  if entry_file["payload"] != source:
    raise AssertionError("workspace payload diverges from refresh projection source")

  payload = entry_file["payload"]
  if payload["projection_id"] != PROJECTION_ID:
    raise AssertionError(payload["projection_id"])
  if payload["source_modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(payload["source_modeling_pass_id"])
  if payload["source_modeling_path"] != MODELING_SOURCE_PATH:
    raise AssertionError(payload["source_modeling_path"])
  if payload["source_modeling_state"] != "AllRefreshesStillBlocking":
    raise AssertionError(payload["source_modeling_state"])
  if payload["source_modeling_state"] != modeling["state"]:
    raise AssertionError("source modeling state diverges from modeling")
  if payload["source_receipt_id"] != modeling["source_receipt_id"]:
    raise AssertionError(payload["source_receipt_id"])
  if payload["source_task_id"] != modeling["source_task_id"]:
    raise AssertionError(payload["source_task_id"])
  if payload["source_projection_id"] != SOURCE_PROJECTION_ID:
    raise AssertionError(payload["source_projection_id"])
  if payload["source_projection_id"] != modeling["source_projection_id"]:
    raise AssertionError("source projection diverges from modeling")
  if payload["projection_status"] != "NoConsumeRefreshSimulationBlocked":
    raise AssertionError(payload["projection_status"])
  if payload["may_consume_simulation"]:
    raise AssertionError(payload)
  if payload["simulation_state"] != "SimulationBlocked":
    raise AssertionError(payload["simulation_state"])
  if payload["refresh_action_count"] != 3:
    raise AssertionError(payload["refresh_action_count"])
  if payload["refreshed_count"] != 0:
    raise AssertionError(payload["refreshed_count"])
  if payload["still_blocking_count"] != 3:
    raise AssertionError(payload["still_blocking_count"])
  if set(payload["consumed_refresh_result_ids"]) != REFRESH_IDS:
    raise AssertionError(payload["consumed_refresh_result_ids"])
  if set(payload["blocking_refresh_ids"]) != REFRESH_IDS:
    raise AssertionError(payload["blocking_refresh_ids"])
  if set(payload["blocking_margin_ids"]) != MARGIN_IDS:
    raise AssertionError(payload["blocking_margin_ids"])
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  if payload["hardware_denied"] is not True:
    raise AssertionError(payload["hardware_denied"])
  if "no-consume refresh projection" not in payload["reason"]:
    raise AssertionError(payload["reason"])


def main() -> int:
  assert_refresh_projection_workspace(ROOT)
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-moonbook-remediation-refresh-projection-",
  ) as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_refresh_projection_workspace(tmp_root)
  print("checked MoonBook remediation margin refresh projection workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
