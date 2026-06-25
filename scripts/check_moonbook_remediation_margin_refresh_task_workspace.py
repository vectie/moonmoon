#!/usr/bin/env python3
"""Check MoonClaw remediation-margin refresh task is durable in MoonBook."""

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
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-refresh-task"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-refresh-task.json"
SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json"
)
PROJECTION_SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task"
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
TARGETS = {
  "terrain-northeast-stepout": (
    "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"
  ),
  "illumination-northeast-stepout": (
    "output/mission/first_trusted_square_northeast_stepout_horizon.json"
  ),
  "energy-window": "output/mission/first_trusted_square_energy_remediation.json",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_refresh_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  projection = load_json(root / PROJECTION_SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no refresh task entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonClawRemediationMarginRefreshTask":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "NoConsumeSimulationBlocked",
    "3 ranked refreshes",
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "simulation-blocked",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no refresh task payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh task")
  if PROJECTION_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include projection")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name refresh task source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve indexed entry")
  payload = entry_file["payload"]
  if payload["tasks"] != source:
    raise AssertionError("workspace payload diverges from generated task bundle")
  primary = payload["primary_task"]
  if primary != source[0]:
    raise AssertionError("primary task diverges from generated source")
  if primary["task_id"] != TASK_ID:
    raise AssertionError(primary["task_id"])
  if primary["source_projection_id"] != PROJECTION_ID:
    raise AssertionError(primary["source_projection_id"])
  if primary["source_projection_id"] != projection["projection_id"]:
    raise AssertionError("refresh task projection id diverges from source")
  if primary["source_projection_status"] != "NoConsumeSimulationBlocked":
    raise AssertionError(primary["source_projection_status"])
  if primary["source_projection_status"] != projection["projection_status"]:
    raise AssertionError("refresh task projection status diverges from source")
  if primary["source_simulation_state"] != "SimulationBlocked":
    raise AssertionError(primary["source_simulation_state"])
  if primary["may_consume_simulation"]:
    raise AssertionError(primary)
  if primary["blocking_margin_count"] != 3:
    raise AssertionError(primary["blocking_margin_count"])
  if primary["ranked_margin_ids"] != MARGIN_IDS:
    raise AssertionError(primary["ranked_margin_ids"])
  if primary["ranked_margin_ids"] != projection["blocking_margin_ids"]:
    raise AssertionError("ranked margins diverge from projection blockers")

  actions = primary["refresh_actions"]
  if len(actions) != 3:
    raise AssertionError(actions)
  for index, margin_id in enumerate(MARGIN_IDS, start=1):
    action = actions[index - 1]
    if action["rank"] != index:
      raise AssertionError(action)
    if action["margin_id"] != margin_id:
      raise AssertionError(action)
    if action["target_artifact_path"] != TARGETS[margin_id]:
      raise AssertionError(action)
    if not action["command"] or not action["acceptance_check"]:
      raise AssertionError(action)

  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])
  if primary["hardware_state"] != projection["hardware_state"]:
    raise AssertionError("hardware state diverges from projection")
  if primary["hardware_authority"] != projection["hardware_authority"]:
    raise AssertionError("hardware authority diverges from projection")


def main() -> int:
  assert_refresh_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-remediation-refresh-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_refresh_workspace(tmp_root)
  print("checked MoonBook remediation margin refresh task workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
