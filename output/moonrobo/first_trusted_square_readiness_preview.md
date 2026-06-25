# MoonRobo Imported Clearance Readiness Preview

- preview: moonrobo-readiness-preview/first-trusted-square/northeast-stepout
- route: northeast-stepout
- clearance decision: allow
- clearance allows simulation review: true
- mission readiness: block
- robot simulation status: simulation-blocked
- simulation state: SimulationBlocked
- hardware state: HardwareDenied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- blocker gaps: 6
- safety summary: selected-route clearance is allowed by imported operator decisions; MoonRobo simulation readiness is still gated by mission preconditions and MoonMoon keeps hardware execution denied

## Accepted Clearance Items

- clear-terrain-grade-northeast-stepout
- clear-illumination-confidence-northeast-stepout
- clear-energy-margin
- clear-moonbook-review-northeast-stepout

## Blocker Gap Report

- terrain-northeast-stepout (terrain-readiness)
  - evidence: mission/first-trusted-square/routes/northeast-stepout.json
  - clearance: AcceptedEvidence via clear-terrain-grade-northeast-stepout
  - next action: route terrain evidence reports grade 0.5139499999999998, roughness 5.95975 m, confidence 0.7544: review the promoted route fixture and attach ephemeris-backed illumination before simulation
- corridor-scan-best-window (corridor-readiness)
  - evidence: mission/first-trusted-square/corridor-scan.json
  - clearance: NotClearanceGated
  - next action: lowest max-neighbor-grade window in this measured 9x9 scan; selects route northeast-stepout and still blocked
- illumination-northeast-stepout (illumination-readiness)
  - evidence: output/mission/first_trusted_square_northeast_stepout_horizon.json
  - clearance: AcceptedEvidence via clear-illumination-confidence-northeast-stepout
  - next action: local horizon evidence records terrain-shadow blockage; collect wider horizon evidence before route simulation
- energy-window (energy-readiness)
  - evidence: mission/first-trusted-square/energy-window.json
  - clearance: AcceptedEvidence via clear-energy-margin
  - next action: energy gate reads power-window evidence first-trusted-square-power-window-computed-v1: revise rover power model, route count, or site window before simulation
- moonbook-review (moon-book-review-readiness)
  - evidence: output/moonbook/workspaces/first-trusted-square/review_transitions.json
  - clearance: AcceptedEvidence via clear-moonbook-review-northeast-stepout
  - next action: MoonBook review remains blocked because selected route northeast-stepout still has route or illumination blockers
- robot-simulation (robot-simulation-readiness)
  - evidence: output/moonrobo/first_trusted_square_handoffs.json
  - clearance: NotClearanceGated
  - next action: MoonRobo simulation stays blocked until mission readiness checks clear
