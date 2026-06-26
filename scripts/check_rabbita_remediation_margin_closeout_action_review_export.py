#!/usr/bin/env python3
"""Execute Rabbita UI and check closeout action review export."""

from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from rabbita_ui_harness import extract_json_script, rabbita_app_script

ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "output/ui/rabbita/first_trusted_square.html"
ENTRY_ID = "moonclaw/first-trusted-square/remediation-margin-closeout-action-task"
ENTRY_PATH = "moonclaw/first-trusted-square/remediation-margin-closeout-action-task.json"
ITEM_ID = "moonclaw-remediation-margin-closeout-action-review"
EXPORT_NAME = "first_trusted_square_closeout_action_review.json"
REVIEWER_ID = "operator/rabbita-closeout-action-review"
REVIEWER_ROLE = "moonclaw-closeout-action-review"
IMMUTABLE_URI = f"moonbook://moonmoon/first-trusted-square/{ENTRY_PATH}#{ITEM_ID}"


def run_rabbita_script(view: Any, book: Any, script: str) -> dict[str, Any]:
  harness = r"""
const fs = require('fs');
const vm = require('vm');
const input = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));

class Element {
  constructor(tagName, id = '') {
    this.tagName = tagName;
    this.id = id;
    this.children = [];
    this.attributes = {};
    this.eventListeners = {};
    this.className = '';
    this.textContent = '';
    this.value = '';
    this.style = { setProperty: (key, value) => { this.style[key] = String(value); } };
  }
  setAttribute(key, value) { this.attributes[key] = String(value); }
  append(child) { this.children.push(child); }
  replaceChildren(...children) { this.children = children; }
  addEventListener(type, handler) { this.eventListeners[type] = handler; }
  click() { if (this.eventListeners.click) this.eventListeners.click(); }
}

const elements = new Map();
const document = {
  createElement(tag) { return new Element(tag); },
  createElementNS(_namespace, tag) { return new Element(tag); },
  getElementById(id) {
    if (!elements.has(id)) elements.set(id, new Element('div', id));
    return elements.get(id);
  }
};

document.getElementById('moonmoon-view-model').textContent = JSON.stringify(input.view);
document.getElementById('moonmoon-moonbook').textContent = JSON.stringify(input.book);

const downloads = [];
const context = {
  document,
  window: {},
  navigator: {},
  Blob,
  URL: {
    createObjectURL(blob) { downloads.push(blob); return 'blob:closeout-action-review'; },
    revokeObjectURL() {}
  },
  console
};
vm.runInNewContext(input.script, context);

function snapshot() {
  const row = document.getElementById('closeout-action-review').children[0];
  const buttons = row.children[2].children.map(button => ({
    label: button.textContent,
    pressed: button.attributes['aria-pressed']
  }));
  return {
    row: {
      decision: row.attributes['data-review-decision'],
      status: row.attributes['data-review-status'],
      entry_id: row.attributes['data-entry-id'],
      title: row.children[0].textContent,
      note: row.children[1].textContent,
      buttons
    },
    exported: JSON.parse(document.getElementById('closeout-action-review-export').value)
  };
}

const initial = snapshot();
const deferButton = document.getElementById('closeout-action-review')
  .children[0].children[2].children.find(button => button.textContent === 'Defer');
deferButton.eventListeners.click();
const deferred = snapshot();
const acceptButton = document.getElementById('closeout-action-review')
  .children[0].children[2].children.find(button => button.textContent === 'Accept');
acceptButton.eventListeners.click();
const accepted = snapshot();
document.getElementById('download-closeout-action-review-export').eventListeners.click();

console.log(JSON.stringify({ initial, deferred, accepted, download_count: downloads.length }, null, 2));
"""
  with tempfile.TemporaryDirectory(
    prefix="moonmoon-rabbita-closeout-action-review-",
  ) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_closeout_action_review_harness.cjs"
    input_path = tmp_dir / "input.json"
    harness_path.write_text(harness, encoding="utf-8")
    input_path.write_text(
      json.dumps({"view": view, "book": book, "script": script}),
      encoding="utf-8",
    )
    result = subprocess.run(
      ["node", str(harness_path), str(input_path)],
      check=True,
      cwd=ROOT,
      capture_output=True,
      text=True,
    )
  return json.loads(result.stdout)


def assert_transition(
  exported: dict[str, Any],
  decision: str,
  status: str,
) -> None:
  if exported["workspace"] != "moonbook://moonmoon/first-trusted-square":
    raise AssertionError(exported["workspace"])
  if exported["site_id"] != "first-trusted-square":
    raise AssertionError(exported["site_id"])
  if exported["generated_by"] != "output/ui/rabbita/first_trusted_square.html":
    raise AssertionError(exported["generated_by"])
  if exported["review_kind"] != "moonclaw-remediation-margin-closeout-action":
    raise AssertionError(exported["review_kind"])
  transitions = exported["transitions"]
  if len(transitions) != 1:
    raise AssertionError(transitions)
  transition = transitions[0]
  if transition["item_id"] != ITEM_ID:
    raise AssertionError(transition)
  if transition["entry_id"] != ENTRY_ID:
    raise AssertionError(transition)
  if not transition["transition_id"].startswith(f"rabbita-{ITEM_ID}-"):
    raise AssertionError(transition["transition_id"])
  if transition["previous_status"] != "NeedsReview":
    raise AssertionError(transition["previous_status"])
  if transition["decision"] != decision:
    raise AssertionError(transition["decision"])
  if transition["resulting_status"] != status:
    raise AssertionError(transition["resulting_status"])
  if transition["reviewer_id"] != REVIEWER_ID:
    raise AssertionError(transition["reviewer_id"])
  if transition["reviewer_role"] != REVIEWER_ROLE:
    raise AssertionError(transition["reviewer_role"])
  if transition["timestamp_policy"] != "operator-browser-export":
    raise AssertionError(transition["timestamp_policy"])
  if not transition["recorded_at_utc"].endswith("Z"):
    raise AssertionError(transition["recorded_at_utc"])
  if transition["append_only"] is not True:
    raise AssertionError(transition)
  if transition["hardware_authority_change"] is not False:
    raise AssertionError(transition)
  if transition["hardware_state"] != "HardwareDenied":
    raise AssertionError(transition["hardware_state"])
  if transition["hardware_authority"] != "moonmoon-safety-gate-only":
    raise AssertionError(transition["hardware_authority"])
  if "NoConsumeCycleClosedForPolicy" not in transition["rationale"]:
    raise AssertionError(transition["rationale"])
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


def assert_snapshot(
  snapshot: dict[str, Any],
  decision: str,
  status: str,
  pressed_label: str,
) -> None:
  row = snapshot["row"]
  if row["decision"] != decision:
    raise AssertionError(row)
  if row["status"] != status:
    raise AssertionError(row)
  if row["entry_id"] != ENTRY_ID:
    raise AssertionError(row)
  if ITEM_ID not in row["title"]:
    raise AssertionError(row["title"])
  if "NoConsumeCycleClosedForPolicy" not in row["note"]:
    raise AssertionError(row["note"])
  buttons = row["buttons"]
  labels = [button["label"] for button in buttons]
  if labels != ["Accept", "Need evidence", "Defer"]:
    raise AssertionError(labels)
  pressed = [button["label"] for button in buttons if button["pressed"] == "true"]
  if pressed != [pressed_label]:
    raise AssertionError(buttons)
  assert_transition(snapshot["exported"], decision, status)


def main() -> int:
  html = HTML_PATH.read_text(encoding="utf-8")
  for token in [
    "Closeout Action Review",
    "closeout-action-review-export",
  ]:
    if token not in html:
      raise AssertionError(f"missing {token}")
  app_script = rabbita_app_script()
  for token in [
    EXPORT_NAME,
    "function buildCloseoutActionReviewTransition()",
    "function closeoutActionReviewExport()",
    "function renderCloseoutActionReview()",
  ]:
    if token not in app_script:
      raise AssertionError(f"missing app token {token}")

  rendered = run_rabbita_script(
    extract_json_script(html, "moonmoon-view-model"),
    extract_json_script(html, "moonmoon-moonbook"),
    app_script,
  )
  assert_snapshot(rendered["initial"], "RequestEvidence", "NeedsEvidence", "Need evidence")
  assert_snapshot(rendered["deferred"], "Defer", "Deferred", "Defer")
  assert_snapshot(rendered["accepted"], "Accept", "Accepted", "Accept")
  if rendered["download_count"] != 1:
    raise AssertionError(rendered["download_count"])
  print("checked Rabbita remediation margin closeout action review export")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
