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
    if first.get("support_assessment", {}).get("support_count") != 1:
        fail("first frame should have one active support foot")
    patches = first.get("contact_patches", [])
    if len(patches) != 2:
        fail("expected per-foot contact patches")
    if not all(patch.get("sample_count") == 5 for patch in patches):
        fail("contact patches should sample center and four sole corners")
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
    if "friction-cone" not in report.get("note", ""):
        fail("report note must mention friction-cone review")


if __name__ == "__main__":
    main()
