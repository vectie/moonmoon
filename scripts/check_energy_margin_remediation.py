#!/usr/bin/env python3
"""Check bounded selected-route energy remediation is wired into readiness."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
ENERGY_OUTPUT = "output/mission/first_trusted_square_energy_remediation.json"
TERRAIN_OUTPUT = (
  "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"
)
HORIZON_OUTPUT = (
  "output/mission/first_trusted_square_northeast_stepout_horizon.json"
)


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def check_energy_output(root: Path) -> None:
  evidence = load_json(root / ENERGY_OUTPUT)
  if evidence["evidence_id"] != "first-trusted-square-energy-remediation-v1":
    raise AssertionError(evidence["evidence_id"])
  if evidence["route_id"] != "northeast-stepout":
    raise AssertionError(evidence["route_id"])
  if evidence["output_path"] != ENERGY_OUTPUT:
    raise AssertionError(evidence["output_path"])
  if evidence["terrain_evidence_path"] != TERRAIN_OUTPUT:
    raise AssertionError(evidence["terrain_evidence_path"])
  if evidence["horizon_evidence_path"] != HORIZON_OUTPUT:
    raise AssertionError(evidence["horizon_evidence_path"])
  if evidence["decision"] != "Block":
    raise AssertionError(evidence["decision"])
  if evidence["selected_route_count"] != 1:
    raise AssertionError(evidence["selected_route_count"])
  if evidence["route_count_before_bound"] <= evidence["selected_route_count"]:
    raise AssertionError(evidence)
  if evidence["bounded_required_energy_wh"] >= evidence["all_route_required_energy_wh"]:
    raise AssertionError(evidence)
  if evidence["bounded_margin_wh"] >= 0:
    raise AssertionError(evidence)
  if evidence["margin_gap_wh"] <= 0:
    raise AssertionError(evidence)
  if evidence["thermal_survival_energy_wh"] <= evidence["verified_available_energy_wh"]:
    raise AssertionError(evidence)
  reasons = " ".join(evidence["reasons"])
  if "bounded demand" not in reasons or "thermal survival" not in reasons:
    raise AssertionError(evidence["reasons"])


def check_handoffs(root: Path) -> None:
  handoffs = load_json(root / "output/moonrobo/first_trusted_square_handoffs.json")
  selected = next(
    handoff for handoff in handoffs if handoff["route_id"] == "northeast-stepout"
  )
  checks = {
    check["check_id"]: check for check in selected["mission_readiness"]["checks"]
  }
  energy = checks["energy-window"]
  if energy["decision"] != "Block":
    raise AssertionError(energy)
  if energy["evidence_path"] != ENERGY_OUTPUT:
    raise AssertionError(energy)
  if "bounded selected-route margin" not in energy["reason"]:
    raise AssertionError(energy)


def check_imported_gap_modeling(root: Path) -> None:
  with tempfile.TemporaryDirectory(prefix="moonmoon-energy-remediation-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(root / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    preview = load_json(
      tmp_root / "output/moonrobo/first_trusted_square_readiness_preview.json",
    )
    gaps = {gap["check_id"]: gap for gap in preview["blocker_gap_report"]}
    energy_gap = gaps["energy-window"]
    if energy_gap["evidence_path"] != ENERGY_OUTPUT:
      raise AssertionError(energy_gap)
    modeling = load_json(
      tmp_root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json",
    )
    results = {result["check_id"]: result for result in modeling[0]["gap_results"]}
    energy_result = results["energy-window"]
    if energy_result["modeling_evidence_path"] != ENERGY_OUTPUT:
      raise AssertionError(energy_result)
    if "bounded selected-route demand" not in energy_result["result_rationale"]:
      raise AssertionError(energy_result)
    if "check_energy_margin_remediation.py" not in energy_result["modeling_command"]:
      raise AssertionError(energy_result)


def main() -> int:
  check_energy_output(ROOT)
  check_handoffs(ROOT)
  check_imported_gap_modeling(ROOT)
  print("checked selected-route energy remediation")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
