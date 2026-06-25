#!/usr/bin/env python3
"""Check MoonClaw receipt generated for imported MoonRobo gap remediation."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
RECEIPT_ID = (
  "moonclaw/first-trusted-square/moonrobo-gap-remediation-v1/current-receipt"
)
TASK_ID = "moonclaw/first-trusted-square/moonrobo-gap-remediation-v1/task"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_gap_receipt(root: Path) -> None:
  receipt_path = (
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json"
  )
  markdown_path = (
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.md"
  )
  task_path = root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json"
  preview_path = (
    root / "output/moonrobo/first_trusted_square_readiness_preview.json"
  )

  receipts = load_json(receipt_path)
  task = load_json(task_path)[0]
  preview = load_json(preview_path)
  markdown = markdown_path.read_text(encoding="utf-8")
  if len(receipts) != 1:
    raise AssertionError(receipts)
  receipt = receipts[0]

  if receipt["receipt"]["receipt_id"] != RECEIPT_ID:
    raise AssertionError(receipt["receipt"]["receipt_id"])
  if receipt["source_task_id"] != TASK_ID:
    raise AssertionError(receipt["source_task_id"])
  if receipt["source_task_id"] != task["task_id"]:
    raise AssertionError("receipt does not consume generated gap task")
  if receipt["source_preview_id"] != preview["preview_id"]:
    raise AssertionError("receipt does not consume generated preview")
  if receipt["remediation_state"] != "OpenGapsCarriedForward":
    raise AssertionError(receipt["remediation_state"])
  if receipt["hardware_state"] != "HardwareDenied":
    raise AssertionError(receipt["hardware_state"])
  if receipt["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(receipt["hardware_authority"])
  if not receipt["hardware_denied"]:
    raise AssertionError("receipt does not preserve hardware denial")

  task_gaps = {gap["check_id"]: gap for gap in task["blocker_gap_report"]}
  results = {result["check_id"]: result for result in receipt["gap_results"]}
  if set(results) != set(task_gaps):
    raise AssertionError(results)
  if receipt["still_blocking_gap_count"] != len(task_gaps):
    raise AssertionError(receipt["still_blocking_gap_count"])
  if receipt["cleared_gap_count"] != 0:
    raise AssertionError(receipt["cleared_gap_count"])
  for check_id, result in results.items():
    if result["status"] != "StillBlocking":
      raise AssertionError(result)
    if result["evidence_path"] != task_gaps[check_id]["evidence_path"]:
      raise AssertionError(result)
    if not result["next_action"]:
      raise AssertionError(result)

  checks = {check["validation_id"]: check for check in receipt["validation_checks"]}
  for check_id in [
    "source-task-present",
    "gap-accounting-complete",
    "hardware-denial-preserved",
    "still-blocking-gaps-carried-forward",
  ]:
    if not checks.get(check_id, {}).get("passed"):
      raise AssertionError(checks)

  notes = "\n".join(receipt["receipt"]["validation_notes"])
  if "hardware-denial-preserved: pass" not in notes:
    raise AssertionError(notes)
  if "## Gap Results" not in markdown:
    raise AssertionError(markdown)
  if "StillBlocking" not in markdown:
    raise AssertionError(markdown)
  if "moonmoon-safety-gate-only" not in markdown:
    raise AssertionError(markdown)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-moonclaw-gap-receipt-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    assert_gap_receipt(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
