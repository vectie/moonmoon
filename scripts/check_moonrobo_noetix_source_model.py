#!/usr/bin/env python3
"""Validate the Noetix source model audit artifact."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


EXPECTED_REPORT_ID = "moonrobo/noetix-e1/source-model/audit-v0"


def require(condition: bool, message: str) -> None:
  if not condition:
    raise AssertionError(message)


def load(path: Path) -> dict[str, Any]:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def main(argv: list[str]) -> int:
  if len(argv) != 2:
    print("usage: check_moonrobo_noetix_source_model.py REPORT.json", file=sys.stderr)
    return 2

  report = load(Path(argv[1]))
  require(report["report_id"] == EXPECTED_REPORT_ID, report["report_id"])
  require(report["robot_id"] == "noetix-e1-lab-01", "robot id")
  require(report["source_model_path"].endswith("model/robot.urdf"), "urdf path")
  require(report["source_profile_path"].endswith("robot.json"), "profile path")
  require(report["link_count"] == 25, "link count")
  require(report["joint_count"] == 24, "joint count")
  require(report["joint_limit_count"] == 24, "joint limits")
  require(len(report["joint_limits"]) == 24, "joint limit array")
  require(report["visual_geometry_count"] == 6, "visual geometry count")
  require(report["mesh_asset_count"] == 1, "mesh asset count")
  require(report["collision_tag_count"] == 0, "collision tags should be absent")
  require(report["inertial_tag_count"] == 0, "inertial tags should be absent")
  require(report["missing_collision_link_count"] == 25, "missing collision links")
  require(report["missing_inertial_link_count"] == 25, "missing inertial links")
  require(report["source_metadata_blocker_count"] == 50, "metadata blockers")
  blocker_ids = report.get("source_metadata_blocker_ids")
  require(isinstance(blocker_ids, list), "metadata blocker ids must be listed")
  require(len(blocker_ids) == report["source_metadata_blocker_count"], "metadata blocker id count")
  inventory = report["source_metadata_inventory"]
  require(inventory["model_id"] == "noetix-e1-source-model", "inventory model id")
  require(inventory["link_count"] == 25, "inventory link count")
  require(inventory["collision_shape_link_count"] == 0, "inventory collision links")
  require(inventory["inertial_link_count"] == 0, "inventory inertial links")
  require(inventory["blocker_count"] == 50, "inventory blocker count")
  require(inventory.get("blocker_ids") == blocker_ids, "inventory blocker ids")
  require(not inventory["ready"], "inventory must not be ready")
  require(inventory["status"] == "model-metadata-blocked", "inventory status")
  require(
    len(inventory["missing_collision_shape_links"]) == 25,
    "inventory missing collision link array",
  )
  require(
    len(inventory["missing_inertial_links"]) == 25,
    "inventory missing inertial link array",
  )
  require(len(report["missing_collision_links"]) == 25, "missing collision link array")
  require(len(report["missing_inertial_links"]) == 25, "missing inertial link array")
  require("left_foot" in report["missing_collision_links"], "left foot collision blocker")
  require("right_foot" in report["missing_inertial_links"], "right foot inertial blocker")
  require("missing-collision-shape:left_foot" in blocker_ids, "left foot collision blocker id")
  require("missing-inertial:right_foot" in blocker_ids, "right foot inertial blocker id")
  gaps = report.get("source_metadata_gaps")
  require(isinstance(gaps, list), "source metadata gap inventory must be listed")
  require(len(gaps) == report["source_metadata_blocker_count"], "source metadata gap count")
  gaps_by_id = {gap.get("blocker_id"): gap for gap in gaps}
  for blocker_id in blocker_ids:
    require(blocker_id in gaps_by_id, f"missing source metadata gap {blocker_id}")
  left_collision_gap = gaps_by_id["missing-collision-shape:left_foot"]
  require(left_collision_gap["link_name"] == "left_foot", "left foot collision gap link")
  require(left_collision_gap["metadata_kind"] == "collision-shape", "left foot collision gap kind")
  require(left_collision_gap["current_status"] == "missing", "left foot collision gap status")
  require(left_collision_gap["source_path"] == report["source_model_path"], "collision gap source path")
  require("URDF <collision>" in left_collision_gap["required_evidence"], "collision gap evidence")
  require("noetix_source_model" in left_collision_gap["target_artifact_path"], "collision gap target")
  require("check_moonrobo_noetix_source_model" in left_collision_gap["acceptance_check"], "collision gap check")
  require("source collision metadata" in left_collision_gap["next_action"], "collision gap next action")
  right_inertial_gap = gaps_by_id["missing-inertial:right_foot"]
  require(right_inertial_gap["link_name"] == "right_foot", "right foot inertial gap link")
  require(right_inertial_gap["metadata_kind"] == "inertial", "right foot inertial gap kind")
  require(right_inertial_gap["current_status"] == "missing", "right foot inertial gap status")
  require(right_inertial_gap["source_path"] == report["source_model_path"], "inertial gap source path")
  require("URDF <inertial>" in right_inertial_gap["required_evidence"], "inertial gap evidence")
  require("source inertial metadata" in right_inertial_gap["next_action"], "inertial gap next action")
  require(report["status"] == "source-model-metadata-blocked", "metadata blocker status")
  require(not report["low_level_joint_control_enabled"], "low control must remain disabled")
  require(report["high_level_walk_requires_approval"], "walk must require approval")
  require(
    report["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority",
  )
  require("no authoritative collision or inertial tags" in report["note"], "note")

  visuals = {item["link_name"]: item for item in report["visual_geometries"]}
  require(set(visuals) == {
    "base_link",
    "torso_link",
    "chest_link",
    "left_arm_1",
    "right_arm_1",
    "left_leg_1",
  }, f"unexpected visuals: {sorted(visuals)}")
  require(visuals["base_link"]["kind"] == "SourceMeshGeometry", "base mesh")
  require(visuals["base_link"]["mesh_path"].endswith("base.obj"), "base mesh path")
  require(visuals["base_link"]["size_m"] == {"x": 0.24, "y": 0.2, "z": 0.04}, "base mesh bounds")
  require(visuals["base_link"]["origin_xyz_m"] == {"x": 0, "y": 0, "z": 0}, "base mesh origin")
  require(visuals["chest_link"]["kind"] == "SourceBoxGeometry", "chest box")
  require(visuals["chest_link"]["origin_xyz_m"] == {"x": 0, "y": 0, "z": 0.08}, "chest origin")
  require(visuals["left_leg_1"]["kind"] == "SourceCylinderGeometry", "leg cylinder")
  require(visuals["left_leg_1"]["radius_m"] == 0.045, "leg cylinder radius")
  require(visuals["left_leg_1"]["length_m"] == 0.14, "leg cylinder length")

  limits = {item["joint_name"]: item for item in report["joint_limits"]}
  require(len(limits) == 24, f"unexpected joint limits: {sorted(limits)}")
  require(limits["leg_l4_joint"]["joint_index"] == 8, "leg_l4 index")
  require(limits["leg_l4_joint"]["effort_nm"] == 100, "leg_l4 effort")
  require(limits["leg_l4_joint"]["velocity_rad_s"] == 3, "leg_l4 velocity")
  require(limits["waist_2_joint"]["lower_rad"] == -0.5, "waist_2 lower")
  require(limits["waist_2_joint"]["upper_rad"] == 0.5, "waist_2 upper")
  require(limits["waist_2_joint"]["velocity_rad_s"] == 2, "waist_2 velocity")
  require(
    all(item["source_status"] == "urdf-limit-tag" for item in limits.values()),
    "joint limit source status",
  )
  return 0


if __name__ == "__main__":
  raise SystemExit(main(sys.argv))
