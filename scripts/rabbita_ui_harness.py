"""Shared helpers for Rabbita UI verification scripts."""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
RABBITA_OUTPUT = ROOT / "output/ui/rabbita"
RABBITA_ASSETS = RABBITA_OUTPUT / "assets"
HTML_PATH = RABBITA_OUTPUT / "first_trusted_square.html"
NOETIX_TRACE_PATH = ROOT / "output/moonrobo/first_trusted_square_noetix_walk.json"
NOETIX_LINK_POSES_PATH = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_link_poses.json"
)

MISSION_EVIDENCE_SNAPSHOT_JS = r"""
const rows = document.getElementById('mission-evidence-queue').children.map(row => ({
  family: row.attributes['data-evidence-family'],
  entry_id: row.attributes['data-entry-id'],
  className: row.className,
  title: row.children[0].textContent,
  summary: row.children[1].textContent,
  path: row.children[2].textContent
}));
const filters = document.getElementById('mission-evidence-filters').children.map(button => ({
  label: button.textContent,
  pressed: button.attributes['aria-pressed']
}));
const summary = document.getElementById('mission-evidence-summary').children.map(row => ({
  value: row.children[0].textContent,
  label: row.children[1].textContent
}));
return { rows, filters, summary };
"""

NOETIX_WALK_SNAPSHOT_JS = r"""
const viewer = document.getElementById('noetix-walk-viewer');
const controls = document.getElementById('noetix-walk-controls');
const facts = document.getElementById('noetix-walk-facts');
const summary = document.getElementById('noetix-walk-summary').textContent;
const authority = document.getElementById('noetix-walk-authority').textContent;
const svgNodes = [];
function visit(node) {
  svgNodes.push(node);
  for (const child of node.children || []) visit(child);
}
visit(viewer);
const factRows = facts.children.map(row => ({
  label: row.children[0].textContent,
  value: row.children[1].textContent
}));
return {
  summary,
  authority,
  viewer_children: viewer.children.length,
  stage_class: viewer.children[0].attributes.class,
  link_segment_count: svgNodes.filter(node => String(node.attributes.class || '').includes('noetix-link-segment')).length,
  link_joint_count: svgNodes.filter(node => String(node.attributes.class || '').includes('noetix-link-joint')).length,
  left_foot_joint_count: svgNodes.filter(node => node.attributes['data-link-name'] === 'left_foot').length,
  control_count: controls.children.length,
  scrubber_max: controls.children[1].attributes.max,
  scrubber_value: controls.children[1].value,
  facts: factRows
};
"""


def extract_json_script(html: str, script_id: str) -> Any:
  pattern = (
    rf'<script id="{re.escape(script_id)}" type="application/json">\n'
    r"([\s\S]*?)\n</script>"
  )
  match = re.search(pattern, html)
  if not match:
    raise AssertionError(f"missing {script_id}")
  return json.loads(match.group(1))


def read_rabbita_page(path: Path = HTML_PATH) -> tuple[str, Any, Any]:
  html = path.read_text(encoding="utf-8")
  return (
    html,
    extract_json_script(html, "moonmoon-view-model"),
    extract_json_script(html, "moonmoon-moonbook"),
  )


def rabbita_app_script() -> str:
  """Return the browser app scripts in page load order for VM harnesses."""
  scripts = [
    RABBITA_ASSETS / "rabbita_evidence.js",
    RABBITA_ASSETS / "rabbita_app.js",
  ]
  missing = [path for path in scripts if not path.exists()]
  if missing:
    raise AssertionError(f"missing Rabbita assets: {missing}")
  return "\n".join(path.read_text(encoding="utf-8") for path in scripts)


def read_noetix_trace() -> Any:
  return json.loads(NOETIX_TRACE_PATH.read_text(encoding="utf-8"))


def read_noetix_link_poses() -> Any:
  return json.loads(NOETIX_LINK_POSES_PATH.read_text(encoding="utf-8"))


def is_mission_evidence_entry(entry: dict[str, Any]) -> bool:
  entry_id = entry["entry_id"]
  return (
    "/remediation-margin-" in entry_id
    or "/regenerated-receipt-readiness-" in entry_id
    or entry_id.endswith("/noetix-dynamics")
    or entry_id.endswith("/noetix-review-task")
  )


def mission_evidence_family(entry: dict[str, Any]) -> str:
  entry_id = entry["entry_id"]
  if (
    "projection" in entry_id
    or "cycle-closeout" in entry_id
    or "action-receipt-closeout" in entry_id
    or entry_id.endswith("/remediation-margin-regenerated-receipt-readiness")
  ):
    return "blocker"
  if entry_id.endswith("/noetix-dynamics"):
    return "simulation"
  if "modeling" in entry_id:
    return "simulation"
  if (
    "reviewed-action-plan" in entry_id
    or "reviewed-work-items" in entry_id
    or entry_id.endswith("/noetix-review-task")
  ):
    return "review"
  if "fresh-evidence-task" in entry_id or entry_id.endswith("-task"):
    return "remediation"
  if (
    "receipt" in entry_id
    or "receipts" in entry_id
    or "action-receipts" in entry_id
  ):
    return "receipt"
  return "remediation"


def expected_mission_evidence_entries(book: dict[str, Any]) -> list[dict[str, Any]]:
  return [entry for entry in book["entries"] if is_mission_evidence_entry(entry)]


def render_mission_evidence_queue(
  view: Any,
  book: Any,
  *,
  prefix: str = "moonmoon-rabbita-mission-evidence-",
) -> dict[str, Any]:
  return run_rabbita_vm(view, book, MISSION_EVIDENCE_SNAPSHOT_JS, prefix=prefix)


def render_noetix_walk_panel(
  view: Any,
  book: Any,
  noetix_trace: Any,
  noetix_link_poses: Any,
  *,
  prefix: str = "moonmoon-rabbita-noetix-walk-",
) -> dict[str, Any]:
  return run_rabbita_vm(
    view,
    book,
    NOETIX_WALK_SNAPSHOT_JS,
    prefix=prefix,
    noetix_trace=noetix_trace,
    noetix_link_poses=noetix_link_poses,
  )


def assert_noetix_walk_panel(
  rendered: dict[str, Any],
  noetix_trace: dict[str, Any],
  noetix_link_poses: dict[str, Any],
) -> None:
  frames = noetix_trace["frames"]
  pose_frames = noetix_link_poses["frames"]
  if rendered["viewer_children"] != 1:
    raise AssertionError(rendered)
  if rendered["stage_class"] != "noetix-stage":
    raise AssertionError(rendered)
  if rendered["link_segment_count"] < noetix_link_poses["links_per_frame"] - 1:
    raise AssertionError(rendered)
  if rendered["link_joint_count"] < noetix_link_poses["links_per_frame"]:
    raise AssertionError(rendered)
  if rendered["left_foot_joint_count"] < 1:
    raise AssertionError(rendered)
  if rendered["control_count"] != 3:
    raise AssertionError(rendered)
  if rendered["scrubber_max"] != str(len(frames) - 1):
    raise AssertionError(rendered)
  if rendered["scrubber_value"] != "0":
    raise AssertionError(rendered)
  if "Noetix E1 Lab 01" not in rendered["summary"]:
    raise AssertionError(rendered)
  if "1.625" not in rendered["summary"]:
    raise AssertionError(rendered)
  if f"{noetix_link_poses['links_per_frame']} links" not in rendered["summary"]:
    raise AssertionError(rendered)
  if rendered["authority"] != "simulation evidence only":
    raise AssertionError(rendered)
  facts = {row["label"]: row["value"] for row in rendered["facts"]}
  expected = {
    "phase": frames[0]["support_phase"],
    "time": "0.00 s",
    "body x": "0.000 m",
    "joints": "24 kinematic phases",
    "links": f"{len(pose_frames[0]['links'])} URDF-reference poses",
    "pose status": "review-only-link-pose",
  }
  for key, value in expected.items():
    if facts.get(key) != value:
      raise AssertionError({"facts": facts, "expected": expected})
  if "terrain-grade-review" not in facts.get("left foot", ""):
    raise AssertionError(facts)
  if "terrain-grade-review" not in facts.get("right foot", ""):
    raise AssertionError(facts)


def assert_mission_evidence_queue(rendered: dict[str, Any], book: dict[str, Any]) -> None:
  expected = expected_mission_evidence_entries(book)
  rows = rendered["rows"]
  if len(expected) != 26:
    raise AssertionError(f"expected 26 mission evidence entries, got {len(expected)}")
  if len(rows) != len(expected):
    raise AssertionError(f"rendered {len(rows)} mission evidence rows for {len(expected)} entries")

  expected_counts = {"blocker": 0, "receipt": 0, "remediation": 0, "review": 0, "simulation": 0}
  for row, entry in zip(rows, expected):
    family = mission_evidence_family(entry)
    expected_counts[family] += 1
    if row["entry_id"] != entry["entry_id"]:
      raise AssertionError({"row": row["entry_id"], "entry": entry["entry_id"]})
    if row["family"] != family:
      raise AssertionError({"row": row, "expected_family": family})
    if "evidence-row" not in row["className"]:
      raise AssertionError(row)
    if row["summary"] != entry["summary"]:
      raise AssertionError({"row": row["summary"], "entry": entry["summary"]})
    expected_path = f"moonbook://moonmoon/first-trusted-square/{entry['path']}"
    if row["path"] != expected_path:
      raise AssertionError({"row": row["path"], "expected": expected_path})

  if expected_counts != {
    "blocker": 6,
    "receipt": 7,
    "remediation": 6,
    "review": 3,
    "simulation": 4,
  }:
    raise AssertionError(expected_counts)

  filters = {item["label"]: item["pressed"] for item in rendered["filters"]}
  if filters != {
    "All 26": "true",
    "Blockers 6": "false",
    "Work 6": "false",
    "Receipts 7": "false",
    "Simulation 4": "false",
    "Review 3": "false",
  }:
    raise AssertionError(filters)


def run_rabbita_vm(
  view: Any,
  book: Any,
  snapshot_js: str,
  *,
  prefix: str = "moonmoon-rabbita-ui-",
  noetix_trace: Any | None = None,
  noetix_link_poses: Any | None = None,
) -> dict[str, Any]:
  """Execute Rabbita assets in a minimal DOM and return a JSON snapshot."""
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
document.getElementById('moonmoon-noetix-walk').textContent = JSON.stringify(input.noetix_trace);
document.getElementById('moonmoon-noetix-link-poses').textContent = JSON.stringify(input.noetix_link_poses);

const downloads = [];
const context = {
  document,
  window: {},
  navigator: {},
  Blob,
  URL: {
    createObjectURL(blob) { downloads.push(blob); return 'blob:rabbita-export'; },
    revokeObjectURL() {}
  },
  console
};

vm.runInNewContext(input.script, context);
const snapshot = vm.runInNewContext(`(() => { ${input.snapshot_js} })()`, {
  document,
  downloads,
  console
});
console.log(JSON.stringify(snapshot, null, 2));
"""
  with tempfile.TemporaryDirectory(prefix=prefix) as tmp:
    tmp_dir = Path(tmp)
    harness_path = tmp_dir / "rabbita_harness.cjs"
    input_path = tmp_dir / "input.json"
    harness_path.write_text(harness, encoding="utf-8")
    input_path.write_text(
      json.dumps(
        {
          "view": view,
          "book": book,
          "noetix_trace": noetix_trace if noetix_trace is not None else read_noetix_trace(),
          "noetix_link_poses": noetix_link_poses
          if noetix_link_poses is not None
          else read_noetix_link_poses(),
          "script": rabbita_app_script(),
          "snapshot_js": snapshot_js,
        },
      ),
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
