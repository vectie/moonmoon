#!/usr/bin/env python3
"""Check MoonRobo remediation-margin refresh follow-up modeling output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MOONCLAW_RECEIPT = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
)
MOONROBO_MODELING = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json"
)
MOONROBO_MODELING_MD = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.md"
)
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-refresh-followup-modeling.json"
SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json"
)
RECEIPT_SOURCE_PATH = (
  "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
)
MODEL_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-modeling-pass"
)
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt"
)
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task"
)
PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
)
SOURCE_MODELING_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass"
)
MARGINS = [
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
]


def load_json(path: Path) -> Any:
  with path.open(encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_modeling(receipt: dict[str, Any], modeling: dict[str, Any]) -> None:
  require(modeling["modeling_pass_id"] == MODEL_ID, "unexpected modeling pass id")
  require(modeling["source_receipt_id"] == RECEIPT_ID, "unexpected source receipt")
  require(
    modeling["source_receipt_id"] == receipt["receipt"]["receipt_id"],
    "modeling pass source receipt diverges from follow-up receipt bundle",
  )
  require(modeling["source_task_id"] == TASK_ID, "unexpected source task")
  require(
    modeling["source_task_id"] == receipt["source_task_id"],
    "modeling pass source task diverges from follow-up receipt",
  )
  require(
    modeling["source_refresh_projection_id"] == PROJECTION_ID,
    "unexpected source refresh projection",
  )
  require(
    modeling["source_refresh_projection_id"]
    == receipt["source_refresh_projection_id"],
    "modeling pass projection diverges from follow-up receipt",
  )
  require(
    modeling["source_modeling_pass_id"] == SOURCE_MODELING_ID,
    "unexpected source modeling pass",
  )
  require(
    modeling["source_modeling_pass_id"] == receipt["source_modeling_pass_id"],
    "modeling source pass diverges from follow-up receipt",
  )
  require(
    modeling["source_modeling_state"] == receipt["source_modeling_state"],
    "source modeling state diverges from follow-up receipt",
  )
  require(
    modeling["source_projection_status"] == receipt["source_projection_status"],
    "source projection status diverges from follow-up receipt",
  )
  require(
    modeling["source_followup_state"] == receipt["refresh_state"],
    "source follow-up state diverges from follow-up receipt",
  )
  require(
    modeling["state"] == "AllFollowupRefreshesStillBlocking",
    "follow-up modeling should carry all follow-up refreshes forward",
  )
  require(modeling["followup_action_count"] == 3, "expected 3 follow-up actions")
  require(modeling["refreshed_count"] == 0, "expected no accepted follow-up refreshes")
  require(
    modeling["still_blocking_count"] == 3,
    "expected 3 still-blocking follow-up refreshes",
  )
  require(modeling["may_consume_simulation"] is False, "simulation must not consume")
  require(
    modeling["simulation_state"] == "SimulationBlocked",
    "simulation state must stay blocked",
  )
  require(modeling["hardware_state"] == "HardwareDenied", "hardware must stay denied")
  require(
    modeling["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  require(modeling["hardware_denied"] is True, "hardware_denied must stay true")
  require(
    modeling["hardware_state"] == receipt["hardware_state"],
    "hardware state diverges from receipt",
  )
  require(
    modeling["hardware_authority"] == receipt["hardware_authority"],
    "hardware authority diverges from receipt",
  )

  receipt_results = {
    result["refresh_id"]: result for result in receipt["followup_results"]
  }
  modeling_results = modeling["followup_results"]
  require(len(modeling_results) == 3, "expected 3 follow-up modeling results")
  require(
    [result["margin_id"] for result in modeling_results] == MARGINS,
    "follow-up modeling result order changed",
  )
  for result in modeling_results:
    source = receipt_results.get(result["refresh_id"])
    require(source is not None, f"unknown follow-up result {result['refresh_id']}")
    for key in (
      "rank",
      "margin_id",
      "source_refresh_projection_path",
      "target_artifact_path",
      "evidence_path",
    ):
      require(result[key] == source[key], f"{result['refresh_id']} changed {key}")
    require(
      result["receipt_status"] == source["status"],
      f"{result['refresh_id']} receipt status mismatch",
    )
    require(
      result["modeling_command"] == source["acceptance_check"],
      f"{result['refresh_id']} command should use receipt acceptance check",
    )
    require(
      result["result_status"] == "FollowupRefreshStillBlocking",
      f"{result['refresh_id']} should remain still blocking",
    )
    require(result["refreshed"] is False, f"{result['refresh_id']} should not refresh")


def assert_workspace(source: list[dict[str, Any]], modeling: dict[str, Any]) -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  entry_file = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "MoonBook index has no follow-up modeling entry")
  entry = entries[ENTRY_ID]
  require(
    entry["kind"] == "MoonroboRemediationMarginRefreshFollowupModeling",
    f"unexpected entry kind {entry['kind']}",
  )
  require(entry["path"] == ENTRY_PATH, f"unexpected entry path {entry['path']}")
  for text in [
    "AllFollowupRefreshesStillBlocking",
    "3 still-blocking follow-up refreshes",
    "refresh-terrain-northeast-stepout",
    "refresh-illumination-northeast-stepout",
    "refresh-energy-window",
    *MARGINS,
    "0 refreshed",
    RECEIPT_ID,
    PROJECTION_ID,
    "no-consume simulation",
    "simulation-blocked",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ]:
    require(text in entry["summary"], f"entry summary missing {text}")
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing entry path")
  require(SOURCE_PATH in index["source_files"], "index missing source modeling")
  require(
    RECEIPT_SOURCE_PATH in index["source_files"],
    "index missing follow-up receipt source",
  )
  require(SOURCE_PATH in readme, "README missing source modeling")
  require(entry_file["entry"] == entry, "per-entry wrapper diverges from index")
  payload = entry_file["payload"]
  require(payload["modeling_passes"] == source, "workspace bundle diverges")
  require(
    payload["primary_modeling_pass"] == modeling,
    "workspace primary pass diverges",
  )


def main() -> int:
  receipts = load_json(MOONCLAW_RECEIPT)
  passes = load_json(MOONROBO_MODELING)
  markdown = MOONROBO_MODELING_MD.read_text(encoding="utf-8")
  require(len(receipts) == 1, "expected one follow-up receipt")
  require(len(passes) == 1, "expected one follow-up modeling pass")
  receipt = receipts[0]
  modeling = passes[0]
  assert_modeling(receipt, modeling)
  assert_workspace(passes, modeling)

  for token in [
    "MoonRobo Remediation Margin Refresh Follow-Up Modeling Passes",
    "AllFollowupRefreshesStillBlocking",
    "FollowupRefreshesCarriedForward",
    "may consume simulation: false",
    "simulation-blocked",
    "FollowupRefreshStillBlocking",
    *MARGINS,
    "moonmoon-safety-gate-only",
    "do not let MoonRobo consume",
  ]:
    require(token in markdown, f"markdown missing {token}")

  print("checked MoonRobo remediation margin refresh follow-up modeling")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
