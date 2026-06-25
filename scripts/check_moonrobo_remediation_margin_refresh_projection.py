#!/usr/bin/env python3
"""Check MoonRobo remediation-margin refresh projection output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MODELING_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json"
)
PROJECTION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
)
PROJECTION_MD = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.md"
)
PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
)
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass"
)
MODELING_PATH = (
  "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json"
)
SOURCE_PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
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


def main() -> int:
  modeling = load_json(MODELING_JSON)[0]
  projection = load_json(PROJECTION_JSON)
  markdown = PROJECTION_MD.read_text(encoding="utf-8")

  require(projection["projection_id"] == PROJECTION_ID, "unexpected projection id")
  require(
    projection["source_modeling_pass_id"] == MODELING_PASS_ID,
    "unexpected modeling source",
  )
  require(
    projection["source_modeling_pass_id"] == modeling["modeling_pass_id"],
    "projection does not consume generated refresh modeling pass",
  )
  require(
    projection["source_modeling_path"] == MODELING_PATH,
    "unexpected modeling path",
  )
  require(
    projection["source_modeling_state"] == "AllRefreshesStillBlocking",
    "unexpected source modeling state",
  )
  require(
    projection["source_modeling_state"] == modeling["state"],
    "source modeling state diverges from modeling pass",
  )
  require(
    projection["source_receipt_id"] == modeling["source_receipt_id"],
    "source receipt diverges",
  )
  require(
    projection["source_task_id"] == modeling["source_task_id"],
    "source task diverges",
  )
  require(
    projection["source_projection_id"] == SOURCE_PROJECTION_ID,
    "unexpected source projection",
  )
  require(
    projection["source_projection_id"] == modeling["source_projection_id"],
    "source projection diverges from modeling pass",
  )
  require(projection["route_id"] == modeling["route_id"], "route diverges")

  require(
    projection["projection_status"] == "NoConsumeRefreshSimulationBlocked",
    "projection should block simulation consumption",
  )
  require(
    projection["may_consume_simulation"] is False,
    "simulation consumption must stay disabled",
  )
  require(
    projection["simulation_state"] == "SimulationBlocked",
    "simulation state must stay blocked",
  )
  for key in ("refresh_action_count", "refreshed_count", "still_blocking_count"):
    require(projection[key] == modeling[key], f"{key} diverges from modeling pass")
  require(projection["refresh_action_count"] == 3, "expected 3 refresh actions")
  require(projection["refreshed_count"] == 0, "expected no accepted refreshes")
  require(projection["still_blocking_count"] == 3, "expected 3 blockers")
  require(
    set(projection["consumed_refresh_result_ids"]) == REFRESH_IDS,
    "consumed refresh ids changed",
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
    "no-consume refresh projection",
    "3 remediation-margin refreshes still block simulation consumption",
    "AllRefreshesStillBlocking",
    "moonmoon-safety-gate-only",
  ):
    require(token in projection["reason"], f"reason missing {token}")
  require(
    "do not let MoonRobo consume refreshed simulation evidence"
    in projection["next_action"],
    "next action should keep simulation consumption blocked",
  )

  for token in (
    "MoonRobo Remediation Margin Refresh Projection",
    "NoConsumeRefreshSimulationBlocked",
    "may consume simulation: false",
    "simulation-blocked",
    "hardware-denied",
    "AllRefreshesStillBlocking",
    *REFRESH_IDS,
    *MARGIN_IDS,
  ):
    require(token in markdown, f"markdown missing {token}")

  print("checked MoonRobo remediation margin refresh projection")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
