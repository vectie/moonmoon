#!/usr/bin/env python3
"""Check MoonClaw remediation-margin task is durable in MoonBook workspace."""

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
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-task"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-task.json"
SOURCE_PATH = "output/moonclaw/first_trusted_square_remediation_margin_task.json"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/task"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_remediation_margin_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no remediation task entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonClawTask":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "3 active remediation margins",
    "3 blockers",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no remediation task payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include remediation task")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name remediation task source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  payload = entry_file["payload"]
  if payload["tasks"] != source:
    raise AssertionError("workspace payload diverges from generated task bundle")
  primary = payload["primary_task"]
  if primary != source[0]:
    raise AssertionError("primary task diverges from generated source")
  if primary["task_id"] != TASK_ID:
    raise AssertionError(primary["task_id"])
  if primary["active_margin_count"] != 3:
    raise AssertionError(primary["active_margin_count"])
  if primary["active_margin_ids"] != MARGIN_IDS:
    raise AssertionError(primary["active_margin_ids"])
  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])

  artifacts = {artifact["artifact_id"]: artifact for artifact in primary["artifacts"]}
  if set(artifacts) != set(MARGIN_IDS):
    raise AssertionError(artifacts)
  if artifacts["terrain-northeast-stepout"]["ready"]:
    raise AssertionError(artifacts["terrain-northeast-stepout"])
  if artifacts["illumination-northeast-stepout"]["ready"]:
    raise AssertionError(artifacts["illumination-northeast-stepout"])
  if artifacts["energy-window"]["ready"]:
    raise AssertionError(artifacts["energy-window"])
  if "grade margin" not in artifacts["terrain-northeast-stepout"]["current_state"]:
    raise AssertionError(artifacts["terrain-northeast-stepout"])
  if "terrain-shadow margin" not in artifacts["illumination-northeast-stepout"]["current_state"]:
    raise AssertionError(artifacts["illumination-northeast-stepout"])
  if "margin gap" not in artifacts["energy-window"]["current_state"]:
    raise AssertionError(artifacts["energy-window"])


def main() -> int:
  assert_remediation_margin_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-remediation-task-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_remediation_margin_workspace(tmp_root)
  print("checked MoonBook remediation margin task workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
