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
    if not close(evidence.get("cycle_forward_offset_m", 0), expected_offset):
        fail("cycle forward offset does not match cycle*dt*speed")
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
    if not evidence.get("multi_cycle_verified"):
        fail("multi-cycle endless samples must be verified")
    samples = evidence.get("samples")
    if not isinstance(samples, list):
        fail("endless gait samples must be listed")
    if evidence.get("sample_count") != len(samples) or len(samples) != 4:
        fail("unexpected endless gait sample count")
    if evidence.get("sample_cycle_count") != 4:
        fail("unexpected endless gait sample cycle count")
    for index, sample in enumerate(samples, start=1):
        if sample.get("cycle_index") != index:
            fail("sample cycle index must be relative to the reference frame")
        if sample.get("frame_index") != evidence.get("reference_frame_index") + index * evidence.get("cycle_frames"):
            fail("sample frame index must advance by whole cycles")
        if sample.get("phase_index") != evidence.get("reference_frame_index"):
            fail("sample phase index must match the reference phase")
        if sample.get("support_phase") != evidence.get("reference_support_phase"):
            fail("sample support phase must match the reference")
        if not sample.get("left_contact") or not sample.get("right_contact"):
            fail("default sampled reference phase should remain double support")
        if not sample.get("phase_matches_reference"):
            fail("sample phase must be verified")
        if not sample.get("contact_matches_reference"):
            fail("sample contact must be verified")
        if not sample.get("forward_offset_matches_expected"):
            fail("sample forward offset must be verified")
        expected_sample_offset = expected_offset * index
        if abs(sample.get("body_forward_offset_m", 0) - expected_sample_offset) > 1e-6:
            fail("sample body offset does not match expected cycle offset")
        if abs(sample.get("expected_forward_offset_m", 0) - expected_sample_offset) > 1e-9:
            fail("sample expected offset does not match relative cycle")
    if evidence.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("hardware authority must remain denied")
    if evidence.get("status") != "endless-gait-window-verified":
        fail("unexpected status")
    if "simulation evidence only" not in evidence.get("note", ""):
        fail("note must keep hardware authority denied")


if __name__ == "__main__":
    main()
