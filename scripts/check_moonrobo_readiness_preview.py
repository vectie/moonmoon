#!/usr/bin/env python3
"""Check imported clearance produces a robot-facing readiness preview."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_preview(root: Path) -> None:
  preview_path = root / "output/moonrobo/first_trusted_square_readiness_preview.json"
  markdown_path = root / "output/moonrobo/first_trusted_square_readiness_preview.md"
  preview = load_json(preview_path)
  markdown = markdown_path.read_text(encoding="utf-8")

  if preview["route_id"] != "northeast-stepout":
    raise AssertionError(preview["route_id"])
  if preview["clearance_decision"] != "Allow":
    raise AssertionError(preview["clearance_decision"])
  if not preview["clearance_allows_simulation_review"]:
    raise AssertionError(preview)
  if len(preview["accepted_clearance_items"]) != 4:
    raise AssertionError(preview["accepted_clearance_items"])
  if preview["blocking_clearance_items"] or preview["review_clearance_items"]:
    raise AssertionError(preview)
  if preview["mission_readiness_decision"] != "Block":
    raise AssertionError(preview["mission_readiness_decision"])
  if preview["robot_simulation_status"] != "simulation-blocked":
    raise AssertionError(preview["robot_simulation_status"])
  if preview["simulation_state"] != "SimulationBlocked":
    raise AssertionError(preview["simulation_state"])
  if preview["hardware_state"] != "HardwareDenied" or not preview["hardware_denied"]:
    raise AssertionError(preview["hardware_state"])
  if "terrain-northeast-stepout" not in preview["blocking_preconditions"]:
    raise AssertionError(preview["blocking_preconditions"])
  if "energy-window" not in preview["blocking_preconditions"]:
    raise AssertionError(preview["blocking_preconditions"])
  gaps = {gap["check_id"]: gap for gap in preview["blocker_gap_report"]}
  expected_gaps = {
    "terrain-northeast-stepout": (
      "TerrainReadiness",
      "mission/first-trusted-square/routes/northeast-stepout.json",
      "AcceptedEvidence",
    ),
    "illumination-northeast-stepout": (
      "IlluminationReadiness",
      "mission/first-trusted-square/routes/northeast-stepout.illumination.json",
      "AcceptedEvidence",
    ),
    "energy-window": (
      "EnergyReadiness",
      "mission/first-trusted-square/energy-window.json",
      "AcceptedEvidence",
    ),
    "moonbook-review": (
      "MoonBookReviewReadiness",
      "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
      "AcceptedEvidence",
    ),
    "robot-simulation": (
      "RobotSimulationReadiness",
      "output/moonrobo/first_trusted_square_handoffs.json",
      "NotClearanceGated",
    ),
  }
  for check_id, (kind, evidence_path, clearance_status) in expected_gaps.items():
    gap = gaps[check_id]
    if gap["kind"] != kind:
      raise AssertionError(gap)
    if gap["evidence_path"] != evidence_path:
      raise AssertionError(gap)
    if gap["clearance_status"] != clearance_status:
      raise AssertionError(gap)
    if not gap["next_action"]:
      raise AssertionError(gap)
  if "hardware denied: true" not in markdown:
    raise AssertionError(markdown)
  if "clearance decision: allow" not in markdown:
    raise AssertionError(markdown)
  if "robot simulation status: simulation-blocked" not in markdown:
    raise AssertionError(markdown)
  if "## Blocker Gap Report" not in markdown:
    raise AssertionError(markdown)
  if "terrain-northeast-stepout" not in markdown:
    raise AssertionError(markdown)
  if "illumination-northeast-stepout" not in markdown:
    raise AssertionError(markdown)
  if "moonbook-review" not in markdown:
    raise AssertionError(markdown)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonrobo-preview-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_preview(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
