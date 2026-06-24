# Lunar Ephemeris Source Boundary

This directory holds the first trusted square power-window evidence boundary.

`first_trusted_square_power_window.json` is intentionally a checked missing-source
fixture for now. It records the target site, the intended official NAIF SPICE
source family, the local output contract, and the reason Moonmoon must keep the
energy gate blocked until exact ephemeris inputs are pinned with checksums.

Regenerate the MoonBit mirror with:

```bash
python3 scripts/generate_power_window.py
python3 scripts/generate_power_window.py --check
```

