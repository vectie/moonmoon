#!/usr/bin/env python3
"""Check the bounded MoonRobo gap remediation modeling pass."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/moonrobo-gap-remediation-v1/modeling-pass"
)


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_modeling_pass(root: Path) -> None:
  modeling_path = (
    root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json"
  )
  markdown_path = (
    root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.md"
  )
  task_path = root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json"
  preview_path = root / "output/moonrobo/first_trusted_square_readiness_preview.json"
  receipt_path = (
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json"
  )

  modeling = load_json(modeling_path)[0]
  task = load_json(task_path)[0]
  preview = load_json(preview_path)
  receipt = load_json(receipt_path)[0]
  markdown = markdown_path.read_text(encoding="utf-8")

  if modeling["modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(modeling["modeling_pass_id"])
  if modeling["source_task_id"] != task["task_id"]:
    raise AssertionError("modeling pass does not consume gap task")
  if modeling["source_preview_id"] != preview["preview_id"]:
    raise AssertionError("modeling pass does not consume readiness preview")
  if modeling["state"] != "AllGapsStillBlocked":
    raise AssertionError(modeling["state"])
  if modeling["hardware_state"] != "HardwareDenied" or not modeling["hardware_denied"]:
    raise AssertionError(modeling)
  if modeling["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(modeling["hardware_authority"])

  task_gaps = {gap["check_id"]: gap for gap in task["blocker_gap_report"]}
  results = {result["check_id"]: result for result in modeling["gap_results"]}
  if set(results) != set(task_gaps):
    raise AssertionError(results)
  if modeling["blocker_gap_count"] != len(task_gaps):
    raise AssertionError(modeling["blocker_gap_count"])
  if modeling["cleared_gap_count"] != 0:
    raise AssertionError(modeling["cleared_gap_count"])
  if modeling["still_blocking_gap_count"] != len(task_gaps):
    raise AssertionError(modeling["still_blocking_gap_count"])
  for check_id, result in results.items():
    if result["result_status"] != "StillBlocking" or result["cleared"]:
      raise AssertionError(result)
    if result["input_evidence_path"] != task_gaps[check_id]["evidence_path"]:
      raise AssertionError(result)
    if not result["modeling_command"] or not result["modeling_evidence_path"]:
      raise AssertionError(result)
    if not result["result_rationale"] or not result["next_action"]:
      raise AssertionError(result)

  commands = "\n".join(modeling["commands_evaluated"])
  for required in [
    "check_selected_route_terrain_remediation.py",
    "check_selected_route_horizon_model.py",
    "check_energy_margin_remediation.py",
    "materialize_moonbook_workspace.py --check",
    "check_moonrobo_readiness_preview.py",
  ]:
    if required not in commands:
      raise AssertionError(commands)

  if receipt["source_modeling_pass_id"] != modeling["modeling_pass_id"]:
    raise AssertionError(receipt["source_modeling_pass_id"])
  checks = {check["validation_id"]: check for check in receipt["validation_checks"]}
  if not checks.get("modeling-pass-consumed", {}).get("passed"):
    raise AssertionError(checks)

  if "AllGapsStillBlocked" not in markdown:
    raise AssertionError(markdown)
  if "terrain-northeast-stepout" not in markdown:
    raise AssertionError(markdown)
  if "moonmoon-safety-gate-only" not in markdown:
    raise AssertionError(markdown)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-gap-modeling-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_modeling_pass(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
