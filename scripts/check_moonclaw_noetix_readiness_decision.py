#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def require_contains(items: list[str], expected: str, label: str) -> None:
    if expected not in items:
        fail(f"{label} missing {expected}")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonclaw_noetix_readiness_decision.py DECISION_JSON")

    decision = json.loads(Path(sys.argv[1]).read_text())
    if not isinstance(decision, dict):
        fail("expected one Noetix readiness decision")
    if (
        decision.get("decision_id")
        != "moonclaw/first-trusted-square/noetix-simulation-readiness-decision"
    ):
        fail("unexpected decision id")
    if decision.get("source_task_id") != "moonclaw/first-trusted-square/noetix-review-task":
        fail("unexpected source task id")
    if decision.get("site_id") != "first-trusted-square":
        fail("unexpected site id")
    if decision.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if decision.get("may_consume_moonrobo_simulation"):
        fail("Noetix simulation must not be consumable yet")
    if decision.get("decision") != "NoetixSimulationBlocked":
        fail("decision must remain blocked")
    if decision.get("ready_artifact_count") != 9:
        fail("unexpected ready artifact count")
    if decision.get("blocked_artifact_count") != 2:
        fail("unexpected blocked artifact count")
    if decision.get("metadata_blocker_count") != 50:
        fail("unexpected metadata blocker count")
    metadata_blockers = decision.get("metadata_blocker_ids")
    if not isinstance(metadata_blockers, list):
        fail("source metadata blocker ids must be listed")
    if len(metadata_blockers) != decision.get("metadata_blocker_count"):
        fail("source metadata blocker count must match listed ids")
    if decision.get("source_metadata_ready"):
        fail("source metadata must not be ready yet")
    inventory = decision.get("source_metadata_inventory", {})
    if inventory.get("model_id") != "noetix-e1-source-model":
        fail("source metadata inventory must identify the model")
    if inventory.get("link_count") != 25:
        fail("source metadata inventory must preserve link count")
    if inventory.get("blocker_count") != 50:
        fail("source metadata inventory blocker count should match decision")
    if inventory.get("blocker_ids") != metadata_blockers:
        fail("source metadata blocker ids must match inventory")
    if inventory.get("ready"):
        fail("source metadata inventory must remain blocked")
    if inventory.get("status") != "model-metadata-blocked":
        fail("source metadata inventory must expose blocked status")
    if "missing-collision-shape:left_foot" not in metadata_blockers:
        fail("source metadata blockers must name left foot collision metadata")
    if "missing-inertial:right_foot" not in metadata_blockers:
        fail("source metadata blockers must name right foot inertial metadata")
    if decision.get("physical_model_ready"):
        fail("physical model readiness must remain blocked")
    physical = decision.get("physical_model_readiness", {})
    if physical.get("readiness_id") != "moonrobo/noetix-e1/physical-model-readiness-v0":
        fail("physical readiness must identify the Noetix model")
    if physical.get("blocker_count") != 9:
        fail("physical readiness blocker count should remain explicit")
    if physical.get("ready"):
        fail("physical readiness must remain blocked")
    if physical.get("status") != "physical-model-assumption-review":
        fail("physical readiness must expose assumption-review status")
    if decision.get("physical_model_blocker_count") != physical.get("blocker_count"):
        fail("decision physical blocker count must match readiness")
    physical_blockers = decision.get("physical_model_blocker_ids")
    if not isinstance(physical_blockers, list):
        fail("decision physical blocker ids must be listed")
    if physical.get("blocker_ids") != physical_blockers:
        fail("decision physical blocker ids must match readiness")
    if len(physical_blockers) != decision.get("physical_model_blocker_count"):
        fail("decision physical blocker count must match listed ids")
    if "assumed:mass" not in physical_blockers:
        fail("physical blockers must name assumed mass")
    if "missing:joint-damping" not in physical_blockers:
        fail("physical blockers must name missing joint damping")
    if decision.get("static_support_stable_frame_count") != 32:
        fail("static support should report all frames support-stable")
    if decision.get("dynamic_stability_capture_stable_frame_count") != 32:
        fail("dynamic stability should report all frames capture-stable")
    for field in [
        "static_support_review_frame_count",
        "dynamic_stability_review_frame_count",
        "joint_control_review_frame_count",
        "inertial_collision_review_frame_count",
    ]:
        if decision.get(field, 0) <= 0:
            fail(f"{field} must be explicit")
    if decision.get("joint_control_world_support_review_frame_count") != 0:
        fail("joint_control_world_support_review_frame_count should be cleared")
    if decision.get("joint_control_world_capture_review_frame_count") != 0:
        fail("joint_control_world_capture_review_frame_count should be cleared")
    if decision.get("joint_control_max_support_recovery_shift_m", -1) < 0:
        fail("joint control max support recovery shift must be explicit")
    if decision.get("joint_control_worst_capture_support_margin_m", 0) <= 0:
        fail("joint control worst capture support margin must be positive")
    if decision.get("joint_control_max_capture_recovery_shift_m") != 0:
        fail("joint control max capture recovery shift must be cleared")
    if decision.get("joint_control_world_replay_blocker_count") != 0:
        fail("joint control world replay blockers should be cleared")
    replay_blockers = decision.get("joint_control_world_replay_blockers")
    if not isinstance(replay_blockers, list):
        fail("joint control world replay blocker ids must be listed")
    if len(replay_blockers) != decision.get("joint_control_world_replay_blocker_count"):
        fail("joint control world replay blocker count must match listed ids")
    if "world-envelope-review" in replay_blockers:
        fail("joint control world replay blockers must not retain cleared envelope review")
    if "world-support-review" in replay_blockers:
        fail("joint control world replay blockers must not retain cleared support review")
    if "world-dynamic-support-review" in replay_blockers:
        fail("joint control world replay blockers must clear dynamic support review")

    ready_artifacts = decision.get("ready_artifacts", [])
    blocked_artifacts = decision.get("blocked_artifacts", [])
    if not isinstance(ready_artifacts, list) or not isinstance(blocked_artifacts, list):
        fail("artifact fields must be lists")
    for expected in [
        "noetix-source-model-audit",
        "noetix-moonrobo-source-sync",
        "noetix-endless-gait-window",
        "noetix-endless-walk-trace",
        "noetix-high-control-walk-command-plan",
        "noetix-urdf-reference-link-poses",
        "noetix-static-support-review",
        "noetix-dynamic-stability-review",
        "noetix-rabbita-playback",
    ]:
        require_contains(ready_artifacts, expected, "ready artifacts")
    for expected in [
        "noetix-joint-control-review",
        "noetix-inertial-collision-review",
    ]:
        require_contains(blocked_artifacts, expected, "blocked artifacts")
    for cleared in [
        "noetix-static-support-review",
        "noetix-dynamic-stability-review",
    ]:
        if cleared in blocked_artifacts:
            fail(f"blocked artifacts should not retain cleared margin artifact {cleared}")

    if decision.get("hardware_state") != "HardwareDenied":
        fail("hardware state must remain denied")
    if decision.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("unexpected hardware authority")
    if not decision.get("hardware_denied"):
        fail("hardware_denied must be true")
    invariants = decision.get("hardware_denial_invariants", [])
    require_contains(
        invariants,
        "Noetix review decision must never issue hardware authority",
        "hardware denial invariants",
    )
    reason = decision.get("reason", "")
    if "Noetix simulation remains blocked" not in reason:
        fail("reason must explain blocked decision")
    if "50 source metadata blockers" not in reason:
        fail("reason must name source metadata blockers")
    if "model-metadata-blocked" not in reason:
        fail("reason must name source metadata inventory status")
    if "9 physical model blockers" not in reason:
        fail("reason must name physical model blockers")
    if "physical-model-assumption-review" not in reason:
        fail("reason must name physical readiness status")
    next_action = decision.get("next_action", "")
    if "physical model metadata" not in next_action:
        fail("next action must name physical model metadata")
    if "keep hardware denied" not in next_action:
        fail("next action must preserve hardware denial")


if __name__ == "__main__":
    main()
