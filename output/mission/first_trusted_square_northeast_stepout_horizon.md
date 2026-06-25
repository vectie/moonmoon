# Selected Route Local Horizon

- evidence: first-trusted-square-northeast-stepout-local-horizon-v1
- site: first-trusted-square
- route: northeast-stepout
- source: data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv
- power window: first-trusted-square-power-window-computed-v1
- method: bounded-local-horizon-v1
- decision: block
- max horizon angle: 26.487251 deg
- max sun altitude: 0.130418 deg
- terrain-shadow margin: 26.356833 deg
- confidence: 0.66

## Reasons

- bounded 4x4 LOLA horizon angle 26.487251 deg exceeds maximum sampled sun altitude 0.130418 deg
- terrain-shadow margin is 26.356833 deg from data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv
- zero-horizon power window remains insufficient for local terrain-shadow clearance

## Next Action

collect wider local horizon and terrain-shadow evidence before route simulation

