#!/usr/bin/env python3
"""Check MoonClaw remediation-margin refresh receipt is durable in MoonBook."""

from __future__ import annotations

import json
import shutil
import tempfile
from pathlib import Path
from typing import Any

import check_rabbita_transition_import
import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"
WORKSPACE = Path("output/moonbook/workspaces/first-trusted-square")
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-refresh-receipt"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-refresh-receipt.json"
SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json"
)
TASK_SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json"
)
RECEIPT_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task"
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_refresh_receipt_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  source_task = load_json(root / TASK_SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no refresh receipt entry")
  entry = entries[ENTRY_ID]
  if entry["kind"] != "MoonClawRemediationMarginRefreshReceipt":
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "RefreshesCarriedForward",
    "3 still-blocking refreshes",
    "terrain-northeast-stepout",
    "illumination-northeast-stepout",
    "energy-window",
    "0 refreshed",
    PROJECTION_ID,
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no refresh receipt payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh receipt")
  if TASK_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include refresh task")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name refresh receipt source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve indexed entry")
  payload = entry_file["payload"]
  if payload["receipts"] != source:
    raise AssertionError("workspace payload diverges from generated receipt bundle")
  primary = payload["primary_receipt"]
  if primary != source[0]:
    raise AssertionError("primary receipt diverges from generated source")
  if primary["receipt"]["receipt_id"] != RECEIPT_ID:
    raise AssertionError(primary["receipt"]["receipt_id"])
  if primary["source_task_id"] != TASK_ID:
    raise AssertionError(primary["source_task_id"])
  if primary["source_task_id"] != source_task[0]["task_id"]:
    raise AssertionError("refresh receipt source task diverges from task bundle")
  if primary["source_projection_id"] != PROJECTION_ID:
    raise AssertionError(primary["source_projection_id"])
  if primary["source_projection_id"] != source_task[0]["source_projection_id"]:
    raise AssertionError("refresh receipt projection diverges from task bundle")
  if primary["refresh_state"] != "RefreshesCarriedForward":
    raise AssertionError(primary["refresh_state"])
  if primary["refresh_action_count"] != 3:
    raise AssertionError(primary["refresh_action_count"])
  if primary["refreshed_count"] != 0:
    raise AssertionError(primary["refreshed_count"])
  if primary["still_blocking_count"] != 3:
    raise AssertionError(primary["still_blocking_count"])
  if primary["ranked_margin_ids"] != MARGIN_IDS:
    raise AssertionError(primary["ranked_margin_ids"])
  if primary["ranked_margin_ids"] != source_task[0]["ranked_margin_ids"]:
    raise AssertionError("refresh receipt ranked margins diverge from task")

  results = primary["refresh_results"]
  actions = source_task[0]["refresh_actions"]
  if len(results) != len(actions):
    raise AssertionError(results)
  for result, action in zip(results, actions, strict=True):
    for key in (
      "rank",
      "margin_id",
      "refresh_id",
      "source_projection_path",
      "target_artifact_path",
      "command",
      "acceptance_check",
    ):
      if result[key] != action[key]:
        raise AssertionError(f"{result['refresh_id']} changed {key}")
    if result["status"] != "RefreshStillBlocking":
      raise AssertionError(result)
    if result["evidence_path"] != action["target_artifact_path"]:
      raise AssertionError(result)

  if not all(check["passed"] for check in primary["validation_checks"]):
    raise AssertionError(primary["validation_checks"])
  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])
  if primary["hardware_state"] != source_task[0]["hardware_state"]:
    raise AssertionError("hardware state diverges from refresh task")
  if primary["hardware_authority"] != source_task[0]["hardware_authority"]:
    raise AssertionError("hardware authority diverges from refresh task")


def main() -> int:
  assert_refresh_receipt_workspace(ROOT)
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-moonbook-remediation-refresh-receipt-",
  ) as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_refresh_receipt_workspace(tmp_root)
  print("checked MoonBook remediation margin refresh receipt workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
