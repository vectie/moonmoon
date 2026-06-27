#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_stability.py REPORT_JSON")

    path = Path(sys.argv[1])
    report = json.loads(path.read_text())
    frames = report.get("frames", [])
    profile = report.get("profile", {})
    mass_model = profile.get("mass_model", {})
    foot_geometry = profile.get("foot_geometry", [])
    actuator_profiles = profile.get("actuator_profiles", [])
    collision_shapes = profile.get("collision_shapes", [])

    if report.get("report_id") != (
        "moonrobo/noetix-e1/static-support/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected report_id")
    if not report.get("trace_id", "").startswith(
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
    ):
        fail("unexpected trace_id")
    if profile.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if profile.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("hardware authority must remain denied")
    readiness = profile.get("physical_model_readiness", {})
    if readiness.get("readiness_id") != "moonrobo/noetix-e1/physical-model-readiness-v0":
        fail("physical model readiness id must be stable")
    if readiness.get("required_item_count") != 11:
        fail("physical model readiness must enumerate required items")
    if readiness.get("authoritative_item_count") != 2:
        fail("physical model readiness should only trust URDF actuator limits")
    if readiness.get("assumed_item_count") != 7:
        fail("physical model readiness must count assumed items")
    if readiness.get("missing_item_count") != 2:
        fail("physical model readiness must count missing damping/stiffness")
    if readiness.get("blocker_count") != 9:
        fail("physical model readiness blocker count must be explicit")
    blocker_ids = readiness.get("blocker_ids")
    if not isinstance(blocker_ids, list):
        fail("physical model readiness blocker ids must be listed")
    if len(blocker_ids) != readiness.get("blocker_count"):
        fail("physical model readiness blocker count must match listed ids")
    if readiness.get("ready"):
        fail("physical model readiness must remain blocked")
    if readiness.get("status") != "physical-model-assumption-review":
        fail("physical model readiness must expose assumption-review status")
    if "mass" not in readiness.get("assumed_items", []):
        fail("physical model readiness must name assumed mass")
    if "joint-damping" not in readiness.get("missing_items", []):
        fail("physical model readiness must name missing damping")
    if "assumed:mass" not in blocker_ids:
        fail("physical model readiness must name assumed mass blocker")
    if "missing:joint-damping" not in blocker_ids:
        fail("physical model readiness must name missing damping blocker")
    if "simulation-assumption" not in mass_model.get("source_status", ""):
        fail("mass model must be marked as an assumption")
    if mass_model.get("mass_kg", 0) <= 0:
        fail("mass must be positive")
    if len(foot_geometry) != 2:
        fail("expected left and right foot geometry")
    if any("simulation-assumption" not in foot.get("source_status", "") for foot in foot_geometry):
        fail("foot geometry must be marked as an assumption")
    if len(actuator_profiles) != 24:
        fail("expected 24 URDF actuator limit profiles")
    leg_l4 = next((act for act in actuator_profiles if act.get("joint_name") == "leg_l4_joint"), None)
    if not leg_l4:
        fail("missing leg_l4_joint actuator profile")
    leg_l4_limit = leg_l4.get("limit", {})
    if (
        leg_l4.get("joint_index") != 8
        or leg_l4_limit.get("min_position_rad") != -1.8
        or leg_l4_limit.get("max_position_rad") != 1.8
        or leg_l4_limit.get("max_torque_nm") != 100
        or leg_l4_limit.get("max_velocity_rad_s") != 3
    ):
        fail("leg_l4_joint URDF limits were not preserved")
    if "urdf-limit-tag" not in leg_l4.get("source_status", ""):
        fail("actuator profile source must cite URDF limit tags")
    if len(collision_shapes) < 6:
        fail("expected review collision shape profiles")
    if not any(
        shape.get("link_name") == "chest_link"
        and shape.get("shape", {}).get("kind") == "BoxShape"
        and "urdf-visual-box" in shape.get("source_status", "")
        for shape in collision_shapes
    ):
        fail("missing chest visual-box review collision shape")
    if not any(
        shape.get("link_name") == "left_foot"
        and "simulation-assumption" in shape.get("source_status", "")
        for shape in collision_shapes
    ):
        fail("missing assumed left-foot sole collision shape")
    if report.get("frame_count") != len(frames) or len(frames) < 24:
        fail("frame count is inconsistent or too small")
    if report.get("status") != "static-support-review":
        fail("report should remain review-only")
    if report.get("review_frame_count", 0) <= 0:
        fail("expected review frames")
    if report.get("traction_review_frame_count", -1) != 0:
        fail("expected traction to remain within assumed friction margin")
    if report.get("stable_frame_count", -1) + report.get("review_frame_count", -1) != len(frames):
        fail("stable/review counts do not sum to frame count")
    if report.get("worst_planar_margin_m", 0) >= 0:
        fail("expected negative static support margin")
    if report.get("worst_traction_margin_n", -1) < 0:
        fail("expected nonnegative traction margin")
    if not any(frame.get("status") == "static-margin-review" for frame in frames):
        if not any(frame.get("status") == "contact-patch-review" for frame in frames):
            fail("expected static-margin or contact-patch review frame")
    if not any(frame.get("contact_patch_status") == "contact-patch-review" for frame in frames):
        fail("expected contact patch review evidence")
    first = frames[0]
    first_support = first.get("support_assessment", {})
    if first_support.get("support_count") != 1:
        fail("first frame should have one active support foot")
    polygon_vertices = first_support.get("support_polygon_vertices", [])
    if first_support.get("support_polygon_vertex_count", 0) < 3:
        fail("support assessment must expose a convex support polygon")
    if first_support.get("support_polygon_vertex_count") != len(polygon_vertices):
        fail("support polygon vertex count must match vertices")
    support_load = first.get("support_load_assessment", {})
    if support_load.get("load_count") != first_support.get("support_count"):
        fail("support load count must match active support count")
    if support_load.get("total_normal_force_n", 0) <= 0:
        fail("support load assessment must carry lunar normal force")
    if not any(load.get("normal_force_n", 0) > 0 for load in support_load.get("loads", [])):
        fail("support load assessment must identify a loaded contact")
    patches = first.get("contact_patches", [])
    if len(patches) != 2:
        fail("expected per-foot contact patches")
    if not all(patch.get("sample_count") == 5 for patch in patches):
        fail("contact patches should sample center and four sole corners")
    patch_loads = first.get("contact_patch_loads", [])
    if len(patch_loads) != 2:
        fail("expected per-foot contact patch load assessments")
    if not any(load.get("loaded_sample_count", 0) > 0 for load in patch_loads):
        fail("expected at least one loaded contact patch sample")
    if not any(load.get("max_pressure_pa", 0) > 0 for load in patch_loads):
        fail("expected contact patch pressure evidence")
    if not all("average_surface_normal" in patch for patch in patches):
        fail("contact patches must carry averaged terrain normals")
    if not any(
        patch.get("status") in {
            "patch-contact",
            "patch-partial-contact-review",
            "patch-penetration-review",
        }
        for patch in patches
    ):
        fail("contact patches should carry contact/review status")
    if first.get("terrain_contact_status") != "terrain-contact-review":
        fail("terrain contact review must carry through")
    traction = first.get("traction_assessments", [])
    if len(traction) != 2:
        fail("expected per-foot traction assessments")
    if first.get("traction_status") != "traction-ok":
        fail("first frame should keep traction margin")
    if not any(
        item.get("status") == "traction-ok"
        and item.get("normal_force_n", 0) > 0
        and item.get("friction_limit_n", 0) > item.get("tangential_force_n", 0)
        and item.get("margin_n", 0) > 0
        for item in traction
    ):
        fail("missing active support traction margin")
    if not all(
        item.get("material", {}).get("material_id", "").endswith("review-friction")
        for item in traction
    ):
        fail("traction material must cite review foot friction")
    if "dynamic walking can be valid" not in report.get("note", ""):
        fail("report note must distinguish static evidence from dynamics")
    if "Contact patches use Moonphys heightfield patch sampling" not in report.get("note", ""):
        fail("report note must mention Moonphys contact-patch evidence")
    if "patch-load pressure review" not in report.get("note", ""):
        fail("report note must mention Moonphys patch-load pressure review")
    if "terrain-normal force projection" not in report.get("note", ""):
        fail("report note must mention Moonphys terrain-normal traction projection")
    if "friction-cone" not in report.get("note", ""):
        fail("report note must mention friction-cone review")


if __name__ == "__main__":
    main()
