#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def close(actual: float, expected: float) -> bool:
    return abs(actual - expected) <= 1e-9


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_endless_gait.py EVIDENCE_JSON")

    evidence = json.loads(Path(sys.argv[1]).read_text())
    if evidence.get("evidence_id") != (
        "moonrobo/noetix-e1/endless-gait/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected evidence id")
    if evidence.get("trace_id") != (
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected trace id")
    if evidence.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if evidence.get("terrain_tile_id") != "first-trusted-square-northeast-stepout-lola":
        fail("unexpected terrain tile")
    if evidence.get("reference_frame_index") < 0:
        fail("reference frame must be nonnegative")
    if evidence.get("cycle_frames") != 32:
        fail("unexpected cycle length")
    if evidence.get("repeated_frame_index") != (
        evidence.get("reference_frame_index") + evidence.get("cycle_frames")
    ):
        fail("repeated frame must be one cycle after reference")
    if not close(evidence.get("dt_s", 0), 0.1):
        fail("unexpected dt")
    if not close(evidence.get("speed_mps", 0), 0.12):
        fail("unexpected speed")
    expected_offset = (
        evidence.get("cycle_frames", 0) *
        evidence.get("dt_s", 0) *
        evidence.get("speed_mps", 0)
    )
    if not close(evidence.get("expected_forward_offset_m", 0), expected_offset):
        fail("expected offset does not match cycle*dt*speed")
    if abs(
        evidence.get("observed_forward_offset_m", 0) -
        evidence.get("expected_forward_offset_m", 0)
    ) > 1e-6:
        fail("observed forward offset does not match expected offset")
    if evidence.get("reference_support_phase") != evidence.get("repeated_support_phase"):
        fail("support phase does not repeat")
    if not evidence.get("phase_repeat_verified"):
        fail("phase repeat must be verified")
    if not evidence.get("contact_repeat_verified"):
        fail("contact repeat must be verified")
    if not evidence.get("monotonic_forward_verified"):
        fail("monotonic forward motion must be verified")
    if evidence.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("hardware authority must remain denied")
    if evidence.get("status") != "endless-gait-window-verified":
        fail("unexpected status")
    if "simulation evidence only" not in evidence.get("note", ""):
        fail("note must keep hardware authority denied")


if __name__ == "__main__":
    main()
