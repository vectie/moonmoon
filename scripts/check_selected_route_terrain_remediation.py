#!/usr/bin/env python3
"""Check selected-route terrain remediation evidence is wired into readiness."""

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
TERRAIN_OUTPUT = "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def check_terrain_output(root: Path) -> None:
  evidence = load_json(root / TERRAIN_OUTPUT)
  if evidence["evidence_id"] != "first-trusted-square-northeast-stepout-terrain-remediation-v1":
    raise AssertionError(evidence["evidence_id"])
  if evidence["route_id"] != "northeast-stepout":
    raise AssertionError(evidence["route_id"])
  if evidence["source_tile_id"] != "first-trusted-square-northeast-stepout-lola":
    raise AssertionError(evidence["source_tile_id"])
  if evidence["output_path"] != TERRAIN_OUTPUT:
    raise AssertionError(evidence["output_path"])
  if evidence["generated_by"] != "scripts/generate_selected_route_terrain_remediation.py":
    raise AssertionError(evidence["generated_by"])
  if evidence["decision"] != "Block":
    raise AssertionError(evidence["decision"])
  if evidence["max_neighbor_grade"] <= evidence["grade_limit"]:
    raise AssertionError(evidence)
  if evidence["roughness_m"] <= evidence["roughness_limit_m"]:
    raise AssertionError(evidence)
  if evidence["blocking_edge_count"] <= 0:
    raise AssertionError(evidence)
  if "blocking grade" not in " ".join(evidence["reasons"]) and "grade" not in " ".join(evidence["reasons"]):
    raise AssertionError(evidence["reasons"])


def check_handoffs(root: Path) -> None:
  handoffs = load_json(root / "output/moonrobo/first_trusted_square_handoffs.json")
  selected = next(handoff for handoff in handoffs if handoff["route_id"] == "northeast-stepout")
  checks = {
    check["check_id"]: check for check in selected["mission_readiness"]["checks"]
  }
  terrain = checks["terrain-northeast-stepout"]
  if terrain["decision"] != "Block":
    raise AssertionError(terrain)
  if terrain["evidence_path"] != TERRAIN_OUTPUT:
    raise AssertionError(terrain)
  if "blocking edges" not in terrain["reason"]:
    raise AssertionError(terrain)


def check_imported_preview(root: Path) -> None:
  with tempfile.TemporaryDirectory(prefix="moonmoon-selected-terrain-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(root / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    preview = load_json(tmp_root / "output/moonrobo/first_trusted_square_readiness_preview.json")
    gaps = {gap["check_id"]: gap for gap in preview["blocker_gap_report"]}
    gap = gaps["terrain-northeast-stepout"]
    if gap["evidence_path"] != TERRAIN_OUTPUT:
      raise AssertionError(gap)
    modeling = load_json(tmp_root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json")
    results = {result["check_id"]: result for result in modeling[0]["gap_results"]}
    terrain = results["terrain-northeast-stepout"]
    if terrain["modeling_evidence_path"] != TERRAIN_OUTPUT:
      raise AssertionError(terrain)
    if "grade and roughness margins" not in terrain["result_rationale"]:
      raise AssertionError(terrain)


def main() -> int:
  subprocess.run(
    ["python3", "scripts/generate_selected_route_terrain_remediation.py", "--check"],
    cwd=ROOT,
    check=True,
  )
  check_terrain_output(ROOT)
  check_handoffs(ROOT)
  check_imported_preview(ROOT)
  print("checked selected-route terrain remediation")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
