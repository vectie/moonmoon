#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_control.py REPORT_JSON")

    report = json.loads(Path(sys.argv[1]).read_text())
    frames = report.get("frames", [])
    profile = report.get("profile", {})

    if report.get("report_id") != (
        "moonrobo/noetix-e1/joint-control/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected report_id")
    if not report.get("trace_id", "").startswith(
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
    ):
        fail("unexpected trace_id")
    if profile.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if report.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("hardware authority must remain denied")
    if report.get("frame_count") != len(frames) or len(frames) < 24:
        fail("frame count is inconsistent or too small")
    if report.get("joint_count_per_frame") != 24:
        fail("expected 24 controlled joints per frame")
    if "review" not in report.get("status", ""):
        fail("control report must remain review evidence")
    if report.get("status") != "joint-control-assumption-review":
        fail("control report should remain assumption review after velocity shaping")
    if report.get("saturated_frame_count") != 0:
        fail("planted-foot gait should not saturate joint control")
    if report.get("limit_review_frame_count") != 0:
        fail("velocity-limited gait should not have limit-review frames")
    if "servo gains" not in report.get("note", ""):
        fail("report note must mention assumed servo gains")
    if "velocity-limited joint command shaping" not in report.get("note", ""):
        fail("report note must mention Moonphys velocity-limited command shaping")
    if "joint-frame motor integration" not in report.get("note", ""):
        fail("report note must mention Moonphys joint-frame replay")
    if "hinge-joint frame assessment" not in report.get("note", ""):
        fail("report note must mention Moonphys hinge-frame assessment")
    if "world hinge constraint replay" not in report.get("note", ""):
        fail("report note must mention Moonphys world hinge replay")
    if "world hinge motor replay" not in report.get("note", ""):
        fail("report note must mention Moonphys world hinge motor replay")
    if "sequential world hinge motor trace" not in report.get("note", ""):
        fail("report note must mention Moonphys sequential hinge motor trace")
    if "target-driven hinge motor heightfield world replay" not in report.get(
        "note", ""
    ):
        fail("report note must mention Moonphys target-driven heightfield replay")
    if report.get("hinge_joint_frame_count") != len(frames):
        fail("hinge joint frame count must match report frames")
    if report.get("hinge_joint_count_per_frame") != 24:
        fail("expected 24 hinge joints per frame")
    if report.get("hinge_motor_driven_frame_count") != len(frames):
        fail("all frames should drive matching Moonphys world hinge motors")
    if report.get("hinge_motor_driven_joint_count", 0) <= 0:
        fail("hinge motor driven joint count must be present")
    hinge_motor_trace = report.get("hinge_motor_trace", {})
    if hinge_motor_trace.get("frame_count") != len(frames):
        fail("hinge motor trace must replay every report frame")
    if hinge_motor_trace.get("driven_joint_count") != report.get(
        "hinge_motor_driven_joint_count"
    ):
        fail("hinge motor trace driven count must match frame summary")
    if hinge_motor_trace.get("final_projected_body_count") != 25:
        fail("hinge motor trace should preserve all projected Noetix bodies")
    if "world-hinge-motor-trace" not in hinge_motor_trace.get("status", ""):
        fail("hinge motor trace must expose Moonphys trace status")
    hinge_motor_world_trace = report.get("hinge_motor_world_trace", {})
    if hinge_motor_world_trace.get("frame_count") != len(frames):
        fail("hinge motor world trace must replay every report frame")
    if hinge_motor_world_trace.get("motor_frame_count") != len(frames):
        fail("hinge motor world trace must consume every motor frame")
    if hinge_motor_world_trace.get("body_target_frame_count") != len(frames):
        fail("hinge motor world trace must consume every body-target frame")
    if hinge_motor_world_trace.get("body_target_count") != 25 * len(frames):
        fail("hinge motor world trace must target every Noetix body per frame")
    if hinge_motor_world_trace.get("support_target_frame_count") != len(frames):
        fail("hinge motor world trace must consume every support-target frame")
    if hinge_motor_world_trace.get("support_target_count", 0) <= 0:
        fail("hinge motor world trace must expose active support targets")
    if hinge_motor_world_trace.get("center_of_mass_target_frame_count") != len(frames):
        fail("hinge motor world trace must consume every COM-target frame")
    if hinge_motor_world_trace.get("driven_joint_count") != report.get(
        "hinge_motor_driven_joint_count"
    ):
        fail("hinge motor world trace driven count must match frame summary")
    if hinge_motor_world_trace.get("contact_count", 0) <= 0:
        fail("hinge motor world trace must include heightfield contacts")
    if hinge_motor_world_trace.get("support_contact_count", 0) <= 0:
        fail("hinge motor world trace must include support contacts")
    if hinge_motor_world_trace.get("stable_support_frame_count", -1) < 0:
        fail("hinge motor world trace must expose stable support frames")
    if hinge_motor_world_trace.get("support_review_frame_count", -1) < 0:
        fail("hinge motor world trace must expose support review frames")
    if hinge_motor_world_trace.get("stable_support_frame_count") != len(frames):
        fail("hinge motor world trace should clear static support review")
    if hinge_motor_world_trace.get("support_review_frame_count") != 0:
        fail("hinge motor world trace should have no static support review frames")
    if (
        hinge_motor_world_trace.get("capture_stable_support_frame_count", -1)
        + hinge_motor_world_trace.get("capture_support_review_frame_count", -1)
        != hinge_motor_world_trace.get("frame_count")
    ):
        fail("hinge motor world trace capture support frames must cover the replay")
    if hinge_motor_world_trace.get("capture_stable_support_frame_count") != 30:
        fail("hinge motor world trace should preserve 30 capture-stable frames")
    if hinge_motor_world_trace.get("capture_support_review_frame_count") != 2:
        fail("hinge motor world trace should expose two capture review frames")
    if hinge_motor_world_trace.get("resolved_hinge_constraint_count", 0) <= (
        report.get("hinge_motor_driven_joint_count", 0)
    ):
        fail("hinge motor world trace should resolve hinge constraints across steps")
    if hinge_motor_world_trace.get("final_body_count") != 25:
        fail("hinge motor world trace should preserve all world bodies")
    if hinge_motor_world_trace.get("final_projected_body_count") != 25:
        fail("hinge motor world trace should preserve all projected Noetix bodies")
    if hinge_motor_world_trace.get("body_sample_count") != 25 * (len(frames) + 1):
        fail("hinge motor world trace envelope should sample each body per world")
    bounds_min = hinge_motor_world_trace.get("min_position", {})
    bounds_max = hinge_motor_world_trace.get("max_position", {})
    if bounds_max.get("x", 0) <= bounds_min.get("x", 0):
        fail("hinge motor world trace envelope should expose x motion bounds")
    if bounds_max.get("z", 0) < bounds_min.get("z", 0):
        fail("hinge motor world trace envelope should expose valid z bounds")
    if hinge_motor_world_trace.get("max_speed_mps", -1) < 0:
        fail("hinge motor world trace envelope should expose max speed")
    if hinge_motor_world_trace.get("max_kinetic_energy_j", -1) < 0:
        fail("hinge motor world trace envelope should expose max kinetic energy")
    if hinge_motor_world_trace.get("total_mass_kg", 0) <= 0:
        fail("hinge motor world trace envelope should expose total mass")
    initial_com = hinge_motor_world_trace.get("initial_center_of_mass", {})
    final_com = hinge_motor_world_trace.get("final_center_of_mass", {})
    min_com = hinge_motor_world_trace.get("min_center_of_mass", {})
    max_com = hinge_motor_world_trace.get("max_center_of_mass", {})
    if final_com.get("x", 0) < initial_com.get("x", 0):
        fail("hinge motor world trace center of mass should not move backward")
    if max_com.get("z", 0) < min_com.get("z", 0):
        fail("hinge motor world trace center-of-mass bounds should be valid")
    if hinge_motor_world_trace.get("max_center_of_mass_speed_mps", -1) < 0:
        fail("hinge motor world trace envelope should expose COM speed")
    if "min_support_margin_m" not in hinge_motor_world_trace:
        fail("hinge motor world trace should expose support margin")
    if hinge_motor_world_trace.get("max_support_recovery_shift_m", -1) < 0:
        fail("hinge motor world trace should expose support recovery shift")
    if "worst_capture_support_margin_m" not in hinge_motor_world_trace:
        fail("hinge motor world trace should expose capture support margin")
    if hinge_motor_world_trace.get("max_capture_recovery_shift_m", -1) < 0:
        fail("hinge motor world trace should expose capture recovery shift")
    if hinge_motor_world_trace.get("max_center_of_pressure_error_m", -1) < 0:
        fail("hinge motor world trace should expose center-of-pressure error")
    if hinge_motor_world_trace.get("max_body_linear_momentum_kg_mps", -1) < 0:
        fail("hinge motor world trace envelope should expose max body momentum")
    if hinge_motor_world_trace.get("max_world_linear_momentum_kg_mps", -1) < 0:
        fail("hinge motor world trace envelope should expose max world momentum")
    if hinge_motor_world_trace.get("max_frame_kinetic_energy_delta_j", -1) < 0:
        fail("hinge motor world trace envelope should expose max energy delta")
    if "world-trace-envelope" not in hinge_motor_world_trace.get(
        "envelope_status", ""
    ):
        fail("hinge motor world trace should expose envelope status")
    if hinge_motor_world_trace.get("envelope_status") != "world-trace-envelope-bounded":
        fail("velocity-shaped replay should have a bounded world envelope")
    if "world-replay-review" not in hinge_motor_world_trace.get(
        "world_review_status", ""
    ):
        fail("hinge motor world trace should expose Moonphys world review status")
    if hinge_motor_world_trace.get("world_review_ready"):
        fail("hinge motor world trace review should remain blocked")
    blockers = hinge_motor_world_trace.get("world_review_blockers", [])
    if hinge_motor_world_trace.get("world_review_blocker_count", 0) != len(blockers):
        fail("hinge motor world trace blocker count must match blocker list")
    if blockers != ["world-dynamic-support-review"]:
        fail("hinge motor world trace should carry only dynamic support blocker")
    if "world-envelope-review" in blockers:
        fail("velocity-shaped replay should not expose envelope blocker")
    if "world-support-review" in blockers:
        fail("hinge motor world trace should clear support blocker")
    if "world-dynamic-support-review" not in blockers:
        fail("hinge motor world trace must expose dynamic support blocker")
    if "world-heightfield-hinge-motor-trace" not in hinge_motor_world_trace.get(
        "status", ""
    ):
        fail("hinge motor world trace must expose Moonphys heightfield trace status")
    if report.get("hinge_review_frame_count", -1) < 0:
        fail("hinge review frame count must be present")
    if report.get("max_hinge_position_error_m", -1) < 0:
        fail("max hinge position error must be present")
    if report.get("max_hinge_angular_error_rad", -1) < 0:
        fail("max hinge angular error must be present")
    if report.get("max_hinge_motor_angle_delta_rad", -1) < 0:
        fail("max hinge motor angle delta must be present")
    if report.get("max_hinge_motor_velocity_delta_rad_s", -1) < 0:
        fail("max hinge motor velocity delta must be present")
    if report.get("hinge_linear_impulse_ns", -1) < 0:
        fail("hinge linear impulse must be present")
    if report.get("hinge_angular_impulse_nms", -1) < 0:
        fail("hinge angular impulse must be present")
    if report.get("max_abs_velocity_rad_s", -1) > 3:
        fail("max velocity must respect Noetix URDF velocity limits")
    if report.get("max_abs_mechanical_power_w", 0) <= 0:
        fail("max mechanical power must be present")
    if report.get("total_absolute_work_j", 0) <= 0:
        fail("absolute joint work must be present")
    if "net_work_j" not in report:
        fail("net joint work must be present")

    first = frames[0]
    steps = first.get("steps", [])
    hinge_frame = first.get("hinge_joint_frame", {})
    if first.get("joint_count") != 24 or len(steps) != 24:
        fail("first frame should carry all joint control steps")
    if hinge_frame.get("body_count") != 25:
        fail("first hinge frame should carry all reference links as bodies")
    if hinge_frame.get("joint_count") != 24:
        fail("first hinge frame should carry all URDF joints")
    if hinge_frame.get("assessed_joint_count") != 24:
        fail("first hinge frame should assess all URDF joints")
    if hinge_frame.get("projected_body_count") != 25:
        fail("first hinge frame should project all reference bodies")
    if hinge_frame.get("resolved_hinge_constraint_count", -1) < 0:
        fail("first hinge frame must report resolved hinge count")
    if hinge_frame.get("motor_driven_joint_count", 0) <= 0:
        fail("first hinge frame must report driven world hinge motors")
    if hinge_frame.get("motor_review_count", -1) < 0:
        fail("first hinge frame must report motor review count")
    if hinge_frame.get("max_motor_angle_delta_rad", -1) < 0:
        fail("first hinge frame must report max motor angle delta")
    if hinge_frame.get("max_motor_velocity_delta_rad_s", -1) < 0:
        fail("first hinge frame must report max motor velocity delta")
    if "world-hinge-constraint" not in hinge_frame.get("world_status", ""):
        fail("first hinge frame must expose Moonphys world hinge status")
    if "world-hinge-motor" not in hinge_frame.get("motor_status", ""):
        fail("first hinge frame must expose Moonphys world hinge motor status")
    if "world-hinge-constraint" not in hinge_frame.get("motor_world_status", ""):
        fail("first hinge frame must expose motor replay hinge constraint status")
    if "hinge-joint-frame" not in hinge_frame.get("assessment_status", ""):
        fail("first hinge frame must expose Moonphys hinge-frame assessment")
    if "noetix-hinge-world" not in hinge_frame.get("status", ""):
        fail("first hinge frame must expose Noetix hinge world status")
    if not any(
        frame.get("hinge_joint_frame", {}).get("resolved_hinge_constraint_count", 0) > 0
        and frame.get("hinge_joint_frame", {}).get("world_status")
        == "world-hinge-constraint-resolved"
        for frame in frames
    ):
        fail("expected at least one Moonphys world hinge-resolved frame")
    if not any(
        frame.get("hinge_joint_frame", {}).get("motor_driven_joint_count", 0) > 0
        and frame.get("hinge_joint_frame", {}).get("motor_status")
        == "world-hinge-motor-driven"
        for frame in frames
    ):
        fail("expected at least one Moonphys world hinge motor-driven frame")
    if not all(step.get("motor_step", {}).get("limit") for step in steps):
        fail("every step must carry a Moonphys joint limit")
    if not all(
        "average_mechanical_power_w" in step.get("motor_step", {})
        and "work_j" in step.get("motor_step", {})
        and "absolute_work_j" in step.get("motor_step", {})
        for frame in frames
        for step in frame.get("steps", [])
    ):
        fail("every step must carry Moonphys power/work accounting")
    if not any(
        frame.get("max_abs_mechanical_power_w", 0) > 0
        and frame.get("total_absolute_work_j", 0) > 0
        for frame in frames
    ):
        fail("frame power/work aggregates must be present")
    if not any(
        step.get("joint_name") == "leg_l4_joint"
        and step.get("joint_index") == 8
        and step.get("motor_step", {}).get("limit", {}).get("max_torque_nm") == 100
        for frame in frames
        for step in frame.get("steps", [])
    ):
        fail("leg_l4_joint URDF effort limit not present in control report")
    if not any(
        step.get("joint_name") == "waist_2_joint"
        and step.get("motor_step", {}).get("limit", {}).get("max_velocity_rad_s") == 2
        for frame in frames
        for step in frame.get("steps", [])
    ):
        fail("waist_2_joint URDF velocity limit not present in control report")
    if any(frame.get("limit_review_count", -1) < 0 for frame in frames):
        fail("limit review counts must be nonnegative")
    if any(frame.get("limit_review_count", 0) != 0 for frame in frames):
        fail("velocity-limited command shaping should clear limit reviews")
    review_steps = [
        step
        for frame in frames
        if frame.get("limit_review_count") > 0
        for step in frame.get("steps", [])
        if not step.get("velocity_within_limits", True)
    ]
    review_joints = {step.get("joint_name") for step in review_steps}
    if review_joints:
        fail(f"unexpected velocity review joints after shaping: {review_joints}")
    leg_steps = [
        step
        for frame in frames
        for step in frame.get("steps", [])
        if str(step.get("joint_name", "")).startswith("leg_")
    ]
    if not leg_steps:
        fail("expected leg joint control steps")
    if any(abs(step.get("target_velocity_rad_s", 0)) > 3 for step in leg_steps):
        fail("leg joint velocities must remain shaped within URDF limits")
    if not all(step.get("velocity_within_limits") for step in leg_steps):
        fail("velocity-shaped leg joints must be within limits")


if __name__ == "__main__":
    main()
