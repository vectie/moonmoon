#!/usr/bin/env python3
"""Check MoonRobo selected-route simulation blocker reduction pass."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
PACKET_JSON = Path("output/moonrobo/first_trusted_square_simulation_review_packet.json")
DECISION_JSON = Path("output/moonrobo/first_trusted_square_simulation_review_decision.json")
REDUCTION_JSON = Path("output/moonrobo/first_trusted_square_simulation_blocker_reduction.json")
REDUCTION_MD = Path("output/moonrobo/first_trusted_square_simulation_blocker_reduction.md")


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_reduction(root: Path) -> None:
  packet = load_json(root / PACKET_JSON)
  decision = load_json(root / DECISION_JSON)
  reduction = load_json(root / REDUCTION_JSON)
  markdown = (root / REDUCTION_MD).read_text(encoding="utf-8")

  if reduction["reduction_id"] != "moonrobo-simulation-blocker-reduction/northeast-stepout":
    raise AssertionError(reduction["reduction_id"])
  if reduction["source_packet_id"] != packet["packet_id"]:
    raise AssertionError(reduction["source_packet_id"])
  if reduction["source_decision_id"] != decision["decision_id"]:
    raise AssertionError(reduction["source_decision_id"])
  if reduction["route_id"] != "northeast-stepout":
    raise AssertionError(reduction["route_id"])
  if reduction["original_non_margin_blocker_count"] != 3:
    raise AssertionError(reduction["original_non_margin_blocker_count"])
  if reduction["closed_non_margin_blocker_count"] != 2:
    raise AssertionError(reduction["closed_non_margin_blocker_count"])
  if reduction["active_non_margin_blocker_count"] != 1:
    raise AssertionError(reduction["active_non_margin_blocker_count"])
  if set(reduction["closed_non_margin_blockers"]) != {
    "corridor-scan-best-window",
    "moonbook-review",
  }:
    raise AssertionError(reduction["closed_non_margin_blockers"])
  if reduction["active_non_margin_blockers"] != ["robot-simulation"]:
    raise AssertionError(reduction["active_non_margin_blockers"])
  if reduction["blocking_margin_count"] != 3:
    raise AssertionError(reduction["blocking_margin_count"])
  if set(reduction["blocking_margin_checks"]) != {
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
  }:
    raise AssertionError(reduction["blocking_margin_checks"])
  if reduction["decision_after_reduction"] != "SimulationBlocked":
    raise AssertionError(reduction["decision_after_reduction"])
  if reduction["may_consume_after_reduction"]:
    raise AssertionError(reduction)

  closeouts = {
    closeout["check_id"]: closeout
    for closeout in reduction["blocker_closeouts"]
  }
  if set(closeouts) != {
    "corridor-scan-best-window",
    "moonbook-review",
    "robot-simulation",
  }:
    raise AssertionError(closeouts)
  for check_id in ["corridor-scan-best-window", "moonbook-review"]:
    closeout = closeouts[check_id]
    if closeout["closeout_state"] != "ClosedByExistingEvidence":
      raise AssertionError(closeout)
    if closeout["active_after_reduction"]:
      raise AssertionError(closeout)
  robot = closeouts["robot-simulation"]
  if robot["closeout_state"] != "StillActive":
    raise AssertionError(robot)
  if not robot["active_after_reduction"]:
    raise AssertionError(robot)

  if reduction["hardware_state"] != "HardwareDenied":
    raise AssertionError(reduction["hardware_state"])
  if reduction["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(reduction["hardware_authority"])
  if not reduction["hardware_denied"]:
    raise AssertionError(reduction)
  for term in [
    "2 stale non-margin blockers closed",
    "1 non-margin blocker remains active",
    "3 remediation margins still block",
    "hardware remains HardwareDenied",
  ]:
    if term not in reduction["summary"]:
      raise AssertionError(reduction["summary"])

  for text in [
    "MoonRobo Simulation Blocker Reduction",
    "ClosedByExistingEvidence",
    "StillActive",
    "corridor-scan-best-window",
    "moonbook-review",
    "robot-simulation",
    "terrain-northeast-stepout",
    "HardwareDenied",
  ]:
    if text not in markdown:
      raise AssertionError(text)


def main() -> int:
  assert_reduction(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonrobo-blocker-reduction-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_reduction(tmp_root)
  print("checked MoonRobo selected-route simulation blocker reduction")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
