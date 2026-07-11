# Lunar Ephemeris Source Boundary

This directory holds the first trusted square power-window evidence boundary.

`first_trusted_square_power_window.json` is a checked computed fixture. It
records the target site, the official NAIF SPICE source family, local output
contract, pinned source files, computed time window, and the reason MoonMoon
must keep the energy gate blocked until the low-margin power result is reviewed.

Current pinned files:

- `naif0012.tls`
- `de440s.bsp`
- `pck00011.tpc`
- `moon_pa_de440_200625.bpc`
- `moon_de440_250416.tf`

The local copies, byte counts, SHA-256 checksums, and hourly DE440s computation
with all 13 PCK11 Moon-orientation terms are pinned. The corrected window keeps
the Sun below the spherical horizon throughout, so verified solar energy is
zero before local terrain shadow is applied. Panel attitude and wider terrain
evidence remain explicit blockers.

`first_trusted_square_observer_timeline.json` contains 14 daily full-observer
samples and 336 compact hourly Sun samples over the same half-open UTC window.
Daily samples record body-fixed Sun and Earth vectors, local altitude and
azimuth, and Earth illuminated fraction. The hourly track stores one start
time, one fixed cadence, and parallel Sun altitude/azimuth arrays for
route-horizon evaluation. `cmd/ephemeris` computes both the JSON artifact and
its typed MoonBit fixture directly from the pinned DE440s kernel.
The phase fraction is the illuminated Earth disc seen from the Moon, so it is
complementary to the Moon phase seen from Earth.

The JSON exposes the sampled minimum and maximum Sun altitude as typed fields.
MoonBit combines that window with each measured route grid to produce an
eight-sector bounded local-horizon profile.

`first_trusted_square_window_search.json` ranks one 14-day candidate per route
across a one-year hourly DE440 search beginning at the end of the checked
window. Windows advance by 24 hours. Ranking prefers windows that satisfy the
illumination constraint, then higher terrain-visible energy, shorter darkness,
more sunlight, and stronger minimum solar clearance. The selected
`northeast-stepout` result is `2026-11-08T00:00:00Z` through
`2026-11-22T00:00:00Z`, with 336 terrain-visible sunlight hours. This result
clears only the illumination constraint; it does not alter terrain, energy,
operator-review, or current-window mission authority.

The MoonBit mirrors are committed under `src/lunar_ephemeris` and `src/mission`
and checked by `moon test`. Regenerate the observer timeline with:

```sh
moon run --target native cmd/ephemeris
```

Regenerate the one-year route-window search with:

```sh
moon run --target native cmd/window_search
```
