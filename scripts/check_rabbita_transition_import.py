#!/usr/bin/env python3
"""Check Rabbita transition import against a disposable generated output tree."""

from __future__ import annotations

import json
import re
import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions
import materialize_moonbook_workspace


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_accept.json"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def embedded_book(html_path: Path) -> dict[str, Any]:
  html = html_path.read_text(encoding="utf-8")
  match = re.search(
    r'<script id="moonmoon-moonbook" type="application/json">\n([\s\S]*?)\n</script>',
    html,
  )
  if not match:
    raise AssertionError("Rabbita HTML has no embedded MoonBook payload")
  return json.loads(match.group(1))


def assert_imported(root: Path) -> None:
  book = load_json(root / "output/moonbook/first_trusted_square_book.json")
  moonrobo = load_json(root / "output/moonrobo/first_trusted_square_handoffs.json")
  preview = load_json(
    root / "output/moonrobo/first_trusted_square_readiness_preview.json",
  )
  gap_task = load_json(
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json",
  )[0]
  gap_receipt = load_json(
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json",
  )[0]
  gap_modeling = load_json(
    root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json",
  )[0]
  workspace_entry = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json",
  )
  workspace_gap_task = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-task.json",
  )
  workspace_gap_receipt = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square/moonclaw/first-trusted-square/moonrobo-gap-receipt.json",
  )
  workspace_gap_modeling = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square/moonrobo/first-trusted-square/gap-remediation-modeling.json",
  )
  embedded = embedded_book(root / "output/ui/rabbita/first_trusted_square.html")

  selected_entry = next(
    entry for entry in book["entries"] if entry["kind"] == "SelectedRouteClearance"
  )
  if selected_entry["summary"] != "allow northeast-stepout: 4 clearance items, 0 blockers":
    raise AssertionError(selected_entry["summary"])

  selected_handoff = next(
    handoff for handoff in moonrobo if handoff["route_id"] == "northeast-stepout"
  )
  plan = selected_handoff["clearance_plan"]
  if plan["decision"] != "Allow":
    raise AssertionError(plan["decision"])
  if plan["blocking_items"] or plan["review_items"] or plan["rejected_items"]:
    raise AssertionError(plan)
  if len(plan["accepted_items"]) != 4:
    raise AssertionError(plan["accepted_items"])
  if {item["status"] for item in plan["items"]} != {"AcceptedEvidence"}:
    raise AssertionError(plan["items"])
  if preview["route_id"] != "northeast-stepout":
    raise AssertionError(preview["route_id"])
  if preview["clearance_decision"] != "Allow":
    raise AssertionError(preview["clearance_decision"])
  if preview["hardware_state"] != "HardwareDenied":
    raise AssertionError(preview["hardware_state"])

  if workspace_entry["payload"] != plan:
    raise AssertionError("workspace selected-route clearance was not materialized")
  if workspace_gap_task["payload"]["primary_task"] != gap_task:
    raise AssertionError("workspace MoonClaw gap task was not materialized")
  if workspace_gap_receipt["payload"]["primary_receipt"] != gap_receipt:
    raise AssertionError("workspace MoonClaw gap receipt was not materialized")
  if workspace_gap_modeling["payload"]["primary_modeling_pass"] != gap_modeling:
    raise AssertionError("workspace MoonRobo gap modeling was not materialized")

  clear_statuses = {
    item["item_id"]: item["status"]
    for item in embedded["review_queue"]
    if item["item_id"].startswith("clear-")
  }
  if set(clear_statuses.values()) != {"Accepted"}:
    raise AssertionError(clear_statuses)


def rebase_materializer(root: Path) -> None:
  materialize_moonbook_workspace.ROOT = root
  materialize_moonbook_workspace.SITE_JSON = root / "output/site/first_trusted_square.json"
  materialize_moonbook_workspace.BOOK_JSON = root / "output/moonbook/first_trusted_square_book.json"
  materialize_moonbook_workspace.MOONCLAW_JSON = (
    root / "output/moonclaw/first_trusted_square_proposals.json"
  )
  materialize_moonbook_workspace.MOONCLAW_EPHEMERIS_TASKS_JSON = (
    root / "output/moonclaw/first_trusted_square_ephemeris_tasks.json"
  )
  materialize_moonbook_workspace.MOONCLAW_CORRIDOR_TASKS_JSON = (
    root / "output/moonclaw/first_trusted_square_corridor_tasks.json"
  )
  materialize_moonbook_workspace.MOONCLAW_GAP_TASK_JSON = (
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json"
  )
  materialize_moonbook_workspace.MOONCLAW_GAP_RECEIPT_JSON = (
    root / "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json"
  )
  materialize_moonbook_workspace.MOONCLAW_RECEIPTS_JSON = (
    root / "output/moonclaw/first_trusted_square_receipts.json"
  )
  materialize_moonbook_workspace.MOONCLAW_EPHEMERIS_RECEIPTS_JSON = (
    root / "output/moonclaw/first_trusted_square_ephemeris_receipts.json"
  )
  materialize_moonbook_workspace.MOONCLAW_CORRIDOR_RECEIPTS_JSON = (
    root / "output/moonclaw/first_trusted_square_corridor_receipts.json"
  )
  materialize_moonbook_workspace.MOONROBO_JSON = (
    root / "output/moonrobo/first_trusted_square_handoffs.json"
  )
  materialize_moonbook_workspace.MOONROBO_GAP_MODELING_JSON = (
    root / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json"
  )
  materialize_moonbook_workspace.MOONROBO_SIMULATION_REVIEW_PACKET_JSON = (
    root / "output/moonrobo/first_trusted_square_simulation_review_packet.json"
  )
  materialize_moonbook_workspace.MOONROBO_SIMULATION_REVIEW_DECISION_JSON = (
    root / "output/moonrobo/first_trusted_square_simulation_review_decision.json"
  )
  materialize_moonbook_workspace.MOONROBO_SIMULATION_BLOCKER_REDUCTION_JSON = (
    root / "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json"
  )
  materialize_moonbook_workspace.MISSION_HORIZON_JSON = (
    root / "output/mission/first_trusted_square_northeast_stepout_horizon.json"
  )
  materialize_moonbook_workspace.MISSION_TERRAIN_REMEDIATION_JSON = (
    root
    / "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"
  )
  materialize_moonbook_workspace.MISSION_ENERGY_REMEDIATION_JSON = (
    root / "output/mission/first_trusted_square_energy_remediation.json"
  )
  materialize_moonbook_workspace.WORKSPACE = (
    root / "output/moonbook/workspaces/first-trusted-square"
  )


def materialize_temp_workspace(root: Path) -> None:
  rebase_materializer(root)
  site = load_json(materialize_moonbook_workspace.SITE_JSON)
  book = load_json(materialize_moonbook_workspace.BOOK_JSON)
  moonclaw = load_json(materialize_moonbook_workspace.MOONCLAW_JSON)
  moonclaw_ephemeris_tasks = load_json(
    materialize_moonbook_workspace.MOONCLAW_EPHEMERIS_TASKS_JSON,
  )
  moonclaw_corridor_tasks = load_json(
    materialize_moonbook_workspace.MOONCLAW_CORRIDOR_TASKS_JSON,
  )
  moonclaw_gap_tasks = materialize_moonbook_workspace.load_optional_json(
    materialize_moonbook_workspace.MOONCLAW_GAP_TASK_JSON,
    [],
  )
  moonclaw_gap_receipts = materialize_moonbook_workspace.load_optional_json(
    materialize_moonbook_workspace.MOONCLAW_GAP_RECEIPT_JSON,
    [],
  )
  moonclaw_receipts = load_json(
    materialize_moonbook_workspace.MOONCLAW_RECEIPTS_JSON,
  )
  moonclaw_ephemeris_receipts = load_json(
    materialize_moonbook_workspace.MOONCLAW_EPHEMERIS_RECEIPTS_JSON,
  )
  moonclaw_corridor_receipts = load_json(
    materialize_moonbook_workspace.MOONCLAW_CORRIDOR_RECEIPTS_JSON,
  )
  moonrobo = load_json(materialize_moonbook_workspace.MOONROBO_JSON)
  moonrobo_gap_modeling = materialize_moonbook_workspace.load_optional_json(
    materialize_moonbook_workspace.MOONROBO_GAP_MODELING_JSON,
    [],
  )
  moonrobo_simulation_review_packet = (
    materialize_moonbook_workspace.load_optional_json(
      materialize_moonbook_workspace.MOONROBO_SIMULATION_REVIEW_PACKET_JSON,
      {},
    )
  )
  moonrobo_simulation_review_decision = (
    materialize_moonbook_workspace.load_optional_json(
      materialize_moonbook_workspace.MOONROBO_SIMULATION_REVIEW_DECISION_JSON,
      {},
    )
  )
  moonrobo_simulation_blocker_reduction = (
    materialize_moonbook_workspace.load_optional_json(
      materialize_moonbook_workspace.MOONROBO_SIMULATION_BLOCKER_REDUCTION_JSON,
      {},
    )
  )
  mission_horizon = load_json(materialize_moonbook_workspace.MISSION_HORIZON_JSON)
  mission_terrain_remediation = load_json(
    materialize_moonbook_workspace.MISSION_TERRAIN_REMEDIATION_JSON,
  )
  mission_energy_remediation = load_json(
    materialize_moonbook_workspace.MISSION_ENERGY_REMEDIATION_JSON,
  )
  files = materialize_moonbook_workspace.workspace_files(
    site,
    book,
    moonclaw,
    moonclaw_ephemeris_tasks,
    moonclaw_corridor_tasks,
    moonclaw_gap_tasks,
    moonclaw_receipts,
    moonclaw_ephemeris_receipts,
    moonclaw_corridor_receipts,
    moonclaw_gap_receipts,
    moonrobo,
    moonrobo_gap_modeling,
    moonrobo_simulation_review_packet,
    moonrobo_simulation_review_decision,
    moonrobo_simulation_blocker_reduction,
    mission_horizon,
    mission_terrain_remediation,
    mission_energy_remediation,
  )
  materialize_moonbook_workspace.write_workspace(files)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-rabbita-import-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    materialize_temp_workspace(tmp_root)
    assert_imported(tmp_root)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
