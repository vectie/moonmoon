#!/usr/bin/env python3
"""Validate Noetix inertial/collision review evidence."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


EXPECTED_REPORT = (
  "moonrobo/noetix-e1/inertial-collision/"
  "first-trusted-square-northeast-stepout-lola"
)
EXPECTED_TRACE = (
  "moonrobo/noetix-e1/endless-forward-moon-walk/"
  "first-trusted-square-northeast-stepout-lola"
)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise AssertionError(message)


def close(actual: float, expected: float) -> bool:
  return abs(actual - expected) <= 1e-9


def load(path: Path) -> dict[str, Any]:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def main(argv: list[str]) -> int:
  if len(argv) != 2:
    print("usage: check_moonrobo_noetix_inertial_collision.py REPORT.json", file=sys.stderr)
    return 2

  report = load(Path(argv[1]))
  require(report["report_id"] == EXPECTED_REPORT, report["report_id"])
  require(report["trace_id"] == EXPECTED_TRACE, report["trace_id"])
  require(report["profile"]["robot_id"] == "noetix-e1-lab-01", "robot id")
  readiness = report["profile"].get("physical_model_readiness", {})
  require(
    readiness.get("readiness_id")
    == "moonrobo/noetix-e1/physical-model-readiness-v0",
    "physical readiness id",
  )
  require(readiness.get("required_item_count") == 11, "physical required count")
  require(readiness.get("authoritative_item_count") == 2, "physical authoritative count")
  require(readiness.get("assumed_item_count") == 7, "physical assumed count")
  require(readiness.get("missing_item_count") == 2, "physical missing count")
  require(readiness.get("blocker_count") == 9, "physical blocker count")
  require(not readiness.get("ready"), "physical readiness must remain blocked")
  require(
    readiness.get("status") == "physical-model-assumption-review",
    "physical readiness status",
  )
  require("collision-shapes" in readiness.get("assumed_items", []), "assumed collision shapes")
  require("joint-stiffness" in readiness.get("missing_items", []), "missing joint stiffness")
  require(
    report["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority",
  )
  require(report["frame_count"] > 0, "missing frames")
  require(report["shapes_per_frame"] >= 6, "missing collision shapes")
  require(
    "inertial-collision" in report["status"],
    f"unexpected status {report['status']}",
  )
  require("not authoritative" in report["note"], "missing authority note")
  require(
    "Moonphys composite primitive-shape mass properties" in report["note"],
    "missing inertia note",
  )
  require("patch-load contact wrench torque" in report["note"], "missing patch-wrench torque note")
  require("support-wrench motion preview" in report["note"], "missing wrench motion note")
  require(
    "world body-pair contact response" in report["note"],
    "missing world body contact response note",
  )
  require(
    "kinetic-energy accounting" in report["note"],
    "missing wrench energy note",
  )
  require(report["max_support_contact_torque_nm"] > 0, "missing support torque")
  require(report["max_self_penetration_m"] >= 0, "bad self penetration")
  require(
    report["max_self_contact_correction_m"] >= 0,
    "bad self-contact correction",
  )
  require(
    report["max_self_contact_world_correction_m"] > 0,
    "missing self-contact world correction",
  )
  require(
    report["max_self_contact_normal_impulse_ns"] >= 0,
    "bad self-contact normal impulse",
  )
  require(
    report["max_self_contact_friction_impulse_ns"] > 0,
    "missing self-contact friction impulse",
  )
  require("impulse accounting" in report["note"], "missing impulse note")

  frames = report["frames"]
  require(len(frames) == report["frame_count"], "frame count mismatch")
  first = frames[0]
  require(first["shape_count"] == report["shapes_per_frame"], "shape count mismatch")
  require(first["inertia"]["body_id"].endswith("assumed-composite-mass"), "inertia id")
  require(first["inertia"]["diagonal_kg_m2"]["x"] > 0, "inertia x")
  mass_properties = first.get("mass_properties", {})
  require(
    mass_properties.get("status") == "composite-mass-resolved",
    "missing composite mass properties",
  )
  require(
    mass_properties.get("element_count") == first["shape_count"],
    "mass property element count mismatch",
  )
  require(
    close(
      float(mass_properties.get("total_mass_kg", 0.0)),
      float(report["profile"]["mass_model"]["mass_kg"]),
    ),
    "mass property total mass mismatch",
  )
  require(
    mass_properties.get("inertia_about_center") == first["inertia"],
    "frame inertia must come from composite mass properties",
  )
  support_wrenches = first.get("support_contact_wrenches", [])
  require(len(support_wrenches) == 2, "missing per-foot support wrenches")
  require(
    any(
      wrench["status"] == "patch-wrench-resolved"
      and wrench["loaded_sample_count"] > 0
      and wrench["normal_force_n"] > 0
      for wrench in support_wrenches
    ),
    "missing loaded support wrench",
  )
  require(
    all(
      "center_of_pressure" in wrench
      and "total_force_n" in wrench
      and "total_torque_nm" in wrench
      for wrench in support_wrenches
    ),
    "incomplete support wrench evidence",
  )
  motion_step = first.get("support_wrench_motion_step", {})
  require(motion_step.get("status") == "wrench-integrated", "missing support wrench motion step")
  require(
    motion_step.get("wrench", {}).get("force_n", {}).get("z", 0) > 0,
    "support wrench motion force missing",
  )
  require(
    motion_step.get("angular_acceleration_rad_s2", {}).get("x", 0) != 0
    or motion_step.get("angular_acceleration_rad_s2", {}).get("y", 0) != 0
    or motion_step.get("angular_acceleration_rad_s2", {}).get("z", 0) != 0,
    "support wrench angular acceleration missing",
  )
  require(
    motion_step.get("linear_impulse_ns", {}).get("z", 0) > 0,
    "support wrench linear impulse missing",
  )
  require(
    motion_step.get("angular_impulse_nms", {}).get("x", 0) != 0
    or motion_step.get("angular_impulse_nms", {}).get("y", 0) != 0
    or motion_step.get("angular_impulse_nms", {}).get("z", 0) != 0,
    "support wrench angular impulse missing",
  )
  require(
    motion_step.get("kinetic_energy_after_j", 0)
    > motion_step.get("kinetic_energy_before_j", 0),
    "support wrench kinetic energy did not increase",
  )
  require(
    motion_step.get("kinetic_energy_delta_j", 0) > 0,
    "support wrench kinetic energy delta missing",
  )
  require(len(first["terrain_collisions"]) == 2, "terrain foot probes")
  require(
    all(
      item["status"] == "terrain-collision-matches-walk-contact"
      for item in first["terrain_collisions"]
    ),
    "terrain contact mismatch",
  )
  require(
    any(
      shape["link_name"] == "chest_link"
      and shape["bounds"]["status"] == "conservative-bounds"
      for shape in first["shapes"]
    ),
    "missing chest collision bounds",
  )
  require(
    any(
      shape["link_name"] == "left_foot"
      and shape["shape"]["kind"] == "BoxShape"
      for shape in first["shapes"]
    ),
    "missing foot collision shape",
  )
  require(
    first["self_contact_manifold"]["contacts"],
    "missing self-contact contact set",
  )
  contact_statuses = {
    contact["status"]
    for frame in frames
    for contact in frame["self_contact_manifold"]["contacts"]
  }
  require(
    "conservative-contact" not in contact_statuses
    and "conservative-clear" not in contact_statuses,
    "self-contact manifold fell back to conservative pair statuses",
  )
  require(
    "box-capsule-contact" in contact_statuses
    or "capsule-box-contact" in contact_statuses,
    "missing narrow-phase box/capsule contact",
  )
  require(
    "box-box-clear" in contact_statuses,
    "missing narrow-phase box/box clear evidence",
  )
  require(
    first["self_contact_resolution"]["manifold_id"]
    == first["self_contact_manifold"]["manifold_id"],
    "self-contact resolution does not reference frame manifold",
  )
  require(
    first["self_contact_resolution"]["contact_count"]
    == first["self_contact_manifold"]["contact_count"],
    "self-contact resolution count mismatch",
  )
  require(
    first["self_contact_resolution"]["material"]["material_id"]
    == "lunar-regolith-review-model",
    "missing regolith material resolution",
  )
  require(
    first["self_contact_resolution"]["average_normal"],
    "missing average contact normal",
  )
  require(
    first["self_contact_resolution"]["velocity_delta"],
    "missing self-contact velocity delta",
  )
  require(
    first["self_contact_resolution"]["status"]
    in {"single-contact-resolved", "multi-contact-resolved", "no-contact"},
    "bad self-contact resolution status",
  )
  world_resolution = first.get("self_contact_world_response", {})
  require(
    world_resolution.get("status") == "world-contact-resolved",
    "missing self-contact world response",
  )
  require(
    world_resolution.get("contact_count", 0)
    == world_resolution.get("resolved_contact_count", -1),
    "self-contact world response count mismatch",
  )
  require(
    first.get("self_contact_world_correction_m", 0) > 0,
    "missing frame self-contact world correction",
  )
  require(
    any(
      pair.get("status") == "world-pair-resolved"
      and (
        pair.get("correction_a_m", 0) > 0
        or pair.get("correction_b_m", 0) > 0
      )
      for pair in world_resolution.get("resolved_pairs", [])
    ),
    "missing resolved world-pair correction",
  )
  require(
    any(
      frame["self_contact_resolution"]["status"] == "multi-contact-resolved"
      and frame["self_contact_correction_m"] > 0
      and frame["self_contact_resolution"]["friction_impulse_ns"] > 0
      for frame in frames
    ),
    "missing resolved multi-contact impulse frame",
  )
  require(
    report["self_contact_frame_count"] >= 0
    and report["terrain_review_frame_count"] >= 0,
    "bad review counts",
  )
  return 0


if __name__ == "__main__":
  raise SystemExit(main(sys.argv))
