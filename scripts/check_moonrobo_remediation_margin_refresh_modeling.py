#!/usr/bin/env python3
"""Check MoonRobo remediation-margin refresh modeling output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MOONCLAW_RECEIPT = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json"
)
MOONROBO_MODELING = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json"
)
MOONROBO_MODELING_MD = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.md"
)
MODEL_ID = "moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass"
RECEIPT_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt"
TASK_ID = "moonclaw/first-trusted-square/remediation-margin-v1/refresh-task"
PROJECTION_ID = "moonrobo/first-trusted-square/remediation-margin-v1/projection"
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


def main() -> int:
  receipts = load_json(MOONCLAW_RECEIPT)
  passes = load_json(MOONROBO_MODELING)
  markdown = MOONROBO_MODELING_MD.read_text(encoding="utf-8")
  require(len(receipts) == 1, "expected one refresh receipt")
  require(len(passes) == 1, "expected one refresh modeling pass")
  receipt = receipts[0]
  modeling = passes[0]

  require(modeling["modeling_pass_id"] == MODEL_ID, "unexpected modeling pass id")
  require(modeling["source_receipt_id"] == RECEIPT_ID, "unexpected source receipt")
  require(
    modeling["source_receipt_id"] == receipt["receipt"]["receipt_id"],
    "modeling pass source receipt diverges from receipt bundle",
  )
  require(modeling["source_task_id"] == TASK_ID, "unexpected source task")
  require(
    modeling["source_task_id"] == receipt["source_task_id"],
    "modeling pass source task diverges from receipt",
  )
  require(modeling["source_projection_id"] == PROJECTION_ID, "unexpected projection")
  require(
    modeling["source_projection_id"] == receipt["source_projection_id"],
    "modeling pass projection diverges from receipt",
  )
  require(
    modeling["source_refresh_state"] == receipt["refresh_state"],
    "source refresh state diverges from receipt",
  )
  require(
    modeling["state"] == "AllRefreshesStillBlocking",
    "refresh modeling should carry all refreshes forward",
  )
  require(modeling["refresh_action_count"] == 3, "expected 3 refresh actions")
  require(modeling["refreshed_count"] == 0, "expected no accepted refreshes")
  require(modeling["still_blocking_count"] == 3, "expected 3 still-blocking refreshes")
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

  receipt_results = {result["refresh_id"]: result for result in receipt["refresh_results"]}
  modeling_results = modeling["refresh_results"]
  require(len(modeling_results) == 3, "expected 3 refresh modeling results")
  require(
    [result["margin_id"] for result in modeling_results] == MARGINS,
    "refresh modeling result order changed",
  )
  for result in modeling_results:
    source = receipt_results.get(result["refresh_id"])
    require(source is not None, f"unknown refresh result {result['refresh_id']}")
    for key in (
      "rank",
      "margin_id",
      "source_projection_path",
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
      result["result_status"] == "RefreshStillBlocking",
      f"{result['refresh_id']} should remain still blocking",
    )
    require(result["refreshed"] is False, f"{result['refresh_id']} should not refresh")

  required_markdown = [
    "MoonRobo Remediation Margin Refresh Modeling Passes",
    "AllRefreshesStillBlocking",
    "RefreshesCarriedForward",
    "may consume simulation: false",
    "simulation-blocked",
    "RefreshStillBlocking",
    *MARGINS,
    "moonmoon-safety-gate-only",
    "do not let MoonRobo consume",
  ]
  for token in required_markdown:
    require(token in markdown, f"markdown missing {token}")

  print("checked MoonRobo remediation margin refresh modeling")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
