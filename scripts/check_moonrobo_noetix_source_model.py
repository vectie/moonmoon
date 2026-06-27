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
  require(visuals["chest_link"]["kind"] == "SourceBoxGeometry", "chest box")
  require(visuals["left_leg_1"]["kind"] == "SourceCylinderGeometry", "leg cylinder")

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
