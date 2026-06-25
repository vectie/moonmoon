# MoonRobo Remediation Margin Clearance Projection

- projection: moonrobo/first-trusted-square/remediation-margin-v1/projection
- route: northeast-stepout
- source modeling pass: moonrobo/first-trusted-square/remediation-margin-v1/modeling-pass
- source modeling path: output/moonrobo/first_trusted_square_remediation_margin_modeling.json
- source modeling state: AllMarginsStillBlocking
- status: NoConsumeSimulationBlocked
- may consume simulation: false
- simulation state: simulation-blocked
- active margins: 3
- cleared margins: 0
- still blocking margins: 3
- hardware state: hardware-denied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- reason: no-consume projection: 3 remediation margins still block simulation consumption from AllMarginsStillBlocking; hardware authority remains moonmoon-safety-gate-only
- next action: do not let MoonRobo consume simulation for northeast-stepout; regenerate terrain, local-horizon, and energy evidence before changing simulation state

## Consumed Margin Results

- terrain-northeast-stepout
- illumination-northeast-stepout
- energy-window

## Blocking Margins

- terrain-northeast-stepout
- illumination-northeast-stepout
- energy-window

