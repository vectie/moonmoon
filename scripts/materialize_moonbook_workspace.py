#!/usr/bin/env python3
"""Materialize MoonBook entry files from generated Moonmoon dossiers."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SITE_JSON = ROOT / "output/site/first_trusted_square.json"
BOOK_JSON = ROOT / "output/moonbook/first_trusted_square_book.json"
MOONCLAW_JSON = ROOT / "output/moonclaw/first_trusted_square_proposals.json"
MOONCLAW_EPHEMERIS_TASKS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_ephemeris_tasks.json"
)
MOONCLAW_RECEIPTS_JSON = ROOT / "output/moonclaw/first_trusted_square_receipts.json"
MOONCLAW_EPHEMERIS_RECEIPTS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_ephemeris_receipts.json"
)
MOONCLAW_CORRIDOR_RECEIPTS_JSON = (
  ROOT / "output/moonclaw/first_trusted_square_corridor_receipts.json"
)
MOONROBO_JSON = ROOT / "output/moonrobo/first_trusted_square_handoffs.json"
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
GENERATOR = "scripts/materialize_moonbook_workspace.py"


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def render_json(value: Any) -> str:
  return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def read_existing(path: Path) -> str | None:
  try:
    return path.read_text(encoding="utf-8")
  except FileNotFoundError:
    return None


def by_key(values: list[dict[str, Any]], key: str) -> dict[str, dict[str, Any]]:
  return {value[key]: value for value in values}


def route_id_from_entry(entry_id: str) -> str:
  return entry_id.rsplit("/", 1)[-1]


def payload_for_entry(
  entry: dict[str, Any],
  site: dict[str, Any],
  moonclaw: list[dict[str, Any]],
  moonclaw_ephemeris_tasks: list[dict[str, Any]],
  moonclaw_receipts: list[dict[str, Any]],
  moonclaw_ephemeris_receipts: list[dict[str, Any]],
  moonclaw_corridor_receipts: list[dict[str, Any]],
  moonrobo: list[dict[str, Any]],
  lookups: dict[str, dict[str, dict[str, Any]]],
) -> Any:
  kind = entry["kind"]
  entry_id = entry["entry_id"]

  if kind == "SourceDataset":
    return lookups["datasets"][entry_id.removeprefix("dataset/")]
  if kind == "SourceValidation":
    return lookups["validations"][entry_id.removeprefix("validation/")]
  if kind == "SourceUpgradeCandidate":
    return lookups["source_candidates"][
      entry_id.removeprefix("source-candidate/")
    ]
  if kind == "SourceAcquisitionPlan":
    return lookups["source_acquisition_plans"][
      entry_id.removeprefix("source-acquisition/")
    ]
  if kind == "SourceProductSelection":
    return lookups["source_product_selections"][
      entry_id.removeprefix("source-product/")
    ]
  if kind == "SourceExtractionCandidate":
    return lookups["source_extraction_candidates"][
      entry_id.removeprefix("source-extraction/")
    ]
  if kind == "DerivedTerrain":
    return site["terrain"]
  if kind == "MissionDecision":
    return site["traverse"]
  if kind == "CorridorScan":
    return {
      "scan_id": site["corridor_scan"][0]["scan_id"],
      "best_window": site["corridor_scan"][0],
      "windows": site["corridor_scan"],
    }
  if kind == "RouteAlternative":
    return lookups["route_candidates"][route_id_from_entry(entry_id)]
  if kind == "IlluminationAssessment":
    return lookups["route_candidates"][route_id_from_entry(entry_id)][
      "illumination"
    ]
  if kind == "PowerWindowEvidence":
    return site["power_window_evidence"]
  if kind == "EnergyWindow":
    return site["energy"]
  if kind == "MoonroboHandoff":
    return {
      "primary_handoff": next(
        handoff for handoff in moonrobo if handoff["route_id"] == site["corridor_scan"][0]["selected_route_id"]
      ),
      "handoffs": moonrobo,
    }
  if kind == "MoonClawProposal":
    return {
      "primary_proposal": moonclaw[0],
      "proposals": moonclaw,
    }
  if kind == "MoonClawTask":
    return {
      "primary_task": moonclaw_ephemeris_tasks[0],
      "tasks": moonclaw_ephemeris_tasks,
    }
  if kind == "MoonClawReceipt":
    return {
      "primary_receipt": moonclaw_receipts[0],
      "receipts": moonclaw_receipts,
    }
  if kind == "MoonClawEphemerisReceipt":
    return {
      "primary_receipt": moonclaw_ephemeris_receipts[0],
      "receipts": moonclaw_ephemeris_receipts,
    }
  if kind == "MoonClawCorridorReceipt":
    return {
      "primary_receipt": moonclaw_corridor_receipts[0],
      "receipts": moonclaw_corridor_receipts,
    }

  raise ValueError(f"unsupported entry kind {kind!r} for {entry_id}")


def workspace_files(
  site: dict[str, Any],
  book: dict[str, Any],
  moonclaw: list[dict[str, Any]],
  moonclaw_ephemeris_tasks: list[dict[str, Any]],
  moonclaw_receipts: list[dict[str, Any]],
  moonclaw_ephemeris_receipts: list[dict[str, Any]],
  moonclaw_corridor_receipts: list[dict[str, Any]],
  moonrobo: list[dict[str, Any]],
) -> dict[Path, str]:
  lookups = {
    "datasets": by_key(site["datasets"], "dataset_id"),
    "validations": by_key(site["validations"], "dataset_id"),
    "source_candidates": by_key(site["source_candidates"], "candidate_id"),
    "source_acquisition_plans": by_key(
      site["source_acquisition_plans"], "plan_id",
    ),
    "source_product_selections": by_key(
      site["source_product_selections"], "selection_id",
    ),
    "source_extraction_candidates": by_key(
      site["source_extraction_candidates"], "extraction_id",
    ),
    "route_candidates": by_key(site["route_candidates"], "route_id"),
  }

  files: dict[Path, str] = {}
  entries = book["entries"]
  review_queue = book["review_queue"]
  review_transitions = book["review_transitions"]
  entry_paths: list[str] = []

  index = {
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "title": book["title"],
    "generated_by": GENERATOR,
    "source_files": [
      "output/site/first_trusted_square.json",
      "output/moonbook/first_trusted_square_book.json",
      "output/moonclaw/first_trusted_square_proposals.json",
      "output/moonclaw/first_trusted_square_ephemeris_tasks.json",
      "output/moonclaw/first_trusted_square_receipts.json",
      "output/moonclaw/first_trusted_square_ephemeris_receipts.json",
      "output/moonclaw/first_trusted_square_corridor_receipts.json",
      "output/moonrobo/first_trusted_square_handoffs.json",
    ],
    "entries": entries,
    "review_queue_path": "review_queue.json",
    "review_transitions_path": "review_transitions.json",
  }
  files[WORKSPACE / "index.json"] = render_json(index)

  for entry in entries:
    path = WORKSPACE / entry["path"]
    entry_paths.append(entry["path"])
    payload = payload_for_entry(
      entry,
      site,
      moonclaw,
      moonclaw_ephemeris_tasks,
      moonclaw_receipts,
      moonclaw_ephemeris_receipts,
      moonclaw_corridor_receipts,
      moonrobo,
      lookups,
    )
    files[path] = render_json({
      "entry": entry,
      "payload": payload,
      "workspace": book["workspace"],
      "site_id": book["site_id"],
      "generated_by": GENERATOR,
    })

  files[WORKSPACE / "review_queue.json"] = render_json({
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "generated_by": GENERATOR,
    "items": review_queue,
  })

  files[WORKSPACE / "review_transitions.json"] = render_json({
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "generated_by": GENERATOR,
    "items": review_transitions,
  })

  files[WORKSPACE / "manifest.json"] = render_json({
    "workspace": book["workspace"],
    "site_id": book["site_id"],
    "generated_by": GENERATOR,
    "entry_count": len(entries),
    "review_queue_count": len(review_queue),
    "review_transition_count": len(review_transitions),
    "entry_paths": entry_paths,
    "review_queue_path": "review_queue.json",
    "review_transitions_path": "review_transitions.json",
  })

  files[WORKSPACE / "README.md"] = (
    "# First Trusted Square MoonBook Workspace\n\n"
    "This directory is generated. It materializes the MoonBook entry index, "
    "per-entry evidence payloads, and review queue for the Moonmoon "
    "first-trusted-square proof slice.\n\n"
    "- Source site dossier: `output/site/first_trusted_square.json`\n"
    "- Source MoonBook dossier: `output/moonbook/first_trusted_square_book.json`\n"
    "- Source MoonClaw proposals: `output/moonclaw/first_trusted_square_proposals.json`\n"
    "- Source MoonClaw ephemeris tasks: `output/moonclaw/first_trusted_square_ephemeris_tasks.json`\n"
    "- Source MoonClaw receipts: `output/moonclaw/first_trusted_square_receipts.json`\n"
    "- Source MoonClaw ephemeris receipts: `output/moonclaw/first_trusted_square_ephemeris_receipts.json`\n"
    "- Source MoonClaw corridor receipts: `output/moonclaw/first_trusted_square_corridor_receipts.json`\n"
    f"- Entries: {len(entries)}\n"
    f"- Review queue items: {len(review_queue)}\n"
    f"- Review transitions: {len(review_transitions)}\n"
  )

  return files


def check_workspace(files: dict[Path, str]) -> int:
  missing: list[Path] = []
  stale: list[Path] = []
  for path, expected in files.items():
    actual = read_existing(path)
    if actual is None:
      missing.append(path)
    elif actual != expected:
      stale.append(path)

  extra: list[Path] = []
  if WORKSPACE.exists():
    expected_paths = set(files)
    for path in sorted(WORKSPACE.rglob("*")):
      if path.is_file() and path not in expected_paths:
        extra.append(path)

  if missing or stale or extra:
    for path in missing:
      print(f"missing {path.relative_to(ROOT)}", file=sys.stderr)
    for path in stale:
      print(f"stale {path.relative_to(ROOT)}", file=sys.stderr)
    for path in extra:
      print(f"extra {path.relative_to(ROOT)}", file=sys.stderr)
    return 1

  print(f"checked {WORKSPACE.relative_to(ROOT)}")
  return 0


def write_workspace(files: dict[Path, str]) -> None:
  if WORKSPACE.exists():
    shutil.rmtree(WORKSPACE)
  for path, content in files.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
  print(f"wrote {WORKSPACE.relative_to(ROOT)}")


def main() -> int:
  parser = argparse.ArgumentParser()
  parser.add_argument(
    "--check",
    action="store_true",
    help="verify generated workspace files are current",
  )
  args = parser.parse_args()

  site = load_json(SITE_JSON)
  book = load_json(BOOK_JSON)
  moonclaw = load_json(MOONCLAW_JSON)
  moonclaw_ephemeris_tasks = load_json(MOONCLAW_EPHEMERIS_TASKS_JSON)
  moonclaw_receipts = load_json(MOONCLAW_RECEIPTS_JSON)
  moonclaw_ephemeris_receipts = load_json(MOONCLAW_EPHEMERIS_RECEIPTS_JSON)
  moonclaw_corridor_receipts = load_json(MOONCLAW_CORRIDOR_RECEIPTS_JSON)
  moonrobo = load_json(MOONROBO_JSON)
  files = workspace_files(
    site,
    book,
    moonclaw,
    moonclaw_ephemeris_tasks,
    moonclaw_receipts,
    moonclaw_ephemeris_receipts,
    moonclaw_corridor_receipts,
    moonrobo,
  )
  if args.check:
    return check_workspace(files)
  write_workspace(files)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
