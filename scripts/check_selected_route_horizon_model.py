#!/usr/bin/env python3
"""Check selected-route local horizon evidence is wired into readiness."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
HORIZON_OUTPUT = "output/mission/first_trusted_square_northeast_stepout_horizon.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def check_horizon_output(root: Path) -> None:
  evidence = load_json(root / HORIZON_OUTPUT)
  if evidence["evidence_id"] != "first-trusted-square-northeast-stepout-local-horizon-v1":
    raise AssertionError(evidence["evidence_id"])
  if evidence["route_id"] != "northeast-stepout":
    raise AssertionError(evidence["route_id"])
  if evidence["source_tile_id"] != "first-trusted-square-northeast-stepout-lola":
    raise AssertionError(evidence["source_tile_id"])
  if evidence["source_path"] != "data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv":
    raise AssertionError(evidence["source_path"])
  if evidence["generated_by"] != "scripts/generate_selected_route_horizon.py":
    raise AssertionError(evidence["generated_by"])
  if evidence["output_path"] != HORIZON_OUTPUT:
    raise AssertionError(evidence["output_path"])
  if evidence["decision"] != "Block":
    raise AssertionError(evidence["decision"])
  if evidence["max_horizon_angle_deg"] <= evidence["max_sun_altitude_deg"]:
    raise AssertionError(evidence)
  if evidence["terrain_shadow_margin_deg"] <= 0:
    raise AssertionError(evidence)
  if "terrain-shadow margin" not in " ".join(evidence["reasons"]):
    raise AssertionError(evidence["reasons"])


def check_handoffs(root: Path) -> None:
  handoffs = load_json(root / "output/moonrobo/first_trusted_square_handoffs.json")
  selected = next(handoff for handoff in handoffs if handoff["route_id"] == "northeast-stepout")
  checks = {
    check["check_id"]: check for check in selected["mission_readiness"]["checks"]
  }
  illumination = checks["illumination-northeast-stepout"]
  if illumination["decision"] != "Block":
    raise AssertionError(illumination)
  if illumination["evidence_path"] != HORIZON_OUTPUT:
    raise AssertionError(illumination)
  if "local horizon" not in illumination["reason"]:
    raise AssertionError(illumination)


def check_imported_preview(root: Path) -> None:
  with tempfile.TemporaryDirectory(prefix="moonmoon-selected-horizon-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(root / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    preview = load_json(tmp_root / "output/moonrobo/first_trusted_square_readiness_preview.json")
    gaps = {gap["check_id"]: gap for gap in preview["blocker_gap_report"]}
    gap = gaps["illumination-northeast-stepout"]
    if gap["evidence_path"] != HORIZON_OUTPUT:
      raise AssertionError(gap)
    modeling = load_json(tmp_root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json")
    results = {result["check_id"]: result for result in modeling[0]["gap_results"]}
    illumination = results["illumination-northeast-stepout"]
    if illumination["modeling_evidence_path"] != HORIZON_OUTPUT:
      raise AssertionError(illumination)
    if "terrain-shadow margin" not in illumination["result_rationale"]:
      raise AssertionError(illumination)


def main() -> int:
  subprocess.run(
    ["python3", "scripts/generate_selected_route_horizon.py", "--check"],
    cwd=ROOT,
    check=True,
  )
  check_horizon_output(ROOT)
  check_handoffs(ROOT)
  check_imported_preview(ROOT)
  print("checked selected-route local horizon model")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
