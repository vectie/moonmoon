#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_dynamics.py REPORT_JSON")

    report = json.loads(Path(sys.argv[1]).read_text())
    frames = report.get("frames", [])
    profile = report.get("profile", {})

    if report.get("report_id") != (
        "moonrobo/noetix-e1/dynamic-stability/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected report_id")
    if not report.get("trace_id", "").startswith(
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
    ):
        fail("unexpected trace_id")
    if report.get("source_static_support_report_id") != (
        "moonrobo/noetix-e1/static-support/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected static support source")
    if profile.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if report.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("hardware authority must remain denied")
    if profile.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("profile hardware authority must remain denied")
    if report.get("frame_count") != len(frames) or len(frames) < 24:
        fail("frame count is inconsistent or too small")
    if report.get("status") != "dynamic-stability-review":
        fail("dynamic report should remain review-only")
    if report.get("review_frame_count", 0) <= 0:
        fail("expected dynamic review frames")
    if report.get("capture_stable_frame_count", -1) + report.get("review_frame_count", -1) != len(frames):
        fail("stable/review counts do not sum to frame count")
    if report.get("worst_capture_margin_m", 0) >= 0:
        fail("expected negative capture margin")
    if "no controller" not in report.get("note", ""):
        fail("report note must preserve controller limitation")

    first = frames[0]
    assessment = first.get("capture_point_assessment", {})
    if first.get("status") not in {"capture-point-review", "terrain-contact-review"}:
        fail("first frame should expose capture or terrain review status")
    if first.get("terrain_contact_status") != "terrain-contact-review":
        fail("terrain contact review must carry through")
    if first.get("com_velocity", {}).get("x", 0) <= 0:
        fail("COM velocity should move forward")
    if assessment.get("omega_rad_s", 0) <= 0:
        fail("capture point omega should be positive")
    if assessment.get("capture_point", {}).get("x", 0) <= first.get("com_position", {}).get("x", 0):
        fail("forward walking capture point should lead COM")
    if assessment.get("support_assessment", {}).get("support_count") != 1:
        fail("first frame should have one active support foot")
    if assessment.get("support_assessment", {}).get("stable") is not True:
        fail("support-aware body shift should stabilize the first capture point")
    if assessment.get("capture_margin_m", 0) <= 0:
        fail("first frame should expose positive capture margin after body shift")
    if not any(
        frame.get("capture_point_assessment", {}).get("status") == "capture-point-outside-support"
        for frame in frames
    ):
        fail("expected at least one outside-support capture point")


if __name__ == "__main__":
    main()
