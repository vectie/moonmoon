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
    if "servo gains" not in report.get("note", ""):
        fail("report note must mention assumed servo gains")
    if report.get("max_abs_velocity_rad_s", -1) < 0:
        fail("max velocity must be present")

    first = frames[0]
    steps = first.get("steps", [])
    if first.get("joint_count") != 24 or len(steps) != 24:
        fail("first frame should carry all joint control steps")
    if not all(step.get("motor_step", {}).get("limit") for step in steps):
        fail("every step must carry a Moonphys joint limit")
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


if __name__ == "__main__":
    main()
