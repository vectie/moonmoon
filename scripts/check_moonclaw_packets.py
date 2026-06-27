#!/usr/bin/env python3
"""Verify generated MoonClaw packet bundles."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MOONCLAW = ROOT / "output/moonclaw"
SITE_ID = "first-trusted-square"
ROUTE_ID = "northeast-stepout"
MARGIN_IDS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
}
EXPECTED_COUNTS = {
  "first_trusted_square_corridor_receipts.json": 1,
  "first_trusted_square_corridor_tasks.json": 1,
  "first_trusted_square_ephemeris_receipts.json": 1,
  "first_trusted_square_ephemeris_tasks.json": 1,
  "first_trusted_square_moonrobo_gap_receipt.json": 1,
  "first_trusted_square_moonrobo_gap_task.json": 1,
  "first_trusted_square_noetix_review_task.json": 1,
  "first_trusted_square_proposals.json": 3,
  "first_trusted_square_receipts.json": 1,
  "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json": 3,
  "first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json": 1,
  "first_trusted_square_remediation_margin_closeout_action_task.json": 1,
  "first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json": 3,
  "first_trusted_square_remediation_margin_receipt.json": 1,
  "first_trusted_square_remediation_margin_refresh_followup_receipt.json": 1,
  "first_trusted_square_remediation_margin_refresh_followup_task.json": 1,
  "first_trusted_square_remediation_margin_refresh_receipt.json": 1,
  "first_trusted_square_remediation_margin_refresh_task.json": 1,
  "first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json": 3,
  "first_trusted_square_remediation_margin_reviewed_action_plan.json": 1,
  "first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json": 1,
  "first_trusted_square_remediation_margin_reviewed_work_item_receipts.json": 3,
  "first_trusted_square_remediation_margin_reviewed_work_items.json": 3,
  "first_trusted_square_remediation_margin_task.json": 1,
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def as_items(value: Any) -> list[dict[str, Any]]:
  if isinstance(value, list):
    if not value:
      raise AssertionError("empty packet list")
    return value
  if isinstance(value, dict):
    return [value]
  raise AssertionError(f"unexpected packet root {type(value).__name__}")


def walk_dicts(value: Any) -> list[dict[str, Any]]:
  found: list[dict[str, Any]] = []
  if isinstance(value, dict):
    found.append(value)
    for child in value.values():
      found.extend(walk_dicts(child))
  elif isinstance(value, list):
    for child in value:
      found.extend(walk_dicts(child))
  return found


def assert_hardware_invariants(value: Any, path: Path) -> None:
  for node in walk_dicts(value):
    if "hardware_state" in node and node["hardware_state"] != "HardwareDenied":
      raise AssertionError((path.name, node))
    if "hardware_authority" in node and node["hardware_authority"] != "moonmoon-safety-gate-only":
      raise AssertionError((path.name, node))
    if "hardware_denied" in node and node["hardware_denied"] is not True:
      raise AssertionError((path.name, node))
    if "hardware_authority_change" in node and node["hardware_authority_change"] is not False:
      raise AssertionError((path.name, node))
    if "may_consume_simulation" in node and node["may_consume_simulation"] is not False:
      raise AssertionError((path.name, node))
    if "automatic_refresh_loop_allowed" in node and node["automatic_refresh_loop_allowed"] is not False:
      raise AssertionError((path.name, node))


def assert_receipt(receipt: dict[str, Any], path: Path) -> None:
  if "receipt_id" not in receipt or not receipt["receipt_id"].startswith("moonclaw/first-trusted-square/"):
    raise AssertionError((path.name, receipt))
  if receipt.get("status") != "Accepted":
    raise AssertionError((path.name, receipt))
  if not receipt.get("accepted_outputs"):
    raise AssertionError((path.name, receipt))
  notes = receipt.get("validation_notes", [])
  if not notes or not all("pass" in note for note in notes):
    raise AssertionError((path.name, notes))


def assert_item(item: dict[str, Any], path: Path) -> None:
  if item.get("site_id") != SITE_ID:
    raise AssertionError((path.name, item.get("site_id")))
  if "route_id" in item and item["route_id"] != ROUTE_ID:
    raise AssertionError((path.name, item["route_id"]))
  if "state" in item and item["state"] not in {"Accepted", "NeedsReview"}:
    raise AssertionError((path.name, item["state"]))
  if "receipt" in item:
    assert_receipt(item["receipt"], path)
  if "acceptance_criteria" in item and not item["acceptance_criteria"]:
    raise AssertionError((path.name, "missing acceptance criteria"))
  if "commands" in item and not item["commands"]:
    raise AssertionError((path.name, "missing commands"))
  for key in ["active_margin_ids", "ranked_margin_ids", "blocking_margin_ids"]:
    if key in item and set(item[key]) != MARGIN_IDS:
      raise AssertionError((path.name, key, item[key]))


def assert_markdown(path: Path, items: list[dict[str, Any]]) -> None:
  markdown = path.with_suffix(".md")
  if not markdown.exists():
    return
  text = markdown.read_text(encoding="utf-8")
  if "moonmoon-safety-gate-only" in json.dumps(items) and "moonmoon-safety-gate-only" not in text:
    raise AssertionError(markdown.name)
  if "remediation_margin" in path.name:
    for margin_id in MARGIN_IDS:
      if margin_id not in text:
        raise AssertionError((markdown.name, margin_id))


def main() -> int:
  actual = {path.name: path for path in MOONCLAW.glob("first_trusted_square*.json")}
  if set(actual) != set(EXPECTED_COUNTS):
    raise AssertionError({"missing": sorted(set(EXPECTED_COUNTS) - set(actual)), "extra": sorted(set(actual) - set(EXPECTED_COUNTS))})
  for name, expected_count in sorted(EXPECTED_COUNTS.items()):
    path = actual[name]
    packet = load_json(path)
    items = as_items(packet)
    if len(items) != expected_count:
      raise AssertionError((name, len(items), expected_count))
    assert_hardware_invariants(packet, path)
    for item in items:
      assert_item(item, path)
    assert_markdown(path, items)
  print("checked MoonClaw packets")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
