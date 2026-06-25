#!/usr/bin/env python3
"""Check MoonRobo selected-route simulation review closeout decision."""

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
DECISION_MD = Path("output/moonrobo/first_trusted_square_simulation_review_decision.md")


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_decision(root: Path) -> None:
  packet = load_json(root / PACKET_JSON)
  decision = load_json(root / DECISION_JSON)
  markdown = (root / DECISION_MD).read_text(encoding="utf-8")

  if decision["decision_id"] != (
    "moonrobo-simulation-review-decision/first-trusted-square/northeast-stepout"
  ):
    raise AssertionError(decision["decision_id"])
  if decision["source_packet_id"] != packet["packet_id"]:
    raise AssertionError(decision["source_packet_id"])
  if decision["source_packet_path"] != str(PACKET_JSON):
    raise AssertionError(decision["source_packet_path"])
  if decision["route_id"] != "northeast-stepout":
    raise AssertionError(decision["route_id"])
  if decision["may_consume_simulation_packet"]:
    raise AssertionError(decision)
  if decision["decision"] != "SimulationBlocked":
    raise AssertionError(decision["decision"])
  if decision["blocking_margin_count"] != 3:
    raise AssertionError(decision["blocking_margin_count"])
  if decision["accepted_clearance_transition_count"] != 4:
    raise AssertionError(decision["accepted_clearance_transition_count"])
  if decision["original_non_margin_blocker_count"] != 3:
    raise AssertionError(decision["original_non_margin_blocker_count"])
  if decision["closed_non_margin_blocker_count"] != 2:
    raise AssertionError(decision["closed_non_margin_blocker_count"])
  if decision["remaining_non_margin_blocker_count"] != 1:
    raise AssertionError(decision["remaining_non_margin_blocker_count"])

  expected_margins = {
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
  }
  if set(decision["blocking_margin_checks"]) != expected_margins:
    raise AssertionError(decision["blocking_margin_checks"])
  expected_closed = {
    "corridor-scan-best-window",
    "moonbook-review",
  }
  if set(decision["closed_non_margin_blockers"]) != expected_closed:
    raise AssertionError(decision["closed_non_margin_blockers"])
  expected_blockers = {
    "robot-simulation",
  }
  if set(decision["remaining_non_margin_blockers"]) != expected_blockers:
    raise AssertionError(decision["remaining_non_margin_blockers"])

  if decision["hardware_state"] != "HardwareDenied":
    raise AssertionError(decision["hardware_state"])
  if decision["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(decision["hardware_authority"])
  if not decision["hardware_denied"]:
    raise AssertionError(decision)
  for invariant in [
    "hardware_state must remain HardwareDenied",
    "hardware_authority must remain moonmoon-safety-gate-only",
    "MoonMoon must not emit hardware commands or physical execution authority",
    "simulation readiness must be regenerated from mission checks, not from clearance acceptance alone",
  ]:
    if invariant not in decision["hardware_denial_invariants"]:
      raise AssertionError(decision["hardware_denial_invariants"])

  for term in [
    "simulation packet remains blocked",
    "3 remediation margins",
    "1 active non-margin blockers",
    "2 stale non-margin blockers are closed",
    "hardware authority remains moonmoon-safety-gate-only",
  ]:
    if term not in decision["reason"]:
      raise AssertionError(decision["reason"])
  for term in [
    "do not let MoonRobo consume",
    "regenerate the packet",
    "keep hardware denied",
  ]:
    if term not in decision["next_action"]:
      raise AssertionError(decision["next_action"])

  for text in [
    "MoonRobo Selected-Route Simulation Review Decision",
    "may consume simulation packet: false",
    "SimulationBlocked",
    "terrain-northeast-stepout",
    "moonbook-review",
    "robot-simulation",
    "HardwareDenied",
    "Hardware Denial Invariants",
  ]:
    if text not in markdown:
      raise AssertionError(text)


def main() -> int:
  assert_decision(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonrobo-sim-decision-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_decision(tmp_root)
  print("checked MoonRobo selected-route simulation review decision")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
