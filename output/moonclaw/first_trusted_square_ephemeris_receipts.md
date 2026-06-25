# MoonClaw Ephemeris Receipts

- moonclaw/first-trusted-square/ephemeris-energy-v1/current-receipt
  - proposal: moonclaw/first-trusted-square/ephemeris-energy-v1
  - status: needs-review
  - energy decision: block
  - has time-windowed ephemeris: false
  - power-window evidence: first-trusted-square-power-window-sources-ready-v1
  - power-window source: data/sources/lunar_ephemeris/first_trusted_square_power_window.json
  - power-window source status: source-files-ready
  - routes: 6 total, 6 blocked
  - required sunlit hours: 4
  - dark survival hours: 2
  - required energy: 880 Wh
  - verified available energy: 0 Wh
  - next action: MoonClaw ephemeris acquisition has pinned source files but cannot clear the energy gate until a computed sunlit/dark window is attached
  - validation:
    - energy-window-present: pass - 6 route candidates are represented in the current energy assessment.
    - time-window-ephemeris-not-computed: pass - current energy budget explicitly reads first-trusted-square-power-window-sources-ready-v1, whose pinned sources have not produced a time-windowed computation.
    - power-window-source-files-ready: pass - generated power-window evidence source status is source-files-ready.
    - verified-available-energy-zero: pass - verified available energy remains zero without a time-windowed power source.
    - source-checksums-verified: pass - 6 of 6 dataset source fingerprints match their manifests.
    - expected-output-contract-present: pass - ephemeris proposal names the source evidence, generated MoonBit window, site output, and MoonBook energy payload outputs.
  - missing outputs:
    - data/sources/lunar_ephemeris/first_trusted_square_power_window.json
    - src/mission/generated_first_trusted_square_power_window.mbt
    - output/site/first_trusted_square.json
    - output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/energy-window.json

