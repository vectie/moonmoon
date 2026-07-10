# DE440 Lunar Lighting Timeline

Status: implemented for the first trusted square.

## Product Outcome

The canonical Moon globe now uses checked observer geometry instead of a
hard-coded light vector. The operator can scrub 14 daily samples across the
existing half-open power window and switch between physical illumination and
an explicitly readable ambient-fill mode.

The 14 full samples are visualization evidence. A compact 336-sample hourly
Sun track drives route clearance by matching each Sun azimuth to the measured
terrain horizon sector.

## Step 1: Compute Observer Geometry

1. `src/lunar_ephemeris` parses the pinned type-2 DE440s SPK segments for the
   Earth-Moon barycenter, Sun, and Moon.
2. The package applies the IAU Moon orientation terms pinned in `pck00011.tpc`.
3. All 13 PCK11 nutation/precession terms contribute to right ascension,
   declination, and prime meridian orientation.
4. Each sample records body-fixed Sun and Earth vectors, local altitude and
   azimuth, and Earth illuminated fraction at the trusted-square observer.
   Earth phase is complementary to the Moon phase seen from Earth.
5. A separate compact hourly track stores one start time, one fixed cadence,
   and parallel Sun altitude/azimuth arrays for mission calculations.

## Step 2: Keep One Build Boundary

1. `moon run --target native cmd/ephemeris` reads the pinned kernel.
2. It writes the checked observer-timeline JSON under
   `data/sources/lunar_ephemeris`.
3. It writes the typed MoonBit fixture consumed by mission and browser builds.
4. The same command recomputes the hourly power-window summary.
5. Tests recompute both daily and hourly samples from the binary kernel and
   compare every field with tight floating-point tolerances.

## Step 3: Project Product State

1. `src/lunar_data` catalogs the timeline as a second ephemeris data ref.
2. `src/mission` carries the typed timeline inside power-window evidence.
3. `src/ui` projects one site-level lighting model rather than copying samples
   into every route.
4. The highest daily Sun sample is the initial timestamp; it remains below the
   spherical horizon in this declared window.
5. `src/mission` matches every hourly Sun sample to the corresponding
   eight-sector route horizon and computes visible hours, longest darkness,
   route energy, and solar-clearance range.

## Step 4: Drive The Globe

1. `ui/rabbita-moon/moon-globe.js` sends the selected body-fixed Sun vector to
   the WebGL shader.
2. Physical mode uses minimal ambient fill; readable mode changes only ambient
   fill and remains a separate scene state.
3. Canvas metadata exposes method, frame, both source paths, timestamp,
   Sun/Earth vectors, local angles, and Earth illuminated fraction.
4. The scrubber is hidden in local-terrain mode until that renderer consumes
   the same lighting contract.

## Step 5: Drive Earthrise

1. The lazy adapter scene receives the same typed lighting view and selected
   sample as the globe.
2. Local Sun and Earth altitude/azimuth place both directions in the scene's
   east/up/north frame; Earth phase and the terminator therefore come from the
   checked observer geometry.
3. Camera-relative limb shading and approximate physical angular size keep the
   distant Earth grounded in the lunar landscape.
4. Physical and Readable remain separate presentation states. GMST-based
   texture rotation does not replace DE440/PCK11 lighting authority.
5. Canvas metadata exposes the selected sample, source paths, frame, scene
   vectors, phase, local angles, and presentation mode.

## Acceptance

- No hard-coded globe light direction remains.
- Moving the timeline changes the timestamp and source-backed Sun vector.
- An open Earthrise preview follows the same timeline and mode.
- Route evidence evaluates all 336 hourly samples against azimuth-matched
  terrain horizons.
- Physical and readable modes remain distinguishable.
- The 390x844, 768x1024, and 1440x900 layouts have no overlap or horizontal
  overflow.
- MoonBit tests, catalog validation, browser contracts, and the production
  build remain green.
