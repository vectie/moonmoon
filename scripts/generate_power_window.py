#!/usr/bin/env python3
"""Generate the MoonBit power-window evidence from the checked JSON source."""

from __future__ import annotations

import json
import sys
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
TARGET = ROOT / "src" / "mission" / "generated_first_trusted_square_power_window.mbt"

REQUIRED_FIELDS = {
    "evidence_id": str,
    "source_status": str,
    "source_family_url": str,
    "local_source_path": str,
    "source_sha256": str,
    "source_bytes": int,
    "source_files": list,
    "computation": dict,
    "time_start_utc": str,
    "time_end_utc": str,
    "target_lat_deg": (int, float),
    "target_lon_deg": (int, float),
    "sunlit_hours": (int, float),
    "dark_hours": (int, float),
    "available_energy_wh": (int, float),
    "confidence": (int, float),
    "has_time_window_ephemeris": bool,
    "reasons": list,
}

SOURCE_FILE_FIELDS = {
    "file_id": str,
    "label": str,
    "source_url": str,
    "local_path": str,
    "sha256": str,
    "bytes": int,
    "role": str,
    "status": str,
}

COMPUTATION_FIELDS = {
    "method_id": str,
    "generated_by": str,
    "time_step_minutes": int,
    "horizon_model": str,
    "rover_power_model": str,
    "status": str,
}

ALLOWED_SOURCE_FILE_STATUSES = {"missing", "candidate", "ready"}
ALLOWED_MISSING_COMPUTATION_STATUSES = {"not-computed", "blocked"}
INCOMPLETE_SOURCE_STATUSES = {"candidate-source"}
READY_SOURCE_STATUS = "ready"


def read_evidence() -> dict[str, Any]:
    with SOURCE.open(encoding="utf-8") as handle:
        evidence = json.load(handle)
    for field, expected_type in REQUIRED_FIELDS.items():
        if field not in evidence:
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} missing {field!r}")
        if not isinstance(evidence[field], expected_type):
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} field {field!r} has wrong type")
    if not evidence["reasons"]:
        raise SystemExit(f"{SOURCE.relative_to(ROOT)} must explain the power-window state")
    for reason in evidence["reasons"]:
        if not isinstance(reason, str):
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} reasons must be strings")
    seen_source_file_ids: set[str] = set()
    for source_file in evidence["source_files"]:
        if not isinstance(source_file, dict):
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} source_files must be objects")
        for field, expected_type in SOURCE_FILE_FIELDS.items():
            if field not in source_file:
                raise SystemExit(f"{SOURCE.relative_to(ROOT)} source_files entry missing {field!r}")
            if not isinstance(source_file[field], expected_type):
                raise SystemExit(
                    f"{SOURCE.relative_to(ROOT)} source_files field {field!r} has wrong type"
                )
        file_id = source_file["file_id"]
        if file_id in seen_source_file_ids:
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} repeats source_files file_id {file_id!r}")
        seen_source_file_ids.add(file_id)
        if source_file["status"] not in ALLOWED_SOURCE_FILE_STATUSES:
            raise SystemExit(
                f"{SOURCE.relative_to(ROOT)} source_files entry {file_id!r} has unknown status"
            )
        if source_file["status"] == "ready":
            if source_file["sha256"] == "" or source_file["bytes"] <= 0:
                raise SystemExit(
                    f"{SOURCE.relative_to(ROOT)} ready source file {file_id!r} must pin checksum and bytes"
                )
        elif source_file["sha256"] != "" or source_file["bytes"] != 0:
            raise SystemExit(
                f"{SOURCE.relative_to(ROOT)} non-ready source file {file_id!r} must leave checksum and bytes pending"
            )
    for field, expected_type in COMPUTATION_FIELDS.items():
        if field not in evidence["computation"]:
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} computation missing {field!r}")
        if not isinstance(evidence["computation"][field], expected_type):
            raise SystemExit(f"{SOURCE.relative_to(ROOT)} computation field {field!r} has wrong type")
    source_file_statuses = {source_file["status"] for source_file in evidence["source_files"]}
    if not evidence["has_time_window_ephemeris"]:
        if evidence["available_energy_wh"] != 0:
            raise SystemExit("missing ephemeris evidence must not verify available energy")
        if evidence["computation"]["status"] not in ALLOWED_MISSING_COMPUTATION_STATUSES:
            raise SystemExit("missing ephemeris evidence must not report a completed computation")
        if evidence["source_status"] in INCOMPLETE_SOURCE_STATUSES:
            if evidence["source_sha256"] != "" or evidence["source_bytes"] != 0:
                raise SystemExit("incomplete ephemeris source evidence must leave bundle checksum pending")
            if "ready" in source_file_statuses:
                raise SystemExit("incomplete ephemeris source evidence must not list ready source files")
        else:
            raise SystemExit(
                f"incomplete ephemeris evidence has unsupported source_status={evidence['source_status']!r}"
            )
    else:
        if evidence["source_status"] != READY_SOURCE_STATUS:
            raise SystemExit("time-windowed ephemeris evidence must have source_status='ready'")
        if evidence["source_sha256"] == "" or evidence["source_bytes"] <= 0:
            raise SystemExit("ready ephemeris evidence must pin aggregate checksum and bytes")
        if not evidence["source_files"]:
            raise SystemExit("ready ephemeris evidence must list source files")
        if evidence["computation"]["status"] != "computed":
            raise SystemExit("ready ephemeris evidence must report a computed power window")
        for source_file in evidence["source_files"]:
            if source_file["status"] != "ready":
                raise SystemExit("ready ephemeris evidence must only list ready source files")
            if source_file["sha256"] == "" or source_file["bytes"] <= 0:
                raise SystemExit("ready ephemeris source files must pin checksum and bytes")
    return evidence


def moon_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def moon_bool(value: bool) -> str:
    return "true" if value else "false"


def moon_number(value: int | float) -> str:
    return f"{float(value):.6f}"


def render() -> str:
    evidence = read_evidence()
    source_file_lines = []
    for source_file in evidence["source_files"]:
        source_file_lines.append(
            f'''      {{
        file_id: "{moon_string(source_file["file_id"])}",
        label: "{moon_string(source_file["label"])}",
        source_url: "{moon_string(source_file["source_url"])}",
        local_path: "{moon_string(source_file["local_path"])}",
        sha256: "{moon_string(source_file["sha256"])}",
        bytes: {source_file["bytes"]},
        role: "{moon_string(source_file["role"])}",
        status: "{moon_string(source_file["status"])}",
      }},'''
        )
    source_files_literal = "\n".join(source_file_lines)
    reason_values = [f'"{moon_string(reason)}"' for reason in evidence["reasons"]]
    reason_lines = []
    while reason_values:
        if len(reason_values) >= 2:
            reason_lines.append(f"      {reason_values[0]}, {reason_values[1]},")
            reason_values = reason_values[2:]
        else:
            reason_lines.append(f"      {reason_values[0]},")
            reason_values = []
    reasons_literal = "\n".join(reason_lines)
    source_label = SOURCE.relative_to(ROOT)
    computation = evidence["computation"]
    return f'''///| Generated from {source_label} by scripts/generate_power_window.py.

///|
/// Do not edit this file by hand.
fn generated_first_trusted_square_power_window_evidence() -> PowerWindowEvidence {{
  {{
    evidence_id: "{moon_string(evidence["evidence_id"])}",
    source_status: "{moon_string(evidence["source_status"])}",
    source_family_url: "{moon_string(evidence["source_family_url"])}",
    local_source_path: "{moon_string(evidence["local_source_path"])}",
    source_sha256: "{moon_string(evidence["source_sha256"])}",
    source_bytes: {evidence["source_bytes"]},
    source_files: [
{source_files_literal}
    ],
    computation: {{
      method_id: "{moon_string(computation["method_id"])}",
      generated_by: "{moon_string(computation["generated_by"])}",
      time_step_minutes: {computation["time_step_minutes"]},
      horizon_model: "{moon_string(computation["horizon_model"])}",
      rover_power_model: "{moon_string(computation["rover_power_model"])}",
      status: "{moon_string(computation["status"])}",
    }},
    time_start_utc: "{moon_string(evidence["time_start_utc"])}",
    time_end_utc: "{moon_string(evidence["time_end_utc"])}",
    target_lat_deg: {moon_number(evidence["target_lat_deg"])},
    target_lon_deg: {moon_number(evidence["target_lon_deg"])},
    sunlit_hours: {moon_number(evidence["sunlit_hours"])},
    dark_hours: {moon_number(evidence["dark_hours"])},
    available_energy_wh: {moon_number(evidence["available_energy_wh"])},
    confidence: {moon_number(evidence["confidence"])},
    has_time_window_ephemeris: {moon_bool(evidence["has_time_window_ephemeris"])},
    reasons: [
{reasons_literal}
    ],
  }}
}}
'''


def main() -> None:
    check_only = len(sys.argv) == 2 and sys.argv[1] == "--check"
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and not check_only):
        raise SystemExit("usage: generate_power_window.py [--check]")
    content = render()
    if check_only:
        current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
        if current != content:
            raise SystemExit(
                f"{TARGET.relative_to(ROOT)} is stale; run python3 scripts/generate_power_window.py"
            )
        print(f"checked {TARGET.relative_to(ROOT)} from {SOURCE.relative_to(ROOT)}")
    else:
        TARGET.write_text(content, encoding="utf-8")
        print(f"generated {TARGET.relative_to(ROOT)} from {SOURCE.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
