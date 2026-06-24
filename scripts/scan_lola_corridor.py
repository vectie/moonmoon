#!/usr/bin/env python3
"""Scan the first trusted square corridor with tiny LOLA byte-range windows."""

from __future__ import annotations

import argparse
import csv
import io
import sys
from pathlib import Path

sys.dont_write_bytecode = True

import extract_lola_trusted_square as extractor


ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "data" / "sources" / "lro_lola" / "first_trusted_square_corridor_scan.csv"
DEFAULT_RADIUS = 8
DEFAULT_STEP = 4
DEFAULT_SCAN_ID = "first-trusted-square-5x5-corridor-scan-v1"
ROUTE_IDS = {
    (0, 0): "direct-lola-window",
    (0, -4): "west-contour-detour",
    (-4, 0): "north-rim-stepout",
    (8, -8): "southwest-bypass",
    (8, 0): "south-stepout",
}


def metrics_from_content(content: str) -> dict[str, float]:
    rows = list(csv.DictReader(io.StringIO(content)))
    max_row = max(int(row["row"]) for row in rows)
    max_col = max(int(row["col"]) for row in rows)
    grid = [[0.0 for _ in range(max_col + 1)] for _ in range(max_row + 1)]
    for row in rows:
        grid[int(row["row"])][int(row["col"])] = float(row["elevation_m"])
    values = [value for line in grid for value in line]
    pairs: list[tuple[float, float]] = []
    for r in range(max_row + 1):
        for c in range(max_col + 1):
            if c + 1 <= max_col:
                pairs.append((grid[r][c], grid[r][c + 1]))
            if r + 1 <= max_row:
                pairs.append((grid[r][c], grid[r + 1][c]))
    deltas = [abs(a - b) for a, b in pairs]
    return {
        "min_elevation_m": min(values),
        "max_elevation_m": max(values),
        "elevation_range_m": max(values) - min(values),
        "max_neighbor_grade": max(deltas) / extractor.read_label_grid().pixel_resolution_m,
        "roughness_m": sum(deltas) / len(deltas),
    }


def hazard(max_neighbor_grade: float, roughness_m: float) -> str:
    if max_neighbor_grade >= 0.35 or roughness_m >= 2.5:
        return "blocked"
    if max_neighbor_grade >= 0.18 or roughness_m >= 1.2:
        return "caution"
    return "clear"


def scan_shape_label(offsets: list[int]) -> str:
    side = len(offsets)
    return f"{side}x{side}"


def scan_id_for(radius: int, step: int) -> str:
    if radius == DEFAULT_RADIUS and step == DEFAULT_STEP:
        return DEFAULT_SCAN_ID
    side = radius // step * 2 + 1
    return f"first-trusted-square-{side}x{side}-corridor-scan-v2"


def offsets_for(radius: int, step: int) -> list[int]:
    if radius < 0:
        raise SystemExit("--radius must be non-negative")
    if step <= 0:
        raise SystemExit("--step must be positive")
    if radius % step != 0:
        raise SystemExit("--radius must be divisible by --step")
    return list(range(-radius, radius + step, step))


def render_plan(*, radius: int, step: int, scan_id: str | None = None) -> str:
    offsets = offsets_for(radius, step)
    resolved_scan_id = scan_id if scan_id is not None else scan_id_for(radius, step)
    return (
        f"scan_id: {resolved_scan_id}\n"
        f"shape: {scan_shape_label(offsets)}\n"
        f"radius: {radius}\n"
        f"step: {step}\n"
        f"windows: {len(offsets) * len(offsets)}\n"
        f"offsets: {', '.join(str(offset) for offset in offsets)}\n"
    )


def note(rank: int, route_id: str, shape_label: str) -> str:
    if rank == 1:
        return f"lowest max-neighbor-grade window in this measured {shape_label} scan; still blocked"
    if route_id:
        return "promoted route evidence window; still blocked"
    return "measured scan window; not promoted as a route candidate"


def render(
    raw_path: Path | None = None,
    *,
    radius: int = DEFAULT_RADIUS,
    step: int = DEFAULT_STEP,
    scan_id: str | None = None,
) -> str:
    grid = extractor.read_label_grid()
    base_row, base_col = extractor.centered_window(grid)
    offsets = offsets_for(radius, step)
    shape_label = scan_shape_label(offsets)
    resolved_scan_id = scan_id if scan_id is not None else scan_id_for(radius, step)
    rows = []
    for row_offset in offsets:
        for col_offset in offsets:
            window_id = f"r{row_offset:+d}-c{col_offset:+d}"
            window = extractor.ExtractionWindow(
                tile_id=f"first-trusted-square-scan-{window_id}",
                target=ROOT / "unused.csv",
                row_offset=row_offset,
                col_offset=col_offset,
            )
            content = extractor.extract_window(window, raw_path)
            metrics = metrics_from_content(content)
            route_id = ROUTE_IDS.get((row_offset, col_offset), "")
            rows.append({
                "scan_id": resolved_scan_id,
                "window_id": window_id,
                "rank": 0,
                "row_offset": row_offset,
                "col_offset": col_offset,
                "source_row_start": base_row + row_offset,
                "source_col_start": base_col + col_offset,
                "min_elevation_m": metrics["min_elevation_m"],
                "max_elevation_m": metrics["max_elevation_m"],
                "elevation_range_m": metrics["elevation_range_m"],
                "max_neighbor_grade": metrics["max_neighbor_grade"],
                "roughness_m": metrics["roughness_m"],
                "hazard": hazard(metrics["max_neighbor_grade"], metrics["roughness_m"]),
                "selected_route_id": route_id,
            })
    rows.sort(key=lambda row: (row["max_neighbor_grade"], row["roughness_m"], row["window_id"]))
    for index, row in enumerate(rows, start=1):
        row["rank"] = index
        row["note"] = note(index, row["selected_route_id"], shape_label)

    output = io.StringIO()
    fieldnames = [
        "scan_id",
        "window_id",
        "rank",
        "row_offset",
        "col_offset",
        "source_row_start",
        "source_col_start",
        "min_elevation_m",
        "max_elevation_m",
        "elevation_range_m",
        "max_neighbor_grade",
        "roughness_m",
        "hazard",
        "selected_route_id",
        "note",
    ]
    writer = csv.DictWriter(output, fieldnames=fieldnames, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        formatted = row.copy()
        for key in [
            "min_elevation_m",
            "max_elevation_m",
            "elevation_range_m",
            "max_neighbor_grade",
            "roughness_m",
        ]:
            formatted[key] = f"{row[key]:.6f}"
        writer.writerow(formatted)
    return output.getvalue()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify the generated scan CSV is current")
    parser.add_argument("--plan", action="store_true", help="print scan shape without reading source bytes")
    parser.add_argument("--raw-img", type=Path, help="optional local raw IMG path")
    parser.add_argument("--radius", type=int, default=DEFAULT_RADIUS, help="scan radius in raster cells")
    parser.add_argument("--step", type=int, default=DEFAULT_STEP, help="scan stride in raster cells")
    parser.add_argument("--scan-id", help="override generated scan id")
    args = parser.parse_args()

    if args.plan:
        print(render_plan(radius=args.radius, step=args.step, scan_id=args.scan_id), end="")
        return

    content = render(args.raw_img, radius=args.radius, step=args.step, scan_id=args.scan_id)
    if args.check:
        current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
        if current != content:
            raise SystemExit(
                f"{TARGET.relative_to(ROOT)} is stale; run python3 scripts/scan_lola_corridor.py"
            )
        print(f"checked {TARGET.relative_to(ROOT)} from selected LOLA byte ranges")
    else:
        TARGET.write_text(content, encoding="utf-8")
        print(f"wrote {TARGET.relative_to(ROOT)} from selected LOLA byte ranges")


if __name__ == "__main__":
    main()
