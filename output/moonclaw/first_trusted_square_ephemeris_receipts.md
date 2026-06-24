# MoonClaw Ephemeris Receipts

- moonclaw/first-trusted-square/ephemeris-energy-v1/current-receipt
  - proposal: moonclaw/first-trusted-square/ephemeris-energy-v1
  - status: needs-review
  - energy decision: block
  - has time-windowed ephemeris: false
  - routes: 5 total, 5 blocked
  - required sunlit hours: 4
  - dark survival hours: 2
  - required energy: 845 Wh
  - verified available energy: 0 Wh
  - next action: MoonClaw ephemeris acquisition cannot clear the energy gate until a cited time-windowed solar source, checksum, and generated MoonBit power window are attached
  - validation:
    - energy-window-present: pass - 5 route candidates are represented in the current energy assessment.
    - time-window-ephemeris-missing: pass - current energy budget explicitly has no time-windowed ephemeris attached.
    - verified-available-energy-zero: pass - verified available energy remains zero without a time-windowed power source.
    - source-checksums-verified: pass - 5 of 5 dataset source fingerprints match their manifests.
    - expected-output-contract-present: pass - ephemeris proposal names the source evidence, generated MoonBit window, site output, and MoonBook energy payload outputs.
  - missing outputs:
    - data/sources/lunar_ephemeris/first_trusted_square_power_window.json
    - src/mission/generated_first_trusted_square_power_window.mbt
    - output/site/first_trusted_square.json
    - output/moonbook/workspaces/first-trusted-square/mission/first-trusted-square/energy-window.json

