#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonclaw_noetix_review_task.py TASK_JSON")

    tasks = json.loads(Path(sys.argv[1]).read_text())
    if not isinstance(tasks, list) or len(tasks) != 1:
        fail("expected one Noetix review task")
    task = tasks[0]
    if task.get("task_id") != "moonclaw/first-trusted-square/noetix-review-task":
        fail("unexpected task id")
    if task.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if task.get("frame_count", 0) < 24:
        fail("expected at least 24 walk frames")
    if task.get("link_pose_count_per_frame") != 25:
        fail("expected compact Noetix URDF-reference link count")
    if task.get("static_support_review_frame_count", 0) <= 0:
        fail("static support review blocker should be explicit")
    if task.get("dynamic_stability_review_frame_count", 0) <= 0:
        fail("dynamic stability review blocker should be explicit")
    if task.get("hardware_state") != "HardwareDenied":
        fail("hardware state must remain denied")
    if task.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("unexpected hardware authority")
    if not task.get("hardware_denied"):
        fail("hardware_denied must be true")
    if "Dynamic stability" not in task.get("safety_gate", ""):
        fail("safety gate must name dynamic stability")

    inputs = {item.get("input_id") for item in task.get("inputs", [])}
    expected_inputs = {
        "noetix-walk-trace",
        "noetix-link-poses",
        "noetix-static-support",
        "noetix-dynamic-stability",
        "noetix-rabbita-playback",
    }
    if inputs != expected_inputs:
        fail(f"unexpected inputs: {sorted(inputs)}")

    artifacts = {item.get("artifact_id"): item for item in task.get("artifacts", [])}
    expected_artifacts = {
        "noetix-endless-walk-trace",
        "noetix-urdf-reference-link-poses",
        "noetix-static-support-review",
        "noetix-dynamic-stability-review",
        "noetix-rabbita-playback",
    }
    if set(artifacts) != expected_artifacts:
        fail(f"unexpected artifacts: {sorted(artifacts)}")
    if artifacts["noetix-static-support-review"].get("ready"):
        fail("static support artifact must remain review-blocked")
    if "review-only" not in artifacts["noetix-static-support-review"].get("blocking_reason", ""):
        fail("static support blocker must explain review-only state")
    if artifacts["noetix-dynamic-stability-review"].get("ready"):
        fail("dynamic stability artifact must remain review-blocked")
    if "review-only" not in artifacts["noetix-dynamic-stability-review"].get("blocking_reason", ""):
        fail("dynamic stability blocker must explain review-only state")

    commands = "\n".join(task.get("commands", []))
    for expected in [
        "check_moonrobo_noetix_walk.py",
        "check_moonrobo_noetix_link_poses.py",
        "check_moonrobo_noetix_stability.py",
        "check_moonrobo_noetix_dynamics.py",
        "check_rabbita_noetix_walk.py",
    ]:
        if expected not in commands:
            fail(f"missing command {expected}")


if __name__ == "__main__":
    main()
