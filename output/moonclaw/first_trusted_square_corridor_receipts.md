# MoonClaw Corridor Receipts

- moonclaw/first-trusted-square/corridor-expansion-v1/current-receipt
  - proposal: moonclaw/first-trusted-square/corridor-expansion-v1
  - status: accepted
  - scan: first-trusted-square-9x9-corridor-scan-v2
  - sampled windows: 81
  - best window: r-12-c+16
  - selected route: northeast-stepout
  - next action: MoonClaw corridor expansion accepts the bounded search result but proves every sampled LOLA window remains blocked
  - validation:
    - corridor-scan-present: pass - 81 measured LOLA corridor windows are available.
    - bounded-search-size: pass - current corridor expansion receipt covers the reproducible 9x9 LOLA search surface.
    - best-window-promotion-state: pass - best measured window r-12-c+16 selects route northeast-stepout.
    - all-sampled-windows-blocked: pass - all sampled corridor windows remain blocked by conservative rover limits.
    - source-checksums-verified: pass - 6 of 6 dataset source fingerprints match their manifests.
    - proposal-blockers-current: pass - corridor proposal blocker corridor-scan-best-window remains active.
  - top windows:
    - #1 r-12-c+16: block risk 1.109925, grade 0.51395, roughness 5.95975 m, route northeast-stepout
    - #2 r+0-c+12: block risk 1.3170708, grade 0.579, roughness 7.380708 m
    - #3 r+0-c-16: block risk 1.4264667000000002, grade 0.61575, roughness 8.107167 m
    - #4 r-12-c+12: block risk 1.313075, grade 0.6223, roughness 6.90775 m
    - #5 r+16-c+4: block risk 1.3704792000000001, grade 0.62295, roughness 7.475292 m

