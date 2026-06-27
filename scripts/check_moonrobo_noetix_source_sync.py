#!/usr/bin/env python3
"""Check Moonmoon Noetix evidence against the sibling Moonrobo source files."""

from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MOONROBO_ROOT = ROOT.parent / "moonrobo"
ROBOT_JSON = MOONROBO_ROOT / "examples/noetix-e1/robot.json"
ROBOT_URDF = MOONROBO_ROOT / "examples/noetix-e1/model/robot.urdf"


def fail(message: str) -> None:
  print(message, file=sys.stderr)
  raise SystemExit(1)


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def close(actual: float, expected: float) -> bool:
  return abs(actual - expected) <= 1e-9


def float_attr(element: ET.Element, name: str) -> float:
  text = element.attrib.get(name)
  if text is None:
    fail(f"missing {name} on {element.tag}")
  return float(text)


def urdf_facts(path: Path) -> dict[str, Any]:
  tree = ET.parse(path)
  robot = tree.getroot()
  links = robot.findall("link")
  joints = robot.findall("joint")
  limits: dict[str, dict[str, float]] = {}
  for joint in joints:
    name = joint.attrib.get("name", "")
    limit = joint.find("limit")
    if limit is None:
      fail(f"joint {name} has no limit tag")
    limits[name] = {
      "lower_rad": float_attr(limit, "lower"),
      "upper_rad": float_attr(limit, "upper"),
      "effort_nm": float_attr(limit, "effort"),
      "velocity_rad_s": float_attr(limit, "velocity"),
    }
  visual_links = {
    link.attrib.get("name", "")
    for link in links
    if link.find("visual") is not None
  }
  return {
    "robot_name": robot.attrib.get("name", ""),
    "link_count": len(links),
    "joint_count": len(joints),
    "visual_count": len(robot.findall(".//visual")),
    "visual_links": visual_links,
    "collision_count": len(robot.findall(".//collision")),
    "inertial_count": len(robot.findall(".//inertial")),
    "limits": limits,
  }


def check_robot_profile(profile: dict[str, Any], report: dict[str, Any]) -> None:
  if profile.get("id") != report.get("robot_id"):
    fail("robot.json id does not match source-model report robot_id")
  if profile.get("model", {}).get("primary") != "model/robot.urdf":
    fail("robot.json primary model changed")
  if report.get("source_profile_path") != "../moonrobo/examples/noetix-e1/robot.json":
    fail("source profile path no longer points at sibling robot.json")
  if report.get("source_model_path") != (
    "../moonrobo/examples/noetix-e1/model/robot.urdf"
  ):
    fail("source model path no longer points at sibling URDF")
  if len(profile.get("joints", [])) != report.get("joint_count"):
    fail("robot.json joint count does not match source-model report")
  report_limits = {
    item.get("joint_name"): item
    for item in report.get("joint_limits", [])
  }
  for joint in profile.get("joints", []):
    name = joint.get("name")
    if name not in report_limits:
      fail(f"robot.json joint {name} missing from source-model report")
    if joint.get("index") != report_limits[name].get("joint_index"):
      fail(f"robot.json joint {name} index drifted")
  walk_capability = next(
    (
      item
      for item in profile.get("capabilities", [])
      if item.get("id") == "control.high.walk"
    ),
    None,
  )
  if walk_capability is None:
    fail("robot.json no longer exposes control.high.walk")
  if walk_capability.get("command_class") != "HighControl":
    fail("control.high.walk command class changed")
  if not walk_capability.get("requires_approval"):
    fail("control.high.walk must require approval")
  if not walk_capability.get("requires_dry_run"):
    fail("control.high.walk must require dry run")
  low_control = next(
    (
      item
      for item in profile.get("capabilities", [])
      if item.get("id") == "control.low.joint-position"
    ),
    None,
  )
  if low_control is None or low_control.get("enabled"):
    fail("low-level joint position control must remain disabled")


def check_urdf(report: dict[str, Any], facts: dict[str, Any]) -> None:
  if facts["robot_name"] != "noetix_e1_lab_01":
    fail("unexpected URDF robot name")
  if report.get("link_count") != facts["link_count"]:
    fail("URDF link count does not match source-model report")
  if report.get("joint_count") != facts["joint_count"]:
    fail("URDF joint count does not match source-model report")
  if report.get("joint_limit_count") != len(facts["limits"]):
    fail("URDF joint limit count does not match source-model report")
  if report.get("collision_tag_count") != facts["collision_count"]:
    fail("URDF collision count does not match source-model report")
  if report.get("inertial_tag_count") != facts["inertial_count"]:
    fail("URDF inertial count does not match source-model report")
  if facts["collision_count"] != 0 or facts["inertial_count"] != 0:
    fail("Moonrobo now exposes authoritative collision/inertial tags; promote evidence deliberately")
  visual_names = {
    item.get("link_name")
    for item in report.get("visual_geometries", [])
  }
  if visual_names != facts["visual_links"]:
    fail(
      "visual link set drifted: "
      f"report={sorted(visual_names)} urdf={sorted(facts['visual_links'])}"
    )
  if report.get("visual_geometry_count") != facts["visual_count"]:
    fail("URDF visual count does not match source-model report")
  report_limits = {
    item.get("joint_name"): item
    for item in report.get("joint_limits", [])
  }
  if set(report_limits) != set(facts["limits"]):
    fail("URDF joint limit names drifted")
  for name, source_limit in facts["limits"].items():
    reported = report_limits[name]
    for key in ["lower_rad", "upper_rad", "effort_nm", "velocity_rad_s"]:
      if not close(float(reported.get(key, 0.0)), source_limit[key]):
        fail(f"{name} {key} drifted")


def check_command_plan(
  profile: dict[str, Any],
  report: dict[str, Any],
  plan: dict[str, Any],
) -> None:
  limits = profile.get("limits", {})
  plan_limits = plan.get("high_control_limits", {})
  if plan.get("robot_id") != report.get("robot_id"):
    fail("command plan robot id does not match source-model report")
  if plan_limits.get("source_profile_path") != report.get("source_profile_path"):
    fail("command plan source profile path drifted")
  expected = {
    "max_x_abs_mps": limits.get("high_control_max_x_abs"),
    "max_yaw_abs_rad_s": limits.get("high_control_max_yaw_abs"),
    "max_duration_ms": limits.get("high_control_max_duration_ms"),
    "telemetry_freshness_ms": limits.get("telemetry_freshness_ms"),
    "heartbeat_ms": limits.get("heartbeat_ms"),
    "default_mode": limits.get("default_mode"),
  }
  for key, value in expected.items():
    if isinstance(value, float):
      if not close(float(plan_limits.get(key, 0.0)), value):
        fail(f"command plan {key} drifted from robot.json")
    elif plan_limits.get(key) != value:
      fail(f"command plan {key} drifted from robot.json")


def main(argv: list[str]) -> int:
  if len(argv) != 3:
    print(
      "usage: check_moonrobo_noetix_source_sync.py SOURCE_MODEL_JSON WALK_COMMAND_JSON",
      file=sys.stderr,
    )
    return 2
  if not ROBOT_JSON.exists() or not ROBOT_URDF.exists():
    fail(f"missing sibling Moonrobo Noetix source under {MOONROBO_ROOT}")
  report = load_json(Path(argv[1]))
  plan = load_json(Path(argv[2]))
  profile = load_json(ROBOT_JSON)
  facts = urdf_facts(ROBOT_URDF)
  check_robot_profile(profile, report)
  check_urdf(report, facts)
  check_command_plan(profile, report, plan)
  return 0


if __name__ == "__main__":
  raise SystemExit(main(sys.argv))
