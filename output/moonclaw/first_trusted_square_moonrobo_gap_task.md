# MoonClaw MoonRobo Gap Remediation Task

- task: moonclaw/first-trusted-square/moonrobo-gap-remediation-v1/task
- priority: Critical
- state: Accepted
- objective: Consume the imported-clearance MoonRobo readiness gap report and produce the next bounded modeling updates required before simulation.
- safety gate: Do not allow MoonRobo hardware execution. Simulation may only become consumable after the blocker gap report is empty or all remaining gaps are explicitly moved to reviewed non-blocking states by regenerated MoonMoon evidence.

## Blocker Gaps

- terrain-northeast-stepout (terrain-readiness)
  - evidence: output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json
  - clearance: AcceptedEvidence
  - next action: route terrain remediation reports grade 0.51395, roughness 5.95975 m, blocking edges 11/24: collect a wider smoother selected-route corridor or keep northeast-stepout out of MoonRobo simulation
- corridor-scan-best-window (corridor-readiness)
  - evidence: mission/first-trusted-square/corridor-scan.json
  - clearance: NotClearanceGated
  - next action: lowest max-neighbor-grade window in this measured 9x9 scan; selects route northeast-stepout and still blocked
- illumination-northeast-stepout (illumination-readiness)
  - evidence: output/mission/first_trusted_square_northeast_stepout_horizon.json
  - clearance: AcceptedEvidence
  - next action: local horizon evidence records terrain-shadow blockage; collect wider horizon evidence before route simulation
- energy-window (energy-readiness)
  - evidence: mission/first-trusted-square/energy-window.json
  - clearance: AcceptedEvidence
  - next action: energy gate reads power-window evidence first-trusted-square-power-window-computed-v1: revise rover power model, route count, or site window before simulation
- moonbook-review (moon-book-review-readiness)
  - evidence: output/moonbook/workspaces/first-trusted-square/review_transitions.json
  - clearance: AcceptedEvidence
  - next action: MoonBook review remains blocked because selected route northeast-stepout still has route or illumination blockers
- robot-simulation (robot-simulation-readiness)
  - evidence: output/moonrobo/first_trusted_square_handoffs.json
  - clearance: NotClearanceGated
  - next action: MoonRobo simulation stays blocked until mission readiness checks clear

## Commands

- `python3 scripts/check_moonrobo_readiness_preview.py`
- `python3 scripts/scan_lola_corridor.py --plan --radius 16 --step 4`
- `python3 scripts/compute_power_window.py --check`
- `bash scripts/build_moonmoon_dossier.sh --review-transitions data/fixtures/rabbita_clearance_transitions_accept.json`
- `python3 scripts/materialize_moonbook_workspace.py --check`
- `python3 scripts/check_moonclaw_gap_remediation_receipt.py`
- `/Users/kq/.moon/bin/moon test`

## Acceptance Criteria

- gap-report-consumed: Task input names the imported-clearance preview and includes every current blocker gap with evidence path and next action.
- remediation-commands: Commands cover terrain/corridor review, power-window verification, imported transition rebuild, workspace check, and MoonBit tests.
- robot-safety-invariant: MoonRobo hardware_state remains HardwareDenied and authority remains moonmoon-safety-gate-only while remediation is incomplete.

## Robot Safety Invariants

- hardware_state must remain HardwareDenied
- hardware_authority must remain moonmoon-safety-gate-only
- physical execution authority must not be emitted by MoonMoon
- simulation readiness must be regenerated from mission checks, not from clearance acceptance alone
