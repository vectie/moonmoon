#!/usr/bin/env python3
"""Check MoonRobo remediation-margin refresh follow-up projection output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MODELING_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json"
)
PROJECTION_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json"
)
PROJECTION_MD = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.md"
)
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-refresh-followup-projection.json"
SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json"
)
MODELING_SOURCE_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json"
)
PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection"
)
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-modeling-pass"
)
SOURCE_REFRESH_PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
)
RECEIPT_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt"
)
TASK_ID = (
  "moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task"
)
REFRESH_IDS = {
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
}
MARGIN_IDS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_projection(modeling: dict[str, Any], projection: dict[str, Any]) -> None:
  require(projection["projection_id"] == PROJECTION_ID, "unexpected projection id")
  require(
    projection["source_modeling_pass_id"] == MODELING_PASS_ID,
    "unexpected source modeling pass",
  )
  require(
    projection["source_modeling_pass_id"] == modeling["modeling_pass_id"],
    "projection does not consume follow-up modeling pass",
  )
  require(
    projection["source_modeling_path"] == MODELING_SOURCE_PATH,
    "unexpected source modeling path",
  )
  require(
    projection["source_modeling_state"] == "AllFollowupRefreshesStillBlocking",
    "unexpected source modeling state",
  )
  require(
    projection["source_modeling_state"] == modeling["state"],
    "projection source state diverges from modeling",
  )
  require(projection["source_receipt_id"] == RECEIPT_ID, "unexpected receipt")
  require(
    projection["source_receipt_id"] == modeling["source_receipt_id"],
    "receipt diverges from modeling",
  )
  require(projection["source_task_id"] == TASK_ID, "unexpected task")
  require(
    projection["source_task_id"] == modeling["source_task_id"],
    "task diverges from modeling",
  )
  require(
    projection["source_refresh_projection_id"] == SOURCE_REFRESH_PROJECTION_ID,
    "unexpected source refresh projection",
  )
  require(
    projection["source_refresh_projection_id"]
    == modeling["source_refresh_projection_id"],
    "source refresh projection diverges from modeling",
  )
  require(
    projection["source_followup_state"] == "FollowupRefreshesCarriedForward",
    "unexpected source follow-up state",
  )
  require(
    projection["source_followup_state"] == modeling["source_followup_state"],
    "source follow-up state diverges from modeling",
  )
  require(projection["route_id"] == modeling["route_id"], "route diverges")

  require(
    projection["projection_status"]
    == "NoConsumeFollowupRefreshSimulationBlocked",
    "projection must block simulation consumption",
  )
  require(
    projection["may_consume_simulation"] is False,
    "simulation consumption must stay disabled",
  )
  require(
    projection["simulation_state"] == "SimulationBlocked",
    "simulation must stay blocked",
  )
  for key in ("followup_action_count", "refreshed_count", "still_blocking_count"):
    require(projection[key] == modeling[key], f"{key} diverges from modeling")
  require(projection["followup_action_count"] == 3, "expected 3 follow-up actions")
  require(projection["refreshed_count"] == 0, "expected no refreshed follow-ups")
  require(
    projection["still_blocking_count"] == 3,
    "expected 3 still-blocking follow-ups",
  )
  require(
    set(projection["consumed_followup_result_ids"]) == REFRESH_IDS,
    "consumed follow-up ids changed",
  )
  require(
    set(projection["blocking_refresh_ids"]) == REFRESH_IDS,
    "blocking refresh ids changed",
  )
  require(
    set(projection["blocking_margin_ids"]) == MARGIN_IDS,
    "blocking margin ids changed",
  )

  require(projection["hardware_state"] == "HardwareDenied", "hardware changed")
  require(
    projection["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  require(projection["hardware_denied"] is True, "hardware_denied changed")
  require(
    projection["hardware_state"] == modeling["hardware_state"],
    "hardware state diverges from modeling",
  )
  require(
    projection["hardware_authority"] == modeling["hardware_authority"],
    "hardware authority diverges from modeling",
  )

  for token in (
    "no-consume follow-up refresh projection",
    "3 remediation-margin follow-up refreshes still block simulation consumption",
    "AllFollowupRefreshesStillBlocking",
    "moonmoon-safety-gate-only",
  ):
    require(token in projection["reason"], f"reason missing {token}")
  require(
    "do not let MoonRobo consume follow-up refreshed simulation evidence"
    in projection["next_action"],
    "next action should keep follow-up simulation consumption blocked",
  )


def assert_workspace(projection: dict[str, Any]) -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  entry_file = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "MoonBook index missing follow-up projection")
  entry = entries[ENTRY_ID]
  require(
    entry["kind"] == "MoonroboRemediationMarginRefreshFollowupProjection",
    f"unexpected entry kind {entry['kind']}",
  )
  require(entry["path"] == ENTRY_PATH, f"unexpected entry path {entry['path']}")
  for token in (
    "NoConsumeFollowupRefreshSimulationBlocked",
    "AllFollowupRefreshesStillBlocking",
    "3 still-blocking follow-up refreshes",
    "refresh-terrain-northeast-stepout",
    "refresh-illumination-northeast-stepout",
    "refresh-energy-window",
    *MARGIN_IDS,
    "simulation-blocked",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ):
    require(token in entry["summary"], f"entry summary missing {token}")
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing entry path")
  require(SOURCE_PATH in index["source_files"], "index missing projection source")
  require(SOURCE_PATH in readme, "README missing projection source")
  require(entry_file["entry"] == entry, "per-entry wrapper diverges from index")
  require(entry_file["payload"] == projection, "workspace projection diverges")


def main() -> int:
  modeling_passes = load_json(MODELING_JSON)
  projection = load_json(PROJECTION_JSON)
  markdown = PROJECTION_MD.read_text(encoding="utf-8")
  require(len(modeling_passes) == 1, "expected one follow-up modeling pass")
  assert_projection(modeling_passes[0], projection)
  assert_workspace(projection)

  for token in (
    "MoonRobo Remediation Margin Refresh Follow-Up Projection",
    "NoConsumeFollowupRefreshSimulationBlocked",
    "AllFollowupRefreshesStillBlocking",
    "may consume simulation: false",
    "simulation-blocked",
    "hardware-denied",
    "moonmoon-safety-gate-only",
    *REFRESH_IDS,
    *MARGIN_IDS,
  ):
    require(token in markdown, f"markdown missing {token}")

  print("checked MoonRobo remediation margin refresh follow-up projection")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
