# MoonRobo Remediation Margin Refresh Follow-Up Projection

- projection: moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection
- route: northeast-stepout
- source modeling pass: moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-modeling-pass
- source modeling path: output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_modeling.json
- source modeling state: AllFollowupRefreshesStillBlocking
- source receipt: moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-receipt
- source task: moonclaw/first-trusted-square/remediation-margin-v1/refresh-followup-task
- source refresh projection: moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection
- source follow-up state: FollowupRefreshesCarriedForward
- status: NoConsumeFollowupRefreshSimulationBlocked
- may consume simulation: false
- simulation state: simulation-blocked
- follow-up actions: 3
- refreshed: 0
- still blocking: 3
- hardware state: hardware-denied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- reason: no-consume follow-up refresh projection: 3 remediation-margin follow-up refreshes still block simulation consumption from AllFollowupRefreshesStillBlocking; hardware authority remains moonmoon-safety-gate-only
- next action: do not let MoonRobo consume follow-up refreshed simulation evidence for northeast-stepout; regenerate terrain, local-horizon, and energy follow-up refresh evidence before changing simulation state

## Consumed Follow-Up Results

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

