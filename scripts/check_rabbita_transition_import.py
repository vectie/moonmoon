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
  workspace_entry = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/selected-route-clearance.json",
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
  files = materialize_moonbook_workspace.workspace_files(
    site,
    book,
    moonclaw,
    moonclaw_ephemeris_tasks,
    moonclaw_corridor_tasks,
    moonclaw_receipts,
    moonclaw_ephemeris_receipts,
    moonclaw_corridor_receipts,
    moonrobo,
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
