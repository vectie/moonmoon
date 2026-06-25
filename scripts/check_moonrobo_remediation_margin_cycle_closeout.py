#!/usr/bin/env python3
"""Check MoonRobo remediation-margin cycle closeout policy output."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REFRESH_PROJECTION_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json"
)
FOLLOWUP_PROJECTION_JSON = (
  ROOT
  / "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json"
)
CLOSEOUT_JSON = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
)
CLOSEOUT_MD = (
  ROOT / "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.md"
)
WORKSPACE = ROOT / "output/moonbook/workspaces/first-trusted-square"
ENTRY_ID = "moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy"
ENTRY_KIND = "MoonroboRemediationMarginCycleCloseoutPolicy"
ENTRY_PATH = "moonrobo/first-trusted-square/remediation-margin-cycle-closeout-policy.json"
SOURCE_PATH = "output/moonrobo/first_trusted_square_remediation_margin_cycle_closeout.json"
POLICY_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy"
)
REFRESH_PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection"
)
FOLLOWUP_PROJECTION_ID = (
  "moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection"
)
REFRESH_IDS = {
  "refresh-terrain-northeast-stepout",
  "refresh-illumination-northeast-stepout",
  "refresh-energy-window",
}
MARGIN_IDS = {
  "terrain-northeast-stepout",
  "illumination-northeast-stepout",
  "energy-window",
}
EXPECTED_DISPOSITIONS = {
  "terrain-northeast-stepout": ("terrain", "EscalateToOperatorDecision"),
  "illumination-northeast-stepout": ("local-horizon", "RetryWithNewEvidence"),
  "energy-window": ("energy", "FreezeUntilNewSourceEvidence"),
}


def load_json(path: Path) -> Any:
  with path.open("r", encoding="utf-8") as handle:
    return json.load(handle)


def require(condition: bool, message: str) -> None:
  if not condition:
    raise SystemExit(message)


def assert_closeout(
  refresh_projection: dict[str, Any],
  followup_projection: dict[str, Any],
  closeout: dict[str, Any],
) -> None:
  require(closeout["policy_id"] == POLICY_ID, "unexpected policy id")
  require(closeout["route_id"] == "northeast-stepout", "unexpected route")
  require(
    closeout["source_refresh_projection_id"] == REFRESH_PROJECTION_ID,
    "unexpected refresh projection source",
  )
  require(
    closeout["source_refresh_projection_id"] == refresh_projection["projection_id"],
    "refresh projection source diverges",
  )
  require(
    closeout["source_refresh_projection_status"]
    == "NoConsumeRefreshSimulationBlocked",
    "unexpected refresh projection status",
  )
  require(
    closeout["source_refresh_projection_status"]
    == refresh_projection["projection_status"],
    "refresh status diverges",
  )
  require(
    closeout["source_followup_projection_id"] == FOLLOWUP_PROJECTION_ID,
    "unexpected follow-up projection source",
  )
  require(
    closeout["source_followup_projection_id"]
    == followup_projection["projection_id"],
    "follow-up projection source diverges",
  )
  require(
    closeout["source_followup_projection_status"]
    == "NoConsumeFollowupRefreshSimulationBlocked",
    "unexpected follow-up projection status",
  )
  require(
    closeout["source_followup_projection_status"]
    == followup_projection["projection_status"],
    "follow-up status diverges",
  )
  require(
    closeout["source_refresh_projection_path"]
    == "output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json",
    "unexpected refresh source path",
  )
  require(
    closeout["source_followup_projection_path"]
    == "output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json",
    "unexpected follow-up source path",
  )
  require(
    closeout["closeout_status"] == "NoConsumeCycleClosedForPolicy",
    "closeout should block simulation consumption",
  )
  require(closeout["may_consume_simulation"] is False, "may consume changed")
  require(
    closeout["simulation_state"] == "SimulationBlocked",
    "simulation state changed",
  )
  require(closeout["refresh_cycle_count"] == 2, "expected two refresh cycles")
  require(closeout["blocker_count"] == 3, "expected three blockers")
  require(
    set(closeout["blocking_refresh_ids"]) == REFRESH_IDS,
    "blocking refresh ids changed",
  )
  require(
    set(closeout["blocking_margin_ids"]) == MARGIN_IDS,
    "blocking margin ids changed",
  )
  require(
    set(closeout["blocking_refresh_ids"])
    == set(followup_projection["blocking_refresh_ids"]),
    "closeout no longer consumes follow-up blockers",
  )
  require(
    set(closeout["blocking_margin_ids"])
    == set(followup_projection["blocking_margin_ids"]),
    "closeout margin blockers diverge from follow-up projection",
  )
  require(
    closeout["hardware_state"] == "HardwareDenied",
    "hardware state changed",
  )
  require(
    closeout["hardware_authority"] == "moonmoon-safety-gate-only",
    "hardware authority changed",
  )
  require(closeout["hardware_denied"] is True, "hardware denial changed")

  dispositions = {
    item["margin_id"]: item for item in closeout["dispositions"]
  }
  require(set(dispositions) == MARGIN_IDS, "disposition margins changed")
  for margin_id, (domain, disposition) in EXPECTED_DISPOSITIONS.items():
    item = dispositions[margin_id]
    require(item["blocker_domain"] == domain, f"{margin_id} domain changed")
    require(item["disposition"] == disposition, f"{margin_id} disposition changed")
    require(item["attempt_count"] == 2, f"{margin_id} attempt count changed")
    require(item["refresh_id"] in REFRESH_IDS, f"{margin_id} refresh id changed")
    require(item["required_evidence"], f"{margin_id} missing required evidence")
    require("unbounded refresh loop" in item["reason"], f"{margin_id} reason changed")

  for token in (
    "no-consume remediation-margin refresh cycle closed for policy",
    "NoConsumeRefreshSimulationBlocked",
    "NoConsumeFollowupRefreshSimulationBlocked",
    "terrain/horizon/energy blockers",
    "moonmoon-safety-gate-only",
  ):
    require(token in closeout["reason"], f"reason missing {token}")
  require(
    "retry/escalate/freeze dispositions" in closeout["next_action"],
    "next action should name retry/escalate/freeze policy",
  )


def assert_workspace(closeout: dict[str, Any]) -> None:
  index = load_json(WORKSPACE / "index.json")
  manifest = load_json(WORKSPACE / "manifest.json")
  entry_file = load_json(WORKSPACE / ENTRY_PATH)
  readme = (WORKSPACE / "README.md").read_text(encoding="utf-8")
  entries = {entry["entry_id"]: entry for entry in index["entries"]}
  require(ENTRY_ID in entries, "MoonBook index missing cycle closeout")
  entry = entries[ENTRY_ID]
  require(entry["kind"] == ENTRY_KIND, f"unexpected entry kind {entry['kind']}")
  require(entry["path"] == ENTRY_PATH, f"unexpected entry path {entry['path']}")
  for token in (
    "NoConsumeCycleClosedForPolicy",
    "2 refresh cycles",
    "3 terrain/horizon/energy blockers",
    "terrain=EscalateToOperatorDecision",
    "local-horizon=RetryWithNewEvidence",
    "energy=FreezeUntilNewSourceEvidence",
    "simulation-blocked",
    "moonmoon-safety-gate-only",
    "hardware-denied",
  ):
    require(token in entry["summary"], f"entry summary missing {token}")
  require(ENTRY_PATH in manifest["entry_paths"], "manifest missing entry path")
  require(SOURCE_PATH in index["source_files"], "index missing source file")
  require(SOURCE_PATH in readme, "README missing source file")
  require(entry_file["entry"] == entry, "entry wrapper diverges from index")
  require(entry_file["payload"] == closeout, "workspace payload diverges")


def main() -> int:
  refresh_projection = load_json(REFRESH_PROJECTION_JSON)
  followup_projection = load_json(FOLLOWUP_PROJECTION_JSON)
  closeout = load_json(CLOSEOUT_JSON)
  markdown = CLOSEOUT_MD.read_text(encoding="utf-8")
  assert_closeout(refresh_projection, followup_projection, closeout)
  assert_workspace(closeout)

  for token in (
    "MoonRobo Remediation Margin Cycle Closeout Policy",
    "NoConsumeCycleClosedForPolicy",
    "NoConsumeRefreshSimulationBlocked",
    "NoConsumeFollowupRefreshSimulationBlocked",
    "may consume simulation: false",
    "simulation-blocked",
    "hardware-denied",
    "EscalateToOperatorDecision",
    "RetryWithNewEvidence",
    "FreezeUntilNewSourceEvidence",
    *REFRESH_IDS,
    *MARGIN_IDS,
  ):
    require(token in markdown, f"markdown missing {token}")

  print("checked MoonRobo remediation margin cycle closeout")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
