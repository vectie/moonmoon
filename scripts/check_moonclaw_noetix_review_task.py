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
    if task.get("endless_gait_cycle_frames") != 32:
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
    metadata_blockers = task.get("source_model_metadata_blocker_ids")
    if not isinstance(metadata_blockers, list):
        fail("source metadata blocker ids must be listed")
    if len(metadata_blockers) != task.get("source_model_metadata_blocker_count"):
        fail("source metadata blocker count must match listed ids")
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
    if inventory.get("blocker_ids") != metadata_blockers:
        fail("source metadata blocker ids must match inventory")
    if inventory.get("ready"):
        fail("source metadata inventory must remain blocked")
    if inventory.get("status") != "model-metadata-blocked":
        fail("source metadata inventory must expose blocked status")
    if len(inventory.get("missing_collision_shape_links", [])) != 25:
        fail("source metadata inventory must list missing collision links")
    if len(inventory.get("missing_inertial_links", [])) != 25:
        fail("source metadata inventory must list missing inertial links")
    if "missing-collision-shape:left_foot" not in metadata_blockers:
        fail("source metadata blockers must name left foot collision metadata")
    if "missing-inertial:right_foot" not in metadata_blockers:
        fail("source metadata blockers must name right foot inertial metadata")
    metadata_gaps = task.get("source_model_metadata_gaps")
    if not isinstance(metadata_gaps, list):
        fail("source metadata gap inventory must be listed")
    if len(metadata_gaps) != task.get("source_model_metadata_blocker_count"):
        fail("source metadata gap count must match blocker count")
    metadata_gaps_by_id = {gap.get("blocker_id"): gap for gap in metadata_gaps}
    for blocker_id in metadata_blockers:
        if blocker_id not in metadata_gaps_by_id:
            fail(f"source metadata gap inventory missing {blocker_id}")
    left_collision_gap = metadata_gaps_by_id.get("missing-collision-shape:left_foot", {})
    if (
        left_collision_gap.get("link_name") != "left_foot"
        or left_collision_gap.get("metadata_kind") != "collision-shape"
        or left_collision_gap.get("current_status") != "missing"
        or "URDF <collision>" not in left_collision_gap.get("required_evidence", "")
        or "source collision metadata" not in left_collision_gap.get("next_action", "")
    ):
        fail("left foot collision source metadata gap must be actionable")
    right_inertial_gap = metadata_gaps_by_id.get("missing-inertial:right_foot", {})
    if (
        right_inertial_gap.get("link_name") != "right_foot"
        or right_inertial_gap.get("metadata_kind") != "inertial"
        or right_inertial_gap.get("current_status") != "missing"
        or "URDF <inertial>" not in right_inertial_gap.get("required_evidence", "")
        or "source inertial metadata" not in right_inertial_gap.get("next_action", "")
    ):
        fail("right foot inertial source metadata gap must be actionable")
    physical = task.get("physical_model_readiness", {})
    if physical.get("readiness_id") != "moonrobo/noetix-e1/physical-model-readiness-v0":
        fail("physical readiness must identify the Noetix model")
    if physical.get("blocker_count") != 9:
        fail("physical readiness blocker count should remain explicit")
    if physical.get("ready"):
        fail("physical readiness must remain blocked")
    if physical.get("status") != "physical-model-assumption-review":
        fail("physical readiness must expose assumption-review status")
    if task.get("physical_model_blocker_count") != physical.get("blocker_count"):
        fail("task physical blocker count must match readiness")
    physical_blockers = task.get("physical_model_blocker_ids")
    if not isinstance(physical_blockers, list):
        fail("task physical blocker ids must be listed")
    if physical.get("blocker_ids") != physical_blockers:
        fail("task physical blocker ids must match readiness")
    if len(physical_blockers) != task.get("physical_model_blocker_count"):
        fail("task physical blocker count must match listed ids")
    if "assumed:mass" not in physical_blockers:
        fail("physical blockers must name assumed mass")
    if "missing:joint-damping" not in physical_blockers:
        fail("physical blockers must name missing joint damping")
    if task.get("link_pose_count_per_frame") != 25:
        fail("expected compact Noetix URDF-reference link count")
    if task.get("static_support_stable_frame_count") != task.get("frame_count"):
        fail("static support should report every frame support-stable")
    if task.get("static_support_review_frame_count", 0) <= 0:
        fail("static support provenance review blocker should be explicit")
    if task.get("dynamic_stability_capture_stable_frame_count") != task.get(
        "frame_count"
    ):
        fail("dynamic stability should report every frame capture-stable")
    if task.get("dynamic_stability_review_frame_count", 0) <= 0:
        fail("dynamic stability provenance review blocker should be explicit")
    if task.get("joint_control_review_frame_count", 0) <= 0:
        fail("joint control review blocker should be explicit")
    if task.get("joint_control_world_support_review_frame_count") != 0:
        fail("joint control world-support review should be cleared")
    if task.get("joint_control_world_capture_review_frame_count") != 0:
        fail("joint control world-capture review should be cleared")
    if task.get("joint_control_max_support_recovery_shift_m", -1) < 0:
        fail("joint control max support recovery shift should be explicit")
    if task.get("joint_control_worst_capture_support_margin_m", 0) <= 0:
        fail("joint control worst capture support margin should be positive")
    if task.get("joint_control_max_capture_recovery_shift_m") != 0:
        fail("joint control max capture recovery shift should be cleared")
    if task.get("joint_control_world_replay_blocker_count") != 0:
        fail("joint control world replay blockers should be cleared")
    replay_blockers = task.get("joint_control_world_replay_blockers")
    if not isinstance(replay_blockers, list):
        fail("joint control world replay blocker ids must be listed")
    if len(replay_blockers) != task.get("joint_control_world_replay_blocker_count"):
        fail("joint control world replay blocker count must match listed ids")
    if "world-envelope-review" in replay_blockers:
        fail("joint control world replay blockers must not retain cleared envelope review")
    if "world-support-review" in replay_blockers:
        fail("joint control world replay blockers must not retain cleared support review")
    if "world-dynamic-support-review" in replay_blockers:
        fail("joint control world replay blockers must clear dynamic support review")
    if task.get("inertial_collision_review_frame_count") != 0:
        fail("inertial collision terrain/self-contact review frames should clear")
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
    if not artifacts["noetix-urdf-reference-link-poses"].get("ready"):
        fail("link pose artifact should be ready evidence")
    link_pose_state = artifacts["noetix-urdf-reference-link-poses"].get(
        "current_state", ""
    )
    if "collision metadata links 0" not in link_pose_state:
        fail("link pose artifact must expose missing collision metadata")
    if "inertial metadata links 0" not in link_pose_state:
        fail("link pose artifact must expose missing inertial metadata")
    if "missing collision links 25" not in link_pose_state:
        fail("link pose artifact must preserve missing collision link count")
    if "missing inertial links 25" not in link_pose_state:
        fail("link pose artifact must preserve missing inertial link count")
    if not artifacts["noetix-static-support-review"].get("ready"):
        fail("static support artifact should be ready once every frame is support-stable")
    if artifacts["noetix-static-support-review"].get("blocking_reason") != "none":
        fail("static support artifact should keep provenance blockers outside artifact readiness")
    static_state = artifacts["noetix-static-support-review"].get("current_state", "")
    if "frames support-stable" not in static_state:
        fail("static support artifact must expose support-stable frame count")
    if "review frames from contact/model provenance" not in static_state:
        fail("static support artifact must separate review provenance blockers")
    if not artifacts["noetix-dynamic-stability-review"].get("ready"):
        fail("dynamic stability artifact should be ready once every frame is capture-stable")
    if artifacts["noetix-dynamic-stability-review"].get("blocking_reason") != "none":
        fail("dynamic stability artifact should keep provenance blockers outside artifact readiness")
    dynamic_state = artifacts["noetix-dynamic-stability-review"].get("current_state", "")
    if "frames capture-stable" not in dynamic_state:
        fail("dynamic stability artifact must expose capture-stable frame count")
    if "dynamic review frames from model/provenance blockers" not in dynamic_state:
        fail("dynamic stability artifact must separate review provenance blockers")
    if not artifacts["noetix-joint-control-review"].get("ready"):
        fail("joint control artifact should be ready after replay blockers clear")
    if artifacts["noetix-joint-control-review"].get("blocking_reason") != "none":
        fail("joint control artifact should keep servo/inertia authority blockers outside artifact readiness")
    joint_control_state = artifacts["noetix-joint-control-review"].get("current_state", "")
    if "capture-review frames" not in joint_control_state:
        fail("joint control artifact must expose world capture-review frames")
    if "worst capture support margin" not in joint_control_state:
        fail("joint control artifact must expose worst capture support margin")
    if "world replay blockers" not in joint_control_state:
        fail("joint control artifact must expose world replay blockers")
    if "world-replay-review" not in joint_control_state:
        fail("joint control artifact must expose Moonphys world replay review")
    if not artifacts["noetix-inertial-collision-review"].get("ready"):
        fail("inertial collision artifact should be ready after filtered self-contact checks clear")
    if artifacts["noetix-inertial-collision-review"].get("blocking_reason") != "none":
        fail("inertial collision artifact should keep source/physical authority blockers outside artifact readiness")
    inertial_state = artifacts["noetix-inertial-collision-review"].get("current_state", "")
    if "self-contact review frames 0" not in inertial_state:
        fail("inertial collision artifact must expose cleared self-contact frames")
    if "terrain-review frames 0" not in inertial_state:
        fail("inertial collision artifact must expose cleared terrain-review frames")
    if "max self penetration 0" not in inertial_state:
        fail("inertial collision artifact must expose cleared self penetration")

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
