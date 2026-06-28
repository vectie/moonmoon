# Lunar Ephemeris Source Boundary

This directory holds the first trusted square power-window evidence boundary.

`first_trusted_square_power_window.json` is a checked computed fixture. It
records the target site, the official NAIF SPICE source family, local output
contract, pinned source files, computed time window, and the reason Moonmoon
must keep the energy gate blocked until the low-margin power result is reviewed.

Current pinned files:

- `naif0012.tls`
- `de440s.bsp`
- `pck00011.tpc`
- `moon_pa_de440_200625.bpc`
- `moon_de440_250416.tf`

The local copies, byte counts, SHA-256 checksums, and first hourly DE440s
sunlit/dark computation are pinned. This is still a conservative review result:
local terrain-shadow and panel-attitude modeling remain explicit blockers.

The MoonBit mirror is committed under `src/mission` and checked by `moon test`.
External ephemeris computation tools may exist outside this repository, but
they are not part of the committed source architecture.
