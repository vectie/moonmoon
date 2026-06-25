#!/usr/bin/env python3
"""Generate selected-route local horizon evidence from checked source data."""

from __future__ import annotations

import csv
import json
import math
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEM_SOURCE = (
    ROOT / "data" / "sources" / "lro_lola" / "first_trusted_square_northeast_stepout_dem.csv"
)
POWER_SOURCE = (
    ROOT / "data" / "sources" / "lunar_ephemeris" / "first_trusted_square_power_window.json"
)
TARGET = ROOT / "src" / "mission" / "generated_first_trusted_square_horizon.mbt"

CELL_SIZE_M = 20.0
ALTITUDE_RE = re.compile(r"sun altitude between ([\-0-9.]+) and ([\-0-9.]+) degrees")


def read_dem() -> list[list[float]]:
  with DEM_SOURCE.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))
  if not rows:
    raise SystemExit(f"{DEM_SOURCE.relative_to(ROOT)} has no cells")
  tile_ids = {row["tile_id"] for row in rows}
  if tile_ids != {"first-trusted-square-northeast-stepout-lola"}:
    raise SystemExit(f"{DEM_SOURCE.relative_to(ROOT)} must contain the selected route tile")
  max_row = max(int(row["row"]) for row in rows)
  max_col = max(int(row["col"]) for row in rows)
  grid: list[list[float | None]] = [
    [None for _ in range(max_col + 1)] for _ in range(max_row + 1)
  ]
  for row in rows:
    r = int(row["row"])
    c = int(row["col"])
    if grid[r][c] is not None:
      raise SystemExit(f"{DEM_SOURCE.relative_to(ROOT)} repeats cell row={r} col={c}")
    grid[r][c] = float(row["elevation_m"])
  if len(grid) != 4 or any(len(row) != 4 for row in grid):
    raise SystemExit(f"{DEM_SOURCE.relative_to(ROOT)} must be a 4x4 DEM")
  missing = [
    (r, c)
    for r, row in enumerate(grid)
    for c, value in enumerate(row)
    if value is None
  ]
  if missing:
    raise SystemExit(f"{DEM_SOURCE.relative_to(ROOT)} is missing cells: {missing}")
  return [[value or 0.0 for value in row] for row in grid]


def read_power_window() -> dict[str, Any]:
  with POWER_SOURCE.open(encoding="utf-8") as handle:
    evidence = json.load(handle)
  if evidence.get("source_status") != "ready":
    raise SystemExit(f"{POWER_SOURCE.relative_to(ROOT)} must be ready")
  if not evidence.get("has_time_window_ephemeris"):
    raise SystemExit(f"{POWER_SOURCE.relative_to(ROOT)} must include time-window ephemeris")
  return evidence


def sun_altitude_range(power: dict[str, Any]) -> tuple[float, float]:
  for reason in power["reasons"]:
    match = ALTITUDE_RE.search(reason)
    if match:
      return (float(match.group(1)), float(match.group(2)))
  raise SystemExit(f"{POWER_SOURCE.relative_to(ROOT)} does not record a sun-altitude range")


def center_elevation(grid: list[list[float]]) -> float:
  return (grid[1][1] + grid[1][2] + grid[2][1] + grid[2][2]) / 4.0


def max_horizon(grid: list[list[float]], center: float) -> tuple[float, float]:
  center_row = (len(grid) - 1) / 2.0
  center_col = (len(grid[0]) - 1) / 2.0
  max_angle = 0.0
  max_elevation = center
  for row_index, row in enumerate(grid):
    for col_index, elevation in enumerate(row):
      row_delta = (row_index - center_row) * CELL_SIZE_M
      col_delta = (col_index - center_col) * CELL_SIZE_M
      distance = math.hypot(row_delta, col_delta)
      if distance <= 0.0:
        continue
      obstruction = elevation - center
      angle = math.degrees(math.atan2(max(0.0, obstruction), distance))
      if angle > max_angle:
        max_angle = angle
        max_elevation = elevation
  return (max_angle, max_elevation)


def model() -> dict[str, Any]:
  grid = read_dem()
  power = read_power_window()
  min_sun, max_sun = sun_altitude_range(power)
  center = center_elevation(grid)
  horizon_angle, obstruction_elevation = max_horizon(grid, center)
  margin = horizon_angle - max_sun
  decision = "Block" if margin > 0.0 else "Review"
  reasons = [
    (
      f"bounded 4x4 LOLA horizon angle {horizon_angle:.6f} deg exceeds "
      f"maximum sampled sun altitude {max_sun:.6f} deg"
    ),
    (
      f"terrain-shadow margin is {margin:.6f} deg from "
      f"{DEM_SOURCE.relative_to(ROOT)}"
    ),
    "zero-horizon power window remains insufficient for local terrain-shadow clearance",
  ]
  return {
    "evidence_id": "first-trusted-square-northeast-stepout-local-horizon-v1",
    "route_id": "northeast-stepout",
    "site_id": "first-trusted-square",
    "source_dataset_id": "lro-lola-first-trusted-square-northeast-stepout-dem-v1",
    "source_tile_id": "first-trusted-square-northeast-stepout-lola",
    "source_path": str(DEM_SOURCE.relative_to(ROOT)),
    "power_window_evidence_id": power["evidence_id"],
    "power_window_source_path": str(POWER_SOURCE.relative_to(ROOT)),
    "output_path": "output/mission/first_trusted_square_northeast_stepout_horizon.json",
    "method_id": "bounded-local-horizon-v1",
    "generated_by": "scripts/generate_selected_route_horizon.py",
    "rows": len(grid),
    "cols": len(grid[0]),
    "cell_size_m": CELL_SIZE_M,
    "center_elevation_m": center,
    "max_obstruction_elevation_m": obstruction_elevation,
    "max_horizon_angle_deg": horizon_angle,
    "min_sun_altitude_deg": min_sun,
    "max_sun_altitude_deg": max_sun,
    "terrain_shadow_margin_deg": margin,
    "confidence": 0.66,
    "decision": decision,
    "reasons": reasons,
    "next_action": (
      "collect wider local horizon and terrain-shadow evidence before route simulation"
    ),
  }


def moon_string(value: str) -> str:
  return value.replace("\\", "\\\\").replace('"', '\\"')


def moon_number(value: int | float) -> str:
  return f"{float(value):.6f}"


def moon_decision(value: str) -> str:
  if value not in {"Allow", "Review", "Block"}:
    raise SystemExit(f"unsupported decision {value!r}")
  return value


def render() -> str:
  evidence = model()
  reasons = "\n".join(
    f'      "{moon_string(reason)}",' for reason in evidence["reasons"]
  )
  return f'''///| Generated from {DEM_SOURCE.relative_to(ROOT)} by scripts/generate_selected_route_horizon.py.

///|
/// Do not edit this file by hand.
fn generated_first_trusted_square_northeast_stepout_horizon_evidence() -> LocalHorizonEvidence {{
  {{
    evidence_id: "{moon_string(evidence["evidence_id"])}",
    route_id: "{moon_string(evidence["route_id"])}",
    site_id: "{moon_string(evidence["site_id"])}",
    source_dataset_id: "{moon_string(evidence["source_dataset_id"])}",
    source_tile_id: "{moon_string(evidence["source_tile_id"])}",
    source_path: "{moon_string(evidence["source_path"])}",
    power_window_evidence_id: "{moon_string(evidence["power_window_evidence_id"])}",
    power_window_source_path: "{moon_string(evidence["power_window_source_path"])}",
    output_path: "{moon_string(evidence["output_path"])}",
    method_id: "{moon_string(evidence["method_id"])}",
    generated_by: "{moon_string(evidence["generated_by"])}",
    rows: {evidence["rows"]},
    cols: {evidence["cols"]},
    cell_size_m: {moon_number(evidence["cell_size_m"])},
    center_elevation_m: {moon_number(evidence["center_elevation_m"])},
    max_obstruction_elevation_m: {moon_number(evidence["max_obstruction_elevation_m"])},
    max_horizon_angle_deg: {moon_number(evidence["max_horizon_angle_deg"])},
    min_sun_altitude_deg: {moon_number(evidence["min_sun_altitude_deg"])},
    max_sun_altitude_deg: {moon_number(evidence["max_sun_altitude_deg"])},
    terrain_shadow_margin_deg: {moon_number(evidence["terrain_shadow_margin_deg"])},
    confidence: {moon_number(evidence["confidence"])},
    decision: {moon_decision(evidence["decision"])},
    reasons: [
{reasons}
    ],
    next_action: "{moon_string(evidence["next_action"])}",
  }}
}}
'''


def main() -> int:
  check_only = len(sys.argv) == 2 and sys.argv[1] == "--check"
  if len(sys.argv) > 2 or (len(sys.argv) == 2 and not check_only):
    raise SystemExit("usage: generate_selected_route_horizon.py [--check]")
  content = render()
  if check_only:
    current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
    if current != content:
      raise SystemExit(
        f"{TARGET.relative_to(ROOT)} is stale; run python3 scripts/generate_selected_route_horizon.py"
      )
    print(f"checked {TARGET.relative_to(ROOT)} from {DEM_SOURCE.relative_to(ROOT)}")
  else:
    TARGET.write_text(content, encoding="utf-8")
    print(f"generated {TARGET.relative_to(ROOT)} from {DEM_SOURCE.relative_to(ROOT)}")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
