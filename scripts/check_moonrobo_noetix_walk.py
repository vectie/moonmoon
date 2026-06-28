#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def same_position(a: dict, b: dict) -> bool:
    return (
        abs(a.get("x", 0) - b.get("x", 0)) <= 1e-9
        and abs(a.get("y", 0) - b.get("y", 0)) <= 1e-9
        and abs(a.get("z", 0) - b.get("z", 0)) <= 1e-9
    )


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_walk.py TRACE_JSON")

    path = Path(sys.argv[1])
    trace = json.loads(path.read_text())
    frames = trace.get("frames", [])
    if trace.get("trace_id") != (
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected trace_id")
    if trace.get("robot", {}).get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if trace.get("terrain_tile_id") != "first-trusted-square-northeast-stepout-lola":
        fail("unexpected terrain tile")
    config = trace.get("config", {})
    if abs(config.get("gravity_mps2", 0) - 1.625) > 1e-9:
        fail("gravity is not lunar")
    if config.get("terrain_source_id") != trace.get("terrain_tile_id"):
        fail("walk config terrain source does not match terrain tile")
    if abs(config.get("heading_rad", 999)) > 1e-9:
        fail("default walk heading should remain +x")
    start = config.get("start_position", {})
    if start.get("x") != 0 or start.get("y") != 0 or start.get("z") != 0:
        fail("default walk should start at terrain origin")
    if config.get("foot_radius_m", 0) <= 0:
        fail("foot radius must be explicit")
    if config.get("support_forward_lead_m", 0) <= 0:
        fail("support forward lead must be explicit")
    if config.get("double_support_frames", 0) <= 0:
        fail("double-support transfer frames must be explicit")
    if abs(
        config.get("speed_mps", 0)
        - config.get("step_length_m", 0) * config.get("stride_frequency_hz", 0)
    ) > 1e-9:
        fail("stride frequency must match configured speed and step length")
    if trace.get("endless_axis") != "+x":
        fail("unexpected endless axis")
    if trace.get("frame_count") != len(frames) or len(frames) < 24:
        fail("frame count is inconsistent or too small")
    if "not hardware authority" not in trace.get("note", ""):
        fail("trace must explicitly avoid hardware authority")

    first_x = frames[0]["body_position"]["x"]
    last_x = frames[-1]["body_position"]["x"]
    if not last_x > first_x:
        fail("body does not progress in +x")
    if frames[0].get("support_phase") != "double-support-left-transfer":
        fail("first frame should start in left double-support transfer")
    if frames[16].get("support_phase") != "double-support-right-transfer":
        fail("frame 16 should switch to right double-support transfer")
    if not frames[0]["left_foot"]["in_contact"]:
        fail("left foot should support frame 0")
    if not frames[0]["right_foot"]["in_contact"]:
        fail("right foot should share double support at frame 0")
    if not frames[16]["left_foot"]["in_contact"]:
        fail("left foot should share double support at frame 16")
    if not frames[16]["right_foot"]["in_contact"]:
        fail("right foot should support frame 16")
    if frames[12]["right_foot"]["in_contact"]:
        fail("right foot should swing after the left transfer window")
    left_plant = frames[0]["left_foot"]["position"]
    for index in range(0, 16):
        if not frames[index]["left_foot"]["in_contact"]:
            fail(f"left foot should remain planted at frame {index}")
        if not same_position(frames[index]["left_foot"]["position"], left_plant):
            fail(f"left support foot slides at frame {index}")
    right_plant = frames[16]["right_foot"]["position"]
    for index in range(16, 32):
        if not frames[index]["right_foot"]["in_contact"]:
            fail(f"right foot should remain planted at frame {index}")
        if not same_position(frames[index]["right_foot"]["position"], right_plant):
            fail(f"right support foot slides at frame {index}")
    if not any(frame.get("status") == "walking-needs-review" for frame in frames):
        fail("trace should preserve terrain review status")
    if len(frames[0].get("joint_phases", [])) != 24:
        fail("frame should carry 24 Noetix joint phases")
    if not any(
        phase.get("joint_name") == "leg_r3_joint"
        and phase.get("status") == "urdf-walk-clip"
        for phase in frames[5].get("joint_phases", [])
    ):
        fail("joint phases should include Noetix URDF walk clip joints")
    if not all(
        -1.2 <= phase.get("position_rad", 99) <= 1.2
        for frame in frames
        for phase in frame.get("joint_phases", [])
        if phase.get("joint_name") in {"leg_l1_joint", "leg_r1_joint"}
    ):
        fail("hip pitch IK phases should be bounded by source joint limits")


if __name__ == "__main__":
    main()
