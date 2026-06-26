#!/usr/bin/env python3
"""Verify Rabbita's consolidated Mission Evidence Queue."""

from __future__ import annotations

import json
from typing import Any

from rabbita_ui_harness import (
  ROOT,
  assert_mission_evidence_queue,
  expected_mission_evidence_entries,
  read_rabbita_page,
  render_mission_evidence_queue,
)


WORKSPACE_ROOT = ROOT / "output/moonbook/workspaces/first-trusted-square"


def assert_workspace_payloads(book: dict[str, Any]) -> None:
  for entry in expected_mission_evidence_entries(book):
    path = WORKSPACE_ROOT / entry["path"]
    if not path.exists():
      raise AssertionError(f"missing workspace payload {path}")
    document = json.loads(path.read_text(encoding="utf-8"))
    materialized_entry = document.get("entry", {})
    if materialized_entry.get("entry_id") != entry["entry_id"]:
      raise AssertionError(
        {"path": str(path), "entry_id": materialized_entry.get("entry_id")},
      )
    if materialized_entry.get("path") != entry["path"]:
      raise AssertionError(
        {"path": str(path), "payload_path": materialized_entry.get("path")},
      )
    if "payload" not in document:
      raise AssertionError(f"missing payload in {path}")


def assert_queue_source(html: str) -> None:
  if "Mission Evidence Queue" not in html:
    raise AssertionError("missing Mission Evidence Queue section")
  app_script = (ROOT / "output/ui/rabbita/assets/rabbita_app.js").read_text(
    encoding="utf-8",
  )
  evidence_script = (ROOT / "output/ui/rabbita/assets/rabbita_evidence.js").read_text(
    encoding="utf-8",
  )
  if "function renderMissionEvidenceQueue()" not in app_script:
    raise AssertionError("missing Mission Evidence Queue renderer")
  if "function missionEvidenceRows()" not in evidence_script:
    raise AssertionError("missing Mission Evidence Queue discovery helper")


def main() -> int:
  html, view, book = read_rabbita_page()
  assert_queue_source(html)
  assert_workspace_payloads(book)
  rendered = render_mission_evidence_queue(view, book)
  assert_mission_evidence_queue(rendered, book)
  print("checked Rabbita Mission Evidence Queue")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
