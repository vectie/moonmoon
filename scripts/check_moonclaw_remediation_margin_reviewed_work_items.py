#!/usr/bin/env python3
"""Check MoonClaw reviewed remediation-margin work item output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PLAN_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json"
)
ITEMS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json"
)
ITEMS_MD = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.md"
)
PLAN_ID = "moonclaw/first-trusted-square/remediation-margin-v1/reviewed-action-plan"
REVIEW_TRANSITION_ID = (
  "rabbita-moonclaw-remediation-margin-closeout-action-review-accept"
)
EXPECTED_ITEMS = {
  "terrain-northeast-stepout": {
    "rank": 1,
    "refresh_id": "refresh-terrain-northeast-stepout",
    "blocker_domain": "terrain",
    "disposition": "EscalateToOperatorDecision",
    "command": "manual: review DEM",
    "check": "python3 scripts/check_selected_route_terrain_remediation.py",
  },
  "illumination-northeast-stepout": {
    "rank": 2,
    "refresh_id": "refresh-illumination-northeast-stepout",
    "blocker_domain": "local-horizon",
    "disposition": "RetryWithNewEvidence",
    "command": "python3 scripts/generate_selected_route_horizon.py --check",
    "check": "python3 scripts/check_selected_route_horizon_model.py",
  },
  "energy-window": {
    "rank": 3,
    "refresh_id": "refresh-energy-window",
    "blocker_domain": "energy",
    "disposition": "FreezeUntilNewSourceEvidence",
    "command": "manual: keep energy-window frozen",
    "check": "python3 scripts/check_energy_margin_remediation.py",
  },
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_items(plan: dict[str, Any], items: list[dict[str, Any]]) -> None:
  require(len(items) == 3, "expected three reviewed work items")
  actions = {action["margin_id"]: action for action in plan["actions"]}
  by_margin = {item["margin_id"]: item for item in items}
  require(set(by_margin) == set(EXPECTED_ITEMS), "unexpected work item margins")
  require(set(by_margin) == set(actions), "work items diverge from plan actions")
  for margin_id, expected in EXPECTED_ITEMS.items():
    item = by_margin[margin_id]
    action = actions[margin_id]
    require(
      item["work_item_id"] == f"{PLAN_ID}/work-item-{expected['rank']}-{margin_id}",
      f"{margin_id} work item id changed",
    )
    require(item["plan_id"] == PLAN_ID, f"{margin_id} plan id changed")
    require(item["plan_id"] == plan["plan_id"], f"{margin_id} plan diverges")
    require(item["state"] == "Accepted", f"{margin_id} state changed")
    require(item["route_id"] == plan["route_id"], f"{margin_id} route changed")
    require(item["rank"] == expected["rank"], f"{margin_id} rank changed")
    require(
      item["refresh_id"] == expected["refresh_id"],
      f"{margin_id} refresh changed",
    )
    require(
      item["blocker_domain"] == expected["blocker_domain"],
      f"{margin_id} domain changed",
    )
    require(
      item["disposition"] == expected["disposition"],
      f"{margin_id} disposition changed",
    )
    require(
      item["disposition"] == action["disposition"],
      f"{margin_id} disposition diverges from plan",
    )
    require(
      item["required_evidence"] == action["required_evidence"],
      f"{margin_id} required evidence diverges",
    )
    require(
      item["target_artifact_path"] == action["target_artifact_path"],
      f"{margin_id} target diverges",
    )
    require(expected["command"] in item["command"], f"{margin_id} command changed")
    require(item["command"] == action["command"], f"{margin_id} command diverges")
    require(
      item["acceptance_check"] == expected["check"],
      f"{margin_id} check changed",
    )
    require(
      item["acceptance_check"] == action["acceptance_check"],
      f"{margin_id} check diverges",
    )
    require(
      item["source_review_transition_id"] == REVIEW_TRANSITION_ID,
      f"{margin_id} review transition changed",
    )
    require(item["source_review_decision"] == "Accept", f"{margin_id} review changed")
    require(
      item["reviewer_id"] == plan["reviewer_id"],
      f"{margin_id} reviewer changed",
    )
    require(
      item["reviewed_at_utc"] == plan["reviewed_at_utc"],
      f"{margin_id} reviewed timestamp changed",
    )
    require(item["may_consume_simulation"] is False, f"{margin_id} may-consume")
    require(
      item["simulation_state"] == "SimulationBlocked",
      f"{margin_id} simulation changed",
    )
    require(
      item["automatic_refresh_loop_allowed"] is False,
      f"{margin_id} refresh loop allowed",
    )
    require(item["hardware_state"] == "HardwareDenied", f"{margin_id} hardware")
    require(
      item["hardware_authority"] == "moonmoon-safety-gate-only",
      f"{margin_id} hardware authority",
    )
    require(
      item["hardware_authority_change"] is False,
      f"{margin_id} hardware authority changed",
    )
    require(item["hardware_denied"] is True, f"{margin_id} hardware denial")
    require(
      "do not start an automatic refresh loop" in item["safety_gate"],
      f"{margin_id} safety gate missing loop block",
    )


def assert_markdown(markdown: str) -> None:
  for token in (
    "MoonClaw Remediation Margin Reviewed Work Items",
    "work-item-1-terrain-northeast-stepout",
    "work-item-2-illumination-northeast-stepout",
    "work-item-3-energy-window",
    "review decision: Accept",
    "may consume simulation: false",
    "automatic refresh loop allowed: false",
    "hardware authority change: false",
    "moonmoon-safety-gate-only",
    "hardware-denied",
    "EscalateToOperatorDecision",
    "RetryWithNewEvidence",
    "FreezeUntilNewSourceEvidence",
  ):
    require(token in markdown, f"markdown missing {token!r}")


def main() -> None:
  plan = load_json(PLAN_JSON)[0]
  items = load_json(ITEMS_JSON)
  assert_items(plan, items)
  assert_markdown(ITEMS_MD.read_text(encoding="utf-8"))
  print("checked MoonClaw remediation-margin reviewed work items")


if __name__ == "__main__":
  main()
