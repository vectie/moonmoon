#!/usr/bin/env python3
"""Materialize MoonBook entry files from generated Moonmoon dossiers."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SITE_JSON = ROOT / "output/site/first_trusted_square.json"
BOOK_JSON = ROOT / "output/moonbook/first_trusted_square_book.json"
MOONCLAW_JSON = ROOT / "output/moonclaw/first_trusted_square_proposals.json"
MOONCLAW_EPHEMERIS_TASKS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_ephemeris_tasks.json"
)
MOONCLAW_CORRIDOR_TASKS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_corridor_tasks.json"
)
MOONCLAW_NOETIX_REVIEW_TASK_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_noetix_review_task.json"
)
MOONCLAW_REMEDIATION_MARGIN_TASK_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_task.json"
)
MOONCLAW_REMEDIATION_MARGIN_REFRESH_TASK_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json"
)
MOONCLAW_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json"
)
MOONCLAW_REMEDIATION_MARGIN_CLOSEOUT_ACTION_TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json"
)
MOONCLAW_REMEDIATION_MARGIN_REVIEWED_ACTION_PLAN_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json"
)
MOONCLAW_REMEDIATION_MARGIN_REVIEWED_WORK_ITEMS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json"
)
MOONCLAW_REMEDIATION_MARGIN_REVIEWED_WORK_ITEM_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json"
)
MOONCLAW_REMEDIATION_MARGIN_REVIEWED_FRESH_EVIDENCE_TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json"
)
MOONCLAW_REMEDIATION_MARGIN_FRESH_EVIDENCE_ACTION_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json"
)
MOONCLAW_REMEDIATION_MARGIN_REGENERATED_REVIEWED_WORK_ITEM_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json"
)
MOONCLAW_REGENERATED_RECEIPT_READINESS_FRESH_EVIDENCE_TASK_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json"
)
MOONCLAW_REGENERATED_RECEIPT_READINESS_FRESH_EVIDENCE_ACTION_RECEIPTS_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json"
)
MOONCLAW_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_RECEIPT_JSON = (
  ROOT
  / "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
)
MOONCLAW_REMEDIATION_MARGIN_REFRESH_RECEIPT_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json"
)
MOONCLAW_REMEDIATION_MARGIN_RECEIPT_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_remediation_margin_receipt.json"
)
MOONCLAW_GAP_TASK_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_moonrobo_gap_task.json"
)
MOONCLAW_GAP_RECEIPT_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json"
)
MOONROBO_GAP_MODELING_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_gap_remediation_modeling.json"
)
MOONROBO_REMEDIATION_MARGIN_MODELING_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_modeling.json"
)
MOONROBO_REMEDIATION_MARGIN_PROJECTION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_projection.json"
)
MOONROBO_REMEDIATION_MARGIN_REFRESH_MODELING_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json"
)
MOONROBO_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_MODELING_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json"
)
MOONROBO_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_PROJECTION_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json"
)
MOONROBO_REMEDIATION_MARGIN_CYCLE_CLOSEOUT_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
)
MOONROBO_REMEDIATION_MARGIN_REFRESH_PROJECTION_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
)
MOONROBO_REMEDIATION_MARGIN_REGENERATED_RECEIPT_READINESS_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json"
)
MOONROBO_REGENERATED_RECEIPT_READINESS_ACTION_RECEIPT_CLOSEOUT_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json"
)
MOONROBO_SIMULATION_REVIEW_PACKET_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_simulation_review_packet.json"
)
MOONROBO_SIMULATION_REVIEW_DECISION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_simulation_review_decision.json"
)
MOONROBO_SIMULATION_BLOCKER_REDUCTION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json"
)
MOONCLAW_RECEIPTS_JSON = ROOT / "output/moonclaw/first_trusted_square_receipts.json"
MOONCLAW_EPHEMERIS_RECEIPTS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_ephemeris_receipts.json"
)
MOONCLAW_CORRIDOR_RECEIPTS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_corridor_receipts.json"
)
MOONROBO_JSON = ROOT / "output/moonrobo/first_trusted_square_handoffs.json"
MOONROBO_NOETIX_SOURCE_MODEL_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_source_model.json"
)
MOONROBO_NOETIX_WALK_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_walk.json"
)
MOONROBO_NOETIX_WALK_COMMAND_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_walk_command.json"
)
MOONROBO_NOETIX_STABILITY_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_stability.json"
)
MOONROBO_NOETIX_DYNAMICS_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_dynamics.json"
)
MOONROBO_NOETIX_CONTROL_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_control.json"
)
MOONROBO_NOETIX_INERTIAL_COLLISION_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_inertial_collision.json"
)
MOONROBO_NOETIX_LINK_POSES_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_noetix_link_poses.json"
)
MISSION_HORIZON_JSON = (
  ROOT / "output/mission/first_trusted_square_northeast_stepout_horizon.json"
)
MISSION_TERRAIN_REMEDIATION_JSON = (
  ROOT
  / "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json"
)
MISSION_ENERGY_REMEDIATION_JSON = (
  ROOT / "output/mission/first_trusted_square_energy_remediation.json"
)
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
GENERATOR = "scripts/materialize_moonbook_workspace.py"
CLOSEOUT_ACTION_REVIEW_ITEM_ID = "moonclaw-remediation-margin-closeout-action-review"
CLOSEOUT_ACTION_ENTRY_ID = (
  "moonclaw/first-trusted-square/remediation-margin-closeout-action-task"
)


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def load_optional_json(path: Path, fallback: Any) -> Any:
  try:
    return load_json(path)
  except FileNotFoundError:
    return fallback


def render_json(value: Any) -> str:
  return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def read_existing(path: Path) -> str | None:
  try:
    return path.read_text(encoding="utf-8")
  except FileNotFoundError:
    return None


def by_key(values: list[dict[str, Any]], key: str) -> dict[str, dict[str, Any]]:
  return {value[key]: value for value in values}


def route_id_from_entry(entry_id: str) -> str:
  return entry_id.rsplit("/", 1)[-1]


def first_transition_evidence_ref(transition: dict[str, Any]) -> str:
  refs = transition.get("source_evidence_refs", [])
  if not refs:
    return ""
  return refs[0].get("immutable_uri", "")


def clearance_transition_by_id(
  review_transitions: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
  return {
    transition["item_id"]: transition
    for transition in review_transitions
    if transition["item_id"].startswith("clear-")
    and transition["decision"] in {"Accept", "Reject", "RequestEvidence"}
  }


def closeout_action_review_state(
  review_transitions: list[dict[str, Any]],
) -> dict[str, Any]:
  transition = next(
    (
      item
      for item in reversed(review_transitions)
      if item.get("item_id") == CLOSEOUT_ACTION_REVIEW_ITEM_ID
    ),
    None,
  )
  if transition is None:
    return {
      "item_id": CLOSEOUT_ACTION_REVIEW_ITEM_ID,
      "entry_id": CLOSEOUT_ACTION_ENTRY_ID,
      "status": "NeedsReview",
      "decision": "RequestEvidence",
      "transition": None,
      "hardware_authority_change": False,
      "hardware_state": "HardwareDenied",
      "hardware_authority": "moonmoon-safety-gate-only",
    }
  return {
    "item_id": CLOSEOUT_ACTION_REVIEW_ITEM_ID,
    "entry_id": CLOSEOUT_ACTION_ENTRY_ID,
    "status": transition["resulting_status"],
    "decision": transition["decision"],
    "transition": transition,
    "hardware_authority_change": transition.get("hardware_authority_change", False),
    "hardware_state": transition.get("hardware_state", "HardwareDenied"),
    "hardware_authority": transition.get(
      "hardware_authority",
      "moonmoon-safety-gate-only",
    ),
  }


def apply_clearance_transition(
  item: dict[str, Any],
  transition: dict[str, Any],
) -> dict[str, Any]:
  decision = transition["decision"]
  next_item = dict(item)
  if decision == "Accept":
    next_item["decision"] = "Allow"
    next_item["status"] = "AcceptedEvidence"
    next_item["accepted_evidence_id"] = first_transition_evidence_ref(transition)
  elif decision == "Reject":
    next_item["decision"] = "Block"
    next_item["status"] = "RejectedEvidence"
    next_item["accepted_evidence_id"] = ""
  else:
    next_item["decision"] = "Block"
    next_item["status"] = "NeedsEvidence"
    next_item["accepted_evidence_id"] = ""
  label = {
    "Accept": "accept",
    "Reject": "reject",
    "RequestEvidence": "request-evidence",
  }[decision]
  action_prefix = (
    f"{label} by {transition['reviewer_id']} at "
    f"{transition['recorded_at_utc']}: {transition['rationale']}"
  )
  if not item["clearance_action"].startswith(action_prefix):
    next_item["clearance_action"] = (
      f"{action_prefix}; prior action was {item['clearance_action']}"
    )
  return next_item


def clearance_plan_with_review_transitions(
  plan: dict[str, Any],
  review_transitions: list[dict[str, Any]],
) -> dict[str, Any]:
  transitions = clearance_transition_by_id(review_transitions)
  next_plan = dict(plan)
  items = [
    apply_clearance_transition(item, transitions[item["clearance_id"]])
    if item["clearance_id"] in transitions
    else dict(item)
    for item in plan["items"]
  ]
  next_plan["items"] = items
  next_plan["blocking_items"] = [
    item["clearance_id"] for item in items if item["decision"] == "Block"
  ]
  next_plan["review_items"] = [
    item["clearance_id"] for item in items if item["decision"] == "Review"
  ]
  next_plan["accepted_items"] = [
    item["clearance_id"]
    for item in items
    if item["status"] == "AcceptedEvidence"
  ]
  next_plan["rejected_items"] = [
    item["clearance_id"]
    for item in items
    if item["status"] == "RejectedEvidence"
  ]
  if next_plan["blocking_items"]:
    next_plan["decision"] = "Block"
    next_plan["next_action"] = (
      "clear required terrain grade, illumination confidence, energy margin, "
      "and MoonBook review actions before simulation"
    )
  elif next_plan["review_items"]:
    next_plan["decision"] = "Review"
    next_plan["next_action"] = (
      "resolve review clearance items before MoonRobo consumes the "
      "selected-route simulation packet"
    )
  else:
    next_plan["decision"] = "Allow"
    next_plan["next_action"] = (
      "selected-route blockers are cleared; simulation packet can advance "
      "to MoonRobo review"
    )
  return next_plan


def handoff_with_reviewed_clearance(
  handoff: dict[str, Any],
  book: dict[str, Any],
) -> dict[str, Any]:
  next_handoff = dict(handoff)
  next_handoff["clearance_plan"] = clearance_plan_with_review_transitions(
    handoff["clearance_plan"],
    book["review_transitions"],
  )
  return next_handoff


def selected_moonrobo_handoff(
  site: dict[str, Any],
  book: dict[str, Any],
  moonrobo: list[dict[str, Any]],
) -> dict[str, Any]:
  primary_handoff = next(
    (
      handoff
      for handoff in moonrobo
      if handoff["route_id"] == site["corridor_scan"][0]["selected_route_id"]
    ),
    moonrobo[0],
  )
  return handoff_with_reviewed_clearance(primary_handoff, book)


def payload_for_entry(
  entry: dict[str, Any],
  site: dict[str, Any],
  book: dict[str, Any],
  moonclaw: list[dict[str, Any]],
  moonclaw_ephemeris_tasks: list[dict[str, Any]],
  moonclaw_corridor_tasks: list[dict[str, Any]],
  moonclaw_noetix_review_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_followup_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_closeout_action_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_action_plans: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_work_items: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_work_item_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_fresh_evidence_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_fresh_evidence_action_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts: list[dict[str, Any]],
  moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks: list[dict[str, Any]],
  moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_followup_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_receipts: list[dict[str, Any]],
  moonclaw_gap_tasks: list[dict[str, Any]],
  moonclaw_receipts: list[dict[str, Any]],
  moonclaw_ephemeris_receipts: list[dict[str, Any]],
  moonclaw_corridor_receipts: list[dict[str, Any]],
  moonclaw_gap_receipts: list[dict[str, Any]],
  moonrobo: list[dict[str, Any]],
  moonrobo_gap_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_projection: dict[str, Any],
  moonrobo_remediation_margin_refresh_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_refresh_followup_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_refresh_followup_projection: dict[str, Any],
  moonrobo_remediation_margin_cycle_closeout: dict[str, Any],
  moonrobo_remediation_margin_refresh_projection: dict[str, Any],
  moonrobo_remediation_margin_regenerated_receipt_readiness: dict[str, Any],
  moonrobo_regenerated_receipt_readiness_action_receipt_closeout: dict[str, Any],
  moonrobo_simulation_review_packet: dict[str, Any],
  moonrobo_simulation_review_decision: dict[str, Any],
  moonrobo_simulation_blocker_reduction: dict[str, Any],
  moonrobo_noetix_source_model: dict[str, Any],
  moonrobo_noetix_walk: dict[str, Any],
  moonrobo_noetix_walk_command: dict[str, Any],
  moonrobo_noetix_stability: dict[str, Any],
  moonrobo_noetix_dynamics: dict[str, Any],
  moonrobo_noetix_control: dict[str, Any],
  moonrobo_noetix_inertial_collision: dict[str, Any],
  moonrobo_noetix_link_poses: dict[str, Any],
  mission_energy_remediation: dict[str, Any],
  lookups: dict[str, dict[str, dict[str, Any]]],
) -> Any:
  kind = entry["kind"]
  entry_id = entry["entry_id"]

  if kind == "SourceDataset":
    return lookups["datasets"][entry_id.removeprefix("dataset/")]
  if kind == "SourceValidation":
    return lookups["validations"][entry_id.removeprefix("validation/")]
  if kind == "SourceUpgradeCandidate":
    return lookups["source_candidates"][
      entry_id.removeprefix("source-candidate/")
    ]
  if kind == "SourceAcquisitionPlan":
    return lookups["source_acquisition_plans"][
      entry_id.removeprefix("source-acquisition/")
    ]
  if kind == "SourceProductSelection":
    return lookups["source_product_selections"][
      entry_id.removeprefix("source-product/")
    ]
  if kind == "SourceExtractionCandidate":
    return lookups["source_extraction_candidates"][
      entry_id.removeprefix("source-extraction/")
    ]
  if kind == "DerivedTerrain":
    return site["terrain"]
  if kind == "MissionDecision":
    return site["traverse"]
  if kind == "CorridorScan":
    return {
      "scan_id": site["corridor_scan"][0]["scan_id"],
      "best_window": site["corridor_scan"][0],
      "windows": site["corridor_scan"],
    }
  if kind == "RouteAlternative":
    return lookups["route_candidates"][route_id_from_entry(entry_id)]
  if kind == "IlluminationAssessment":
    return lookups["route_candidates"][route_id_from_entry(entry_id)][
      "illumination"
    ]
  if kind == "LocalHorizonEvidence":
    return lookups["route_candidates"][route_id_from_entry(entry_id)][
      "illumination"
    ]["local_horizon"]
  if kind == "TerrainRemediationEvidence":
    return lookups["route_candidates"][route_id_from_entry(entry_id)][
      "terrain_remediation"
    ]
  if kind == "PowerWindowEvidence":
    return site["power_window_evidence"]
  if kind == "EnergyWindow":
    return site["energy"]
  if kind == "EnergyRemediationEvidence":
    return mission_energy_remediation
  if kind == "SelectedRouteClearance":
    return selected_moonrobo_handoff(site, book, moonrobo)["clearance_plan"]
  if kind == "MoonroboHandoff":
    primary_handoff = selected_moonrobo_handoff(site, book, moonrobo)
    return {
      "primary_handoff": primary_handoff,
      "handoffs": [
        primary_handoff if handoff["route_id"] == primary_handoff["route_id"]
        else handoff
        for handoff in moonrobo
      ],
    }
  if kind == "MoonroboGapModeling":
    return {
      "primary_modeling_pass": moonrobo_gap_modeling[0],
      "modeling_passes": moonrobo_gap_modeling,
    }
  if kind == "MoonroboRemediationMarginModeling":
    return {
      "primary_modeling_pass": moonrobo_remediation_margin_modeling[0],
      "modeling_passes": moonrobo_remediation_margin_modeling,
    }
  if kind == "MoonroboRemediationMarginProjection":
    return moonrobo_remediation_margin_projection
  if kind == "MoonroboRemediationMarginRefreshModeling":
    return {
      "primary_modeling_pass": moonrobo_remediation_margin_refresh_modeling[0],
      "modeling_passes": moonrobo_remediation_margin_refresh_modeling,
    }
  if kind == "MoonroboRemediationMarginRefreshFollowupModeling":
    return {
      "primary_modeling_pass": moonrobo_remediation_margin_refresh_followup_modeling[
        0
      ],
      "modeling_passes": moonrobo_remediation_margin_refresh_followup_modeling,
    }
  if kind == "MoonroboRemediationMarginRefreshFollowupProjection":
    return moonrobo_remediation_margin_refresh_followup_projection
  if kind == "MoonroboRemediationMarginCycleCloseoutPolicy":
    return moonrobo_remediation_margin_cycle_closeout
  if kind == "MoonroboRemediationMarginRefreshProjection":
    return moonrobo_remediation_margin_refresh_projection
  if kind == "MoonroboRemediationMarginRegeneratedReceiptReadiness":
    return moonrobo_remediation_margin_regenerated_receipt_readiness
  if kind == "MoonroboRegeneratedReceiptReadinessActionReceiptCloseout":
    return {
      "closeout": moonrobo_regenerated_receipt_readiness_action_receipt_closeout,
      "source_action_receipts": moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts,
      "source_readiness": moonrobo_remediation_margin_regenerated_receipt_readiness,
    }
  if kind == "MoonroboSimulationReviewPacket":
    return moonrobo_simulation_review_packet
  if kind == "MoonroboSimulationReviewDecision":
    return moonrobo_simulation_review_decision
  if kind == "MoonroboSimulationBlockerReduction":
    return moonrobo_simulation_blocker_reduction
  if kind == "MoonroboNoetixSourceModel":
    return moonrobo_noetix_source_model
  if kind == "MoonroboNoetixWalk":
    return moonrobo_noetix_walk
  if kind == "MoonroboNoetixWalkCommand":
    return moonrobo_noetix_walk_command
  if kind == "MoonroboNoetixPhysics":
    return moonrobo_noetix_stability
  if kind == "MoonroboNoetixDynamics":
    return moonrobo_noetix_dynamics
  if kind == "MoonroboNoetixJointControl":
    return moonrobo_noetix_control
  if kind == "MoonroboNoetixInertialCollision":
    return moonrobo_noetix_inertial_collision
  if kind == "MoonroboNoetixLinkPoses":
    return moonrobo_noetix_link_poses
  if kind == "MoonClawProposal":
    return {
      "primary_proposal": moonclaw[0],
      "proposals": moonclaw,
    }
  if kind == "MoonClawTask":
    if entry_id.endswith("/moonrobo-gap-remediation-task"):
      return {
        "primary_task": moonclaw_gap_tasks[0],
        "tasks": moonclaw_gap_tasks,
      }
    if entry_id.endswith("/remediation-margin-task"):
      return {
        "primary_task": moonclaw_remediation_margin_tasks[0],
        "tasks": moonclaw_remediation_margin_tasks,
      }
    if entry_id.endswith("/corridor-expansion-task"):
      return {
        "primary_task": moonclaw_corridor_tasks[0],
        "tasks": moonclaw_corridor_tasks,
      }
    return {
      "primary_task": moonclaw_ephemeris_tasks[0],
      "tasks": moonclaw_ephemeris_tasks,
    }
  if kind == "MoonClawNoetixReviewTask":
    return {
      "primary_task": moonclaw_noetix_review_tasks[0],
      "tasks": moonclaw_noetix_review_tasks,
      "source_model": moonrobo_noetix_source_model,
      "source_walk": moonrobo_noetix_walk,
      "source_walk_command": moonrobo_noetix_walk_command,
      "source_static_support": moonrobo_noetix_stability,
      "source_dynamic_stability": moonrobo_noetix_dynamics,
      "source_joint_control": moonrobo_noetix_control,
      "source_inertial_collision": moonrobo_noetix_inertial_collision,
      "source_link_poses": moonrobo_noetix_link_poses,
    }
  if kind == "MoonClawRemediationMarginRefreshTask":
    return {
      "primary_task": moonclaw_remediation_margin_refresh_tasks[0],
      "tasks": moonclaw_remediation_margin_refresh_tasks,
    }
  if kind == "MoonClawRemediationMarginRefreshFollowupTask":
    return {
      "primary_task": moonclaw_remediation_margin_refresh_followup_tasks[0],
      "tasks": moonclaw_remediation_margin_refresh_followup_tasks,
    }
  if kind == "MoonClawRemediationMarginCloseoutActionTask":
    return {
      "primary_task": moonclaw_remediation_margin_closeout_action_tasks[0],
      "tasks": moonclaw_remediation_margin_closeout_action_tasks,
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRemediationMarginReviewedActionPlan":
    return {
      "primary_plan": moonclaw_remediation_margin_reviewed_action_plans[0],
      "plans": moonclaw_remediation_margin_reviewed_action_plans,
      "source_task": moonclaw_remediation_margin_closeout_action_tasks[0],
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRemediationMarginReviewedWorkItems":
    return {
      "primary_work_item": moonclaw_remediation_margin_reviewed_work_items[0],
      "work_items": moonclaw_remediation_margin_reviewed_work_items,
      "source_plan": moonclaw_remediation_margin_reviewed_action_plans[0],
      "source_task": moonclaw_remediation_margin_closeout_action_tasks[0],
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRemediationMarginReviewedWorkItemReceipts":
    return {
      "primary_receipt": moonclaw_remediation_margin_reviewed_work_item_receipts[
        0
      ],
      "receipts": moonclaw_remediation_margin_reviewed_work_item_receipts,
      "source_work_items": moonclaw_remediation_margin_reviewed_work_items,
      "source_plan": moonclaw_remediation_margin_reviewed_action_plans[0],
      "source_task": moonclaw_remediation_margin_closeout_action_tasks[0],
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRemediationMarginReviewedFreshEvidenceTask":
    return {
      "primary_task": moonclaw_remediation_margin_reviewed_fresh_evidence_tasks[
        0
      ],
      "tasks": moonclaw_remediation_margin_reviewed_fresh_evidence_tasks,
      "source_receipts": moonclaw_remediation_margin_reviewed_work_item_receipts,
      "source_work_items": moonclaw_remediation_margin_reviewed_work_items,
      "source_plan": moonclaw_remediation_margin_reviewed_action_plans[0],
      "source_task": moonclaw_remediation_margin_closeout_action_tasks[0],
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRemediationMarginFreshEvidenceActionReceipts":
    return {
      "primary_receipt": moonclaw_remediation_margin_fresh_evidence_action_receipts[
        0
      ],
      "receipts": moonclaw_remediation_margin_fresh_evidence_action_receipts,
      "source_task": moonclaw_remediation_margin_reviewed_fresh_evidence_tasks[
        0
      ],
      "source_receipts": moonclaw_remediation_margin_reviewed_work_item_receipts,
      "source_work_items": moonclaw_remediation_margin_reviewed_work_items,
      "source_plan": moonclaw_remediation_margin_reviewed_action_plans[0],
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRemediationMarginRegeneratedReviewedWorkItemReceipts":
    return {
      "primary_receipt": moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts[
        0
      ],
      "receipts": moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts,
      "source_action_receipts": moonclaw_remediation_margin_fresh_evidence_action_receipts,
      "source_task": moonclaw_remediation_margin_reviewed_fresh_evidence_tasks[
        0
      ],
      "source_receipts": moonclaw_remediation_margin_reviewed_work_item_receipts,
      "source_work_items": moonclaw_remediation_margin_reviewed_work_items,
      "source_plan": moonclaw_remediation_margin_reviewed_action_plans[0],
      "review": closeout_action_review_state(book["review_transitions"]),
    }
  if kind == "MoonClawRegeneratedReceiptReadinessFreshEvidenceTask":
    return {
      "primary_task": moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks[
        0
      ],
      "tasks": moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks,
      "source_readiness": moonrobo_remediation_margin_regenerated_receipt_readiness,
      "source_receipts": moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts,
      "source_action_receipts": moonclaw_remediation_margin_fresh_evidence_action_receipts,
    }
  if kind == "MoonClawRegeneratedReceiptReadinessFreshEvidenceActionReceipts":
    return {
      "primary_receipt": moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts[
        0
      ],
      "receipts": moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts,
      "source_task": moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks[
        0
      ],
      "source_readiness": moonrobo_remediation_margin_regenerated_receipt_readiness,
      "source_receipts": moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts,
      "source_action_receipts": moonclaw_remediation_margin_fresh_evidence_action_receipts,
    }
  if kind == "MoonClawRemediationMarginRefreshFollowupReceipt":
    return {
      "primary_receipt": moonclaw_remediation_margin_refresh_followup_receipts[0],
      "receipts": moonclaw_remediation_margin_refresh_followup_receipts,
    }
  if kind == "MoonClawRemediationMarginRefreshReceipt":
    return {
      "primary_receipt": moonclaw_remediation_margin_refresh_receipts[0],
      "receipts": moonclaw_remediation_margin_refresh_receipts,
    }
  if kind == "MoonClawReceipt":
    return {
      "primary_receipt": moonclaw_receipts[0],
      "receipts": moonclaw_receipts,
    }
  if kind == "MoonClawRemediationMarginReceipt":
    return {
      "primary_receipt": moonclaw_remediation_margin_receipts[0],
      "receipts": moonclaw_remediation_margin_receipts,
    }
  if kind == "MoonClawEphemerisReceipt":
    return {
      "primary_receipt": moonclaw_ephemeris_receipts[0],
      "receipts": moonclaw_ephemeris_receipts,
    }
  if kind == "MoonClawCorridorReceipt":
    return {
      "primary_receipt": moonclaw_corridor_receipts[0],
      "receipts": moonclaw_corridor_receipts,
    }
  if kind == "MoonClawGapReceipt":
    return {
      "primary_receipt": moonclaw_gap_receipts[0],
      "receipts": moonclaw_gap_receipts,
    }

  raise ValueError(f"unsupported entry kind {kind!r} for {entry_id}")


def workspace_files(
  site: dict[str, Any],
  book: dict[str, Any],
  moonclaw: list[dict[str, Any]],
  moonclaw_ephemeris_tasks: list[dict[str, Any]],
  moonclaw_corridor_tasks: list[dict[str, Any]],
  moonclaw_noetix_review_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_followup_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_closeout_action_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_action_plans: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_work_items: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_work_item_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_reviewed_fresh_evidence_tasks: list[dict[str, Any]],
  moonclaw_remediation_margin_fresh_evidence_action_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts: list[dict[str, Any]],
  moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks: list[dict[str, Any]],
  moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_followup_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_refresh_receipts: list[dict[str, Any]],
  moonclaw_remediation_margin_receipts: list[dict[str, Any]],
  moonclaw_gap_tasks: list[dict[str, Any]],
  moonclaw_receipts: list[dict[str, Any]],
  moonclaw_ephemeris_receipts: list[dict[str, Any]],
  moonclaw_corridor_receipts: list[dict[str, Any]],
  moonclaw_gap_receipts: list[dict[str, Any]],
  moonrobo: list[dict[str, Any]],
  moonrobo_gap_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_projection: dict[str, Any],
  moonrobo_remediation_margin_refresh_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_refresh_followup_modeling: list[dict[str, Any]],
  moonrobo_remediation_margin_refresh_followup_projection: dict[str, Any],
  moonrobo_remediation_margin_cycle_closeout: dict[str, Any],
  moonrobo_remediation_margin_refresh_projection: dict[str, Any],
  moonrobo_remediation_margin_regenerated_receipt_readiness: dict[str, Any],
  moonrobo_regenerated_receipt_readiness_action_receipt_closeout: dict[str, Any],
  moonrobo_simulation_review_packet: dict[str, Any],
  moonrobo_simulation_review_decision: dict[str, Any],
  moonrobo_simulation_blocker_reduction: dict[str, Any],
  moonrobo_noetix_source_model: dict[str, Any],
  moonrobo_noetix_walk: dict[str, Any],
  moonrobo_noetix_walk_command: dict[str, Any],
  moonrobo_noetix_stability: dict[str, Any],
  moonrobo_noetix_dynamics: dict[str, Any],
  moonrobo_noetix_control: dict[str, Any],
  moonrobo_noetix_inertial_collision: dict[str, Any],
  moonrobo_noetix_link_poses: dict[str, Any],
  mission_horizon: dict[str, Any],
  mission_terrain_remediation: dict[str, Any],
  mission_energy_remediation: dict[str, Any],
) -> dict[Path, str]:
  lookups = {
    "datasets": by_key(site["datasets"], "dataset_id"),
    "validations": by_key(site["validations"], "dataset_id"),
    "source_candidates": by_key(site["source_candidates"], "candidate_id"),
    "source_acquisition_plans": by_key(
      site["source_acquisition_plans"], "plan_id",
    ),
    "source_product_selections": by_key(
      site["source_product_selections"], "selection_id",
    ),
    "source_extraction_candidates": by_key(
      site["source_extraction_candidates"], "extraction_id",
    ),
    "route_candidates": by_key(site["route_candidates"], "route_id"),
  }

  files: dict[Path, str] = {}
  entries = book["entries"]
  review_queue = book["review_queue"]
  review_transitions = book["review_transitions"]
  entry_paths: list[str] = []
  source_files = [
    "output/site/first_trusted_square.json",
    "output/moonbook/first_trusted_square_book.json",
    "output/moonclaw/first_trusted_square_proposals.json",
    "output/moonclaw/first_trusted_square_ephemeris_tasks.json",
    "output/moonclaw/first_trusted_square_corridor_tasks.json",
    "output/moonclaw/first_trusted_square_noetix_review_task.json",
    "output/moonclaw/first_trusted_square_remediation_margin_task.json",
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json",
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json",
    "output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json",
    "output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json",
    "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json",
    "output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json",
    "output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json",
    "output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json",
    "output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json",
    "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json",
    "output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json",
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json",
    "output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json",
    "output/moonclaw/first_trusted_square_remediation_margin_receipt.json",
    "output/moonclaw/first_trusted_square_receipts.json",
    "output/moonclaw/first_trusted_square_ephemeris_receipts.json",
    "output/moonclaw/first_trusted_square_corridor_receipts.json",
    "output/mission/first_trusted_square_northeast_stepout_horizon.json",
    "output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json",
    "output/mission/first_trusted_square_energy_remediation.json",
    "output/moonrobo/first_trusted_square_handoffs.json",
    "output/moonrobo/first_trusted_square_noetix_source_model.json",
    "output/moonrobo/first_trusted_square_noetix_walk.json",
    "output/moonrobo/first_trusted_square_noetix_walk_command.json",
    "output/moonrobo/first_trusted_square_noetix_stability.json",
    "output/moonrobo/first_trusted_square_noetix_dynamics.json",
    "output/moonrobo/first_trusted_square_noetix_control.json",
    "output/moonrobo/first_trusted_square_noetix_inertial_collision.json",
    "output/moonrobo/first_trusted_square_noetix_link_poses.json",
  ]
  if moonclaw_gap_tasks:
    source_files.append(
      "output/moonclaw/first_trusted_square_moonrobo_gap_task.json",
    )
  if moonclaw_gap_receipts:
    source_files.append(
      "output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json",
    )
  if moonrobo_gap_modeling:
    source_files.append(
      "output/moonrobo/first_trusted_square_gap_remediation_modeling.json",
    )
  if moonrobo_remediation_margin_modeling:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_modeling.json",
    )
  if moonrobo_remediation_margin_projection:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_projection.json",
    )
  if moonrobo_remediation_margin_refresh_modeling:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json",
    )
  if moonrobo_remediation_margin_refresh_followup_modeling:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json",
    )
  if moonrobo_remediation_margin_refresh_followup_projection:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
    )
  if moonrobo_remediation_margin_cycle_closeout:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json",
    )
  if moonrobo_remediation_margin_refresh_projection:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
    )
  if moonrobo_remediation_margin_regenerated_receipt_readiness:
    source_files.append(
      "output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json",
    )
  if moonrobo_regenerated_receipt_readiness_action_receipt_closeout:
    source_files.append(
      "output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json",
    )
  if moonrobo_simulation_review_packet:
    source_files.append(
      "output/moonrobo/first_trusted_square_simulation_review_packet.json",
    )
  if moonrobo_simulation_review_decision:
    source_files.append(
      "output/moonrobo/first_trusted_square_simulation_review_decision.json",
    )
  if moonrobo_simulation_blocker_reduction:
    source_files.append(
      "output/moonrobo/first_trusted_square_simulation_blocker_reduction.json",
    )

  index = {
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "title": book["title"],
    "generated_by": GENERATOR,
    "source_files": source_files,
    "entries": entries,
    "review_queue_path": "review_queue.json",
    "review_transitions_path": "review_transitions.json",
  }
  files[WORKSPACE / "index.json"] = render_json(index)

  for entry in entries:
    path = WORKSPACE / entry["path"]
    entry_paths.append(entry["path"])
    payload = payload_for_entry(
      entry,
      site,
      book,
      moonclaw,
      moonclaw_ephemeris_tasks,
      moonclaw_corridor_tasks,
      moonclaw_noetix_review_tasks,
      moonclaw_remediation_margin_tasks,
      moonclaw_remediation_margin_refresh_tasks,
      moonclaw_remediation_margin_refresh_followup_tasks,
      moonclaw_remediation_margin_closeout_action_tasks,
      moonclaw_remediation_margin_reviewed_action_plans,
      moonclaw_remediation_margin_reviewed_work_items,
      moonclaw_remediation_margin_reviewed_work_item_receipts,
      moonclaw_remediation_margin_reviewed_fresh_evidence_tasks,
      moonclaw_remediation_margin_fresh_evidence_action_receipts,
      moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts,
      moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks,
      moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts,
      moonclaw_remediation_margin_refresh_followup_receipts,
      moonclaw_remediation_margin_refresh_receipts,
      moonclaw_remediation_margin_receipts,
      moonclaw_gap_tasks,
      moonclaw_receipts,
      moonclaw_ephemeris_receipts,
      moonclaw_corridor_receipts,
      moonclaw_gap_receipts,
      moonrobo,
      moonrobo_gap_modeling,
      moonrobo_remediation_margin_modeling,
      moonrobo_remediation_margin_projection,
      moonrobo_remediation_margin_refresh_modeling,
      moonrobo_remediation_margin_refresh_followup_modeling,
      moonrobo_remediation_margin_refresh_followup_projection,
      moonrobo_remediation_margin_cycle_closeout,
      moonrobo_remediation_margin_refresh_projection,
      moonrobo_remediation_margin_regenerated_receipt_readiness,
      moonrobo_regenerated_receipt_readiness_action_receipt_closeout,
      moonrobo_simulation_review_packet,
      moonrobo_simulation_review_decision,
      moonrobo_simulation_blocker_reduction,
      moonrobo_noetix_source_model,
      moonrobo_noetix_walk,
      moonrobo_noetix_walk_command,
      moonrobo_noetix_stability,
      moonrobo_noetix_dynamics,
      moonrobo_noetix_control,
      moonrobo_noetix_inertial_collision,
      moonrobo_noetix_link_poses,
      mission_energy_remediation,
      lookups,
    )
    files[path] = render_json({
      "entry": entry,
      "payload": payload,
      "workspace": book["workspace"],
      "site_id": book["site_id"],
      "generated_by": GENERATOR,
    })

  files[WORKSPACE / "review_queue.json"] = render_json({
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "generated_by": GENERATOR,
    "items": review_queue,
  })

  files[WORKSPACE / "review_transitions.json"] = render_json({
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "generated_by": GENERATOR,
    "items": review_transitions,
  })

  files[WORKSPACE / "manifest.json"] = render_json({
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "generated_by": GENERATOR,
    "entry_count": len(entries),
    "review_queue_count": len(review_queue),
    "review_transition_count": len(review_transitions),
    "entry_paths": entry_paths,
    "review_queue_path": "review_queue.json",
    "review_transitions_path": "review_transitions.json",
  })

  readme = (
    "# First Trusted Square MoonBook Workspace\n\n"
    "This directory is generated. It materializes the MoonBook entry index, "
    "per-entry evidence payloads, and review queue for the Moonmoon "
    "first-trusted-square proof slice.\n\n"
    "- Source site dossier: `output/site/first_trusted_square.json`\n"
    "- Source MoonBook dossier: `output/moonbook/first_trusted_square_book.json`\n"
    "- Source MoonClaw proposals: `output/moonclaw/first_trusted_square_proposals.json`\n"
    "- Source MoonClaw ephemeris tasks: `output/moonclaw/first_trusted_square_ephemeris_tasks.json`\n"
    "- Source MoonClaw corridor tasks: `output/moonclaw/first_trusted_square_corridor_tasks.json`\n"
    "- Source MoonClaw Noetix review task: `output/moonclaw/first_trusted_square_noetix_review_task.json`\n"
    "- Source MoonClaw remediation-margin task: `output/moonclaw/first_trusted_square_remediation_margin_task.json`\n"
    "- Source MoonClaw remediation-margin refresh task: `output/moonclaw/first_trusted_square_remediation_margin_refresh_task.json`\n"
    "- Source MoonClaw remediation-margin refresh follow-up task: `output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_task.json`\n"
    "- Source MoonClaw remediation-margin closeout action task: `output/moonclaw/first_trusted_square_remediation_margin_closeout_action_task.json`\n"
    "- Source MoonClaw remediation-margin reviewed action plan: `output/moonclaw/first_trusted_square_remediation_margin_reviewed_action_plan.json`\n"
    "- Source MoonClaw remediation-margin reviewed work items: `output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_items.json`\n"
    "- Source MoonClaw remediation-margin reviewed work item receipts: `output/moonclaw/first_trusted_square_remediation_margin_reviewed_work_item_receipts.json`\n"
    "- Source MoonClaw remediation-margin reviewed fresh evidence task: `output/moonclaw/first_trusted_square_remediation_margin_reviewed_fresh_evidence_task.json`\n"
    "- Source MoonClaw remediation-margin fresh evidence action receipts: `output/moonclaw/first_trusted_square_remediation_margin_fresh_evidence_action_receipts.json`\n"
    "- Source MoonClaw remediation-margin regenerated reviewed work item receipts: `output/moonclaw/first_trusted_square_remediation_margin_regenerated_reviewed_work_item_receipts.json`\n"
    "- Source MoonClaw regenerated receipt readiness fresh evidence task: `output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_task.json`\n"
    "- Source MoonClaw regenerated receipt readiness fresh evidence action receipts: `output/moonclaw/first_trusted_square_regenerated_receipt_readiness_fresh_evidence_action_receipts.json`\n"
    "- Source MoonClaw remediation-margin refresh follow-up receipt: `output/moonclaw/first_trusted_square_remediation_margin_refresh_followup_receipt.json`\n"
    "- Source MoonClaw remediation-margin refresh receipt: `output/moonclaw/first_trusted_square_remediation_margin_refresh_receipt.json`\n"
    "- Source MoonClaw remediation-margin receipt: `output/moonclaw/first_trusted_square_remediation_margin_receipt.json`\n"
    "- Source MoonClaw receipts: `output/moonclaw/first_trusted_square_receipts.json`\n"
    "- Source MoonClaw ephemeris receipts: `output/moonclaw/first_trusted_square_ephemeris_receipts.json`\n"
    "- Source MoonClaw corridor receipts: `output/moonclaw/first_trusted_square_corridor_receipts.json`\n"
    "- Source MoonRobo Noetix source model: `output/moonrobo/first_trusted_square_noetix_source_model.json`\n"
    "- Source MoonRobo Noetix walk: `output/moonrobo/first_trusted_square_noetix_walk.json`\n"
    "- Source MoonRobo Noetix walk command: `output/moonrobo/first_trusted_square_noetix_walk_command.json`\n"
    "- Source MoonRobo Noetix static support: `output/moonrobo/first_trusted_square_noetix_stability.json`\n"
    "- Source MoonRobo Noetix dynamic stability: `output/moonrobo/first_trusted_square_noetix_dynamics.json`\n"
    "- Source MoonRobo Noetix joint control: `output/moonrobo/first_trusted_square_noetix_control.json`\n"
    "- Source MoonRobo Noetix inertial/collision: `output/moonrobo/first_trusted_square_noetix_inertial_collision.json`\n"
    "- Source MoonRobo Noetix link poses: `output/moonrobo/first_trusted_square_noetix_link_poses.json`\n"
  )
  if moonclaw_gap_tasks:
    readme += "- Source imported MoonClaw gap task: `output/moonclaw/first_trusted_square_moonrobo_gap_task.json`\n"
  if moonclaw_gap_receipts:
    readme += "- Source imported MoonClaw gap receipt: `output/moonclaw/first_trusted_square_moonrobo_gap_receipt.json`\n"
  if moonrobo_gap_modeling:
    readme += "- Source imported MoonRobo gap modeling: `output/moonrobo/first_trusted_square_gap_remediation_modeling.json`\n"
  if moonrobo_remediation_margin_modeling:
    readme += "- Source MoonRobo remediation-margin modeling: `output/moonrobo/first_trusted_square_remediation_margin_modeling.json`\n"
  if moonrobo_remediation_margin_projection:
    readme += "- Source MoonRobo remediation-margin projection: `output/moonrobo/first_trusted_square_remediation_margin_projection.json`\n"
  if moonrobo_remediation_margin_refresh_modeling:
    readme += "- Source MoonRobo remediation-margin refresh modeling: `output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json`\n"
  if moonrobo_remediation_margin_refresh_followup_modeling:
    readme += "- Source MoonRobo remediation-margin refresh follow-up modeling: `output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json`\n"
  if moonrobo_remediation_margin_refresh_followup_projection:
    readme += "- Source MoonRobo remediation-margin refresh follow-up projection: `output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json`\n"
  if moonrobo_remediation_margin_cycle_closeout:
    readme += "- Source MoonRobo remediation-margin cycle closeout: `output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json`\n"
  if moonrobo_remediation_margin_refresh_projection:
    readme += "- Source MoonRobo remediation-margin refresh projection: `output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json`\n"
  if moonrobo_remediation_margin_regenerated_receipt_readiness:
    readme += "- Source MoonRobo regenerated receipt readiness: `output/moonrobo/first_trusted_square_remediation_margin_regenerated_receipt_readiness.json`\n"
  if moonrobo_regenerated_receipt_readiness_action_receipt_closeout:
    readme += "- Source MoonRobo regenerated receipt readiness action receipt closeout: `output/moonrobo/first_trusted_square_regenerated_receipt_readiness_action_receipt_closeout.json`\n"
  if moonrobo_simulation_review_packet:
    readme += "- Source MoonRobo simulation review packet: `output/moonrobo/first_trusted_square_simulation_review_packet.json`\n"
  if moonrobo_simulation_review_decision:
    readme += "- Source MoonRobo simulation review decision: `output/moonrobo/first_trusted_square_simulation_review_decision.json`\n"
  if moonrobo_simulation_blocker_reduction:
    readme += "- Source MoonRobo simulation blocker reduction: `output/moonrobo/first_trusted_square_simulation_blocker_reduction.json`\n"
  if mission_horizon:
    readme += "- Source selected-route horizon: `output/mission/first_trusted_square_northeast_stepout_horizon.json`\n"
  if mission_terrain_remediation:
    readme += "- Source selected-route terrain remediation: `output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json`\n"
  if mission_energy_remediation:
    readme += "- Source selected-route energy remediation: `output/mission/first_trusted_square_energy_remediation.json`\n"
  readme += (
    f"- Entries: {len(entries)}\n"
    f"- Review queue items: {len(review_queue)}\n"
    f"- Review transitions: {len(review_transitions)}\n"
  )
  files[WORKSPACE / "README.md"] = readme

  return files


def check_workspace(files: dict[Path, str]) -> int:
  missing: list[Path] = []
  stale: list[Path] = []
  for path, expected in files.items():
    actual = read_existing(path)
    if actual is None:
      missing.append(path)
    elif actual != expected:
      stale.append(path)

  extra: list[Path] = []
  if WORKSPACE.exists():
    expected_paths = set(files)
    for path in sorted(WORKSPACE.rglob("*")):
      if path.is_file() and path not in expected_paths:
        extra.append(path)

  if missing or stale or extra:
    for path in missing:
      print(f"missing {path.relative_to(ROOT)}", file=sys.stderr)
    for path in stale:
      print(f"stale {path.relative_to(ROOT)}", file=sys.stderr)
    for path in extra:
      print(f"extra {path.relative_to(ROOT)}", file=sys.stderr)
    return 1

  print(f"checked {WORKSPACE.relative_to(ROOT)}")
  return 0


def write_workspace(files: dict[Path, str]) -> None:
  if WORKSPACE.exists():
    shutil.rmtree(WORKSPACE)
  for path, content in files.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
  print(f"wrote {WORKSPACE.relative_to(ROOT)}")


def main() -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument(
    "--check",
    action="store_true",
    help="verify generated workspace files are current",
  )
  args = parser.parse_args()

  site = load_json(SITE_JSON)
  book = load_json(BOOK_JSON)
  moonclaw = load_json(MOONCLAW_JSON)
  moonclaw_ephemeris_tasks = load_json(MOONCLAW_EPHEMERIS_TASKS_JSON)
  moonclaw_corridor_tasks = load_json(MOONCLAW_CORRIDOR_TASKS_JSON)
  moonclaw_noetix_review_tasks = load_json(MOONCLAW_NOETIX_REVIEW_TASK_JSON)
  moonclaw_remediation_margin_tasks = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_TASK_JSON,
    [],
  )
  moonclaw_remediation_margin_refresh_tasks = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REFRESH_TASK_JSON,
    [],
  )
  moonclaw_remediation_margin_refresh_followup_tasks = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_TASK_JSON,
    [],
  )
  moonclaw_remediation_margin_closeout_action_tasks = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_CLOSEOUT_ACTION_TASK_JSON,
    [],
  )
  moonclaw_remediation_margin_reviewed_action_plans = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REVIEWED_ACTION_PLAN_JSON,
    [],
  )
  moonclaw_remediation_margin_reviewed_work_items = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REVIEWED_WORK_ITEMS_JSON,
    [],
  )
  moonclaw_remediation_margin_reviewed_work_item_receipts = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REVIEWED_WORK_ITEM_RECEIPTS_JSON,
    [],
  )
  moonclaw_remediation_margin_reviewed_fresh_evidence_tasks = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REVIEWED_FRESH_EVIDENCE_TASK_JSON,
    [],
  )
  moonclaw_remediation_margin_fresh_evidence_action_receipts = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_FRESH_EVIDENCE_ACTION_RECEIPTS_JSON,
    [],
  )
  moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REGENERATED_REVIEWED_WORK_ITEM_RECEIPTS_JSON,
    [],
  )
  moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks = load_optional_json(
    MOONCLAW_REGENERATED_RECEIPT_READINESS_FRESH_EVIDENCE_TASK_JSON,
    [],
  )
  moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts = load_optional_json(
    MOONCLAW_REGENERATED_RECEIPT_READINESS_FRESH_EVIDENCE_ACTION_RECEIPTS_JSON,
    [],
  )
  moonclaw_remediation_margin_refresh_followup_receipts = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_RECEIPT_JSON,
    [],
  )
  moonclaw_remediation_margin_refresh_receipts = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_REFRESH_RECEIPT_JSON,
    [],
  )
  moonclaw_remediation_margin_receipts = load_optional_json(
    MOONCLAW_REMEDIATION_MARGIN_RECEIPT_JSON,
    [],
  )
  moonclaw_gap_tasks = load_optional_json(MOONCLAW_GAP_TASK_JSON, [])
  moonclaw_receipts = load_json(MOONCLAW_RECEIPTS_JSON)
  moonclaw_ephemeris_receipts = load_json(MOONCLAW_EPHEMERIS_RECEIPTS_JSON)
  moonclaw_corridor_receipts = load_json(MOONCLAW_CORRIDOR_RECEIPTS_JSON)
  moonclaw_gap_receipts = load_optional_json(MOONCLAW_GAP_RECEIPT_JSON, [])
  moonrobo = load_json(MOONROBO_JSON)
  moonrobo_gap_modeling = load_optional_json(MOONROBO_GAP_MODELING_JSON, [])
  moonrobo_remediation_margin_modeling = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_MODELING_JSON,
    [],
  )
  moonrobo_remediation_margin_projection = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_PROJECTION_JSON,
    {},
  )
  moonrobo_remediation_margin_refresh_modeling = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_REFRESH_MODELING_JSON,
    [],
  )
  moonrobo_remediation_margin_refresh_followup_modeling = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_MODELING_JSON,
    [],
  )
  moonrobo_remediation_margin_refresh_followup_projection = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_REFRESH_FOLLOWUP_PROJECTION_JSON,
    {},
  )
  moonrobo_remediation_margin_cycle_closeout = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_CYCLE_CLOSEOUT_JSON,
    {},
  )
  moonrobo_remediation_margin_refresh_projection = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_REFRESH_PROJECTION_JSON,
    {},
  )
  moonrobo_remediation_margin_regenerated_receipt_readiness = load_optional_json(
    MOONROBO_REMEDIATION_MARGIN_REGENERATED_RECEIPT_READINESS_JSON,
    {},
  )
  moonrobo_regenerated_receipt_readiness_action_receipt_closeout = load_optional_json(
    MOONROBO_REGENERATED_RECEIPT_READINESS_ACTION_RECEIPT_CLOSEOUT_JSON,
    {},
  )
  moonrobo_simulation_review_packet = load_optional_json(
    MOONROBO_SIMULATION_REVIEW_PACKET_JSON,
    {},
  )
  moonrobo_simulation_review_decision = load_optional_json(
    MOONROBO_SIMULATION_REVIEW_DECISION_JSON,
    {},
  )
  moonrobo_simulation_blocker_reduction = load_optional_json(
    MOONROBO_SIMULATION_BLOCKER_REDUCTION_JSON,
    {},
  )
  moonrobo_noetix_source_model = load_json(MOONROBO_NOETIX_SOURCE_MODEL_JSON)
  moonrobo_noetix_walk = load_json(MOONROBO_NOETIX_WALK_JSON)
  moonrobo_noetix_walk_command = load_json(MOONROBO_NOETIX_WALK_COMMAND_JSON)
  moonrobo_noetix_stability = load_json(MOONROBO_NOETIX_STABILITY_JSON)
  moonrobo_noetix_dynamics = load_json(MOONROBO_NOETIX_DYNAMICS_JSON)
  moonrobo_noetix_control = load_json(MOONROBO_NOETIX_CONTROL_JSON)
  moonrobo_noetix_inertial_collision = load_json(
    MOONROBO_NOETIX_INERTIAL_COLLISION_JSON,
  )
  moonrobo_noetix_link_poses = load_json(MOONROBO_NOETIX_LINK_POSES_JSON)
  mission_horizon = load_json(MISSION_HORIZON_JSON)
  mission_terrain_remediation = load_json(MISSION_TERRAIN_REMEDIATION_JSON)
  mission_energy_remediation = load_json(MISSION_ENERGY_REMEDIATION_JSON)
  files = workspace_files(
    site,
    book,
    moonclaw,
    moonclaw_ephemeris_tasks,
    moonclaw_corridor_tasks,
    moonclaw_noetix_review_tasks,
    moonclaw_remediation_margin_tasks,
    moonclaw_remediation_margin_refresh_tasks,
    moonclaw_remediation_margin_refresh_followup_tasks,
    moonclaw_remediation_margin_closeout_action_tasks,
    moonclaw_remediation_margin_reviewed_action_plans,
    moonclaw_remediation_margin_reviewed_work_items,
    moonclaw_remediation_margin_reviewed_work_item_receipts,
    moonclaw_remediation_margin_reviewed_fresh_evidence_tasks,
    moonclaw_remediation_margin_fresh_evidence_action_receipts,
    moonclaw_remediation_margin_regenerated_reviewed_work_item_receipts,
    moonclaw_regenerated_receipt_readiness_fresh_evidence_tasks,
    moonclaw_regenerated_receipt_readiness_fresh_evidence_action_receipts,
    moonclaw_remediation_margin_refresh_followup_receipts,
    moonclaw_remediation_margin_refresh_receipts,
    moonclaw_remediation_margin_receipts,
    moonclaw_gap_tasks,
    moonclaw_receipts,
    moonclaw_ephemeris_receipts,
    moonclaw_corridor_receipts,
    moonclaw_gap_receipts,
    moonrobo,
    moonrobo_gap_modeling,
    moonrobo_remediation_margin_modeling,
    moonrobo_remediation_margin_projection,
    moonrobo_remediation_margin_refresh_modeling,
    moonrobo_remediation_margin_refresh_followup_modeling,
    moonrobo_remediation_margin_refresh_followup_projection,
    moonrobo_remediation_margin_cycle_closeout,
    moonrobo_remediation_margin_refresh_projection,
    moonrobo_remediation_margin_regenerated_receipt_readiness,
    moonrobo_regenerated_receipt_readiness_action_receipt_closeout,
    moonrobo_simulation_review_packet,
    moonrobo_simulation_review_decision,
    moonrobo_simulation_blocker_reduction,
    moonrobo_noetix_source_model,
    moonrobo_noetix_walk,
    moonrobo_noetix_walk_command,
    moonrobo_noetix_stability,
    moonrobo_noetix_dynamics,
    moonrobo_noetix_control,
    moonrobo_noetix_inertial_collision,
    moonrobo_noetix_link_poses,
    mission_horizon,
    mission_terrain_remediation,
    mission_energy_remediation,
  )
  if args.check:
    return check_workspace(files)
  write_workspace(files)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
