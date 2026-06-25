# MoonClaw Ephemeris Receipts

- moonclaw/first-trusted-square/ephemeris-energy-v1/current-receipt
  - proposal: moonclaw/first-trusted-square/ephemeris-energy-v1
  - status: accepted
  - energy decision: block
  - has time-windowed ephemeris: true
  - power-window evidence: first-trusted-square-power-window-computed-v1
  - power-window source: data/sources/lunar_ephemeris/first_trusted_square_power_window.json
  - power-window source status: ready
  - routes: 6 total, 6 blocked
  - required sunlit hours: 4
  - dark survival hours: 13
  - required energy: 1265 Wh
  - verified available energy: 234.938073 Wh
  - next action: MoonClaw ephemeris acquisition is accepted; Moonrobo remains blocked by terrain, horizon, and energy-margin gates
  - validation:
    - energy-window-present: pass - 6 route candidates are represented in the current energy assessment.
    - time-window-ephemeris-computed: pass - current energy budget reads computed evidence first-trusted-square-power-window-computed-v1 for 2026-06-25T00:00:00Z through 2026-07-09T00:00:00Z.
    - power-window-source-ready: pass - generated power-window evidence source status is ready.
    - verified-available-energy-positive: pass - verified available energy is 234.938073 Wh from the computed time-windowed power source.
    - energy-margin-remains-blocked: pass - computed power remains insufficient for the conservative route set; energy margin is -1030.061927 Wh.
    - source-checksums-verified: pass - 6 of 6 dataset source fingerprints match their manifests.
    - expected-output-contract-present: pass - ephemeris proposal names the source evidence, generated MoonBit window, site output, and MoonBook energy payload outputs.
  - missing outputs:

