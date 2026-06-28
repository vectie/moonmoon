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
    if trace.get("robot_rig_id") != "moonrobo/noetix-e1/urdf-rigid-rig":
        fail("unexpected robot rig id")
    if trace.get("robot_rig_status") != "urdf-rigid-rig-ready":
        fail("robot rig should be ready for current URDF source")
    if trace.get("motion_frame_source") != "planned-gait-joint-samples":
        fail("motion frame source should come from planned robot joint samples")
    if trace.get("rig_motion_contract_status") != "robot-rig-motion-contract-ready":
        fail("rig motion contract should be ready")
    if trace.get("primary_render_source") != "robot-rig-visual-instances":
        fail("primary render source should be robot rig visual instances")
    if trace.get("links_per_frame") != 25:
        fail("expected 25 URDF-reference links per frame")
    if trace.get("visual_instances_per_frame") != 6:
        fail("expected six renderable visual instances per frame")
    if trace.get("visual_geometry_link_count") != 6:
        fail("expected six URDF visual geometry links")
    if trace.get("mesh_visual_geometry_link_count") != 1:
        fail("expected one mesh visual geometry link")
    if trace.get("primitive_visual_geometry_link_count") != 5:
        fail("expected five primitive visual geometry links")
    if trace.get("rig_render_contract_status") != "urdf-rigid-visual-contract-ready":
        fail("rig render contract should be ready for current URDF visuals")
    if trace.get("collision_metadata_link_count") != 0:
        fail("link pose trace should not claim authoritative collision metadata")
    if trace.get("inertial_metadata_link_count") != 0:
        fail("link pose trace should not claim authoritative inertial metadata")
    if trace.get("missing_collision_link_count") != 25:
        fail("link pose trace should preserve missing collision link count")
    if trace.get("missing_inertial_link_count") != 25:
        fail("link pose trace should preserve missing inertial link count")
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
    if "missing collision/inertial metadata" not in trace.get("note", ""):
        fail("trace note must preserve missing collision/inertial metadata")
    if "RobotRig plus RobotMotionFrame" not in trace.get("note", ""):
        fail("trace note must name the robot rig and motion frame contract")
    if "RobotRig visual instances" not in trace.get("note", ""):
        fail("trace note must name robot rig visual instances as primary render source")
    if "Debug sticks are only a link-tree overlay" not in trace.get("note", ""):
        fail("trace note must keep sticks as debug overlay only")
    physical_metadata = {
        item.get("link_name"): item for item in trace.get("physical_metadata", [])
    }
    if len(physical_metadata) != 25:
        fail("trace should carry one physical metadata record per reference link")
    left_physical = physical_metadata.get("left_foot", {})
    if left_physical.get("has_collision_metadata"):
        fail("left foot should not claim collision metadata")
    if left_physical.get("has_inertial_metadata"):
        fail("left foot should not claim inertial metadata")
    if left_physical.get("collision_blocker_id") != "missing-collision-shape:left_foot":
        fail("left foot should name its collision metadata blocker")
    if left_physical.get("inertial_blocker_id") != "missing-inertial:left_foot":
        fail("left foot should name its inertial metadata blocker")
    base_physical = physical_metadata.get("base_link", {})
    if base_physical.get("collision_source_status") != "urdf-collision-metadata-missing":
        fail("base link should preserve missing collision metadata status")
    if base_physical.get("inertial_source_status") != "urdf-inertial-metadata-missing":
        fail("base link should preserve missing inertial metadata status")

    first = by_link(frames[0])
    fifth = by_link(frames[5])
    required = {"base_link", "chest_link", "left_foot", "right_foot", "right_leg_3"}
    if not required.issubset(first):
        fail("first frame is missing required links")
    first_frame = frames[0]
    if first_frame.get("robot_rig_id") != trace.get("robot_rig_id"):
        fail("frame should carry robot rig id")
    if not first_frame.get("motion_id", "").endswith("/0"):
        fail("first frame should carry motion frame id")
    if first_frame.get("rig_pose_status") != "robot-rig-pose-ready":
        fail("first frame should be produced by ready rig pose sampling")
    if first_frame.get("rig_render_status") != "robot-rig-render-frame-ready":
        fail("first frame should carry ready rig render status")
    visual_instances = first_frame.get("visual_instances", [])
    if first_frame.get("visual_instance_count") != 6 or len(visual_instances) != 6:
        fail("first frame should carry six robot rig visual instances")
    visual_by_link = {item.get("link_name"): item for item in visual_instances}
    if set(visual_by_link) != {
        "base_link",
        "torso_link",
        "chest_link",
        "left_arm_1",
        "right_arm_1",
        "left_leg_1",
    }:
        fail("visual instances should mirror current URDF visual links")
    base_instance = visual_by_link.get("base_link", {})
    if base_instance.get("render_kind") != "mesh":
        fail("base visual instance should render as mesh")
    if base_instance.get("mesh_extension") != "obj":
        fail("base visual instance should preserve OBJ extension")
    if base_instance.get("loader_status") != "mesh-loader-obj-ready":
        fail("base visual instance should be OBJ-loader ready")
    if not base_instance.get("mesh_path", "").endswith("base.obj"):
        fail("base visual instance should preserve mesh path")
    if visual_by_link.get("chest_link", {}).get("render_kind") != "box":
        fail("chest visual instance should render as box")
    if visual_by_link.get("left_arm_1", {}).get("render_kind") != "cylinder":
        fail("left arm visual instance should render as cylinder")
    if any(
        item.get("loader_status") != "primitive-renderer-ready"
        for item in visual_instances
        if item.get("render_kind") != "mesh"
    ):
        fail("primitive visual instances should be primitive-renderer ready")
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
    if first["base_link"]["visual_geometry"].get("source_status", "").startswith("urdf-visual-mesh") is False:
        fail("base link mesh should preserve source mesh status")
    if first["chest_link"]["visual_geometry"].get("kind") != "SourceBoxGeometry":
        fail("chest link visual geometry should come from URDF box")
    if first["chest_link"]["visual_geometry"]["world_origin_xyz_m"]["z"] <= first["chest_link"]["world_position"]["z"]:
        fail("chest visual origin should be transformed above link joint origin")
    if first["left_arm_1"]["visual_geometry"].get("kind") != "SourceCylinderGeometry":
        fail("left_arm_1 visual geometry should come from URDF cylinder")
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
