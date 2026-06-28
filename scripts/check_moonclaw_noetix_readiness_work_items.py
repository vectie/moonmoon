#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def item_by_domain(items: list[dict], domain: str) -> dict:
    for item in items:
        if item.get("blocker_domain") == domain:
            return item
    fail(f"missing work item domain {domain}")


def require_item(
    item: dict,
    count: int,
    expected_id: str,
    expected_check: str,
) -> None:
    if item.get("state") != "NeedsReview":
        fail(f"{item.get('blocker_domain')} must remain NeedsReview")
    if item.get("blocker_count") != count:
        fail(f"{item.get('blocker_domain')} blocker count drifted")
    blocker_ids = item.get("blocker_ids")
    if not isinstance(blocker_ids, list) or len(blocker_ids) != count:
        fail(f"{item.get('blocker_domain')} blocker ids must match count")
    if expected_id not in blocker_ids:
        fail(f"{item.get('blocker_domain')} missing blocker id {expected_id}")
    if expected_check not in item.get("acceptance_check", ""):
        fail(f"{item.get('blocker_domain')} missing acceptance check")
    if item.get("may_consume_moonrobo_simulation"):
        fail(f"{item.get('blocker_domain')} must not consume MoonRobo simulation")
    if item.get("hardware_state") != "HardwareDenied":
        fail(f"{item.get('blocker_domain')} hardware must remain denied")
    if item.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail(f"{item.get('blocker_domain')} has unexpected hardware authority")
    if not item.get("hardware_denied"):
        fail(f"{item.get('blocker_domain')} must preserve hardware_denied")
    if "must not issue hardware authority" not in item.get("safety_gate", ""):
        fail(f"{item.get('blocker_domain')} safety gate must deny hardware")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonclaw_noetix_readiness_work_items.py WORK_ITEMS_JSON")

    items = json.loads(Path(sys.argv[1]).read_text())
    if not isinstance(items, list) or len(items) != 3:
        fail("expected three Noetix readiness work items")

    expected_ranks = [1, 2, 4]
    for index, item in enumerate(items):
        if item.get("rank") != expected_ranks[index]:
            fail("work item ranks must preserve source priority")
        if item.get("decision_id") != "moonclaw/first-trusted-square/noetix-simulation-readiness-decision":
            fail("unexpected decision id")
        if item.get("source_task_id") != "moonclaw/first-trusted-square/noetix-review-task":
            fail("unexpected source task id")
        if item.get("site_id") != "first-trusted-square":
            fail("unexpected site id")
        if item.get("robot_id") != "noetix-e1-lab-01":
            fail("unexpected robot id")

    require_item(
        item_by_domain(items, "source-metadata"),
        50,
        "missing-collision-shape:left_foot",
        "check_moonrobo_noetix_source_sync",
    )
    require_item(
        item_by_domain(items, "physical-model"),
        9,
        "assumed:mass",
        "check_moonrobo_noetix_stability",
    )
    if any(item.get("blocker_domain") == "world-replay" for item in items):
        fail("world replay item should be omitted after replay blockers clear")
    require_item(
        item_by_domain(items, "review-artifacts"),
        4,
        "noetix-joint-control-review",
        "check_moonclaw_noetix_review_task",
    )


if __name__ == "__main__":
    main()
