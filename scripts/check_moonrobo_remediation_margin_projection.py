#!/usr/bin/env python3
"""Check MoonRobo remediation-margin simulation-consumption projection."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MODELING_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_modeling.json"
)
PROJECTION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
)
PROJECTION_MD = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_projection.md"
)
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
MODELING_PASS_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass"
)
MODELING_PATH = "output/moonrobo/first_trusted_square_remediation_margin_modeling.json"
MARGIN_IDS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def assert_projection() -> None:
  modeling = load_json(MODELING_JSON)[0]
  projection = load_json(PROJECTION_JSON)
  markdown = PROJECTION_MD.read_text(encoding="utf-8")

  if projection["projection_id"] != PROJECTION_ID:
    raise AssertionError(projection["projection_id"])
  if projection["source_modeling_pass_id"] != MODELING_PASS_ID:
    raise AssertionError(projection["source_modeling_pass_id"])
  if projection["source_modeling_pass_id"] != modeling["modeling_pass_id"]:
    raise AssertionError("projection does not consume generated modeling pass")
  if projection["source_modeling_path"] != MODELING_PATH:
    raise AssertionError(projection["source_modeling_path"])
  if projection["source_modeling_state"] != modeling["state"]:
    raise AssertionError(projection["source_modeling_state"])
  if projection["source_receipt_id"] != modeling["source_receipt_id"]:
    raise AssertionError(projection["source_receipt_id"])
  if projection["source_task_id"] != modeling["source_task_id"]:
    raise AssertionError(projection["source_task_id"])
  if projection["route_id"] != modeling["route_id"]:
    raise AssertionError(projection["route_id"])

  if projection["projection_status"] != "NoConsumeSimulationBlocked":
    raise AssertionError(projection["projection_status"])
  if projection["may_consume_simulation"]:
    raise AssertionError(projection)
  if projection["simulation_state"] != "SimulationBlocked":
    raise AssertionError(projection["simulation_state"])
  if projection["active_margin_count"] != modeling["active_margin_count"]:
    raise AssertionError(projection["active_margin_count"])
  if projection["cleared_margin_count"] != modeling["cleared_margin_count"]:
    raise AssertionError(projection["cleared_margin_count"])
  if (
    projection["still_blocking_margin_count"]
    != modeling["still_blocking_margin_count"]
  ):
    raise AssertionError(projection["still_blocking_margin_count"])
  if set(projection["blocking_margin_ids"]) != MARGIN_IDS:
    raise AssertionError(projection["blocking_margin_ids"])
  if set(projection["consumed_margin_result_ids"]) != MARGIN_IDS:
    raise AssertionError(projection["consumed_margin_result_ids"])

  if projection["hardware_state"] != "HardwareDenied":
    raise AssertionError(projection["hardware_state"])
  if projection["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(projection["hardware_authority"])
  if projection["hardware_denied"] is not True:
    raise AssertionError(projection["hardware_denied"])
  if projection["hardware_state"] != modeling["hardware_state"]:
    raise AssertionError("projection hardware state diverges from modeling")
  if projection["hardware_authority"] != modeling["hardware_authority"]:
    raise AssertionError("projection hardware authority diverges from modeling")

  for term in [
    "no-consume projection",
    "3 remediation margins still block simulation consumption",
    "AllMarginsStillBlocking",
    "moonmoon-safety-gate-only",
  ]:
    if term not in projection["reason"]:
      raise AssertionError(projection["reason"])

  for term in [
    "MoonRobo Remediation Margin Clearance Projection",
    "NoConsumeSimulationBlocked",
    "may consume simulation: false",
    "simulation-blocked",
    "hardware-denied",
    *MARGIN_IDS,
  ]:
    if term not in markdown:
      raise AssertionError(term)


def main() -> int:
  assert_projection()
  print("checked MoonRobo remediation margin projection")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
