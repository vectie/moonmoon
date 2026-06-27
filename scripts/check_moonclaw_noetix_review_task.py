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
    if task.get("endless_gait_cycle_frames") != 20:
        fail("unexpected endless gait cycle length")
    if task.get("source_model_collision_tag_count") != 0:
        fail("source model should have no authoritative collision tags yet")
    if task.get("source_model_inertial_tag_count") != 0:
        fail("source model should have no authoritative inertial tags yet")
    if task.get("source_model_missing_collision_link_count") != 25:
        fail("source model should report missing collision metadata for every link")
    if task.get("source_model_missing_inertial_link_count") != 25:
        fail("source model should report missing inertial metadata for every link")
    if task.get("source_model_metadata_blocker_count") != 50:
        fail("source metadata blocker count should be explicit")
    inventory = task.get("source_model_metadata_inventory", {})
    if inventory.get("model_id") != "noetix-e1-source-model":
        fail("source metadata inventory must identify the model")
    if inventory.get("link_count") != 25:
        fail("source metadata inventory must preserve link count")
    if inventory.get("collision_shape_link_count") != 0:
        fail("source metadata inventory should not report collision links yet")
    if inventory.get("inertial_link_count") != 0:
        fail("source metadata inventory should not report inertial links yet")
    if inventory.get("blocker_count") != 50:
        fail("source metadata inventory blocker count should match audit")
    if inventory.get("ready"):
        fail("source metadata inventory must remain blocked")
    if inventory.get("status") != "model-metadata-blocked":
        fail("source metadata inventory must expose blocked status")
    if len(inventory.get("missing_collision_shape_links", [])) != 25:
        fail("source metadata inventory must list missing collision links")
    if len(inventory.get("missing_inertial_links", [])) != 25:
        fail("source metadata inventory must list missing inertial links")
    if task.get("link_pose_count_per_frame") != 25:
        fail("expected compact Noetix URDF-reference link count")
    if task.get("static_support_review_frame_count", 0) <= 0:
        fail("static support review blocker should be explicit")
    if task.get("dynamic_stability_review_frame_count", 0) <= 0:
        fail("dynamic stability review blocker should be explicit")
    if task.get("joint_control_review_frame_count", 0) <= 0:
        fail("joint control review blocker should be explicit")
    if task.get("joint_control_world_support_review_frame_count", 0) <= 0:
        fail("joint control world-support review blocker should be explicit")
    if task.get("joint_control_world_capture_review_frame_count", 0) <= 0:
        fail("joint control world-capture review blocker should be explicit")
    if task.get("joint_control_worst_capture_support_margin_m", 0) >= 0:
        fail("joint control worst capture support margin should remain a blocker")
    if task.get("joint_control_world_replay_blocker_count", 0) <= 0:
        fail("joint control world replay blockers should be explicit")
    if task.get("inertial_collision_review_frame_count", 0) <= 0:
        fail("inertial collision review blocker should be explicit")
    if not task.get("source_walk_command_plan_id", "").startswith(
        "moonrobo/noetix-e1/high-control-walk-plan/"
    ):
        fail("unexpected walk command plan id")
    if task.get("walk_command_segment_count", 0) <= 0:
        fail("walk command segment count should be explicit")
    if task.get("hardware_state") != "HardwareDenied":
        fail("hardware state must remain denied")
    if task.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("unexpected hardware authority")
    if not task.get("hardware_denied"):
        fail("hardware_denied must be true")
    safety_gate = task.get("safety_gate", "")
    if "joint-control" not in safety_gate:
        fail("safety gate must name joint-control evidence")
    if "command plan" not in safety_gate:
        fail("safety gate must name high-control command-plan evidence")
    if "inertial/collision" not in safety_gate:
        fail("safety gate must name inertial/collision evidence")

    inputs = {item.get("input_id") for item in task.get("inputs", [])}
    expected_inputs = {
        "noetix-source-model",
        "noetix-endless-gait",
        "noetix-walk-trace",
        "noetix-walk-command-plan",
        "noetix-link-poses",
        "noetix-static-support",
        "noetix-dynamic-stability",
        "noetix-joint-control",
        "noetix-inertial-collision",
        "noetix-rabbita-playback",
    }
    if inputs != expected_inputs:
        fail(f"unexpected inputs: {sorted(inputs)}")

    artifacts = {item.get("artifact_id"): item for item in task.get("artifacts", [])}
    expected_artifacts = {
        "noetix-source-model-audit",
        "noetix-moonrobo-source-sync",
        "noetix-endless-gait-window",
        "noetix-endless-walk-trace",
        "noetix-high-control-walk-command-plan",
        "noetix-urdf-reference-link-poses",
        "noetix-static-support-review",
        "noetix-dynamic-stability-review",
        "noetix-joint-control-review",
        "noetix-inertial-collision-review",
        "noetix-rabbita-playback",
    }
    if set(artifacts) != expected_artifacts:
        fail(f"unexpected artifacts: {sorted(artifacts)}")
    if not artifacts["noetix-source-model-audit"].get("ready"):
        fail("source model audit should be ready evidence")
    if "check_moonrobo_noetix_source_model" not in artifacts["noetix-source-model-audit"].get("validation_gate", ""):
        fail("source model audit must have validator")
    if not artifacts["noetix-moonrobo-source-sync"].get("ready"):
        fail("source sync artifact should be ready evidence")
    if artifacts["noetix-moonrobo-source-sync"].get("blocking_reason") != "none":
        fail("source sync artifact should not be blocked")
    if "check_moonrobo_noetix_source_sync" not in artifacts["noetix-moonrobo-source-sync"].get("validation_gate", ""):
        fail("source sync artifact must have validator")
    if not artifacts["noetix-endless-gait-window"].get("ready"):
        fail("endless gait artifact should be ready evidence")
    if artifacts["noetix-endless-gait-window"].get("blocking_reason") != "none":
        fail("endless gait artifact should not be blocked")
    if "check_moonrobo_noetix_endless_gait" not in artifacts["noetix-endless-gait-window"].get("validation_gate", ""):
        fail("endless gait artifact must have validator")
    if not artifacts["noetix-high-control-walk-command-plan"].get("ready"):
        fail("walk command plan should be ready dry-run evidence")
    if artifacts["noetix-high-control-walk-command-plan"].get("blocking_reason") != "none":
        fail("walk command plan should not be blocked")
    if "check_moonrobo_noetix_walk_command" not in artifacts["noetix-high-control-walk-command-plan"].get("validation_gate", ""):
        fail("walk command plan must have validator")
    if artifacts["noetix-static-support-review"].get("ready"):
        fail("static support artifact must remain review-blocked")
    if "review-only" not in artifacts["noetix-static-support-review"].get("blocking_reason", ""):
        fail("static support blocker must explain review-only state")
    if artifacts["noetix-dynamic-stability-review"].get("ready"):
        fail("dynamic stability artifact must remain review-blocked")
    if "review-only" not in artifacts["noetix-dynamic-stability-review"].get("blocking_reason", ""):
        fail("dynamic stability blocker must explain review-only state")
    if artifacts["noetix-joint-control-review"].get("ready"):
        fail("joint control artifact must remain review-blocked")
    if "review-only" not in artifacts["noetix-joint-control-review"].get("blocking_reason", ""):
        fail("joint control blocker must explain review-only state")
    joint_control_state = artifacts["noetix-joint-control-review"].get("current_state", "")
    if "capture-review frames" not in joint_control_state:
        fail("joint control artifact must expose world capture-review frames")
    if "worst capture support margin" not in joint_control_state:
        fail("joint control artifact must expose worst capture support margin")
    if "world replay blockers" not in joint_control_state:
        fail("joint control artifact must expose world replay blockers")
    if "world-replay-review" not in joint_control_state:
        fail("joint control artifact must expose Moonphys world replay review")
    if artifacts["noetix-inertial-collision-review"].get("ready"):
        fail("inertial collision artifact must remain review-blocked")
    if "review-only" not in artifacts["noetix-inertial-collision-review"].get("blocking_reason", ""):
        fail("inertial collision blocker must explain review-only state")

    commands = "\n".join(task.get("commands", []))
    for expected in [
        "check_moonrobo_noetix_source_model.py",
        "check_moonrobo_noetix_source_sync.py",
        "check_moonrobo_noetix_endless_gait.py",
        "check_moonrobo_noetix_walk.py",
        "check_moonrobo_noetix_walk_command.py",
        "check_moonrobo_noetix_link_poses.py",
        "check_moonrobo_noetix_stability.py",
        "check_moonrobo_noetix_dynamics.py",
        "check_moonrobo_noetix_control.py",
        "check_moonrobo_noetix_inertial_collision.py",
        "check_rabbita_noetix_walk.py",
    ]:
        if expected not in commands:
            fail(f"missing command {expected}")


if __name__ == "__main__":
    main()
