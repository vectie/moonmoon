# Route Illumination Evidence

This phase turns Moonmoon's existing pinned ephemeris and local-horizon data
into operator-visible route evidence. It does not claim live lighting or route
clearance: the active power window is the checked fixture from
`2026-06-25T00:00:00Z` through `2026-07-09T00:00:00Z`.

## Product Outcome

The selected route and every inspected candidate expose:

- illumination decision and confidence;
- bounded or proxy local-horizon angle;
- maximum sampled Sun altitude when a bounded horizon exists;
- terrain-shadow margin;
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
2. Render the selected route's time window, horizon, Sun altitude, shadow
   margin, confidence, decision, and evidence path in the decision rail.
3. Update the panel when a candidate is inspected without changing mission
   selection.
4. Label routes without bounded local-horizon evidence as `not bounded` rather
   than presenting zero as a measured Sun altitude.

## Phase 3: Expand Horizon Coverage

Status: next feature work.

1. Generate bounded local-horizon evidence for the remaining five candidates.
2. Add azimuth-resolved horizon samples rather than one maximum obstruction.
3. Generate a new declared UTC power window from the pinned kernel boundary.
4. Recompute route illumination and energy decisions from those artifacts.

## Acceptance

- The UI never says ephemeris is missing when the checked DE440 fixture is
  attached.
- The selected route shows its 26.356833 degree terrain-shadow margin.
- Candidate inspection updates illumination values and evidence paths while
  the mission-selected route remains `northeast-stepout`.
- Desktop, tablet, and mobile layouts have no horizontal overflow.
- MoonBit, standalone runtime, adapter contracts, and production build gates
  remain green.
