#!/usr/bin/env python3
"""Check MoonClaw closeout action task is durable in MoonBook workspace."""

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
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-closeout-action-task"
ENTRY_KIND = "MoonClawRemediationMarginCloseoutActionTask"
ENTRY_PATH = (
  "moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json"
)
SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
POLICY_SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
)
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/closeout-action-task"
POLICY_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy"
)
MARGIN_IDS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]
REFRESH_IDS = [
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
]
EXPECTED_ACTIONS = {
  "terrain-northeast-stepout": ("terrain", "EscalateToOperatorDecision"),
  "illumination-northeast-stepout": ("local-horizon", "RetryWithNewEvidence"),
  "energy-window": ("energy", "FreezeUntilNewSourceEvidence"),
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_closeout_action_workspace(root: Path) -> None:
  workspace = root / WORKSPACE
  index = load_json(workspace / "index.json")
  manifest = load_json(workspace / "manifest.json")
  source = load_json(root / SOURCE_PATH)
  policy = load_json(root / POLICY_SOURCE_PATH)
  entry_file = load_json(workspace / ENTRY_PATH)
  readme = (workspace / "README.md").read_text(encoding="utf-8")

  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  if ENTRY_ID not in entries:
    raise AssertionError("MoonBook workspace index has no closeout action task")
  entry = entries[ENTRY_ID]
  if entry["kind"] != ENTRY_KIND:
    raise AssertionError(entry)
  if entry["path"] != ENTRY_PATH:
    raise AssertionError(entry["path"])
  for text in [
    "needs-review",
    "NoConsumeCycleClosedForPolicy",
    "2 refresh cycles",
    "3 terrain/horizon/energy blockers",
    "terrain=EscalateToOperatorDecision",
    "local-horizon=RetryWithNewEvidence",
    "energy=FreezeUntilNewSourceEvidence",
    "simulation-blocked",
    "may consume false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    if text not in entry["summary"]:
      raise AssertionError(entry["summary"])

  if ENTRY_PATH not in manifest["entry_paths"]:
    raise AssertionError("manifest has no closeout action task payload path")
  if SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include closeout action task")
  if POLICY_SOURCE_PATH not in index["source_files"]:
    raise AssertionError("index source_files does not include closeout policy")
  if SOURCE_PATH not in readme:
    raise AssertionError("README does not name closeout action task source")
  if POLICY_SOURCE_PATH not in readme:
    raise AssertionError("README does not name closeout policy source")

  if entry_file["entry"] != entry:
    raise AssertionError("per-entry wrapper does not preserve indexed entry")
  payload = entry_file["payload"]
  if payload["tasks"] != source:
    raise AssertionError("workspace payload diverges from generated task bundle")
  review = payload["review"]
  if review["item_id"] != "moonclaw-remediation-margin-closeout-action-review":
    raise AssertionError(review)
  if review["entry_id"] != ENTRY_ID:
    raise AssertionError(review)
  if review["status"] != "NeedsReview":
    raise AssertionError(review)
  if review["decision"] != "RequestEvidence":
    raise AssertionError(review)
  if review["transition"] is not None:
    raise AssertionError(review)
  if review["hardware_authority_change"] is not False:
    raise AssertionError(review)
  if review["hardware_state"] != "HardwareDenied":
    raise AssertionError(review)
  if review["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(review)
  primary = payload["primary_task"]
  if primary != source[0]:
    raise AssertionError("primary task diverges from generated source")
  if primary["task_id"] != TASK_ID:
    raise AssertionError(primary["task_id"])
  if primary["source_policy_id"] != POLICY_ID:
    raise AssertionError(primary["source_policy_id"])
  if primary["source_policy_id"] != policy["policy_id"]:
    raise AssertionError("task source policy id diverges from policy")
  if primary["source_closeout_status"] != policy["closeout_status"]:
    raise AssertionError("task closeout status diverges from policy")
  if primary["source_closeout_status"] != "NoConsumeCycleClosedForPolicy":
    raise AssertionError(primary["source_closeout_status"])
  if primary["state"] != "NeedsReview":
    raise AssertionError(primary["state"])
  if primary["may_consume_simulation"]:
    raise AssertionError(primary)
  if primary["simulation_state"] != "SimulationBlocked":
    raise AssertionError(primary["simulation_state"])
  if primary["refresh_cycle_count"] != 2:
    raise AssertionError(primary["refresh_cycle_count"])
  if primary["blocker_count"] != 3:
    raise AssertionError(primary["blocker_count"])
  if primary["blocking_refresh_ids"] != REFRESH_IDS:
    raise AssertionError(primary["blocking_refresh_ids"])
  if primary["blocking_margin_ids"] != MARGIN_IDS:
    raise AssertionError(primary["blocking_margin_ids"])
  if primary["blocking_refresh_ids"] != policy["blocking_refresh_ids"]:
    raise AssertionError("task refresh ids diverge from policy")
  if primary["blocking_margin_ids"] != policy["blocking_margin_ids"]:
    raise AssertionError("task margin ids diverge from policy")

  actions = {
    action["margin_id"]: action for action in primary["closeout_actions"]
  }
  if set(actions) != set(EXPECTED_ACTIONS):
    raise AssertionError(actions)
  policy_items = {
    item["margin_id"]: item for item in policy["dispositions"]
  }
  for index, margin_id in enumerate(MARGIN_IDS, start=1):
    action = actions[margin_id]
    domain, disposition = EXPECTED_ACTIONS[margin_id]
    if action["rank"] != index:
      raise AssertionError(action)
    if action["refresh_id"] != REFRESH_IDS[index - 1]:
      raise AssertionError(action)
    if action["blocker_domain"] != domain:
      raise AssertionError(action)
    if action["disposition"] != disposition:
      raise AssertionError(action)
    if action["disposition"] != policy_items[margin_id]["disposition"]:
      raise AssertionError(action)
    if action["required_evidence"] != policy_items[margin_id]["required_evidence"]:
      raise AssertionError(action)
    if not action["target_artifact_path"]:
      raise AssertionError(action)
    if not action["command"] or not action["acceptance_check"]:
      raise AssertionError(action)

  if primary["hardware_state"] != "HardwareDenied":
    raise AssertionError(primary["hardware_state"])
  if primary["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(primary["hardware_authority"])
  if primary["hardware_denied"] is not True:
    raise AssertionError(primary["hardware_denied"])
  if primary["hardware_state"] != policy["hardware_state"]:
    raise AssertionError("hardware state diverges from policy")
  if primary["hardware_authority"] != policy["hardware_authority"]:
    raise AssertionError("hardware authority diverges from policy")
  if "must not emit another automatic follow-up refresh loop" not in primary["safety_gate"]:
    raise AssertionError(primary["safety_gate"])


def main() -> int:
  assert_closeout_action_workspace(ROOT)
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-moonbook-closeout-action-",
  ) as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_closeout_action_workspace(tmp_root)
  print("checked MoonBook remediation margin closeout action workspace")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
