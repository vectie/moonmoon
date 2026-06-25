# MoonRobo Remediation Margin Refresh Projection

- projection: moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection
- route: northeast-stepout
- source modeling pass: moonrobo/first-trusted-square/remediation-margin-v1/refresh-modeling-pass
- source modeling path: output/moonrobo/first_trusted_square_remediation_margin_refresh_modeling.json
- source modeling state: AllRefreshesStillBlocking
- source receipt: moonclaw/first-trusted-square/remediation-margin-v1/refresh-receipt
- source task: moonclaw/first-trusted-square/remediation-margin-v1/refresh-task
- source projection: moonrobo/first-trusted-square/remediation-margin-v1/projection
- status: NoConsumeRefreshSimulationBlocked
- may consume simulation: false
- simulation state: simulation-blocked
- refresh actions: 3
- refreshed: 0
- still blocking: 3
- hardware state: hardware-denied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- reason: no-consume refresh projection: 3 remediation-margin refreshes still block simulation consumption from AllRefreshesStillBlocking; hardware authority remains moonmoon-safety-gate-only
- next action: do not let MoonRobo consume refreshed simulation evidence for northeast-stepout; regenerate terrain, local-horizon, and energy refresh evidence before changing simulation state

## Consumed Refresh Results

- refresh-terrain-northeast-stepout
- refresh-illumination-northeast-stepout
- refresh-energy-window

## Blocking Refreshes

- refresh-terrain-northeast-stepout
- refresh-illumination-northeast-stepout
- refresh-energy-window

## Blocking Margins

- terrain-northeast-stepout
- illumination-northeast-stepout
- energy-window

