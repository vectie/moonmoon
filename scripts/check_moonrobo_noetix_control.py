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
    if report.get("status") != "joint-control-limit-review":
        fail("control report should expose terrain-normal joint limit review")
    if report.get("saturated_frame_count") != 0:
        fail("planted-foot gait should not saturate joint control")
    if report.get("limit_review_frame_count") != 1:
        fail("terrain-normal gait should have exactly one limit-review frame")
    if "servo gains" not in report.get("note", ""):
        fail("report note must mention assumed servo gains")
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
    if "motor-driven heightfield world replay" not in report.get("note", ""):
        fail("report note must mention Moonphys motor-driven heightfield replay")
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
    if hinge_motor_world_trace.get("driven_joint_count") != report.get(
        "hinge_motor_driven_joint_count"
    ):
        fail("hinge motor world trace driven count must match frame summary")
    if hinge_motor_world_trace.get("contact_count", 0) <= 0:
        fail("hinge motor world trace must include heightfield contacts")
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
    if report.get("max_abs_velocity_rad_s", -1) < 0:
        fail("max velocity must be present")
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
    review_steps = [
        step
        for frame in frames
        if frame.get("limit_review_count") > 0
        for step in frame.get("steps", [])
        if not step.get("velocity_within_limits", True)
    ]
    review_joints = {step.get("joint_name") for step in review_steps}
    if review_joints != {"leg_r1_joint", "leg_r3_joint"}:
        fail(f"unexpected terrain-normal velocity review joints: {review_joints}")


if __name__ == "__main__":
    main()
