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


def parse_vec3(
  text: str | None,
  context: str,
  default: tuple[float, float, float] | None = None,
) -> tuple[float, float, float]:
  if text is None:
    if default is not None:
      return default
    fail(f"missing vector for {context}")
  parts = text.split()
  if len(parts) != 3:
    fail(f"expected 3-vector for {context}: {text!r}")
  return (float(parts[0]), float(parts[1]), float(parts[2]))


def report_vec3(value: dict[str, Any]) -> tuple[float, float, float]:
  return (
    float(value.get("x", 0.0)),
    float(value.get("y", 0.0)),
    float(value.get("z", 0.0)),
  )


def close_vec3(
  actual: tuple[float, float, float],
  expected: tuple[float, float, float],
) -> bool:
  return all(close(a, e) for a, e in zip(actual, expected))


def scaled_mesh_bounds(
  path: Path,
  scale: tuple[float, float, float],
) -> tuple[float, float, float]:
  vertices: list[tuple[float, float, float]] = []
  with path.open("r", encoding="utf-8") as handle:
    for line in handle:
      if not line.startswith("v "):
        continue
      parts = line.split()
      if len(parts) < 4:
        fail(f"malformed OBJ vertex in {path}: {line.strip()!r}")
      vertices.append(
        (
          float(parts[1]) * scale[0],
          float(parts[2]) * scale[1],
          float(parts[3]) * scale[2],
        )
      )
  if not vertices:
    fail(f"mesh has no vertices: {path}")
  xs = [vertex[0] for vertex in vertices]
  ys = [vertex[1] for vertex in vertices]
  zs = [vertex[2] for vertex in vertices]
  return (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))


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
  visuals: dict[str, dict[str, Any]] = {}
  for link in links:
    link_name = link.attrib.get("name", "")
    visual = link.find("visual")
    if visual is None:
      continue
    origin = visual.find("origin")
    origin_xyz = (0.0, 0.0, 0.0)
    if origin is not None:
      origin_xyz = parse_vec3(
        origin.attrib.get("xyz"),
        f"{link_name} visual origin xyz",
      )
      rpy = parse_vec3(
        origin.attrib.get("rpy"),
        f"{link_name} visual origin rpy",
        default=(0.0, 0.0, 0.0),
      )
      if not close_vec3(rpy, (0.0, 0.0, 0.0)):
        fail(f"{link_name} visual rpy is no longer representable by source audit")
    geometry = visual.find("geometry")
    if geometry is None:
      fail(f"{link_name} visual has no geometry")
    mesh = geometry.find("mesh")
    box = geometry.find("box")
    cylinder = geometry.find("cylinder")
    if mesh is not None:
      filename = mesh.attrib.get("filename")
      if filename is None:
        fail(f"{link_name} mesh visual has no filename")
      mesh_path = (path.parent / filename).resolve()
      scale = parse_vec3(
        mesh.attrib.get("scale"),
        f"{link_name} mesh scale",
        default=(1.0, 1.0, 1.0),
      )
      visuals[link_name] = {
        "kind": "SourceMeshGeometry",
        "origin_xyz_m": origin_xyz,
        "mesh_path": mesh_path,
        "size_m": scaled_mesh_bounds(mesh_path, scale),
        "radius_m": 0.0,
        "length_m": 0.0,
      }
    elif box is not None:
      visuals[link_name] = {
        "kind": "SourceBoxGeometry",
        "origin_xyz_m": origin_xyz,
        "mesh_path": None,
        "size_m": parse_vec3(box.attrib.get("size"), f"{link_name} box size"),
        "radius_m": 0.0,
        "length_m": 0.0,
      }
    elif cylinder is not None:
      visuals[link_name] = {
        "kind": "SourceCylinderGeometry",
        "origin_xyz_m": origin_xyz,
        "mesh_path": None,
        "size_m": (0.0, 0.0, 0.0),
        "radius_m": float_attr(cylinder, "radius"),
        "length_m": float_attr(cylinder, "length"),
      }
    else:
      fail(f"{link_name} visual geometry kind is unsupported")
  return {
    "robot_name": robot.attrib.get("name", ""),
    "link_count": len(links),
    "joint_count": len(joints),
    "visual_count": len(robot.findall(".//visual")),
    "visual_links": visual_links,
    "visuals": visuals,
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
  check_visual_geometries(report, facts["visuals"])
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


def check_visual_geometries(
  report: dict[str, Any],
  visuals: dict[str, dict[str, Any]],
) -> None:
  reported_visuals = {
    item.get("link_name"): item
    for item in report.get("visual_geometries", [])
  }
  if set(reported_visuals) != set(visuals):
    fail("URDF visual geometry names drifted")
  for link_name, source_visual in visuals.items():
    reported = reported_visuals[link_name]
    if reported.get("kind") != source_visual["kind"]:
      fail(f"{link_name} visual kind drifted")
    if not close_vec3(
      report_vec3(reported.get("origin_xyz_m", {})),
      source_visual["origin_xyz_m"],
    ):
      fail(f"{link_name} visual origin drifted")
    if not close_vec3(
      report_vec3(reported.get("size_m", {})),
      source_visual["size_m"],
    ):
      fail(f"{link_name} visual size drifted")
    if not close(float(reported.get("radius_m", 0.0)), source_visual["radius_m"]):
      fail(f"{link_name} visual radius drifted")
    if not close(float(reported.get("length_m", 0.0)), source_visual["length_m"]):
      fail(f"{link_name} visual length drifted")
    mesh_path = source_visual["mesh_path"]
    if mesh_path is None:
      if reported.get("mesh_path") != "":
        fail(f"{link_name} should not carry a mesh path")
    else:
      reported_path = (ROOT / reported.get("mesh_path", "")).resolve()
      if reported_path != mesh_path:
        fail(f"{link_name} mesh path drifted")


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
