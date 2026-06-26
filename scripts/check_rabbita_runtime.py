#!/usr/bin/env python3
"""Smoke-check that the generated Rabbita UI boots from external assets."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from rabbita_ui_harness import extract_json_script, run_rabbita_vm


ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"


SNAPSHOT_JS = r"""
const evidenceRows = document.getElementById('mission-evidence-queue').children.map(row => ({
  family: row.attributes['data-evidence-family'],
  entry_id: row.attributes['data-entry-id'],
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
const filters = document.getElementById('mission-evidence-filters').children.map(button => ({
  label: button.textContent,
  pressed: button.attributes['aria-pressed']
}));
const closeout = JSON.parse(document.getElementById('closeout-action-review-export').value);
const clearance = JSON.parse(document.getElementById('transition-export').value);
return {
  terrain_cells: document.getElementById('terrain-grid').children.length,
  route_rows: document.getElementById('routes').children.length,
  fact_rows: document.getElementById('facts').children.length,
  review_rows: document.getElementById('review').children.length,
  selected_route_remediation_rows: document.getElementById('selected-route-remediation').children.length,
  evidence_rows: evidenceRows,
  filters,
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
  evidence_rows = rendered["evidence_rows"]
  if len(evidence_rows) != 24:
    raise AssertionError(len(evidence_rows))
  family_counts: dict[str, int] = {}
  for row in evidence_rows:
    family_counts[row["family"]] = family_counts.get(row["family"], 0) + 1
    if not row["path"].startswith("moonbook://moonmoon/first-trusted-square/"):
      raise AssertionError(row)
  if family_counts != {
    "blocker": 6,
    "receipt": 7,
    "remediation": 6,
    "review": 2,
    "simulation": 3,
  }:
    raise AssertionError(family_counts)

  filters = {item["label"]: item["pressed"] for item in rendered["filters"]}
  expected_filters = {
    "All 24": "true",
    "Blockers 6": "false",
    "Work 6": "false",
    "Receipts 7": "false",
    "Simulation 3": "false",
    "Review 2": "false",
  }
  if filters != expected_filters:
    raise AssertionError(filters)

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
  html = HTML_PATH.read_text(encoding="utf-8")
  view = extract_json_script(html, "moonmoon-view-model")
  book = extract_json_script(html, "moonmoon-moonbook")
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
