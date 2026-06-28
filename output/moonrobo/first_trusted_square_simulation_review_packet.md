# MoonRobo Selected-Route Simulation Review Packet

- packet: moonrobo-simulation-review-packet/first-trusted-square/northeast-stepout
- route: northeast-stepout
- clearance decision: allow
- clearance allows simulation review: true
- mission readiness: block
- robot simulation status: simulation-blocked
- simulation state: SimulationBlocked
- hardware state: HardwareDenied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- next action: Keep selected-route simulation blocked until terrain, horizon, and energy remediation margins clear in regenerated MoonMoon evidence; hardware remains denied by MoonMoon.

## Accepted Clearance Transitions

- clear-terrain-grade-northeast-stepout via rabbita-clear-terrain-grade-northeast-stepout-accept
  - reviewer: operator/rabbita-clearance-review
  - rationale: Rabbita accept decision for clear-terrain-grade-northeast-stepout: imported fixture
- clear-illumination-confidence-northeast-stepout via rabbita-clear-illumination-confidence-northeast-stepout-accept
  - reviewer: operator/rabbita-clearance-review
  - rationale: Rabbita accept decision for clear-illumination-confidence-northeast-stepout: imported fixture
- clear-energy-margin via rabbita-clear-energy-margin-accept
  - reviewer: operator/rabbita-clearance-review
  - rationale: Rabbita accept decision for clear-energy-margin: imported fixture
- clear-moonbook-review-northeast-stepout via rabbita-clear-moonbook-review-northeast-stepout-accept
  - reviewer: operator/rabbita-clearance-review
  - rationale: Rabbita accept decision for clear-moonbook-review-northeast-stepout: imported fixture

## Remediation Margins

- terrain-northeast-stepout (terrain-readiness)
  - evidence: output/mission/first_trusted_square_northeast_stepout_terrain_remediation.json
  - terms: grade margin, roughness margin
  - clearance: AcceptedEvidence
  - margin: route terrain remediation reports grade 0.51395, roughness 5.95975 m, blocking edges 11/24: collect a wider smoother selected-route corridor or keep northeast-stepout out of MoonRobo simulation
- illumination-northeast-stepout (illumination-readiness)
  - evidence: output/mission/first_trusted_square_northeast_stepout_horizon.json
  - terms: terrain-shadow margin
  - clearance: AcceptedEvidence
  - margin: local horizon evidence records terrain-shadow blockage; collect wider horizon evidence before route simulation
- energy-window (energy-readiness)
  - evidence: output/mission/first_trusted_square_energy_remediation.json
  - terms: bounded margin, margin gap
  - clearance: AcceptedEvidence
  - margin: energy remediation reports bounded selected-route margin -855.061927 Wh and margin gap 1105.061927 Wh from power-window evidence first-trusted-square-power-window-computed-v1: reduce reserve or dark-survival demand, increase verified power-window energy, or keep northeast-stepout out of MoonRobo simulation

## Remaining Non-Margin Blockers

- corridor-scan-best-window (corridor-readiness)
  - evidence: mission/first-trusted-square/corridor-scan.json
  - next action: lowest max-neighbor-grade window in this measured 9x9 scan; selects route northeast-stepout and still blocked
- moonbook-review (moon-book-review-readiness)
  - evidence: output/moonbook/workspaces/first-trusted-square/review_transitions.json
  - next action: MoonBook review remains blocked because selected route northeast-stepout still has route or illumination blockers
- robot-simulation (robot-simulation-readiness)
  - evidence: output/moonrobo/first_trusted_square_handoffs.json
  - next action: MoonRobo simulation stays blocked until mission readiness checks clear

## Robot Simulation Gates

- robot-simulation:noetix-e1-lab-01: NoetixSimulationBlocked
  - decision: output/moonclaw/first_trusted_square_noetix_readiness_decision.json
  - source metadata blockers: 50
  - physical model blockers: 9
  - active work items: 2
  - next action: keep Noetix evidence in MoonClaw review; all review artifacts are ready, so replace authoritative source metadata and physical model metadata, regenerate the decision, and keep hardware denied; resolve MoonRobo source_metadata_gaps and physical_model_gaps before enabling simulation consumption

## Hardware Denial Invariants

- hardware_state must remain HardwareDenied
- hardware_authority must remain moonmoon-safety-gate-only
- MoonMoon must not emit hardware commands or physical execution authority
- simulation readiness must be regenerated from mission checks, not from clearance acceptance alone
- current hardware_state is HardwareDenied
- current hardware_authority is moonmoon-safety-gate-only
