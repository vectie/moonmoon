#!/usr/bin/env python3
"""Smoke-check that the generated Rabbita UI boots from external assets."""

from __future__ import annotations

from typing import Any

from rabbita_ui_harness import (
  MISSION_EVIDENCE_SNAPSHOT_JS,
  assert_mission_evidence_queue,
  read_rabbita_page,
  run_rabbita_vm,
)


SNAPSHOT_JS = r"""
const closeout = JSON.parse(document.getElementById('closeout-action-review-export').value);
const clearance = JSON.parse(document.getElementById('transition-export').value);
const queue = (() => { """ + MISSION_EVIDENCE_SNAPSHOT_JS + r""" })();
return {
  terrain_cells: document.getElementById('terrain-grid').children.length,
  route_rows: document.getElementById('routes').children.length,
  fact_rows: document.getElementById('facts').children.length,
  review_rows: document.getElementById('review').children.length,
  selected_route_remediation_rows: document.getElementById('selected-route-remediation').children.length,
  queue,
  closeout,
  clearance
};
"""


def assert_runtime(rendered: dict[str, Any], view: dict[str, Any], book: dict[str, Any]) -> None:
  if rendered["terrain_cells"] != len(view["terrain_cells"]):
    raise AssertionError(rendered["terrain_cells"])
  if rendered["route_rows"] != len(view["routes"]):
    raise AssertionError(rendered["route_rows"])
  if rendered["fact_rows"] != len(view["inspector_facts"]):
    raise AssertionError(rendered["fact_rows"])
  if rendered["review_rows"] != 5:
    raise AssertionError(rendered["review_rows"])
  if rendered["selected_route_remediation_rows"] != 3:
    raise AssertionError(rendered["selected_route_remediation_rows"])
  assert_mission_evidence_queue(rendered["queue"], book)

  clearance_items = [item for item in book["review_queue"] if item["item_id"].startswith("clear-")]
  clearance = rendered["clearance"]
  if len(clearance["transitions"]) != len(clearance_items):
    raise AssertionError(clearance)
  if clearance["generated_by"] != "output/ui/rabbita/first_trusted_square.html":
    raise AssertionError(clearance["generated_by"])

  closeout = rendered["closeout"]
  if closeout["review_kind"] != "moonclaw-remediation-margin-closeout-action":
    raise AssertionError(closeout)
  if len(closeout["transitions"]) != 1:
    raise AssertionError(closeout)
  transition = closeout["transitions"][0]
  if transition["hardware_state"] != "HardwareDenied":
    raise AssertionError(transition)
  if transition["hardware_authority_change"] is not False:
    raise AssertionError(transition)


def main() -> int:
  _, view, book = read_rabbita_page()
  rendered = run_rabbita_vm(
    view,
    book,
    SNAPSHOT_JS,
    prefix="moonmoon-rabbita-runtime-",
  )
  assert_runtime(rendered, view, book)
  print("checked Rabbita runtime")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
