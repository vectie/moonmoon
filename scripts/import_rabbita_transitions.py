#!/usr/bin/env python3
"""Apply Rabbita-exported review transitions to generated Moonmoon outputs."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

import materialize_moonbook_workspace as workspace


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def write_json(path: Path, value: Any) -> None:
  path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def output_paths(root: Path) -> dict[str, Path]:
  return {
    "book_json": root / "output/moonbook/first_trusted_square_book.json",
    "book_md": root / "output/moonbook/first_trusted_square_book.md",
    "moonrobo_json": root / "output/moonrobo/first_trusted_square_handoffs.json",
    "moonrobo_md": root / "output/moonrobo/first_trusted_square_handoffs.md",
    "moonrobo_preview_json": root
    / "output/moonrobo/first_trusted_square_readiness_preview.json",
    "moonrobo_preview_md": root
    / "output/moonrobo/first_trusted_square_readiness_preview.md",
    "moonclaw_gap_task_json": root
    / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json",
    "moonclaw_gap_task_md": root
    / "output/moonclaw/first_trusted_square_moonrobo_gap_task.md",
    "rabbita_html": root / "output/ui/rabbita/first_trusted_square.html",
  }


def imported_transitions(path: Path) -> list[dict[str, Any]]:
  payload = load_json(path)
  if isinstance(payload, list):
    transitions = payload
  elif isinstance(payload, dict) and isinstance(payload.get("transitions"), list):
    transitions = payload["transitions"]
  elif isinstance(payload, dict) and isinstance(payload.get("items"), list):
    transitions = payload["items"]
  else:
    raise ValueError(f"{path} must contain a transition array, transitions, or items")
  for transition in transitions:
    item_id = transition.get("item_id", "")
    if not item_id.startswith("clear-"):
      raise ValueError(f"unsupported transition item_id {item_id!r}; expected clear-*")
    if transition.get("decision") not in {"Accept", "Reject", "RequestEvidence"}:
      raise ValueError(f"unsupported transition decision for {item_id!r}")
  return transitions


def transition_by_item(transitions: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
  return {transition["item_id"]: transition for transition in transitions}


def status_for_decision(decision: str) -> str:
  if decision == "Accept":
    return "Accepted"
  if decision == "Reject":
    return "Rejected"
  return "NeedsEvidence"


def merge_review_transitions(
  book: dict[str, Any],
  imported: list[dict[str, Any]],
) -> None:
  by_item = transition_by_item(imported)
  known_items = {item["item_id"] for item in book["review_queue"]}
  unknown = sorted(set(by_item) - known_items)
  if unknown:
    raise ValueError(f"transitions reference unknown review items: {', '.join(unknown)}")
  merged: list[dict[str, Any]] = []
  seen: set[str] = set()
  for transition in book["review_transitions"]:
    item_id = transition["item_id"]
    if item_id in by_item:
      merged.append(by_item[item_id])
      seen.add(item_id)
    else:
      merged.append(transition)
  for transition in imported:
    if transition["item_id"] not in seen:
      merged.append(transition)
  book["review_transitions"] = merged


def apply_review_queue(book: dict[str, Any]) -> None:
  by_item = transition_by_item(book["review_transitions"])
  reviewed: list[dict[str, Any]] = []
  for item in book["review_queue"]:
    next_item = dict(item)
    transition = by_item.get(item["item_id"])
    if transition:
      next_item["status"] = transition.get(
        "resulting_status",
        status_for_decision(transition["decision"]),
      )
      next_item["last_transition_id"] = transition["transition_id"]
    reviewed.append(next_item)
  book["review_queue"] = reviewed


def selected_handoff(moonrobo: list[dict[str, Any]]) -> dict[str, Any]:
  for handoff in moonrobo:
    if handoff["route_id"] == "northeast-stepout":
      return handoff
  return moonrobo[0]


def reviewed_clearance_plan(
  moonrobo: list[dict[str, Any]],
  book: dict[str, Any],
) -> dict[str, Any]:
  return workspace.clearance_plan_with_review_transitions(
    selected_handoff(moonrobo)["clearance_plan"],
    book["review_transitions"],
  )


def decision_label(decision: str) -> str:
  return {
    "Allow": "allow",
    "Review": "review",
    "Block": "block",
  }[decision]


def update_selected_route_entry(
  book: dict[str, Any],
  plan: dict[str, Any],
) -> None:
  summary = (
    f"{decision_label(plan['decision'])} {plan['route_id']}: "
    f"{len(plan['items'])} clearance items, {len(plan['blocking_items'])} blockers"
  )
  for entry in book["entries"]:
    if entry["kind"] == "SelectedRouteClearance":
      entry["summary"] = summary


def update_moonrobo(
  moonrobo: list[dict[str, Any]],
  plan: dict[str, Any],
) -> None:
  for handoff in moonrobo:
    if handoff["route_id"] == plan["route_id"]:
      handoff["clearance_plan"] = plan


def clearance_item_by_source_check(
  clearance: dict[str, Any],
) -> dict[str, dict[str, Any]]:
  return {item["source_check_id"]: item for item in clearance["items"]}


def readiness_check_by_id(readiness: dict[str, Any]) -> dict[str, dict[str, Any]]:
  return {check["check_id"]: check for check in readiness["checks"]}


def blocker_gap_report(handoff: dict[str, Any]) -> list[dict[str, Any]]:
  readiness = handoff["mission_readiness"]
  checks = readiness_check_by_id(readiness)
  clearance_items = clearance_item_by_source_check(handoff["clearance_plan"])
  report: list[dict[str, Any]] = []
  for check_id in handoff["execution"]["blocking_preconditions"]:
    check = checks[check_id]
    clearance = clearance_items.get(check_id)
    report.append({
      "check_id": check["check_id"],
      "kind": check["kind"],
      "label": check["label"],
      "decision": check["decision"],
      "evidence_path": check["evidence_path"],
      "next_action": check["reason"],
      "clearance_id": clearance["clearance_id"] if clearance else "",
      "clearance_status": clearance["status"] if clearance else "NotClearanceGated",
      "clearance_evidence_id": clearance["accepted_evidence_id"] if clearance else "",
    })
  return report


def moonrobo_readiness_preview(
  handoff: dict[str, Any],
  transition_file: Path,
) -> dict[str, Any]:
  clearance = handoff["clearance_plan"]
  execution = handoff["execution"]
  readiness = handoff["mission_readiness"]
  gaps = blocker_gap_report(handoff)
  clearance_allows = clearance["decision"] == "Allow"
  simulation_ready = readiness["decision"] == "Allow"
  return {
    "preview_id": f"moonrobo-readiness-preview/{handoff['site_id']}/{handoff['route_id']}",
    "generated_by": "scripts/import_rabbita_transitions.py",
    "source_transition_file": str(transition_file),
    "route_id": handoff["route_id"],
    "clearance_decision": clearance["decision"],
    "clearance_allows_simulation_review": clearance_allows,
    "accepted_clearance_items": clearance["accepted_items"],
    "blocking_clearance_items": clearance["blocking_items"],
    "review_clearance_items": clearance["review_items"],
    "rejected_clearance_items": clearance["rejected_items"],
    "mission_readiness_decision": readiness["decision"],
    "robot_simulation_status": readiness["robot_simulation_status"],
    "simulation_state": execution["simulation_state"],
    "hardware_state": execution["hardware_state"],
    "hardware_authority": execution["authority"],
    "hardware_denied": execution["hardware_state"] == "HardwareDenied",
    "blocking_preconditions": execution["blocking_preconditions"],
    "review_preconditions": execution["review_preconditions"],
    "blocker_gap_count": len(gaps),
    "blocker_gap_report": gaps,
    "safety_summary": (
      "selected-route clearance is allowed by imported operator decisions; "
      "MoonRobo simulation readiness is still gated by mission preconditions "
      "and MoonMoon keeps hardware execution denied"
      if clearance_allows and not simulation_ready
      else "selected-route clearance and mission readiness both allow only simulation consumption; hardware execution remains outside MoonMoon authority"
      if clearance_allows
      else "selected-route clearance still has blocking or review items; MoonRobo simulation remains gated and hardware execution remains denied"
    ),
  }


def render_moonrobo_preview_markdown(preview: dict[str, Any]) -> str:
  text = "# MoonRobo Imported Clearance Readiness Preview\n\n"
  text += f"- preview: {preview['preview_id']}\n"
  text += f"- route: {preview['route_id']}\n"
  text += f"- clearance decision: {decision_label(preview['clearance_decision'])}\n"
  text += (
    "- clearance allows simulation review: "
    f"{str(preview['clearance_allows_simulation_review']).lower()}\n"
  )
  text += (
    "- mission readiness: "
    f"{decision_label(preview['mission_readiness_decision'])}\n"
  )
  text += f"- robot simulation status: {preview['robot_simulation_status']}\n"
  text += f"- simulation state: {preview['simulation_state']}\n"
  text += f"- hardware state: {preview['hardware_state']}\n"
  text += f"- hardware authority: {preview['hardware_authority']}\n"
  text += f"- hardware denied: {str(preview['hardware_denied']).lower()}\n"
  text += f"- blocker gaps: {preview['blocker_gap_count']}\n"
  text += f"- safety summary: {preview['safety_summary']}\n\n"
  text += "## Accepted Clearance Items\n\n"
  for item in preview["accepted_clearance_items"]:
    text += f"- {item}\n"
  text += "\n## Blocker Gap Report\n\n"
  for gap in preview["blocker_gap_report"]:
    text += f"- {gap['check_id']} ({book_entry_kind_label(gap['kind'])})\n"
    text += f"  - evidence: {gap['evidence_path']}\n"
    text += f"  - clearance: {gap['clearance_status']}"
    if gap["clearance_id"]:
      text += f" via {gap['clearance_id']}"
    text += "\n"
    text += f"  - next action: {gap['next_action']}\n"
  return text


def moonclaw_gap_task_artifacts(preview: dict[str, Any]) -> list[dict[str, Any]]:
  artifacts: list[dict[str, Any]] = [
    {
      "artifact_id": "imported-clearance-preview",
      "path": "output/moonrobo/first_trusted_square_readiness_preview.json",
      "producer": "scripts/import_rabbita_transitions.py",
      "required_state": "preview consumes accepted Rabbita clearance transitions and reports remaining MoonRobo gaps",
      "current_state": (
        f"{preview['blocker_gap_count']} blocker gaps; "
        f"clearance {preview['clearance_decision']}; "
        f"simulation {preview['robot_simulation_status']}"
      ),
      "ready": True,
      "blocking_reason": "",
      "validation_gate": "python3 scripts/check_moonrobo_readiness_preview.py",
    }
  ]
  for gap in preview["blocker_gap_report"]:
    artifacts.append({
      "artifact_id": f"gap-{gap['check_id']}",
      "path": gap["evidence_path"],
      "producer": "moonmoon mission and MoonRobo evidence generators",
      "required_state": (
        f"{gap['label']} no longer blocks MoonRobo simulation, with "
        "reviewed evidence and refreshed handoff output"
      ),
      "current_state": (
        f"{gap['decision']}; clearance {gap['clearance_status']}; "
        f"{gap['next_action']}"
      ),
      "ready": False,
      "blocking_reason": gap["next_action"],
      "validation_gate": "bash scripts/build_moonmoon_dossier.sh && python3 scripts/materialize_moonbook_workspace.py --check",
    })
  return artifacts


def moonclaw_gap_task(preview: dict[str, Any], transition_file: Path) -> dict[str, Any]:
  return {
    "task_id": "moonclaw/first-trusted-square/moonrobo-gap-remediation-v1/task",
    "proposal_id": "moonclaw/first-trusted-square/moonrobo-gap-remediation-v1",
    "site_id": "first-trusted-square",
    "priority": "Critical",
    "state": "Accepted",
    "objective": (
      "Consume the imported-clearance MoonRobo readiness gap report and "
      "produce the next bounded modeling updates required before simulation."
    ),
    "inputs": [
      {
        "input_id": "imported-clearance-transitions",
        "evidence_path": str(transition_file),
        "claim_kind": "Assumed",
        "summary": "Operator-exported Rabbita transitions accept selected-route clearance items without changing source facts.",
      },
      {
        "input_id": "moonrobo-readiness-preview",
        "evidence_path": "output/moonrobo/first_trusted_square_readiness_preview.json",
        "claim_kind": "Derived",
        "summary": "Preview shows selected-route clearance is allowed while mission readiness and hardware authority remain blocked.",
      },
    ],
    "blocker_gap_report": preview["blocker_gap_report"],
    "artifacts": moonclaw_gap_task_artifacts(preview),
    "commands": [
      "python3 scripts/check_moonrobo_readiness_preview.py",
      "python3 scripts/scan_lola_corridor.py --plan --radius 16 --step 4",
      "python3 scripts/compute_power_window.py --check",
      "bash scripts/build_moonmoon_dossier.sh --review-transitions data/fixtures/rabbita_clearance_transitions_accept.json",
      "python3 scripts/materialize_moonbook_workspace.py --check",
      "/Users/kq/.moon/bin/moon test",
    ],
    "acceptance_criteria": [
      {
        "criterion_id": "gap-report-consumed",
        "description": "Task input names the imported-clearance preview and includes every current blocker gap with evidence path and next action.",
      },
      {
        "criterion_id": "remediation-commands",
        "description": "Commands cover terrain/corridor review, power-window verification, imported transition rebuild, workspace check, and MoonBit tests.",
      },
      {
        "criterion_id": "robot-safety-invariant",
        "description": "MoonRobo hardware_state remains HardwareDenied and authority remains moonmoon-safety-gate-only while remediation is incomplete.",
      },
    ],
    "safety_gate": (
      "Do not allow MoonRobo hardware execution. Simulation may only become "
      "consumable after the blocker gap report is empty or all remaining gaps "
      "are explicitly moved to reviewed non-blocking states by regenerated "
      "MoonMoon evidence."
    ),
    "robot_safety_invariants": [
      "hardware_state must remain HardwareDenied",
      "hardware_authority must remain moonmoon-safety-gate-only",
      "physical execution authority must not be emitted by MoonMoon",
      "simulation readiness must be regenerated from mission checks, not from clearance acceptance alone",
    ],
    "next_action": (
      "Run bounded terrain, illumination, energy, MoonBook, and robot-simulation "
      "remediation work from the blocker gap report, then regenerate MoonRobo "
      "handoffs and the imported-clearance preview."
    ),
  }


def render_moonclaw_gap_task_markdown(task: dict[str, Any]) -> str:
  text = "# MoonClaw MoonRobo Gap Remediation Task\n\n"
  text += f"- task: {task['task_id']}\n"
  text += f"- priority: {task['priority']}\n"
  text += f"- state: {task['state']}\n"
  text += f"- objective: {task['objective']}\n"
  text += f"- safety gate: {task['safety_gate']}\n\n"
  text += "## Blocker Gaps\n\n"
  for gap in task["blocker_gap_report"]:
    text += f"- {gap['check_id']} ({book_entry_kind_label(gap['kind'])})\n"
    text += f"  - evidence: {gap['evidence_path']}\n"
    text += f"  - clearance: {gap['clearance_status']}\n"
    text += f"  - next action: {gap['next_action']}\n"
  text += "\n## Commands\n\n"
  for command in task["commands"]:
    text += f"- `{command}`\n"
  text += "\n## Acceptance Criteria\n\n"
  for criterion in task["acceptance_criteria"]:
    text += f"- {criterion['criterion_id']}: {criterion['description']}\n"
  text += "\n## Robot Safety Invariants\n\n"
  for invariant in task["robot_safety_invariants"]:
    text += f"- {invariant}\n"
  return text


def book_entry_kind_label(kind: str) -> str:
  out = []
  for index, char in enumerate(kind):
    if index > 0 and char.isupper() and not kind[index - 1].isupper():
      out.append("-")
    out.append(char.lower())
  return "".join(out)


def render_book_markdown(book: dict[str, Any]) -> str:
  text = f"# {book['title']}\n\n"
  text += f"- workspace: {book['workspace']}\n"
  text += f"- site: {book['site_id']}\n\n"
  text += "## Entries\n\n"
  for entry in book["entries"]:
    text += f"- {entry['entry_id']}: {entry['title']}\n"
    text += f"  - kind: {book_entry_kind_label(entry['kind'])}\n"
    text += f"  - claim: {entry['claim_kind'].lower()}\n"
    text += f"  - confidence: {entry['confidence']}\n"
    text += f"  - path: {entry['path']}\n"
  text += "\n## Review Queue\n\n"
  for item in book["review_queue"]:
    text += (
      f"- {item['item_id']} [{item['severity']}/{item['status'].lower()}] "
      f"{item['reason']} -> {item['owner']}\n"
    )
  text += "\n## Review Transitions\n\n"
  for transition in book["review_transitions"]:
    text += (
      f"- {transition['transition_id']}: {transition['decision'].lower()} "
      f"{transition['item_id']} -> {transition['resulting_status'].lower()}\n"
    )
    text += f"  - reviewer: {transition['reviewer_id']} as {transition['reviewer_role']}\n"
    text += f"  - timestamp: {transition['recorded_at_utc']} ({transition['timestamp_policy']})\n"
    text += f"  - append only: {str(transition['append_only']).lower()}\n"
    for source in transition["source_evidence_refs"]:
      text += f"  - source: {source['entry_id']} at {source['immutable_uri']}\n"
    text += f"  - rationale: {transition['rationale']}\n"
  return text


def clearance_kind_label(kind: str) -> str:
  return {
    "TerrainGradeClearance": "terrain-grade",
    "IlluminationConfidenceClearance": "illumination-confidence",
    "EnergyMarginClearance": "energy-margin",
    "MoonBookReviewClearance": "moonbook-review",
  }.get(kind, kind)


def clearance_status_label(status: str) -> str:
  return {
    "AcceptedEvidence": "accepted-evidence",
    "RejectedEvidence": "rejected-evidence",
    "NeedsEvidence": "needs-evidence",
    "ActionRequired": "action-required",
  }.get(status, status)


def render_moonrobo_markdown(moonrobo: list[dict[str, Any]]) -> str:
  text = "# Moonrobo Simulation Preconditions\n\n"
  for handoff in moonrobo:
    text += f"- {handoff['handoff_id']}\n"
    text += f"  - route: {handoff['route_id']}\n"
    text += f"  - decision: {decision_label(handoff['decision'])}\n"
    text += f"  - task: {handoff['task_kind']}\n"
    text += f"  - simulation: {handoff['mission_readiness']['robot_simulation_status']}\n"
    text += f"  - replay: {handoff['execution']['replay_state']}\n"
    text += f"  - hardware: {handoff['execution']['hardware_state']}\n"
    text += f"  - mission readiness: {decision_label(handoff['mission_readiness']['decision'])}\n"
    text += f"  - robot simulation status: {handoff['mission_readiness']['robot_simulation_status']}\n"
    text += f"  - clearance plan: {decision_label(handoff['clearance_plan']['decision'])}\n"
    text += f"  - authority: {handoff['execution']['authority']}\n"
    text += f"  - hardware denial: {handoff['execution']['hardware_denial_reason']}\n"
    text += f"  - next action: {handoff['next_action']}\n"
    text += "  - selected-route clearance actions:\n"
    for item in handoff["clearance_plan"]["items"]:
      text += (
        f"    - {item['clearance_id']} ({clearance_kind_label(item['kind'])}): "
        f"{clearance_status_label(item['status'])} - {item['clearance_action']}\n"
      )
    text += "  - mission readiness checks:\n"
    for check in handoff["mission_readiness"]["checks"]:
      text += (
        f"    - {check['check_id']} ({book_entry_kind_label(check['kind'])}): "
        f"{decision_label(check['decision'])} - {check['reason']}\n"
      )
  return text


def replace_embedded_book(html: str, book: dict[str, Any]) -> str:
  replacement = (
    '<script id="moonmoon-moonbook" type="application/json">\n'
    + json.dumps(book, indent=2, ensure_ascii=False)
    + "\n</script>"
  )
  return re.sub(
    r'<script id="moonmoon-moonbook" type="application/json">\n[\s\S]*?\n</script>',
    replacement,
    html,
  )


def apply_import(root: Path, transition_file: Path) -> None:
  paths = output_paths(root)
  book = load_json(paths["book_json"])
  moonrobo = load_json(paths["moonrobo_json"])
  merge_review_transitions(book, imported_transitions(transition_file))
  apply_review_queue(book)
  plan = reviewed_clearance_plan(moonrobo, book)
  update_selected_route_entry(book, plan)
  update_moonrobo(moonrobo, plan)
  preview = moonrobo_readiness_preview(selected_handoff(moonrobo), transition_file)
  gap_task = moonclaw_gap_task(preview, transition_file)
  write_json(paths["book_json"], book)
  write_json(paths["moonrobo_json"], moonrobo)
  write_json(paths["moonrobo_preview_json"], preview)
  write_json(paths["moonclaw_gap_task_json"], [gap_task])
  paths["book_md"].write_text(render_book_markdown(book), encoding="utf-8")
  paths["moonrobo_md"].write_text(render_moonrobo_markdown(moonrobo), encoding="utf-8")
  paths["moonrobo_preview_md"].write_text(
    render_moonrobo_preview_markdown(preview),
    encoding="utf-8",
  )
  paths["moonclaw_gap_task_md"].write_text(
    render_moonclaw_gap_task_markdown(gap_task),
    encoding="utf-8",
  )
  html = paths["rabbita_html"].read_text(encoding="utf-8")
  paths["rabbita_html"].write_text(replace_embedded_book(html, book), encoding="utf-8")


def main() -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument("--review-transitions", required=True)
  parser.add_argument("--root", default=str(workspace.ROOT))
  args = parser.parse_args()
  apply_import(Path(args.root).resolve(), Path(args.review_transitions).resolve())
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
