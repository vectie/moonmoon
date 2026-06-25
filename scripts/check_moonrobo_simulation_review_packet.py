#!/usr/bin/env python3
"""Check selected-route MoonRobo simulation review packet materialization."""

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
PACKET_MD = Path("output/moonrobo/first_trusted_square_simulation_review_packet.md")


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_packet(root: Path) -> None:
  packet = load_json(root / PACKET_JSON)
  markdown = (root / PACKET_MD).read_text(encoding="utf-8")

  if packet["packet_id"] != (
    "moonrobo-simulation-review-packet/first-trusted-square/northeast-stepout"
  ):
    raise AssertionError(packet["packet_id"])
  if packet["route_id"] != "northeast-stepout":
    raise AssertionError(packet["route_id"])
  if packet["clearance_decision"] != "Allow":
    raise AssertionError(packet["clearance_decision"])
  if not packet["clearance_allows_simulation_review"]:
    raise AssertionError(packet)
  if packet["mission_readiness_decision"] != "Block":
    raise AssertionError(packet["mission_readiness_decision"])
  if packet["robot_simulation_status"] != "simulation-blocked":
    raise AssertionError(packet["robot_simulation_status"])
  if packet["simulation_state"] != "SimulationBlocked":
    raise AssertionError(packet["simulation_state"])
  if packet["hardware_state"] != "HardwareDenied" or not packet["hardware_denied"]:
    raise AssertionError(packet["hardware_state"])
  if packet["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(packet["hardware_authority"])
  if len(packet["accepted_clearance_transitions"]) != 4:
    raise AssertionError(packet["accepted_clearance_transitions"])

  accepted = {
    transition["clearance_id"]: transition
    for transition in packet["accepted_clearance_transitions"]
  }
  for clearance_id in {
    "clear-terrain-grade-northeast-stepout",
    "clear-illumination-confidence-northeast-stepout",
    "clear-energy-margin",
    "clear-moonbook-review-northeast-stepout",
  }:
    transition = accepted.get(clearance_id)
    if transition is None:
      raise AssertionError(accepted)
    if transition["reviewer_id"] != "operator/rabbita-clearance-review":
      raise AssertionError(transition)
    refs = transition["source_evidence_refs"]
    if not refs or "selected-route-clearance.json" not in refs[0]["path"]:
      raise AssertionError(transition)

  margins = {margin["check_id"]: margin for margin in packet["remediation_margins"]}
  expected_margins = {
    "terrain-northeast-stepout": (
      "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
      ["grade margin", "roughness margin"],
      ["grade", "roughness"],
    ),
    "illumination-northeast-stepout": (
      "output/mission/first_trusted_square_northeast_stepout_horizon.json",
      ["terrain-shadow margin"],
      ["terrain-shadow"],
    ),
    "energy-window": (
      "output/mission/first_trusted_square_energy_remediation.json",
      ["bounded margin", "margin gap"],
      ["bounded selected-route margin", "margin gap"],
    ),
  }
  if set(margins) != set(expected_margins):
    raise AssertionError(margins)
  for check_id, (path, terms, summary_terms) in expected_margins.items():
    margin = margins[check_id]
    if margin["evidence_path"] != path:
      raise AssertionError(margin)
    if margin["decision"] != "Block":
      raise AssertionError(margin)
    if margin["clearance_status"] != "AcceptedEvidence":
      raise AssertionError(margin)
    for term in terms:
      if term not in margin["margin_terms"]:
        raise AssertionError(margin)
    for term in summary_terms:
      if term not in margin["margin_summary"]:
        raise AssertionError(margin)

  blockers = {
    blocker["check_id"]: blocker
    for blocker in packet["remaining_non_margin_blockers"]
  }
  for check_id in {
    "corridor-scan-best-window",
    "moonbook-review",
    "robot-simulation",
  }:
    if check_id not in blockers:
      raise AssertionError(blockers)
  invariants = packet["hardware_denial_invariants"]
  for invariant in [
    "hardware_state must remain HardwareDenied",
    "hardware_authority must remain moonmoon-safety-gate-only",
    "MoonMoon must not emit hardware commands or physical execution authority",
    "simulation readiness must be regenerated from mission checks, not from clearance acceptance alone",
  ]:
    if invariant not in invariants:
      raise AssertionError(invariants)

  for text in [
    "MoonRobo Selected-Route Simulation Review Packet",
    "Accepted Clearance Transitions",
    "Remediation Margins",
    "Hardware Denial Invariants",
    "grade margin",
    "terrain-shadow margin",
    "bounded margin",
    "HardwareDenied",
  ]:
    if text not in markdown:
      raise AssertionError(text)


def main() -> int:
  assert_packet(ROOT)
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonrobo-sim-packet-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_packet(tmp_root)
  print("checked MoonRobo selected-route simulation review packet")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
