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
    if "not hardware authority" not in trace.get("note", ""):
        fail("trace must explicitly avoid hardware authority")

    first = by_link(frames[0])
    fifth = by_link(frames[5])
    required = {"base_link", "chest_link", "left_foot", "right_foot", "right_leg_3"}
    if not required.issubset(first):
        fail("first frame is missing required links")
    if first["left_foot"].get("source_status") != "contact-probe-bound":
        fail("left foot must be bound to contact evidence")
    if first["right_foot"].get("source_status") != "contact-probe-bound":
        fail("right foot must be bound to contact evidence")
    if first["left_foot"].get("joint_name") != "leg_l6_joint":
        fail("left foot joint name should come from URDF")
    if first["right_foot"].get("joint_name") != "leg_r6_joint":
        fail("right foot joint name should come from URDF")
    if not first["chest_link"]["world_position"]["z"] > first["base_link"]["world_position"]["z"]:
        fail("chest link should sit above base link")
    if fifth["right_leg_3"]["world_position"]["z"] <= first["right_leg_3"]["world_position"]["z"]:
        fail("right leg proxy should move upward during swing")
    if not any(
        link.get("source_status") == "urdf-reference-gait-proxy"
        for link in first.values()
    ):
        fail("expected non-foot URDF-reference gait proxies")


if __name__ == "__main__":
    main()
