#!/usr/bin/env python3
"""Check MoonRobo simulation review packet is durable in MoonBook workspace."""

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
ENTRY_ID = "moonrobo/first-trusted-square/simulation-review-packet"
ENTRY_PATH = "moonrobo/first-trusted-square/simulation-review-packet.json"
SOURCE_PATH = "output/moonrobo/first_trusted_square_simulation_review_packet.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_packet_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no simulation packet entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonroboSimulationReviewPacket":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  if "hardware HardwareDenied" not in entry["summary"]:
    raise AssertionError(entry["summary"])
  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no simulation packet payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include simulation packet")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name simulation packet source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve the indexed entry")
  if entry_file["payload"] != source:
    raise AssertionError("workspace payload diverges from simulation packet source")

  payload = entry_file["payload"]
  if payload["packet_id"] != "moonrobo-simulation-review-packet/first-trusted-square/northeast-stepout":
    raise AssertionError(payload["packet_id"])
  if payload["hardware_state"] != "HardwareDenied":
    raise AssertionError(payload["hardware_state"])
  if payload["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(payload["hardware_authority"])
  if len(payload["accepted_clearance_transitions"]) != 4:
    raise AssertionError(payload["accepted_clearance_transitions"])
  if len(payload["remediation_margins"]) != 3:
    raise AssertionError(payload["remediation_margins"])
  if "hardware_state must remain HardwareDenied" not in payload["hardware_denial_invariants"]:
    raise AssertionError(payload["hardware_denial_invariants"])


def main() -> int:
  assert_packet_workspace(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonbook-sim-packet-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_packet_workspace(tmp_root)
  print("checked MoonBook simulation review packet workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
