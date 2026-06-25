# Selected Route Terrain Remediation

- evidence: first-trusted-square-northeast-stepout-terrain-remediation-v1
- site: first-trusted-square
- route: northeast-stepout
- source: data/sources/lro_lola/first_trusted_square_northeast_stepout_dem.csv
- method: bounded-selected-route-terrain-remediation-v1
- decision: block
- max neighbor grade: 0.51395
- grade limit: 0.35
- grade margin: 0.16395
- roughness: 5.95975 m
- roughness limit: 2.5 m
- roughness margin: 3.45975 m
- blocking edges: 11 / 24
- confidence: 0.7544

## Reasons

- bounded 4x4 LOLA route window has max neighbor grade 0.513950 against limit 0.350000
- average neighbor roughness is 5.959750 m against limit 2.500000 m
- 11 of 24 neighbor edges exceed the conservative grade limit

## Next Action

collect a wider smoother selected-route corridor or keep northeast-stepout out of MoonRobo simulation

