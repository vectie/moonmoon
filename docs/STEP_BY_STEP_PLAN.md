# Step-by-Step Build Plan

MoonMoon is a new standalone product, not a compatibility shell around older
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

## Phase Order

The plan is now feature-first, then hardening. Phases 1-4 deliver the product
path a user can see or consume: selected route truth, movable Moon view, robot
data migration, and adapter handoff. Phases 5-7 harden the substrate and source
authority after the product path is moving.

## Phase 1: Explain the Selected Route Gate

Status: implemented for the first trusted square. The selected route clearance
plan is part of `SiteDossier`, markdown/JSON render paths expose it, and the
operator view projects both the summary and individual clearance gates. A
one-year DE440 search now ranks the next 14-day illumination window per route
without changing the blocked current-window decision.

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

Implementation plan:

1. Confirm the dossier owns the selected route decision.
   - Keep the selected route id, selected route trace, and clearance plan in
     `src/site`.
   - Keep route gate policy in `src/mission`, not in UI rendering.
   - Add only the fields needed to explain the selected route; avoid parallel
     readiness models.

2. Wire one route-gate projection through every output.
   - Add the selected route clearance summary to markdown first, because it is
     the most inspectable text artifact.
   - Add the same projection to `data ui-json`.
   - Make `src/ui` consume that projection instead of recalculating gate state.

3. Make the UI answer one operator question.
   - Show selected route, clearance decision, blocking gates, review gates,
     next action, and evidence path in one compact area.
   - Keep the scorecard and inspector facts connected to the same view model.

4. Lock the behavior with focused tests.
   - Test the selected route decision in the site package.
   - Test rendered HTML/JSON contains the same route id and clearance status.
   - Test markdown emits each gate with the required action.

5. Commit once the product answer is visible.
   - Commit after route truth appears in the dossier, JSON, and HTML.
   - Push before moving to Moon visualization changes.

6. Rank the next illumination window without weakening authority.
   - Generate one year of hourly Sun geometry from the pinned source boundary.
   - Evaluate every route over fixed 14-day windows at a daily stride.
   - Project the best per-route candidate separately from the current gate.
   - Keep terrain, mission energy, and operator review blocked until their own
     evidence changes.

Done when: a user can open the product view and answer: which route is
selected, which gate blocks it, what evidence backs the decision, and what must
change before traversal is allowed.

## Phase 2: Deliver the Canonical Lunar Operator Experience

Status: complete. `ui/rabbita-moon` is the canonical interactive product,
the generated page remains a static report, and robot motion stays behind a
mission-gated adapter preview. The completed checkpoint record is in
`docs/UI_UX_NEXT_PHASE.md`.
Checkpoint 2 now supports route-candidate inspection and terrain-cell
selection without changing the mission-selected route authority.

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

Implementation plan:

1. Establish one interactive product surface.
   - Make `ui/rabbita-moon` the canonical live operator UI.
   - Keep `src/ui` as the renderer-neutral MoonBit contract.
   - Keep generated HTML as a static report and fast boundary check.

2. Improve the source-backed visual layer.
   - Promote compact terrain cells, elevation range, slope, roughness, source
     dataset id, and source path into the view model.
   - Draw source-backed terrain texture before route overlays.
   - Keep large raw DEM/image products outside the repository; commit only
     compact fixtures and manifests.

3. Make movement and product truth correct before adding more layers.
   - Verify drag direction across east and west longitudes.
   - Keep initial zoom lunar-scale, then focus-site zoom local.
   - Keep controls limited to pan, wheel zoom, orbit, reset, and focus site.
   - Keep robot motion behind a closed, mission-gated adapter preview.

4. Add browser-grade checks after generated HTML checks.
   - Keep `scripts/check-standalone-ui-runtime.mjs` as the fast static/runtime
     smoke test.
   - Add browser screenshot checks only for layout, canvas nonblank state, and
     control reachability.
   - Test desktop, tablet, and mobile viewports before calling the phase done.
   - Exercise every visible control and reject horizontal overflow.

5. Commit in visible checkpoints.
   - Commit runtime organization separately from visual/data changes.
   - Commit browser QA separately from new source fixture work.

Done when: the first screen shows a movable Moon context, the user can zoom to
the trusted square, and visible evidence labels match catalog-backed records.

## Phase 3: Migrate Robot Data Through the General Layer

Goal: robot data should move in quickly without turning MoonMoon into a robot
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

Implementation plan:

1. Choose the first robot family by leverage.
   - Start with a family that can become visible quickly, such as robot model
     package metadata or one telemetry/episode fixture.
   - Define the smallest useful dossier for that family before writing import
     code.

2. Map robot terms onto generic data refs.
   - Put robot-specific ids, task labels, episode fields, gait clip fields, and
     rollout summaries in `src/robot_data`.
   - Reference payload paths, versions, checksums, and lineage through
     `src/data_core` types.
   - Do not add robot nouns to `src/data_core`.

3. Materialize through the catalog boundary.
   - Add one `src/robot_catalog` materializer that writes payloads and a
     manifest under the data root.
   - Add one reader that turns the stored manifest back into the robot dossier.
   - Validate the data root through `src/data_validate` after materialization.

4. Add one CLI path per real boundary.
   - Add an ingest command only if it writes a robot dataset family into the
     root.
   - Add a read command only if it returns a user-meaningful dossier or
     readiness projection.
   - Avoid commands that merely expose internal transforms.

5. Prove migration can repeat.
   - Add tests for manifest generation, read-back, and validation findings.
   - Document the next robot family only after the first family is committed.

Done when: robot migration can proceed family-by-family while generic packages
remain reusable for non-robot datasets.

## Phase 4: Add Suite Adapters After Route Readiness

Goal: MoonMoon should expose route-motion readiness, then external adapters can
consume it for robot walking or richer simulation.

Steps:

1. Keep `src/ui/motion_contract.mbt` as the current handoff.
   - The contract reports selected site, selected route, route gates, and next
     action.

2. Keep Moonphys robot-agnostic.
   - It may own generic transforms, contacts, joints, and rigid-body checks.
   - It should not own Noetix, URDF walking clips, or robot-specific gait
     policy.

3. Let suite adapters consume MoonMoon evidence later.
   - Robot model ingestion, URDF/FK mapping, gait clips, mesh assets, and
     browser animation belong outside standalone MoonMoon domain packages.

Implementation plan:

1. Freeze the handoff shape before adding adapters.
   - Treat `src/ui/motion_contract.mbt` as the product contract until a better
     package boundary is justified.
   - Include selected site, selected route, clearance gates, evidence paths,
     next action, and adapter readiness.

2. Make route readiness the only unlock.
   - Adapters may consume a route only after terrain, illumination, energy, and
     review gates allow traversal.
   - If a route is blocked, expose why and stop before robot-specific walking
     claims.

3. Keep adapter previews thin.
   - Put suite preview wiring in adapter/preview packages, not core lunar
     packages.
   - Use robot data imported through Phase 3, not direct references to external
     repository layouts.
   - Keep Moonphys concepts robot-agnostic.

4. Add one adapter consumer at a time.
   - Start with a read-only readiness export.
   - Then add one preview path that consumes route and robot dossier data.
   - Do not add live animation until the route contract and robot data are both
     stable enough to explain.

5. Validate contract compatibility.
   - Test blocked route export, review route export, and allowed route export.
   - Test adapter preview refuses blocked routes.

Done when: a route can become adapter-ready only after its terrain,
illumination, energy, and review gates allow traversal.

## Phase 5: Harden the General Data Layer

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

Implementation plan:

1. Audit generic package vocabulary.
   - Search `src/data_core`, `src/data_store`, and `src/data_validate` for
     lunar or robot terms.
   - Move domain nouns back into `src/lunar_data`, `src/site`, or
     `src/robot_data`.

2. Tighten generic types around durable concepts.
   - Keep source refs, dataset refs, versions, checksums, lineage, catalog
     entries, statuses, and validation findings as the public substrate.
   - Add helper constructors only when two domain packages need the same
     invariant.

3. Make `data_store` the only filesystem owner.
   - Centralize root layout, manifest paths, payload paths, JSON read/write,
     and catalog rebuild logic.
   - Keep domain packages responsible for interpreting payload meaning after
     read-back.

4. Make validation composable.
   - Keep generic checks for unsafe refs, missing payloads, checksum mismatch,
     duplicate ids, stale catalogs, and broken lineage.
   - Let domain packages append domain-specific validation without weakening
     generic findings.

5. Add boundary tests before expanding APIs.
   - Test invalid refs, missing files, checksum mismatch, duplicate manifests,
     and stale catalog behavior.
   - Run `moon info` after each API change and inspect generated interfaces.

Done when: a root can be inspected generically before any lunar or robot reader
is used, and domain readers can layer their own meaning on top.

## Phase 6: Improve Lunar Source Authority

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

Implementation plan:

1. Build the source register first.
   - Record candidate source records for global DEM, local DEM/image slices,
     nomenclature, lighting, and ephemeris.
   - Store source identity, authority, intended use, acquisition status,
     license/usage notes, and local fixture path where applicable.

2. Select compact first-square fixtures.
   - Use small reproducible extraction windows for the trusted square.
   - Keep generated fixtures small enough to commit and review.
   - Store extraction parameters next to the fixture manifest.

3. Convert source products into domain evidence.
   - Turn terrain products into elevation, slope, roughness, route candidates,
     and blockers.
   - Turn lighting/ephemeris products into confidence fields before making
     illumination claims.
   - Turn nomenclature products into labels only when coordinate matching is
     explicit.

4. Promote evidence through the site dossier.
   - Every terrain, route, lighting, and label claim should carry a source id
     or fixture evidence path.
   - The UI should show the source id for user-facing claims.

5. Validate source lineage.
   - Test source records are present for promoted claims.
   - Test missing source records block promotion into the dossier.
   - Keep acquisition scripts at true data boundaries, not in UI code.

Done when: the trusted square's terrain, route, lighting, and catalog labels
can be traced back to named source records and validated fixtures.

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

Implementation plan:

1. Define the expansion trigger before adding scope.
   - Add a second site only when the first site has route gates, source-backed
     terrain, visible Moon context, and clear evidence paths.
   - Add richer lunar layers only when Phase 6 source records can support them.
   - Add richer robot views only when Phase 3 data migration has a repeatable
     family pattern.

2. Reuse the same package boundaries.
   - New sites go through site/lunar packages and the generic data root.
   - New robot views go through robot data/catalog packages.
   - New UI surfaces consume existing view models or documented contracts.

3. Keep the generated standalone page until it is genuinely too small.
   - Add live UI packages only when the standalone page blocks real workflow
     needs such as multi-site comparison, long-running sessions, or richer
     operator interaction.
   - Do not create a parallel product shell for decorative reasons.

4. Add one expansion axis per checkpoint.
   - Choose one of: new site, richer lunar layer, richer robot view, or live UI
     package.
   - Commit and push that axis before starting another.

5. Protect the first site as the regression anchor.
   - Keep tests and generated outputs for the first trusted square stable.
   - Any expansion must preserve the original route gate and evidence story.

Done when: each expansion reuses existing boundaries instead of creating a new
parallel path.
