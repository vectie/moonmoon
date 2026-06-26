#!/usr/bin/env python3
"""Execute Rabbita's generated review UI against imported mixed state."""

from __future__ import annotations

import shutil
import tempfile
from pathlib import Path
from typing import Any

import import_rabbita_transitions
from rabbita_ui_harness import extract_json_script, run_rabbita_vm


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_clearance_transitions_mixed.json"


SNAPSHOT_JS = r"""
const rows = document.getElementById('clearance-review').children.map(row => ({
  decision: row.attributes['data-review-decision'],
  status: row.attributes['data-review-status'],
  title: row.children[0].textContent,
  note: row.children[1].textContent,
  buttons: row.children[2].children.map(button => ({
    label: button.textContent,
    pressed: button.attributes['aria-pressed']
  }))
}));
const exported = JSON.parse(document.getElementById('transition-export').value);
return { rows, exported };
"""


def assert_feedback_state(rendered: dict[str, Any]) -> None:
  decisions = {row["title"].split(" - ", 1)[0]: row for row in rendered["rows"]}
  expected = {
    "clear-terrain-grade-northeast-stepout": ("Accept", "Accepted"),
    "clear-illumination-confidence-northeast-stepout": ("Reject", "Rejected"),
    "clear-energy-margin": ("RequestEvidence", "NeedsEvidence"),
    "clear-moonbook-review-northeast-stepout": ("Accept", "Accepted"),
  }
  for item_id, (decision, status) in expected.items():
    row = decisions[item_id]
    if row["decision"] != decision or row["status"] != status:
      raise AssertionError(row)
    pressed = [
      button["label"] for button in row["buttons"] if button["pressed"] == "true"
    ]
    label = {
      "Accept": "Accept",
      "Reject": "Reject",
      "RequestEvidence": "Need evidence",
    }[decision]
    if pressed != [label]:
      raise AssertionError(row["buttons"])

  exported = {
    transition["item_id"]: transition["decision"]
    for transition in rendered["exported"]["transitions"]
  }
  if exported != {item_id: value[0] for item_id, value in expected.items()}:
    raise AssertionError(exported)


def main() -> int:
  with tempfile.TemporaryDirectory(prefix="moonmoon-rabbita-feedback-") as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    import_rabbita_transitions.apply_import(tmp_root, FIXTURE)
    html = (tmp_root / "output/ui/rabbita/first_trusted_square.html").read_text(
      encoding="utf-8",
    )
  rendered = run_rabbita_vm(
    extract_json_script(html, "moonmoon-view-model"),
    extract_json_script(html, "moonmoon-moonbook"),
    SNAPSHOT_JS,
    prefix="moonmoon-rabbita-feedback-",
  )
  assert_feedback_state(rendered)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
