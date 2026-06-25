#!/usr/bin/env python3
"""Compute the first trusted square power window from the pinned SPK files."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import struct
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "data"
    / "sources"
    / "lunar_ephemeris"
    / "first_trusted_square_power_window.json"
)
SPK = ROOT / "data" / "sources" / "lunar_ephemeris" / "kernels" / "de440s.bsp"

J2000_UTC = dt.datetime(2000, 1, 1, 12, tzinfo=dt.timezone.utc)
TIME_START_UTC = "2026-06-25T00:00:00Z"
TIME_END_UTC = "2026-07-09T00:00:00Z"
TIME_STEP_MINUTES = 60
UTC_TT_OFFSET_SECONDS = 69.184
SOLAR_ARRAY_PEAK_W = 450.0
CONFIDENCE = 0.62


class SpkSegment:
    def __init__(
        self,
        target: int,
        center: int,
        start_et: float,
        end_et: float,
        values: tuple[float, ...],
    ) -> None:
        self.target = target
        self.center = center
        self.start_et = start_et
        self.end_et = end_et
        self.values = values
        self.init = values[-4]
        self.interval_length = values[-3]
        self.record_size = int(values[-2])
        self.record_count = int(values[-1])

    def position(self, et: float) -> tuple[float, float, float]:
        if et < self.start_et or et > self.end_et:
            raise ValueError(f"ET {et} outside segment for target {self.target}")
        index = int((et - self.init) // self.interval_length)
        index = max(0, min(index, self.record_count - 1))
        offset = index * self.record_size
        record = self.values[offset : offset + self.record_size]
        midpoint = record[0]
        radius = record[1]
        x = (et - midpoint) / radius
        coefficient_count = (self.record_size - 2) // 3
        return tuple(
            chebyshev(
                record[
                    2 + axis * coefficient_count : 2
                    + (axis + 1) * coefficient_count
                ],
                x,
            )
            for axis in range(3)
        )


def parse_utc(value: str) -> dt.datetime:
    if not value.endswith("Z"):
        raise ValueError(f"UTC timestamp must end with Z: {value}")
    return dt.datetime.fromisoformat(value[:-1] + "+00:00")


def et_seconds(value: dt.datetime) -> float:
    return (value - J2000_UTC).total_seconds() + UTC_TT_OFFSET_SECONDS


def chebyshev(coefficients: tuple[float, ...], x: float) -> float:
    if len(coefficients) == 1:
        return coefficients[0]
    b0 = 0.0
    b1 = 0.0
    for coefficient in reversed(coefficients[1:]):
        b0, b1 = 2.0 * x * b0 - b1 + coefficient, b0
    return x * b0 - b1 + coefficients[0]


def vector_add(
    left: tuple[float, float, float],
    right: tuple[float, float, float],
) -> tuple[float, float, float]:
    return (left[0] + right[0], left[1] + right[1], left[2] + right[2])


def vector_subtract(
    left: tuple[float, float, float],
    right: tuple[float, float, float],
) -> tuple[float, float, float]:
    return (left[0] - right[0], left[1] - right[1], left[2] - right[2])


def unit(vector: tuple[float, float, float]) -> tuple[float, float, float]:
    norm = math.sqrt(vector[0] ** 2 + vector[1] ** 2 + vector[2] ** 2)
    return (vector[0] / norm, vector[1] / norm, vector[2] / norm)


def dot(
    left: tuple[float, float, float],
    right: tuple[float, float, float],
) -> float:
    return left[0] * right[0] + left[1] * right[1] + left[2] * right[2]


def load_spk(path: Path) -> dict[int, SpkSegment]:
    segments: dict[int, SpkSegment] = {}
    with path.open("rb") as handle:
        file_record = handle.read(1024)
        if file_record[:7] != b"DAF/SPK":
            raise ValueError(f"{path} is not a DAF/SPK file")
        nd, ni = struct.unpack("<ii", file_record[8:16])
        if (nd, ni) != (2, 6):
            raise ValueError(f"{path} has unsupported DAF summary shape {(nd, ni)}")
        summary_record = struct.unpack("<i", file_record[76:80])[0]
        summary_size = 8 * (nd + (ni + 1) // 2)
        while summary_record:
            handle.seek((summary_record - 1) * 1024)
            record = handle.read(1024)
            next_record = int(struct.unpack("<d", record[:8])[0])
            summary_count = int(struct.unpack("<d", record[16:24])[0])
            for index in range(summary_count):
                start = 24 + index * summary_size
                summary = record[start : start + summary_size]
                start_et, end_et = struct.unpack("<dd", summary[:16])
                target, center, _frame, data_type, start_addr, end_addr = struct.unpack(
                    "<iiiiii", summary[16:40]
                )
                if data_type != 2 or target not in {3, 10, 301}:
                    continue
                handle.seek((start_addr - 1) * 8)
                values = struct.unpack(
                    "<" + "d" * (end_addr - start_addr + 1),
                    handle.read((end_addr - start_addr + 1) * 8),
                )
                segments[target] = SpkSegment(target, center, start_et, end_et, values)
            summary_record = next_record
    for target in (3, 10, 301):
        if target not in segments:
            raise ValueError(f"{path} missing SPK segment for target {target}")
    return segments


def lunar_body_fixed_normal(lat_deg: float, lon_deg: float) -> tuple[float, float, float]:
    lat = math.radians(lat_deg)
    lon = math.radians(lon_deg)
    return (math.cos(lat) * math.cos(lon), math.cos(lat) * math.sin(lon), math.sin(lat))


def body_fixed_to_j2000_normal(
    et: float,
    body_fixed: tuple[float, float, float],
) -> tuple[float, float, float]:
    days = et / 86400.0
    centuries = days / 36525.0
    ra = math.radians(269.9949 + 0.0031 * centuries)
    dec = math.radians(66.5392 + 0.0130 * centuries)
    prime_meridian = math.radians(
        (38.3213 + 13.17635815 * days - 1.4e-12 * days * days) % 360.0
    )
    inertial_to_fixed = matmul(
        rotation_z(prime_meridian),
        matmul(rotation_x(math.pi / 2.0 - dec), rotation_z(ra + math.pi / 2.0)),
    )
    return transpose_multiply(inertial_to_fixed, body_fixed)


def rotation_z(angle: float) -> tuple[tuple[float, float, float], ...]:
    c = math.cos(angle)
    s = math.sin(angle)
    return ((c, s, 0.0), (-s, c, 0.0), (0.0, 0.0, 1.0))


def rotation_x(angle: float) -> tuple[tuple[float, float, float], ...]:
    c = math.cos(angle)
    s = math.sin(angle)
    return ((1.0, 0.0, 0.0), (0.0, c, s), (0.0, -s, c))


def matmul(
    left: tuple[tuple[float, float, float], ...],
    right: tuple[tuple[float, float, float], ...],
) -> tuple[tuple[float, float, float], ...]:
    return tuple(
        tuple(sum(left[row][k] * right[k][col] for k in range(3)) for col in range(3))
        for row in range(3)
    )


def transpose_multiply(
    matrix: tuple[tuple[float, float, float], ...],
    vector: tuple[float, float, float],
) -> tuple[float, float, float]:
    return tuple(sum(matrix[row][col] * vector[row] for row in range(3)) for col in range(3))


def sun_altitude_deg(
    segments: dict[int, SpkSegment],
    timestamp: dt.datetime,
    lat_deg: float,
    lon_deg: float,
) -> float:
    et = et_seconds(timestamp)
    sun = segments[10].position(et)
    moon = vector_add(segments[3].position(et), segments[301].position(et))
    sun_from_moon = unit(vector_subtract(sun, moon))
    normal = body_fixed_to_j2000_normal(et, lunar_body_fixed_normal(lat_deg, lon_deg))
    return math.degrees(math.asin(max(-1.0, min(1.0, dot(normal, sun_from_moon)))))


def compute_window(evidence: dict[str, Any]) -> dict[str, Any]:
    start = parse_utc(TIME_START_UTC)
    end = parse_utc(TIME_END_UTC)
    step = dt.timedelta(minutes=TIME_STEP_MINUTES)
    segments = load_spk(SPK)
    lat = float(evidence["target_lat_deg"])
    lon = float(evidence["target_lon_deg"])
    current = start
    sunlit_hours = 0.0
    dark_hours = 0.0
    available_wh = 0.0
    min_altitude = 90.0
    max_altitude = -90.0
    while current < end:
        altitude = sun_altitude_deg(segments, current, lat, lon)
        min_altitude = min(min_altitude, altitude)
        max_altitude = max(max_altitude, altitude)
        hours = TIME_STEP_MINUTES / 60.0
        if altitude > 0.0:
            sunlit_hours += hours
            available_wh += SOLAR_ARRAY_PEAK_W * math.sin(math.radians(altitude)) * hours
        else:
            dark_hours += hours
        current += step
    evidence = json.loads(json.dumps(evidence))
    evidence["evidence_id"] = "first-trusted-square-power-window-computed-v1"
    evidence["source_status"] = "ready"
    evidence["computation"] = {
        "method_id": "south-pole-power-window-v1",
        "generated_by": "scripts/compute_power_window.py",
        "time_step_minutes": TIME_STEP_MINUTES,
        "horizon_model": "iau-moon-spherical-zero-horizon-v1",
        "rover_power_model": "conservative-south-pole-energy-v1",
        "status": "computed",
    }
    evidence["time_start_utc"] = TIME_START_UTC
    evidence["time_end_utc"] = TIME_END_UTC
    evidence["sunlit_hours"] = round(sunlit_hours, 6)
    evidence["dark_hours"] = round(dark_hours, 6)
    evidence["available_energy_wh"] = round(available_wh, 6)
    evidence["confidence"] = CONFIDENCE
    evidence["has_time_window_ephemeris"] = True
    evidence["reasons"] = [
        "official NAIF DE440 source files are locally pinned with byte counts and checksums",
        "Sun/Moon geometry was sampled hourly from DE440s over the declared UTC window",
        f"spherical zero-horizon model found sun altitude between {min_altitude:.6f} and {max_altitude:.6f} degrees",
        "local terrain-shadow and panel-attitude modeling remain conservative review blockers",
    ]
    return evidence


def read_source() -> dict[str, Any]:
    with SOURCE.open(encoding="utf-8") as handle:
        return json.load(handle)


def render_json(evidence: dict[str, Any]) -> str:
    return json.dumps(evidence, indent=2) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    computed = render_json(compute_window(read_source()))
    if args.check:
        current = SOURCE.read_text(encoding="utf-8")
        if current != computed:
            raise SystemExit(
                f"{SOURCE.relative_to(ROOT)} is stale; run python3 scripts/compute_power_window.py"
            )
        print(f"checked {SOURCE.relative_to(ROOT)}")
    else:
        SOURCE.write_text(computed, encoding="utf-8")
        digest = hashlib.sha256(computed.encode()).hexdigest()
        print(f"computed {SOURCE.relative_to(ROOT)} sha256={digest}")


if __name__ == "__main__":
    main()
