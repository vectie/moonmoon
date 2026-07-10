# DE440 Lunar Lighting Timeline

Status: implemented for the first trusted square.

## Product Outcome

The canonical Moon globe now uses checked observer geometry instead of a
hard-coded light vector. The operator can scrub 14 daily samples across the
existing half-open power window and switch between physical illumination and
an explicitly readable ambient-fill mode.

This is visualization evidence, not route clearance. Terrain-shadow decisions
continue to use the bounded route horizon profiles and the hourly power-window
extrema.

## Step 1: Compute Observer Geometry

1. `src/lunar_ephemeris` parses the pinned type-2 DE440s SPK segments for the
   Earth-Moon barycenter, Sun, and Moon.
2. The package applies the IAU Moon orientation terms pinned in `pck00011.tpc`.
3. All 13 PCK11 nutation/precession terms contribute to right ascension,
   declination, and prime meridian orientation.
4. Each sample records body-fixed Sun and Earth vectors, local altitude and
   azimuth, and Earth illuminated fraction at the trusted-square observer.

## Step 2: Keep One Build Boundary

1. `moon run --target native cmd/ephemeris` reads the pinned kernel.
2. It writes the checked observer-timeline JSON under
   `data/sources/lunar_ephemeris`.
3. It writes the typed MoonBit fixture consumed by mission and browser builds.
4. The same command recomputes the hourly power-window summary.
5. Tests recompute the timeline from the binary kernel and compare every field
   with tight floating-point tolerances.

## Step 3: Project Product State

1. `src/lunar_data` catalogs the timeline as a second ephemeris data ref.
2. `src/mission` carries the typed timeline inside power-window evidence.
3. `src/ui` projects one site-level lighting model rather than copying samples
   into every route.
4. The highest daily Sun sample is the initial timestamp; it remains below the
   spherical horizon in this declared window.

## Step 4: Drive The Globe

1. `ui/rabbita-moon/moon-globe.js` sends the selected body-fixed Sun vector to
   the WebGL shader.
2. Physical mode uses minimal ambient fill; readable mode changes only ambient
   fill and remains a separate scene state.
3. Canvas metadata exposes method, frame, both source paths, timestamp,
   Sun/Earth vectors, local angles, and Earth illuminated fraction.
4. The scrubber is hidden in local-terrain mode until that renderer consumes
   the same lighting contract.

## Acceptance

- No hard-coded globe light direction remains.
- Moving the timeline changes the timestamp and source-backed Sun vector.
- Physical and readable modes remain distinguishable.
- The 390x844, 768x1024, and 1440x900 layouts have no overlap or horizontal
  overflow.
- MoonBit tests, catalog validation, browser contracts, and the production
  build remain green.
