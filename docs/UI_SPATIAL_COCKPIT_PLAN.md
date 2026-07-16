# Spatial Lunar Cockpit Upgrade

This is the active UI upgrade plan for MoonMoon. It builds on the completed
canonical lunar operator phase without reopening its compatibility work. The
goal is a world-first spatial cockpit where an operator can identify the site,
understand mission authority, inspect a route, and reach the next evidence in
seconds.

## Product Rules

- The Moon or local terrain is always the primary visual object.
- Mission authority comes from the MoonBit view model, never browser state.
- One overall mission decision dominates the first viewport.
- A favorable subsystem result is not mission authorization. Future windows
  are candidates until every mission gate passes.
- Controls must operate a real surface. Diagnostics and adapters use
  progressive disclosure.
- JavaScript owns canvas interaction, view state, and URL restoration only.
- MoonSuite visual-system assets may be copied with provenance, but MoonMoon
  has no runtime dependency on the visual reference application.

## Phase 1: Decision Cockpit

Status: complete.

1. Recompose the first viewport as a global command bar, full lunar stage, and
   concise contextual decision panel.
2. Put the overall decision, controlling blockers, and next action before
   route-level evidence.
3. Keep route inspection distinct from the mission-selected route.
4. Replace the long candidate list with a compact comparison disclosure.
5. Reduce stage controls to familiar icon commands with accessible tooltips.
6. Make the lighting timeline compact enough to preserve the lunar landscape.

Acceptance:

- The overall decision and next action are understandable within five seconds.
- No green subsystem label can be mistaken for route or mission approval.
- The selected route and primary blockers are visible without scrolling.
- No control is inert, and the Moon remains visually dominant.

## Phase 2: Spatial Operating Modes

Status: planned.

1. Add implemented Globe, Terrain, Routes, and Evidence modes.
2. Project the selected site, route corridor, hazard state, sun direction, and
   inspected cell onto the relevant spatial surface.
3. Keep inspected route, cell, time, and mode synchronized across the stage and
   contextual panel.
4. Persist restorable investigation state in the URL.

Acceptance:

- Every major panel claim has a visible spatial counterpart.
- Reloading or sharing a URL restores the same investigation.
- Mode switching does not lose the selected operational object.

## Phase 3: Illumination Workbench

Status: planned.

1. Promote the compact lighting timeline into a dedicated analysis mode.
2. Compare sun clearance with horizon obstruction across the route.
3. Compare current and ranked windows using explicit units and timestamps.
4. Explain physical versus readable lighting and energy consequences.
5. Preserve a complete textual and 2D fallback.

Acceptance:

- An operator can explain why the current route is blocked.
- A future window is always described as a candidate, never implicit approval.
- The plot identifies its route, time range, units, comparison, and next action.

## Phase 4: Robot Handoff

Status: planned.

1. Turn the adapter preview into a Robot mode only when its data is available.
2. Keep route authority, source validation, simulation freshness, and runtime
   availability visible in the same frame.
3. Add loading, unavailable, stale, and error states.
4. Keep the robot surface outside mission policy and route calculations.

Acceptance:

- Robot visualization cannot be mistaken for validated mission authority.
- Missing robot data does not break the lunar workflow.
- Hidden robot canvases do not consume render work.

## Phase 5: Visual-System Hardening

Status: planned.

1. Split style tokens, components, and responsive layout at real ownership
   boundaries while retaining one Vite stylesheet entry.
2. Formalize structural, floating, and control-glass material tiers.
3. Use telemetry typography for coordinates, timestamps, identifiers, and
   measured values.
4. Adopt the accepted monochrome suite mark and a reusable Lucide icon boundary.
5. Keep panel radii restrained and reserve pills for segmented or round controls.

Acceptance:

- Repeated styling is token-driven rather than copied declarations.
- Status colors communicate operational state only.
- The visual reference remains a source asset, not an application dependency.

## Phase 6: Responsive And Quality Gates

Status: planned.

1. Verify 1440x900, 768x1024, 390x844, and mobile landscape layouts.
2. Cover keyboard navigation, screen-reader updates, 44px targets, contrast,
   reduced motion, and readable no-blur fallbacks.
3. Test loading, empty, stale, unavailable, error, selected, and blocked states.
4. Add screenshot and canvas-pixel checks for nonblank spatial surfaces.
5. Verify hidden-canvas pause/disposal and browser-console cleanliness.

Acceptance:

- No supported viewport clips, overlaps, or horizontally scrolls.
- Every primary canvas is nonblank and correctly framed.
- Investigation state, accessibility semantics, and lifecycle behavior remain
  stable across navigation and reload.

## Delivery Order

There are four feature phases followed by two hardening phases. Each phase must
ship as a complete operator workflow and pass `moon check`, `moon test`,
`moon info`, `moon fmt`, the standalone runtime check, the Rabbita build, and
desktop/mobile browser acceptance before the next phase begins.
