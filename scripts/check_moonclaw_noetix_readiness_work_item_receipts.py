#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def receipt_by_domain(receipts: list[dict], domain: str) -> dict:
    for receipt in receipts:
        result = receipt.get("work_item_result", {})
        if result.get("blocker_domain") == domain:
            return receipt
    fail(f"missing receipt domain {domain}")


def require_receipt(
    receipt: dict,
    count: int,
    expected_id: str,
    expected_check: str,
) -> None:
    result = receipt.get("work_item_result", {})
    domain = result.get("blocker_domain")
    envelope = receipt.get("receipt", {})
    if envelope.get("status") != "Accepted":
        fail(f"{domain} receipt must be Accepted")
    if receipt.get("source_work_item_state") != "NeedsReview":
        fail(f"{domain} source work item must remain NeedsReview")
    if receipt.get("result_state") != "NoetixReadinessWorkItemsCarriedForward":
        fail(f"{domain} must be carried forward")
    if result.get("status") != "NoetixReadinessWorkItemPendingEvidence":
        fail(f"{domain} must remain pending evidence")
    if result.get("blocker_count") != count:
        fail(f"{domain} blocker count drifted")
    blocker_ids = result.get("blocker_ids")
    if not isinstance(blocker_ids, list) or len(blocker_ids) != count:
        fail(f"{domain} blocker ids must match count")
    if expected_id not in blocker_ids:
        fail(f"{domain} missing blocker id {expected_id}")
    if expected_check not in result.get("acceptance_check", ""):
        fail(f"{domain} missing acceptance check")
    if receipt.get("may_consume_simulation"):
        fail(f"{domain} must not consume simulation")
    if receipt.get("may_consume_moonrobo_simulation"):
        fail(f"{domain} must not consume MoonRobo simulation")
    if receipt.get("simulation_state") != "SimulationBlocked":
        fail(f"{domain} simulation must remain blocked")
    if receipt.get("hardware_state") != "HardwareDenied":
        fail(f"{domain} hardware must remain denied")
    if receipt.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail(f"{domain} has unexpected hardware authority")
    if receipt.get("hardware_authority_change"):
        fail(f"{domain} must not change hardware authority")
    if not receipt.get("hardware_denied"):
        fail(f"{domain} must preserve hardware_denied")
    validations = receipt.get("validation_checks")
    if not isinstance(validations, list) or not validations:
        fail(f"{domain} missing validation checks")
    if not all(check.get("passed") for check in validations):
        fail(f"{domain} validation checks must pass")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonclaw_noetix_readiness_work_item_receipts.py RECEIPTS_JSON")

    receipts = json.loads(Path(sys.argv[1]).read_text())
    if not isinstance(receipts, list) or len(receipts) != 2:
        fail("expected two Noetix readiness work item receipts")

    for receipt in receipts:
        if receipt.get("source_decision_id") != "moonclaw/first-trusted-square/noetix-simulation-readiness-decision":
            fail("unexpected decision id")
        if receipt.get("source_task_id") != "moonclaw/first-trusted-square/noetix-review-task":
            fail("unexpected source task id")
        if receipt.get("site_id") != "first-trusted-square":
            fail("unexpected site id")
        if receipt.get("robot_id") != "noetix-e1-lab-01":
            fail("unexpected robot id")

    require_receipt(
        receipt_by_domain(receipts, "source-metadata"),
        50,
        "missing-collision-shape:left_foot",
        "check_moonrobo_noetix_source_sync",
    )
    source = receipt_by_domain(receipts, "source-metadata").get("work_item_result", {})
    if "source_metadata_gaps" not in source.get("required_evidence", ""):
        fail("source-metadata receipt must target the source_metadata_gaps inventory")
    if "source_metadata_gaps" not in source.get("next_action", ""):
        fail("source-metadata receipt next action must name the gap inventory")
    require_receipt(
        receipt_by_domain(receipts, "physical-model"),
        9,
        "assumed:mass",
        "check_moonrobo_noetix_stability",
    )
    physical = receipt_by_domain(receipts, "physical-model").get("work_item_result", {})
    if "physical_model_gaps" not in physical.get("required_evidence", ""):
        fail("physical-model receipt must target the physical_model_gaps inventory")
    if "physical_model_gaps" not in physical.get("next_action", ""):
        fail("physical-model receipt next action must name the gap inventory")
    if any(
        receipt.get("work_item_result", {}).get("blocker_domain") == "world-replay"
        for receipt in receipts
    ):
        fail("world replay receipt should be omitted after replay blockers clear")
    if any(
        receipt.get("work_item_result", {}).get("blocker_domain") == "review-artifacts"
        for receipt in receipts
    ):
        fail("review artifact receipt should be omitted after all review artifacts clear")


if __name__ == "__main__":
    main()
