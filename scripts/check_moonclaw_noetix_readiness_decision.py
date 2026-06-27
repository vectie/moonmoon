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
    if decision.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if decision.get("may_consume_moonrobo_simulation"):
        fail("Noetix simulation must not be consumable yet")
    if decision.get("decision") != "NoetixSimulationBlocked":
        fail("decision must remain blocked")
    if decision.get("ready_artifact_count") != 7:
        fail("unexpected ready artifact count")
    if decision.get("blocked_artifact_count") != 4:
        fail("unexpected blocked artifact count")
    if decision.get("metadata_blocker_count") != 50:
        fail("unexpected metadata blocker count")
    for field in [
        "static_support_review_frame_count",
        "dynamic_stability_review_frame_count",
        "joint_control_review_frame_count",
        "inertial_collision_review_frame_count",
    ]:
        if decision.get(field, 0) <= 0:
            fail(f"{field} must be explicit")

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
        "noetix-rabbita-playback",
    ]:
        require_contains(ready_artifacts, expected, "ready artifacts")
    for expected in [
        "noetix-static-support-review",
        "noetix-dynamic-stability-review",
        "noetix-joint-control-review",
        "noetix-inertial-collision-review",
    ]:
        require_contains(blocked_artifacts, expected, "blocked artifacts")

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
    next_action = decision.get("next_action", "")
    if "keep hardware denied" not in next_action:
        fail("next action must preserve hardware denial")


if __name__ == "__main__":
    main()
