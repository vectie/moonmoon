#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOONCLAW_OUT = ROOT / "output" / "moonclaw"


def load_json(path: Path):
    with path.open() as fh:
        return json.load(fh)


def require(condition: bool, message: str):
    if not condition:
        raise SystemExit(message)


def main() -> None:
    task_path = MOONCLAW_OUT / "first_trusted_square_remediation_margin_refresh_task.json"
    receipt_path = (
        MOONCLAW_OUT / "first_trusted_square_remediation_margin_refresh_receipt.json"
    )
    markdown_path = (
        MOONCLAW_OUT / "first_trusted_square_remediation_margin_refresh_receipt.md"
    )
    tasks = load_json(task_path)
    receipts = load_json(receipt_path)
    markdown = markdown_path.read_text()

    require(len(tasks) == 1, "expected one remediation margin refresh task")
    require(len(receipts) == 1, "expected one remediation margin refresh receipt")
    task = tasks[0]
    receipt = receipts[0]

    require(
        receipt["source_task_id"] == task["task_id"],
        "receipt source task does not match refresh task",
    )
    require(
        receipt["source_projection_id"] == task["source_projection_id"],
        "receipt source projection does not match refresh task",
    )
    require(
        receipt["refresh_state"] == "RefreshesCarriedForward",
        "refresh receipt should carry open refreshes forward",
    )
    require(receipt["refresh_action_count"] == 3, "expected 3 refresh actions")
    require(receipt["refreshed_count"] == 0, "expected 0 refreshed actions")
    require(receipt["still_blocking_count"] == 3, "expected 3 still-blocking actions")
    expected_margins = [
        "terrain-northeast-stepout",
        "illumination-northeast-stepout",
        "energy-window",
    ]
    require(
        receipt["ranked_margin_ids"] == expected_margins,
        "ranked refresh margins changed",
    )
    require(
        len(receipt["refresh_results"]) == len(task["refresh_actions"]),
        "refresh result count must match task actions",
    )
    task_actions = {action["refresh_id"]: action for action in task["refresh_actions"]}
    for result in receipt["refresh_results"]:
        action = task_actions.get(result["refresh_id"])
        require(action is not None, f"unknown refresh result {result['refresh_id']}")
        for key in (
            "rank",
            "margin_id",
            "source_projection_path",
            "target_artifact_path",
            "command",
            "acceptance_check",
        ):
            require(result[key] == action[key], f"{result['refresh_id']} changed {key}")
        require(
            result["status"] == "RefreshStillBlocking",
            f"{result['refresh_id']} should remain still blocking",
        )
        require(
            result["evidence_path"] == action["target_artifact_path"],
            f"{result['refresh_id']} evidence path should target refreshed artifact",
        )

    require(
        all(check["passed"] for check in receipt["validation_checks"]),
        "all refresh receipt validation checks must pass",
    )
    for key in ("hardware_state", "hardware_authority", "hardware_denied"):
        require(receipt[key] == task[key], f"{key} must match source task")
    require(receipt["hardware_state"] == "HardwareDenied", "hardware must stay denied")
    require(receipt["hardware_denied"] is True, "hardware_denied must stay true")

    required_markdown = [
        "MoonClaw Remediation Margin Refresh Receipts",
        "RefreshesCarriedForward",
        "still blocking: 3",
        "refresh-terrain-northeast-stepout",
        "refresh-illumination-northeast-stepout",
        "refresh-energy-window",
        "NoConsumeSimulationBlocked",
        "hardware-denied",
        "moonmoon-safety-gate-only",
    ]
    for token in required_markdown:
        require(token in markdown, f"receipt markdown missing {token}")

    print("moonclaw remediation margin refresh receipt ok")


if __name__ == "__main__":
    main()
