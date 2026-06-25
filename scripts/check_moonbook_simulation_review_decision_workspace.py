#!/usr/bin/env python3
"""Check MoonRobo simulation review decision is durable in MoonBook workspace."""

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
ENTRY_ID = "moonrobo/first-trusted-square/simulation-review-decision"
ENTRY_PATH = "moonrobo/first-trusted-square/simulation-review-decision.json"
SOURCE_PATH = "output/moonrobo/first_trusted_square_simulation_review_decision.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_decision_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no simulation decision entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonroboSimulationReviewDecision":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "SimulationBlocked northeast-stepout",
    "consume=false",
    "3 remediation margins",
    "3 non-margin blockers",
    "hardware authority denied at HardwareDenied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no simulation decision payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include simulation decision")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name simulation decision source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if entry_file["payload"] != source:
    raise AssertionError("workspace payload diverges from simulation decision source")

  payload = entry_file["payload"]
  if payload["decision_id"] != (
    "moonrobo-simulation-review-decision/first-trusted-square/northeast-stepout"
  ):
    raise AssertionError(payload["decision_id"])
  if payload["decision"] != "SimulationBlocked":
    raise AssertionError(payload["decision"])
  if payload["may_consume_simulation_packet"]:
    raise AssertionError(payload)
  if payload["blocking_margin_count"] != 3:
    raise AssertionError(payload["blocking_margin_count"])
  if payload["remaining_non_margin_blocker_count"] != 3:
    raise AssertionError(payload["remaining_non_margin_blocker_count"])
  if payload["accepted_clearance_transition_count"] != 4:
    raise AssertionError(payload["accepted_clearance_transition_count"])
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  if not payload["hardware_denied"]:
    raise AssertionError(payload)
  if "do not let MoonRobo consume" not in payload["next_action"]:
    raise AssertionError(payload["next_action"])


def main() -> int:
  assert_decision_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-sim-decision-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_decision_workspace(tmp_root)
  print("checked MoonBook simulation review decision workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
