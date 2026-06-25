#!/usr/bin/env python3
"""Extract a tiny first-trusted-square CSV from the selected LOLA GDR IMG.

The raw IMG is about 230 MB. This script reads only the required byte ranges
from the official PDS URL unless a local raw image path is provided.
"""

from __future__ import annotations

import argparse
import math
import struct
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LABEL = ROOT / "data" / "sources" / "lro_lola" / "ldem_875s_20m_float.xml"
IMAGE_URL = "https://pds-geosciences.wustl.edu/lro/lro-l-lola-3-rdr-v1/lrolol_1xxx/data/lola_gdr/polar/float_img/ldem_875s_20m_float.img"

SITE_CENTER_LAT_DEG = -89.88
SITE_CENTER_LON_DEG = 0.12
WINDOW_ROWS = 4
WINDOW_COLS = 4
TILE_ID = "first-trusted-square-lola"


@dataclass(frozen=True)
class ExtractionWindow:
    tile_id: str
    target: Path
    row_offset: int
    col_offset: int


WINDOWS = [
    ExtractionWindow(
        tile_id=TILE_ID,
        target=ROOT / "data" / "sources" / "lro_lola" / "first_trusted_square_dem.csv",
        row_offset=0,
        col_offset=0,
    ),
    ExtractionWindow(
        tile_id="first-trusted-square-west-contour-lola",
        target=ROOT
        / "data"
        / "sources"
        / "lro_lola"
        / "first_trusted_square_west_contour_dem.csv",
        row_offset=0,
        col_offset=-WINDOW_COLS,
    ),
    ExtractionWindow(
        tile_id="first-trusted-square-north-rim-lola",
        target=ROOT
        / "data"
        / "sources"
        / "lro_lola"
        / "first_trusted_square_north_rim_dem.csv",
        row_offset=-WINDOW_ROWS,
        col_offset=0,
    ),
    ExtractionWindow(
        tile_id="first-trusted-square-southwest-bypass-lola",
        target=ROOT
        / "data"
        / "sources"
        / "lro_lola"
        / "first_trusted_square_southwest_bypass_dem.csv",
        row_offset=WINDOW_ROWS * 2,
        col_offset=-WINDOW_COLS * 2,
    ),
    ExtractionWindow(
        tile_id="first-trusted-square-south-stepout-lola",
        target=ROOT
        / "data"
        / "sources"
        / "lro_lola"
        / "first_trusted_square_south_stepout_dem.csv",
        row_offset=WINDOW_ROWS * 2,
        col_offset=0,
    ),
    ExtractionWindow(
        tile_id="first-trusted-square-northeast-stepout-lola",
        target=ROOT
        / "data"
        / "sources"
        / "lro_lola"
        / "first_trusted_square_northeast_stepout_dem.csv",
        row_offset=-WINDOW_ROWS * 3,
        col_offset=WINDOW_COLS * 4,
    ),
]


@dataclass(frozen=True)
class LabelGrid:
    lines: int
    samples: int
    pixel_resolution_m: float
    upper_left_x_m: float
    upper_left_y_m: float
    radius_m: float


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def first_text(root: ET.Element, name: str) -> str:
    for element in root.iter():
        if local_name(element.tag) == name and element.text is not None:
            return element.text.strip()
    raise SystemExit(f"{LABEL.relative_to(ROOT)} is missing <{name}>")


def axis_elements(root: ET.Element) -> dict[str, int]:
    axes: dict[str, int] = {}
    for axis in root.iter():
        if local_name(axis.tag) != "Axis_Array":
            continue
        name = None
        elements = None
        for child in axis:
            if local_name(child.tag) == "axis_name" and child.text is not None:
                name = child.text.strip()
            if local_name(child.tag) == "elements" and child.text is not None:
                elements = int(child.text.strip())
        if name is not None and elements is not None:
            axes[name] = elements
    return axes


def read_label_grid() -> LabelGrid:
    root = ET.parse(LABEL).getroot()
    axes = axis_elements(root)
    return LabelGrid(
        lines=axes["Line"],
        samples=axes["Sample"],
        pixel_resolution_m=float(first_text(root, "pixel_resolution_x")),
        upper_left_x_m=float(first_text(root, "upperleft_corner_x")),
        upper_left_y_m=float(first_text(root, "upperleft_corner_y")),
        radius_m=float(first_text(root, "a_axis_radius")) * 1000.0,
    )


def project_south_polar(lat_deg: float, lon_deg: float, radius_m: float) -> tuple[float, float]:
    lat = math.radians(lat_deg)
    lon = math.radians(lon_deg)
    rho = 2.0 * radius_m * math.tan(math.pi / 4.0 + lat / 2.0)
    return rho * math.sin(lon), -rho * math.cos(lon)


def centered_window(grid: LabelGrid) -> tuple[int, int]:
    x, y = project_south_polar(SITE_CENTER_LAT_DEG, SITE_CENTER_LON_DEG, grid.radius_m)
    row_center = (grid.upper_left_y_m - y) / grid.pixel_resolution_m
    col_center = (x - grid.upper_left_x_m) / grid.pixel_resolution_m
    row_start = round(row_center) - WINDOW_ROWS // 2
    col_start = round(col_center) - WINDOW_COLS // 2
    if row_start < 0 or col_start < 0:
        raise SystemExit("computed extraction window starts outside the raster")
    if row_start + WINDOW_ROWS > grid.lines or col_start + WINDOW_COLS > grid.samples:
        raise SystemExit("computed extraction window ends outside the raster")
    return row_start, col_start


def read_row_from_local(raw_path: Path, row: int, col_start: int, col_count: int, samples: int) -> bytes:
    offset = (row * samples + col_start) * 4
    with raw_path.open("rb") as handle:
        handle.seek(offset)
        data = handle.read(col_count * 4)
    if len(data) != col_count * 4:
        raise SystemExit(f"{raw_path} ended before row={row} col={col_start}")
    return data


def read_row_from_url(row: int, col_start: int, col_count: int, samples: int) -> bytes:
    offset = (row * samples + col_start) * 4
    end = offset + col_count * 4 - 1
    request = urllib.request.Request(IMAGE_URL, headers={"Range": f"bytes={offset}-{end}"})
    with urllib.request.urlopen(request, timeout=30) as response:
        data = response.read()
    if len(data) != col_count * 4:
        raise SystemExit(
            f"expected {col_count * 4} bytes for row={row}, got {len(data)}"
        )
    return data


def extract_window(window: ExtractionWindow, raw_path: Path | None = None) -> str:
    grid = read_label_grid()
    row_start, col_start = centered_window(grid)
    row_start += window.row_offset
    col_start += window.col_offset
    if row_start < 0 or col_start < 0:
        raise SystemExit(f"{window.tile_id} starts outside the raster")
    if row_start + WINDOW_ROWS > grid.lines or col_start + WINDOW_COLS > grid.samples:
        raise SystemExit(f"{window.tile_id} ends outside the raster")
    rows: list[list[float]] = []
    for row in range(row_start, row_start + WINDOW_ROWS):
        if raw_path is None:
            data = read_row_from_url(row, col_start, WINDOW_COLS, grid.samples)
        else:
            data = read_row_from_local(raw_path, row, col_start, WINDOW_COLS, grid.samples)
        rows.append([value * 1000.0 for value in struct.unpack("<" + "f" * WINDOW_COLS, data)])

    lines = ["tile_id,row,col,elevation_m"]
    for row_index, values in enumerate(rows):
        for col_index, value in enumerate(values):
            lines.append(f"{window.tile_id},{row_index},{col_index},{value:.3f}")
    return "\n".join(lines) + "\n"


def selected_windows(only: str | None) -> list[ExtractionWindow]:
    if only is None:
        return WINDOWS
    matches = [window for window in WINDOWS if window.tile_id == only]
    if not matches:
        names = ", ".join(window.tile_id for window in WINDOWS)
        raise SystemExit(f"unknown --tile-id {only!r}; choose one of: {names}")
    return matches


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify the generated CSV is current")
    parser.add_argument("--raw-img", type=Path, help="optional local raw IMG path")
    parser.add_argument("--tile-id", help="optional single tile id to extract or check")
    args = parser.parse_args()

    for window in selected_windows(args.tile_id):
        content = extract_window(window, args.raw_img)
        if args.check:
            current = window.target.read_text(encoding="utf-8") if window.target.exists() else ""
            if current != content:
                raise SystemExit(
                    f"{window.target.relative_to(ROOT)} is stale; run python3 scripts/extract_lola_trusted_square.py"
                )
            print(f"checked {window.target.relative_to(ROOT)} from selected LOLA byte ranges")
        else:
            window.target.write_text(content, encoding="utf-8")
            print(f"wrote {window.target.relative_to(ROOT)} from selected LOLA byte ranges")


if __name__ == "__main__":
    main()
