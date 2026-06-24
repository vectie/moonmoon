# MoonClaw Corridor Receipts

- moonclaw/first-trusted-square/corridor-expansion-v1/current-receipt
  - proposal: moonclaw/first-trusted-square/corridor-expansion-v1
  - status: accepted
  - scan: first-trusted-square-5x5-corridor-scan-v1
  - sampled windows: 25
  - best window: r+8-c-8
  - selected route: southwest-bypass
  - next action: MoonClaw corridor expansion accepts the bounded search result but proves every sampled LOLA window remains blocked
  - validation:
    - corridor-scan-present: pass - 25 measured LOLA corridor windows are available.
    - bounded-search-size: pass - current corridor expansion receipt covers the reproducible 5x5 LOLA search surface.
    - best-window-selected-route: pass - best measured window r+8-c-8 selects route southwest-bypass.
    - all-sampled-windows-blocked: pass - all sampled corridor windows remain blocked by conservative rover limits.
    - source-checksums-verified: pass - 5 of 5 dataset source fingerprints match their manifests.
    - proposal-blockers-current: pass - corridor proposal blocker corridor-scan-best-window remains active.
  - top windows:
    - #1 r+8-c-8: block risk 1.3541167, grade 0.64845, roughness 7.056667 m, route southwest-bypass
    - #2 r+4-c-8: block risk 1.5992875, grade 0.6913, roughness 9.079875 m
    - #3 r+0-c+8: block risk 1.5571167000000001, grade 0.7054, roughness 8.517167 m
    - #4 r-4-c-8: block risk 1.5203583, grade 0.7091, roughness 8.112583 m
    - #5 r-4-c+8: block risk 1.568775, grade 0.7125, roughness 8.56275 m

