# Route Illumination Evidence

This phase turns Moonmoon's existing pinned ephemeris and local-horizon data
into operator-visible route evidence. It does not claim live lighting or route
clearance: the active power window is the checked fixture from
`2026-06-25T00:00:00Z` through `2026-07-09T00:00:00Z`.

## Product Outcome

The selected route and every inspected candidate expose:

- illumination decision and confidence;
- bounded local-horizon angle and eight-sector azimuth profile;
- terrain-visible and terrain-shadowed sunlight hours;
- longest continuous darkness and route-available energy;
- minimum and maximum azimuth-matched solar clearance;
- power-window dates and evidence path.

Mission selection remains MoonBit-owned. Inspecting another candidate changes
only browser-local inspection state.

## Phase 1: Correct Mission Authority

Status: implemented.

1. Keep the pinned NAIF DE440 power-window evidence attached to every route.
2. Stop asking operators to attach ephemeris that is already present.
3. Combine terrain and illumination next actions when both gates block.
4. Include selected-route terrain shadow and energy margin in dossier blockers.

## Phase 2: Project Route Evidence

Status: implemented.

1. Add a compact illumination projection to `RouteView`.
2. Render the selected route's time window, visible sunlight, longest darkness,
   route energy, best solar clearance, decision, and evidence path in the
   decision rail.
3. Update the panel when a candidate is inspected without changing mission
   selection.
4. Preserve a `not bounded` fallback for future routes that do not yet have a
   measured horizon grid.

## Phase 3: Expand Horizon Coverage

Status: implemented for the six measured 4x4 route fixtures.

1. Generate bounded local-horizon evidence for all six candidates.
2. Add eight azimuth-resolved horizon sectors rather than one maximum
   obstruction.
3. Keep the eight-sector geometry typed so later temporal evidence can select
   the matching horizon by Sun azimuth.
4. Show the profile while inspecting candidates without changing mission
   selection.

## Phase 4: Drive Source-Backed Globe Lighting

Status: implemented.

1. Parse the pinned DE440s kernel in MoonBit.
2. Generate a compact body-fixed Sun/Earth observer timeline for the declared
   half-open UTC window.
3. Project one site-level lighting model into the canonical operator UI.
4. Drive the globe shader and timeline control from that checked evidence.

The implementation and regeneration boundary are documented in
`docs/LUNAR_LIGHTING_PHASE.md`. The next scientific expansion remains a wider
horizon grid and a newly declared UTC power window.

## Phase 5: Match Hourly Sun To Route Horizon

Status: implemented.

1. Preserve 336 compact hourly Sun altitude/azimuth samples beside the 14
   full observer samples.
2. Match every hourly sample to its measured horizon sector.
3. Apply the spherical horizon before counting terrain-visible sunlight.
4. Compute visible hours, terrain-shadowed daylight, longest darkness,
   route-available energy, and solar-clearance range per candidate.
5. Block the current window because the Sun never rises above the spherical
   horizon, and direct the operator to select a viable mission window rather
   than incorrectly blaming terrain coverage.

## Acceptance

- The UI never says ephemeris is missing when the checked DE440 fixture is
  attached.
- The selected route shows its PCK11-corrected hourly exposure summary.
- Candidate inspection updates illumination values and evidence paths while
  the mission-selected route remains `northeast-stepout`.
- Desktop, tablet, and mobile layouts have no horizontal overflow.
- MoonBit, standalone runtime, adapter contracts, and production build gates
  remain green.
