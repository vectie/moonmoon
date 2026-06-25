# Lunar Ephemeris Source Boundary

This directory holds the first trusted square power-window evidence boundary.

`first_trusted_square_power_window.json` is intentionally a checked
missing-source fixture for now. It records the target site, the official NAIF
SPICE source family, local output contract, candidate source files, computation
method placeholder, and the reason Moonmoon must keep the energy gate blocked
until exact ephemeris inputs are pinned with checksums.

Current candidate files:

- `naif0012.tls`
- `de440s.bsp`
- `pck00011.tpc`
- `moon_pa_de440_200625.bpc`
- `moon_de440_250416.tf`

These names are a source inventory only. They do not become ready evidence until
the local copies, byte counts, SHA-256 checksums, temporal coverage, and computed
sunlit/dark window are attached.

Regenerate the MoonBit mirror with:

```bash
python3 scripts/generate_power_window.py
python3 scripts/generate_power_window.py --check
```
