#!/usr/bin/env python3
"""Check Rabbita closeout action review import and workspace materialization."""

from __future__ import annotations

import json
import re
import shutil
import tempfile
from pathlib import Path
from typing import Any

import check_rabbita_transition_import
import import_rabbita_transitions


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "data/fixtures/rabbita_closeout_action_review_accept.json"
ITEM_ID = "moonclaw-remediation-margin-closeout-action-review"
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-closeout-action-task"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json"
IMMUTABLE_URI = (
  "moonbook://moonmoon/first-trusted-square/"
  f"{ENTRY_PATH}#{ITEM_ID}"
)


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def write_json(path: Path, value: Any) -> None:
  path.write_text(
    json.dumps(value, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
  )


def embedded_book(html_path: Path) -> dict[str, Any]:
  html = html_path.read_text(encoding="utf-8")
  match = re.search(
    r'<script id="moonmoon-moonbook" type="application/json">\n([\s\S]*?)\n</script>',
    html,
  )
  if not match:
    raise AssertionError("Rabbita HTML has no embedded MoonBook payload")
  return json.loads(match.group(1))


def fixture_with_decision(tmp_root: Path, decision: str, status: str) -> Path:
  payload = load_json(FIXTURE)
  transition = payload["transitions"][0]
  suffix = {
    "Accept": "accept",
    "RequestEvidence": "request-evidence",
    "Defer": "defer",
  }[decision]
  transition["decision"] = decision
  transition["resulting_status"] = status
  transition["transition_id"] = f"rabbita-{ITEM_ID}-{suffix}"
  transition["rationale"] = (
    f"Rabbita {decision} decision for {ITEM_ID}: imported fixture; "
    "hardware remains denied"
  )
  path = tmp_root / f"closeout_action_review_{decision}.json"
  write_json(path, payload)
  return path


def transition_by_item(transitions: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
  return {transition["item_id"]: transition for transition in transitions}


def assert_transition(transition: dict[str, Any], decision: str, status: str) -> None:
  if transition["item_id"] != ITEM_ID:
    raise AssertionError(transition)
  if transition["entry_id"] != ENTRY_ID:
    raise AssertionError(transition)
  if transition["previous_status"] != "NeedsReview":
    raise AssertionError(transition["previous_status"])
  if transition["decision"] != decision:
    raise AssertionError(transition["decision"])
  if transition["resulting_status"] != status:
    raise AssertionError(transition["resulting_status"])
  if transition["reviewer_id"] != "operator/rabbita-closeout-action-review":
    raise AssertionError(transition["reviewer_id"])
  if transition["reviewer_role"] != "moonclaw-closeout-action-review":
    raise AssertionError(transition["reviewer_role"])
  if transition["timestamp_policy"] != "operator-browser-export":
    raise AssertionError(transition["timestamp_policy"])
  if transition["append_only"] is not True:
    raise AssertionError(transition)
  if transition["hardware_authority_change"] is not False:
    raise AssertionError(transition)
  if transition["hardware_state"] != "HardwareDenied":
    raise AssertionError(transition["hardware_state"])
  if transition["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(transition["hardware_authority"])
  refs = transition["source_evidence_refs"]
  if refs != [
    {
      "ref_id": ITEM_ID,
      "entry_id": ENTRY_ID,
      "path": ENTRY_PATH,
      "immutable_uri": IMMUTABLE_URI,
    },
  ]:
    raise AssertionError(refs)


def assert_imported(root: Path, decision: str, status: str) -> None:
  book = load_json(root / "output/moonbook/first_trusted_square_book.json")
  embedded = embedded_book(root / "output/ui/rabbita/first_trusted_square.html")
  workspace_transitions = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square/review_transitions.json",
  )
  workspace_entry = load_json(
    root
    / "output/moonbook/workspaces/first-trusted-square"
    / ENTRY_PATH,
  )

  if any(item["item_id"] == ITEM_ID for item in book["review_queue"]):
    raise AssertionError("closeout action review should not pollute review_queue")

  transition = transition_by_item(book["review_transitions"])[ITEM_ID]
  assert_transition(transition, decision, status)
  embedded_transition = transition_by_item(embedded["review_transitions"])[ITEM_ID]
  if embedded_transition != transition:
    raise AssertionError("Rabbita embedded MoonBook transition diverged")

  materialized_transition = transition_by_item(workspace_transitions["items"])[
    ITEM_ID
  ]
  if materialized_transition != transition:
    raise AssertionError("workspace review_transitions did not materialize import")

  review = workspace_entry["payload"]["review"]
  if review["item_id"] != ITEM_ID:
    raise AssertionError(review)
  if review["entry_id"] != ENTRY_ID:
    raise AssertionError(review)
  if review["status"] != status:
    raise AssertionError(review)
  if review["decision"] != decision:
    raise AssertionError(review)
  if review["transition"] != transition:
    raise AssertionError(review)
  if review["hardware_authority_change"] is not False:
    raise AssertionError(review)
  if review["hardware_state"] != "HardwareDenied":
    raise AssertionError(review)
  if review["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(review)


def check_decision(decision: str, status: str) -> None:
  with tempfile.TemporaryDirectory(
    prefix=f"moonmoon-closeout-review-{decision.lower()}-",
  ) as tmp:
    tmp_root = Path(tmp)
    shutil.copytree(ROOT / "output", tmp_root / "output")
    fixture = fixture_with_decision(tmp_root, decision, status)
    import_rabbita_transitions.apply_import(tmp_root, fixture)
    check_rabbita_transition_import.materialize_temp_workspace(tmp_root)
    assert_imported(tmp_root, decision, status)


def main() -> int:
  for decision, status in [
    ("Accept", "Accepted"),
    ("RequestEvidence", "NeedsEvidence"),
    ("Defer", "Deferred"),
  ]:
    check_decision(decision, status)
  print("checked Rabbita closeout action review import")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
