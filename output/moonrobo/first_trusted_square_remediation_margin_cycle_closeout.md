# MoonRobo Remediation Margin Cycle Closeout Policy

- policy: moonrobo/first-trusted-square/remediation-margin-v1/cycle-closeout-policy
- route: northeast-stepout
- status: NoConsumeCycleClosedForPolicy
- source refresh projection: moonrobo/first-trusted-square/remediation-margin-v1/refresh-projection
- source refresh projection status: NoConsumeRefreshSimulationBlocked
- source refresh projection path: output/moonrobo/first_trusted_square_remediation_margin_refresh_projection.json
- source follow-up projection: moonrobo/first-trusted-square/remediation-margin-v1/refresh-followup-projection
- source follow-up projection status: NoConsumeFollowupRefreshSimulationBlocked
- source follow-up projection path: output/moonrobo/first_trusted_square_remediation_margin_refresh_followup_projection.json
- refresh cycles: 2
- blocker count: 3
- may consume simulation: false
- simulation state: simulation-blocked
- hardware state: hardware-denied
- hardware authority: moonmoon-safety-gate-only
- hardware denied: true
- reason: no-consume remediation-margin refresh cycle closed for policy: first projection NoConsumeRefreshSimulationBlocked and follow-up projection NoConsumeFollowupRefreshSimulationBlocked still leave 3 terrain/horizon/energy blockers; hardware authority remains moonmoon-safety-gate-only
- next action: stop issuing automatic remediation-margin follow-up refreshes; apply the retry/escalate/freeze dispositions before any new MoonClaw task is emitted

## Dispositions

- terrain: terrain-northeast-stepout / refresh-terrain-northeast-stepout after 2 attempts -> EscalateToOperatorDecision; required evidence: operator-reviewed DEM slope and roughness evidence before another terrain refresh
- local-horizon: illumination-northeast-stepout / refresh-illumination-northeast-stepout after 2 attempts -> RetryWithNewEvidence; required evidence: new local-horizon or ephemeris evidence before retrying the horizon refresh
- energy: energy-window / refresh-energy-window after 2 attempts -> FreezeUntilNewSourceEvidence; required evidence: new power-window source evidence or rover energy profile before unfreezing energy

## Blocking Refreshes

- refresh-terrain-northeast-stepout
- refresh-illumination-northeast-stepout
- refresh-energy-window

## Blocking Margins

- terrain-northeast-stepout
- illumination-northeast-stepout
- energy-window

