# MoonClaw Modeling Receipts

- moonclaw/first-trusted-square/route-scoring-v1/current-receipt
  - proposal: moonclaw/first-trusted-square/route-scoring-v1
  - status: accepted
  - selected route: southwest-bypass
  - Moonrobo handoff: block
  - next action: MoonClaw route scoring accepts the current evidence result but keeps Moonrobo blocked until corridor and power evidence improve
  - validation:
    - route-candidates-present: pass - 5 route candidates are available for scoring.
    - selected-route-present: pass - corridor-selected route southwest-bypass exists in the current route candidate set.
    - source-checksums-verified: pass - 5 of 5 dataset source fingerprints match their manifests.
    - proposal-blockers-current: pass - route-scoring proposal blockers remain active: corridor-scan-best-window, energy-window, moonrobo-handoff.
    - energy-blocker-current: pass - current energy assessment is block and must remain a scoring blocker until ephemeris evidence is attached.
    - moonrobo-handoff-compatible: pass - primary Moonrobo handoff is block, matching the blocked route-scoring result.
  - route scores:
    - #5 direct-lola-window: block route score 6, risk 2.0843625000000006, grade 1.1593500000000005, roughness 9.250124999999999 m
    - #4 west-contour-detour: block route score 6, risk 1.6044916666666684, grade 0.7517000000000025, roughness 8.52791666666666 m
    - #3 north-rim-stepout: block route score 6, risk 1.4996125, grade 0.7280000000000001, roughness 7.716124999999998 m
    - #1 southwest-bypass: block route score 6, risk 1.3541166666666693, grade 0.6484500000000025, roughness 7.056666666666669 m
    - #2 south-stepout: block route score 6, risk 1.4354083333333336, grade 0.7199500000000001, roughness 7.154583333333335 m

