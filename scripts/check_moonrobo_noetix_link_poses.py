#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def by_link(frame: dict) -> dict[str, dict]:
    return {link["link_name"]: link for link in frame.get("links", [])}


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_link_poses.py TRACE_JSON")

    path = Path(sys.argv[1])
    trace = json.loads(path.read_text())
    frames = trace.get("frames", [])
    if trace.get("trace_id") != (
        "moonrobo/noetix-e1/link-poses/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected trace_id")
    if not trace.get("source_walk_trace_id", "").startswith(
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
    ):
        fail("unexpected source walk trace")
    if trace.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if trace.get("links_per_frame") != 25:
        fail("expected 25 URDF-reference links per frame")
    if trace.get("frame_count") != len(frames) or len(frames) < 24:
        fail("frame count is inconsistent or too small")
    if trace.get("status") != "review-only":
        fail("link pose trace must remain review-only")
    if "hardware authority" not in trace.get("note", ""):
        fail("trace must explicitly avoid hardware authority")
    if "Moonphys evaluates the generic articulated pose tree" not in trace.get(
        "note", ""
    ):
        fail("trace note must preserve Moonphys articulated-tree provenance")

    first = by_link(frames[0])
    fifth = by_link(frames[5])
    required = {"base_link", "chest_link", "left_foot", "right_foot", "right_leg_3"}
    if not required.issubset(first):
        fail("first frame is missing required links")
    if first["left_foot"].get("source_status") != "urdf-fk-contact-bound":
        fail("left foot must be bound to contact evidence")
    if first["left_foot"].get("visual_geometry", {}).get("source_status") != "urdf-visual-geometry-missing":
        fail("left foot should record missing visual geometry")
    if first["right_foot"].get("source_status") != "urdf-fk-contact-bound":
        fail("right foot must be bound to contact evidence")
    if first["left_foot"].get("joint_name") != "leg_l6_joint":
        fail("left foot joint name should come from URDF")
    if first["right_foot"].get("joint_name") != "leg_r6_joint":
        fail("right foot joint name should come from URDF")
    if first["left_foot"].get("joint_axis") != {"x": 0, "y": 1, "z": 0}:
        fail("left foot joint axis should come from URDF")
    if first["left_foot"].get("contact_error_m", -1) < 0:
        fail("contact-bound foot should report FK contact error")
    if not any(link.get("role") == "foot" and link.get("contact_error_m", 0) > 0 for link in first.values()):
        fail("at least one contact-bound foot should report FK correction")
    if "pitch_proxy_rad" in first["right_leg_3"]:
        fail("link pose schema should not expose stale proxy angles")
    if not first["chest_link"]["world_position"]["z"] > first["base_link"]["world_position"]["z"]:
        fail("chest link should sit above base link")
    if not first["base_link"].get("visual_geometry", {}).get("has_visual_geometry"):
        fail("base link should carry visual geometry")
    if first["base_link"]["visual_geometry"].get("kind") != "SourceMeshGeometry":
        fail("base link visual geometry should come from mesh")
    if not first["base_link"]["visual_geometry"].get("mesh_path", "").endswith("base.obj"):
        fail("base link mesh path should be preserved")
    if first["chest_link"]["visual_geometry"].get("kind") != "SourceBoxGeometry":
        fail("chest link visual geometry should come from URDF box")
    if first["chest_link"]["visual_geometry"]["world_origin_xyz_m"]["z"] <= first["chest_link"]["world_position"]["z"]:
        fail("chest visual origin should be transformed above link joint origin")
    if fifth["right_leg_3"]["fk_world_position"]["x"] == first["right_leg_3"]["fk_world_position"]["x"]:
        fail("right leg FK should move during swing")
    if fifth["right_arm_1"]["world_position"]["x"] == first["right_arm_1"]["world_position"]["x"]:
        fail("right arm FK should move during gait")
    if not any(
        link.get("source_status") == "urdf-forward-kinematics"
        for link in first.values()
    ):
        fail("expected non-foot URDF forward-kinematics links")
    if "forward-kinematics" not in trace.get("note", ""):
        fail("trace note must describe FK evidence")


if __name__ == "__main__":
    main()
