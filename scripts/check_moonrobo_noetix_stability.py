#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: check_moonrobo_noetix_stability.py REPORT_JSON")

    path = Path(sys.argv[1])
    report = json.loads(path.read_text())
    frames = report.get("frames", [])
    profile = report.get("profile", {})
    mass_model = profile.get("mass_model", {})
    foot_geometry = profile.get("foot_geometry", [])

    if report.get("report_id") != (
        "moonrobo/noetix-e1/static-support/"
        "first-trusted-square-northeast-stepout-lola"
    ):
        fail("unexpected report_id")
    if not report.get("trace_id", "").startswith(
        "moonrobo/noetix-e1/endless-forward-moon-walk/"
    ):
        fail("unexpected trace_id")
    if profile.get("robot_id") != "noetix-e1-lab-01":
        fail("unexpected robot id")
    if profile.get("hardware_authority") != "moonmoon-safety-gate-only":
        fail("hardware authority must remain denied")
    if "simulation-assumption" not in mass_model.get("source_status", ""):
        fail("mass model must be marked as an assumption")
    if mass_model.get("mass_kg", 0) <= 0:
        fail("mass must be positive")
    if len(foot_geometry) != 2:
        fail("expected left and right foot geometry")
    if any("simulation-assumption" not in foot.get("source_status", "") for foot in foot_geometry):
        fail("foot geometry must be marked as an assumption")
    if report.get("frame_count") != len(frames) or len(frames) < 24:
        fail("frame count is inconsistent or too small")
    if report.get("status") != "static-support-review":
        fail("report should remain review-only")
    if report.get("review_frame_count", 0) <= 0:
        fail("expected review frames")
    if report.get("stable_frame_count", -1) + report.get("review_frame_count", -1) != len(frames):
        fail("stable/review counts do not sum to frame count")
    if report.get("worst_planar_margin_m", 0) >= 0:
        fail("expected negative static support margin")
    if not any(frame.get("status") == "static-margin-review" for frame in frames):
        fail("expected static-margin-review frame")
    first = frames[0]
    if first.get("support_assessment", {}).get("support_count") != 1:
        fail("first frame should have one active support foot")
    if first.get("terrain_contact_status") != "terrain-contact-review":
        fail("terrain contact review must carry through")
    if "dynamic walking can be valid" not in report.get("note", ""):
        fail("report note must distinguish static evidence from dynamics")


if __name__ == "__main__":
    main()
