# Lunar Ephemeris Source Boundary

This directory holds the first trusted square power-window evidence boundary.

`first_trusted_square_power_window.json` is intentionally a checked
source-files-ready fixture for now. It records the target site, the official
NAIF SPICE source family, local output contract, pinned source files,
computation method placeholder, and the reason Moonmoon must keep the energy
gate blocked until the local power window is computed.

Current pinned files:

- `naif0012.tls`
- `de440s.bsp`
- `pck00011.tpc`
- `moon_pa_de440_200625.bpc`
- `moon_de440_250416.tf`

The local copies, byte counts, and SHA-256 checksums are pinned. They are still
not a complete power-window result: temporal coverage selection, local horizon
assumptions, and computed sunlit/dark hours remain pending.

Regenerate the MoonBit mirror with:

```bash
python3 scripts/generate_power_window.py
python3 scripts/generate_power_window.py --check
```
