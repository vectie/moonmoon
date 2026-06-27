#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def close(actual: float, expected: float) -> bool:
    return abs(actual - expected) <= 1e-9


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_walk_command.py PLAN_JSON")

    plan = json.loads(Path(sys.argv[1]).read_text())
    segments = plan.get("segments", [])
    limits = plan.get("high_control_limits", {})

    if plan.get("plan_id") != (
        "moonrobo/noetix-e1/high-control-walk-plan/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected plan_id")
    if not plan.get("trace_id", "").startswith(
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
    ):
        fail("unexpected trace_id")
    if plan.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if plan.get("capability_id") != "control.high.walk":
        fail("unexpected capability id")
    if plan.get("command_class") != "HighControl":
        fail("unexpected command class")
    if plan.get("status") != "walk-command-dry-run-review":
        fail("plan must remain dry-run review evidence")
    if plan.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("unexpected hardware authority")
    if plan.get("executable_on_hardware"):
        fail("plan must not be executable on hardware")
    if "not hardware authority" not in plan.get("note", ""):
        fail("plan note must reject hardware authority")
    if plan.get("frame_count", 0) < 24:
        fail("expected at least 24 source frames")
    if plan.get("segment_count") != len(segments) or len(segments) < 3:
        fail("segment count is inconsistent or too small")

    if limits.get("capability_id") != "control.high.walk":
        fail("unexpected limit capability")
    if limits.get("command_class") != "HighControl":
        fail("unexpected limit command class")
    if not close(limits.get("max_x_abs_mps", 0), 0.25):
        fail("unexpected x velocity limit")
    if not close(limits.get("max_yaw_abs_rad_s", 0), 0.5):
        fail("unexpected yaw limit")
    if limits.get("max_duration_ms") != 1500:
        fail("unexpected segment duration limit")
    if limits.get("telemetry_freshness_ms") != 250:
        fail("unexpected telemetry freshness limit")
    if limits.get("heartbeat_ms") != 100:
        fail("unexpected heartbeat limit")
    if limits.get("default_mode") != "read-only":
        fail("default mode must remain read-only")
    if not limits.get("requires_approval"):
        fail("approval must be required")
    if not limits.get("requires_dry_run"):
        fail("dry run must be required")
    if limits.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("limit hardware authority must remain denied")

    total_distance = 0.0
    for index, segment in enumerate(segments):
        if segment.get("segment_id") != (
            f"segment-{segment.get('start_frame_index')}-"
            f"{segment.get('end_frame_index')}"
        ):
            fail(f"segment {index} has inconsistent id")
        if segment.get("end_frame_index", 0) <= segment.get("start_frame_index", 0):
            fail(f"segment {index} has empty frame span")
        if segment.get("duration_s", 0) > 1.5 + 1e-9:
            fail(f"segment {index} exceeds duration limit")
        if not segment.get("within_x_limit"):
            fail(f"segment {index} exceeds x limit")
        if not segment.get("within_yaw_limit"):
            fail(f"segment {index} exceeds yaw limit")
        if not segment.get("within_duration_limit"):
            fail(f"segment {index} exceeds duration limit")
        if not segment.get("requires_approval"):
            fail(f"segment {index} must require approval")
        if not segment.get("requires_dry_run"):
            fail(f"segment {index} must require dry run")
        if segment.get("executable_on_hardware"):
            fail(f"segment {index} must not be executable")
        if segment.get("status") != "dry-run-command-review":
            fail(f"segment {index} must remain dry-run review")
        if abs(segment.get("command_x_mps", 0)) > limits.get("max_x_abs_mps", 0):
            fail(f"segment {index} x command exceeds profile limit")
        if abs(segment.get("command_yaw_rad_s", 0)) > limits.get(
            "max_yaw_abs_rad_s", 0
        ):
            fail(f"segment {index} yaw command exceeds profile limit")
        total_distance += segment.get("expected_distance_m", 0)

    if plan.get("max_command_x_abs_mps", 0) <= 0:
        fail("max x command must be positive")
    if not close(plan.get("max_command_yaw_abs_rad_s", -1), 0.0):
        fail("unexpected max yaw command")
    if plan.get("max_command_x_abs_mps", 0) > limits.get("max_x_abs_mps", 0):
        fail("max x command exceeds profile limit")
    if plan.get("total_expected_distance_m", 0) <= 0:
        fail("expected distance must be positive")
    if abs(plan.get("total_expected_distance_m", 0) - total_distance) > 1e-9:
        fail("total expected distance does not match segments")


if __name__ == "__main__":
    main()
