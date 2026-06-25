#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output/site"
TERRAIN_OUT="$ROOT/output/terrain"
MISSION_OUT="$ROOT/output/mission"
MOONBOOK_OUT="$ROOT/output/moonbook"
MOONCLAW_OUT="$ROOT/output/moonclaw"
MOONROBO_OUT="$ROOT/output/moonrobo"
UI_OUT="$ROOT/output/ui"
RABBITA_OUT="$UI_OUT/rabbita"
REVIEW_TRANSITIONS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --review-transitions)
      if [[ $# -lt 2 ]]; then
        printf 'missing value for --review-transitions\n' >&2
        exit 2
      fi
      REVIEW_TRANSITIONS="$2"
      shift 2
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

mkdir -p "$OUT"
mkdir -p "$TERRAIN_OUT"
mkdir -p "$MISSION_OUT"
mkdir -p "$MOONBOOK_OUT"
mkdir -p "$MOONCLAW_OUT"
mkdir -p "$MOONROBO_OUT"
mkdir -p "$UI_OUT"
mkdir -p "$RABBITA_OUT"

cd "$ROOT"

bash scripts/verify_moonmoon_sources.sh
python3 scripts/compute_power_window.py --check
python3 scripts/generate_moonmoon_fixture.py
python3 scripts/generate_corridor_scan.py
python3 scripts/generate_power_window.py
python3 scripts/generate_selected_route_horizon.py
python3 scripts/generate_selected_route_terrain_remediation.py

/Users/kq/.moon/bin/moon run cmd/main > "$OUT/first_trusted_square.md"
/Users/kq/.moon/bin/moon run cmd/main -- json > "$OUT/first_trusted_square.json"
/Users/kq/.moon/bin/moon run cmd/main -- terrain fixture > "$TERRAIN_OUT/first_trusted_square_grid.md"
/Users/kq/.moon/bin/moon run cmd/main -- terrain fixture json > "$TERRAIN_OUT/first_trusted_square_grid.json"
/Users/kq/.moon/bin/moon run cmd/main -- mission horizon > "$MISSION_OUT/first_trusted_square_northeast_stepout_horizon.md"
/Users/kq/.moon/bin/moon run cmd/main -- mission horizon json > "$MISSION_OUT/first_trusted_square_northeast_stepout_horizon.json"
/Users/kq/.moon/bin/moon run cmd/main -- mission terrain > "$MISSION_OUT/first_trusted_square_northeast_stepout_terrain_remediation.md"
/Users/kq/.moon/bin/moon run cmd/main -- mission terrain json > "$MISSION_OUT/first_trusted_square_northeast_stepout_terrain_remediation.json"
/Users/kq/.moon/bin/moon run cmd/main -- mission energy > "$MISSION_OUT/first_trusted_square_energy_remediation.md"
/Users/kq/.moon/bin/moon run cmd/main -- mission energy json > "$MISSION_OUT/first_trusted_square_energy_remediation.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonbook dossier > "$MOONBOOK_OUT/first_trusted_square_book.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonbook dossier json > "$MOONBOOK_OUT/first_trusted_square_book.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw proposals > "$MOONCLAW_OUT/first_trusted_square_proposals.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw proposals json > "$MOONCLAW_OUT/first_trusted_square_proposals.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw ephemeris tasks > "$MOONCLAW_OUT/first_trusted_square_ephemeris_tasks.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw ephemeris tasks json > "$MOONCLAW_OUT/first_trusted_square_ephemeris_tasks.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw corridor tasks > "$MOONCLAW_OUT/first_trusted_square_corridor_tasks.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw corridor tasks json > "$MOONCLAW_OUT/first_trusted_square_corridor_tasks.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation margins > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_task.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation margins json > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_task.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_task.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh json > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_task.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh followup > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_task.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh followup json > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_task.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh followup receipts > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_receipt.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh followup receipts json > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh receipts > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_receipt.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation refresh receipts json > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_receipt.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation receipts > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_receipt.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw remediation receipts json > "$MOONCLAW_OUT/first_trusted_square_remediation_margin_receipt.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw receipts > "$MOONCLAW_OUT/first_trusted_square_receipts.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw receipts json > "$MOONCLAW_OUT/first_trusted_square_receipts.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw ephemeris receipts > "$MOONCLAW_OUT/first_trusted_square_ephemeris_receipts.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw ephemeris receipts json > "$MOONCLAW_OUT/first_trusted_square_ephemeris_receipts.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw corridor receipts > "$MOONCLAW_OUT/first_trusted_square_corridor_receipts.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonclaw corridor receipts json > "$MOONCLAW_OUT/first_trusted_square_corridor_receipts.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo handoff > "$MOONROBO_OUT/first_trusted_square_handoffs.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo handoff json > "$MOONROBO_OUT/first_trusted_square_handoffs.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation margins > "$MOONROBO_OUT/first_trusted_square_remediation_margin_modeling.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation margins json > "$MOONROBO_OUT/first_trusted_square_remediation_margin_modeling.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation refresh modeling > "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_modeling.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation refresh modeling json > "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_modeling.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation refresh projection > "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_projection.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation refresh projection json > "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_projection.json"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation projection > "$MOONROBO_OUT/first_trusted_square_remediation_margin_projection.md"
/Users/kq/.moon/bin/moon run cmd/main -- moonrobo remediation projection json > "$MOONROBO_OUT/first_trusted_square_remediation_margin_projection.json"
/Users/kq/.moon/bin/moon run cmd/main -- ui view > "$UI_OUT/first_trusted_square_view.md"
/Users/kq/.moon/bin/moon run cmd/main -- ui view json > "$UI_OUT/first_trusted_square_view.json"
/Users/kq/.moon/bin/moon run cmd/main -- ui rabbita > "$RABBITA_OUT/first_trusted_square.html"
if [[ -n "$REVIEW_TRANSITIONS" ]]; then
  python3 scripts/import_rabbita_transitions.py --review-transitions "$REVIEW_TRANSITIONS"
fi
python3 scripts/materialize_moonbook_workspace.py

printf 'wrote %s\n' "$OUT/first_trusted_square.md"
printf 'wrote %s\n' "$OUT/first_trusted_square.json"
printf 'wrote %s\n' "$TERRAIN_OUT/first_trusted_square_grid.md"
printf 'wrote %s\n' "$TERRAIN_OUT/first_trusted_square_grid.json"
printf 'wrote %s\n' "$MISSION_OUT/first_trusted_square_northeast_stepout_horizon.md"
printf 'wrote %s\n' "$MISSION_OUT/first_trusted_square_northeast_stepout_horizon.json"
printf 'wrote %s\n' "$MISSION_OUT/first_trusted_square_northeast_stepout_terrain_remediation.md"
printf 'wrote %s\n' "$MISSION_OUT/first_trusted_square_northeast_stepout_terrain_remediation.json"
printf 'wrote %s\n' "$MISSION_OUT/first_trusted_square_energy_remediation.md"
printf 'wrote %s\n' "$MISSION_OUT/first_trusted_square_energy_remediation.json"
printf 'wrote %s\n' "$MOONBOOK_OUT/first_trusted_square_book.md"
printf 'wrote %s\n' "$MOONBOOK_OUT/first_trusted_square_book.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_proposals.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_proposals.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_ephemeris_tasks.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_ephemeris_tasks.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_corridor_tasks.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_corridor_tasks.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_task.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_task.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_task.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_task.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_task.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_task.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_receipt.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_followup_receipt.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_receipt.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_refresh_receipt.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_receipt.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_remediation_margin_receipt.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_receipts.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_receipts.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_ephemeris_receipts.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_ephemeris_receipts.json"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_corridor_receipts.md"
printf 'wrote %s\n' "$MOONCLAW_OUT/first_trusted_square_corridor_receipts.json"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_handoffs.md"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_handoffs.json"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_modeling.md"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_modeling.json"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_modeling.md"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_modeling.json"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_projection.md"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_refresh_projection.json"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_projection.md"
printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_remediation_margin_projection.json"
if [[ -n "$REVIEW_TRANSITIONS" ]]; then
  printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_simulation_review_packet.md"
  printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_simulation_review_packet.json"
  printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_simulation_review_decision.md"
  printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_simulation_review_decision.json"
  printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_simulation_blocker_reduction.md"
  printf 'wrote %s\n' "$MOONROBO_OUT/first_trusted_square_simulation_blocker_reduction.json"
fi
printf 'wrote %s\n' "$UI_OUT/first_trusted_square_view.md"
printf 'wrote %s\n' "$UI_OUT/first_trusted_square_view.json"
printf 'wrote %s\n' "$RABBITA_OUT/first_trusted_square.html"
printf 'wrote %s\n' "$MOONBOOK_OUT/workspaces/first-trusted-square"
