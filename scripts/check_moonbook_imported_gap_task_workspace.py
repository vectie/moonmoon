#!/usr/bin/env python3
"""Check imported MoonClaw gap task materialization in a temp MoonBook workspace."""

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
ENTRY_ID = "moonclaw/first-trusted-square/moonrobo-gap-remediation-task"
ENTRY_PATH = "moonclaw/first-trusted-square/moonrobo-gap-task.json"
TASK_ID = "moonclaw/first-trusted-square/moonrobo-gap-remediation-v1/task"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_gap_task_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  task_bundle = load_json(
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json",
  )
  task_entry = load_json(workspace / ENTRY_PATH)

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no imported gap task entry")
  entry = entries[ENTRY_ID]
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no imported gap task payload path")

  payload = task_entry["payload"]
  if task_entry["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if payload["primary_task"]["task_id"] != TASK_ID:
    raise AssertionError(payload["primary_task"]["task_id"])
  if payload["tasks"] != task_bundle:
    raise AssertionError("workspace payload diverges from generated task bundle")
  if not payload["primary_task"]["blocker_gap_report"]:
    raise AssertionError("gap task lost the blocker gap report")
  if "robot_safety_invariants" not in payload["primary_task"]:
    raise AssertionError("gap task lost robot safety invariants")
  if (
    "output/moonclaw/first_trusted_square_moonrobo_gap_task.json"
    not in index["source_files"]
  ):
    raise AssertionError("index source_files does not include imported gap task")


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-gap-task-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_gap_task_workspace(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
