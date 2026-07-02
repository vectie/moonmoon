# Step-by-Step Build Plan

Moonmoon is a new standalone product, not a compatibility shell around older
projects. The build order should keep the product credible at every checkpoint:
one inspectable Moon site, real evidence boundaries, clear route gates, and a
generic data layer that can later accept robot data without becoming
robot-specific.

## Operating Rules

1. Work on the highest-leverage boundary first.
   - Start with the feature that changes product truth, not a small cleanup.
   - Avoid temporary compatibility packages unless they are true data/build
     boundaries.

2. Keep source ownership explicit.
   - Generic refs, manifests, lineage, checksums, and validation live in
     `src/data_core`, `src/data_store`, and `src/data_validate`.
   - Lunar facts, coordinate frames, source selections, and extraction windows
     live in lunar packages.
   - Robot episodes, telemetry, gait clips, task labels, and rollout summaries
     live in robot packages.

3. Make every pass product-visible or boundary-visible.
   - Product-visible means the operator view, CLI JSON, or generated HTML shows
     the result.
   - Boundary-visible means a data root can materialize, read, and validate the
     result through the intended package boundary.

4. Commit and push after each finished checkpoint.
   - Keep each commit scoped to one boundary move.
   - Run the relevant MoonBit checks before committing.

## Phase 1: Explain the Selected Route Gate

Status: implemented for the first trusted square. The selected route clearance
plan is part of `SiteDossier`, markdown/JSON render paths expose it, and the
operator view projects both the summary and individual clearance gates.

Goal: the first trusted square must explain why the selected
`northeast-stepout` route is blocked or reviewable before any motion or robot
adapter can claim readiness.

Steps:

1. Add the selected-route clearance plan to the site dossier.
   - Use the existing mission clearance model for terrain grade,
     illumination confidence, energy margin, and operator review.
   - Keep this in `src/site` and `src/mission`; do not add UI-only policy.

2. Surface the clearance result in the product view.
   - Show the selected route, clearance decision, blocking item count, review
     item count, next action, and evidence path.
   - Reuse the existing inspector facts and scorecard before adding a new UI
     panel.

3. Update CLI and markdown outputs through existing render paths.
   - `data ui-json` and `data ui-html` should include the same route-gate
     explanation.
   - Markdown dossier output should list each clearance gate and required
     action.

4. Validate.
   - Add or update tests in `src/site`, `src/ui`, and any affected mission
     package.
   - Run targeted `moon check` and `moon test`, then full `moon check`,
     `moon test`, `moon info`, and `moon fmt`.

Done when: a user can open the product view and answer: which route is
selected, which gate blocks it, what evidence backs the decision, and what must
change before traversal is allowed.

## Phase 2: Make the Moon View Evidence-Backed and Movable

Status: started. The standalone operator page now opens with an inline movable
Moon globe that consumes the existing MoonBit view-model JSON, projects the
trusted-square footprint, selected route, corridor windows, and a LOLA-derived
terrain-cell texture, and keeps the route/grid inspector beside it. The
generated page is checked by `scripts/check-standalone-ui-runtime.mjs`.
Remaining work is browser QA across viewports and stronger global terrain
source products.

Goal: the first viewport should feel like an operable Moon landscape, then let
the user zoom into the selected site.

Steps:

1. Keep the initial view lunar-scale.
   - Start from a recognizable Moon landscape or globe-level context.
   - Let the selected site become the zoom target instead of the first thing
     filling the screen.

2. Replace decorative Moon texture with source-backed texture and elevation
   references.
   - Use explicit lunar source records for global terrain and image/elevation
     choices.
   - Commit manifests and compact fixtures, not large raw datasets.

3. Keep interaction lightweight.
   - Orbit, pan, zoom, selected-site focus, and route overlay are enough for
     the next product pass.
   - Do not add robot animation here.

4. Validate in the browser.
   - Check desktop and mobile framing.
   - Verify the canvas is nonblank, the Moon/site are visible, and route
     overlays do not overlap core UI.
   - Keep `scripts/check-standalone-ui-runtime.mjs` green as the generated HTML
     runtime boundary.

Done when: the first screen shows a movable Moon context, the user can zoom to
the trusted square, and visible evidence labels match catalog-backed records.

## Phase 3: Harden the General Data Layer

Goal: make the data layer general enough that lunar and robot datasets enter
through the same substrate while keeping domain vocabulary outside generic
packages.

Steps:

1. Keep `src/data_core` pure.
   - Only refs, manifests, versions, catalog entries, lineage, checksums,
     statuses, validation findings, and safe data URI helpers belong here.

2. Keep `src/data_store` as the filesystem boundary.
   - It owns root layout, manifest paths, JSON read/write, and catalog rebuild.
   - It does not interpret lunar or robot dataset kinds.

3. Keep `src/data_validate` as the integrity boundary.
   - It checks unsafe refs, missing payloads, checksum mismatch, duplicate ids,
     stale catalogs, and broken lineage.
   - It reports generic findings; domain packages explain domain meaning.

4. Add commands only at data boundaries.
   - Ingest commands materialize data into a root.
   - Read commands expose a dossier or readiness projection.
   - Internal transforms stay inside packages.

Done when: a root can be inspected generically before any lunar or robot reader
is used, and domain readers can layer their own meaning on top.

## Phase 4: Improve Lunar Source Authority

Goal: the Moon model should increasingly come from real data products, not
handwritten visual approximations.

Steps:

1. Record source candidates and acquisition plans.
   - Global terrain: LOLA or SLDEM-style DEM authority.
   - Local detail: higher-resolution regional terrain where practical.
   - Nomenclature: IAU/USGS-style feature names and coordinates.
   - Lighting and ephemeris: explicit source records before simulation claims.

2. Select product slices for the first trusted square.
   - Prefer compact, reproducible fixtures over large committed assets.
   - Store evidence paths and extraction windows so the product can explain
     where each claim came from.

3. Promote only validated evidence into the site dossier.
   - Terrain metrics, route candidates, power windows, and blockers must point
     back to catalog or fixture evidence.

Done when: the trusted square's terrain, route, lighting, and catalog labels
can be traced back to named source records and validated fixtures.

## Phase 5: Migrate Robot Data Through the General Layer

Goal: robot data should move in quickly without turning Moonmoon into a robot
project.

Steps:

1. Pick one robot dataset family at a time.
   - Model package, episode, telemetry stream, gait clip, annotation,
     alignment, task label, rollout summary, or quality report.

2. Add the domain contract in `src/robot_data`.
   - Define the robot-specific manifest and projections onto generic data
     refs, datasets, versions, and lineage.

3. Add the root adapter in `src/robot_catalog`.
   - Materialize payloads under `payloads/robot_data/...`.
   - Read back one dossier for that family.
   - Validate through `data_validate`.

4. Add CLI at the real boundary.
   - One ingest command if it materializes a dataset family.
   - One read command if it exposes a useful dossier or readiness view.

5. Commit the family before selecting the next one.
   - Do not widen `data_core` for robot-only terms.

Done when: robot migration can proceed family-by-family while generic packages
remain reusable for non-robot datasets.

## Phase 6: Add Suite Adapters After Route Readiness

Goal: Moonmoon should expose route-motion readiness, then external adapters can
consume it for robot walking or richer simulation.

Steps:

1. Keep `src/ui/motion_contract.mbt` as the current handoff.
   - The contract reports selected site, selected route, route gates, and next
     action.

2. Keep Moonphys robot-agnostic.
   - It may own generic transforms, contacts, joints, and rigid-body checks.
   - It should not own Noetix, URDF walking clips, or robot-specific gait
     policy.

3. Let suite adapters consume Moonmoon evidence later.
   - Robot model ingestion, URDF/FK mapping, gait clips, mesh assets, and
     browser animation belong outside standalone Moonmoon domain packages.

Done when: a route can become adapter-ready only after its terrain,
illumination, energy, and review gates allow traversal.

## Phase 7: Expand Only After the First Site Is Honest

Goal: add more sites and richer ecosystem features only after the first trusted
square has a clean evidence story.

Steps:

1. Add a second lunar site only after route clearance is clear.
2. Add richer lunar layers only after source authority is traceable.
3. Add richer robot views only after robot data enters through the generic
   layer.
4. Add live UI packages only after the generated standalone page is too small
   for the product workflow.

Done when: each expansion reuses existing boundaries instead of creating a new
parallel path.
