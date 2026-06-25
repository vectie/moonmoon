#!/usr/bin/env python3
"""Check MoonRobo remediation-margin refresh modeling is durable in MoonBook."""

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
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-refresh-modeling"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-refresh-modeling.json"
SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json"
)
RECEIPT_SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json"
)
MODEL_ID = "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass"
RECEIPT_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task"
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_refresh_modeling_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  receipt_source = load_json(root / RECEIPT_SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no refresh modeling entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonroboRemediationMarginRefreshModeling":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "AllRefreshesStillBlocking",
    "3 still-blocking refreshes",
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "0 refreshed",
    RECEIPT_ID,
    "no-consume simulation",
    "simulation-blocked",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no refresh modeling payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh modeling")
  if RECEIPT_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh receipt")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name refresh modeling source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve indexed entry")
  payload = entry_file["payload"]
  if payload["modeling_passes"] != source:
    raise AssertionError("workspace payload diverges from generated modeling bundle")
  primary = payload["primary_modeling_pass"]
  if primary != source[0]:
    raise AssertionError("primary modeling pass diverges from generated source")
  receipt = receipt_source[0]
  if primary["modeling_pass_id"] != MODEL_ID:
    raise AssertionError(primary["modeling_pass_id"])
  if primary["source_receipt_id"] != RECEIPT_ID:
    raise AssertionError(primary["source_receipt_id"])
  if primary["source_receipt_id"] != receipt["receipt"]["receipt_id"]:
    raise AssertionError("source receipt diverges from MoonClaw receipt")
  if primary["source_task_id"] != TASK_ID:
    raise AssertionError(primary["source_task_id"])
  if primary["source_task_id"] != receipt["source_task_id"]:
    raise AssertionError("source task diverges from MoonClaw receipt")
  if primary["source_projection_id"] != PROJECTION_ID:
    raise AssertionError(primary["source_projection_id"])
  if primary["source_projection_id"] != receipt["source_projection_id"]:
    raise AssertionError("source projection diverges from MoonClaw receipt")
  if primary["source_refresh_state"] != receipt["refresh_state"]:
    raise AssertionError(primary["source_refresh_state"])
  if primary["state"] != "AllRefreshesStillBlocking":
    raise AssertionError(primary["state"])
  if primary["refresh_action_count"] != 3:
    raise AssertionError(primary["refresh_action_count"])
  if primary["refreshed_count"] != 0:
    raise AssertionError(primary["refreshed_count"])
  if primary["still_blocking_count"] != 3:
    raise AssertionError(primary["still_blocking_count"])
  if primary["may_consume_simulation"]:
    raise AssertionError(primary)
  if primary["simulation_state"] != "SimulationBlocked":
    raise AssertionError(primary["simulation_state"])
  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])

  receipt_results = {
    result["refresh_id"]: result for result in receipt["refresh_results"]
  }
  results = primary["refresh_results"]
  if [result["margin_id"] for result in results] != MARGIN_IDS:
    raise AssertionError(results)
  for result in results:
    source_result = receipt_results[result["refresh_id"]]
    for key in (
      "rank",
      "margin_id",
      "source_projection_path",
      "target_artifact_path",
      "evidence_path",
    ):
      if result[key] != source_result[key]:
        raise AssertionError(f"{result['refresh_id']} changed {key}")
    if result["receipt_status"] != source_result["status"]:
      raise AssertionError(result)
    if result["modeling_command"] != source_result["acceptance_check"]:
      raise AssertionError(result)
    if result["result_status"] != "RefreshStillBlocking":
      raise AssertionError(result)
    if result["refreshed"] is not False:
      raise AssertionError(result)


def main() -> int:
  assert_refresh_modeling_workspace(ROOT)
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-moonbook-remediation-refresh-modeling-",
  ) as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_refresh_modeling_workspace(tmp_root)
  print("checked MoonBook remediation margin refresh modeling workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
