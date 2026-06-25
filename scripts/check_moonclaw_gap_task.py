#!/usr/bin/env python3
"""Check MoonClaw remediation task generated from MoonRobo gap preview."""

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


def assert_gap_task(root: Path) -> None:
  task_path = root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json"
  markdown_path = root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.md"
  tasks = load_json(task_path)
  markdown = markdown_path.read_text(encoding="utf-8")
  if len(tasks) != 1:
    raise AssertionError(tasks)
  task = tasks[0]
  if task["task_id"] != "moonclaw/first-trusted-square/moonrobo-gap-remediation-v1/task":
    raise AssertionError(task["task_id"])
  if task["priority"] != "Critical" or task["state"] != "Accepted":
    raise AssertionError(task)

  gaps = {gap["check_id"]: gap for gap in task["blocker_gap_report"]}
  for check_id in [
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "moonbook-review",
    "robot-simulation",
  ]:
    if check_id not in gaps:
      raise AssertionError(gaps)
    if not gaps[check_id]["evidence_path"] or not gaps[check_id]["next_action"]:
      raise AssertionError(gaps[check_id])

  commands = "\n".join(task["commands"])
  for required in [
    "check_moonrobo_readiness_preview.py",
    "scan_lola_corridor.py --plan",
    "check_energy_margin_remediation.py",
    "build_moonmoon_dossier.sh --review-transitions",
    "materialize_moonbook_workspace.py --check",
    "/Users/kq/.moon/bin/moon test",
  ]:
    if required not in commands:
      raise AssertionError(commands)

  criteria = {item["criterion_id"] for item in task["acceptance_criteria"]}
  if criteria != {
    "gap-report-consumed",
    "remediation-commands",
    "robot-safety-invariant",
  }:
    raise AssertionError(criteria)

  invariants = "\n".join(task["robot_safety_invariants"])
  if "HardwareDenied" not in invariants:
    raise AssertionError(invariants)
  if "moonmoon-safety-gate-only" not in invariants:
    raise AssertionError(invariants)
  if "physical execution authority must not be emitted" not in invariants:
    raise AssertionError(invariants)
  if "hardware execution" not in task["safety_gate"]:
    raise AssertionError(task["safety_gate"])

  if "## Blocker Gaps" not in markdown:
    raise AssertionError(markdown)
  if "## Robot Safety Invariants" not in markdown:
    raise AssertionError(markdown)
  if "terrain-northeast-stepout" not in markdown:
    raise AssertionError(markdown)
  if "moonmoon-safety-gate-only" not in markdown:
    raise AssertionError(markdown)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonclaw-gap-task-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_gap_task(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
