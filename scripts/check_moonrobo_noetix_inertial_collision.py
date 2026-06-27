#!/usr/bin/env python3
"""Validate Noetix inertial/collision review evidence."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


EXPECTED_REPORT = (
  "moonrobo/noetix-e1/inertial-collision/"
  "first-trusted-square-northeast-stepout-lola"
)
EXPECTED_TRACE = (
  "moonrobo/noetix-e1/endless-forward-moon-walk/"
  "first-trusted-square-northeast-stepout-lola"
)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise AssertionError(message)


def load(path: Path) -> dict[str, Any]:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def main(argv: list[str]) -> int:
  if len(argv) != 2:
    print("usage: check_moonrobo_noetix_inertial_collision.py REPORT.json", file=sys.stderr)
    return 2

  report = load(Path(argv[1]))
  require(report["report_id"] == EXPECTED_REPORT, report["report_id"])
  require(report["trace_id"] == EXPECTED_TRACE, report["trace_id"])
  require(report["profile"]["robot_id"] == "noetix-e1-lab-01", "robot id")
  require(
    report["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority",
  )
  require(report["frame_count"] > 0, "missing frames")
  require(report["shapes_per_frame"] >= 6, "missing collision shapes")
  require(
    "inertial-collision" in report["status"],
    f"unexpected status {report['status']}",
  )
  require("not authoritative" in report["note"], "missing authority note")
  require("Moonphys diagonal inertia" in report["note"], "missing inertia note")
  require(report["max_support_contact_torque_nm"] > 0, "missing support torque")
  require(report["max_self_penetration_m"] >= 0, "bad self penetration")

  frames = report["frames"]
  require(len(frames) == report["frame_count"], "frame count mismatch")
  first = frames[0]
  require(first["shape_count"] == report["shapes_per_frame"], "shape count mismatch")
  require(first["inertia"]["body_id"].endswith("assumed-diagonal-inertia"), "inertia id")
  require(first["inertia"]["diagonal_kg_m2"]["x"] > 0, "inertia x")
  require(len(first["terrain_collisions"]) == 2, "terrain foot probes")
  require(
    all(
      item["status"] == "terrain-collision-matches-walk-contact"
      for item in first["terrain_collisions"]
    ),
    "terrain contact mismatch",
  )
  require(
    any(
      shape["link_name"] == "chest_link"
      and shape["bounds"]["status"] == "conservative-bounds"
      for shape in first["shapes"]
    ),
    "missing chest collision bounds",
  )
  require(
    any(
      shape["link_name"] == "left_foot"
      and shape["shape"]["kind"] == "BoxShape"
      for shape in first["shapes"]
    ),
    "missing foot collision shape",
  )
  require(
    first["self_contact_manifold"]["contacts"],
    "missing self-contact contact set",
  )
  require(
    report["self_contact_frame_count"] >= 0
    and report["terrain_review_frame_count"] >= 0,
    "bad review counts",
  )
  return 0


if __name__ == "__main__":
  raise SystemExit(main(sys.argv))
