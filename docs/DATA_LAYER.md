# General Data Layer Plan

Moonmoon should grow a general data layer before adding more lunar products or
migrating robot data. The layer must be domain-neutral: it owns artifact
identity, provenance, payload references, cataloging, lineage, storage, and
validation. It must not know about lunar terrain, SPICE, craters, robots, URDF,
telemetry, browser UI, or runtime control.

The goal is one shared data substrate that Moonmoon can use now for lunar
sources and that Moonrobo can later use for robot data without carrying
Moonmoon-specific concepts.

## Target Boundary

```text
src/data_core
  Pure contracts: refs, manifests, versions, catalog entries, lineage,
  checksums, statuses, validation findings, safe data URI helpers.

src/data_store
  Local persistence: root layout, manifest paths, read/write JSON, catalog
  rebuild. This is the filesystem boundary.

src/data_validate
  Integrity certification: unsafe refs, missing payloads, checksum mismatch,
  duplicate ids, stale catalog, broken lineage.

src/lunar_data
  Lunar domain layer: LOLA, SPICE, IAU, Diviner, Apollo sample source records,
  terrain tiles, coordinate frames, coverage, resolution, extraction windows.

src/lunar_catalog
  Lunar data-root adapter: writes lunar records through data_store, validates
  through data_validate, and lists first-site evidence from the catalog.

src/site_catalog
  Product evidence adapter: replaces static first-site catalog claims with
  SiteDossier evidence read from a materialized generic data root.

src/robot_data
  Robot domain layer: episodes, frames, signals, robot models, replay/export
  projections, telemetry-specific quality.
```

Dependency direction:

```text
data_core
data_store     -> data_core
data_validate  -> data_core + data_store
lunar_data     -> data_core
lunar_catalog  -> data_core + data_store + data_validate + lunar_data
site_catalog   -> site + lunar_catalog
robot_data     -> data_core
```

`data_core` must stay dependency-light. A package that only needs `DataRef` or
`ArtifactRef` should not import filesystem access or validation policy.

## Execution Plan

This is the current build order. Each phase should stay small enough to review,
but large enough to move a real boundary instead of adding thin compatibility
code.

### Phase 1: Generic Data Contracts

Status: done.

Goal: define a domain-neutral vocabulary for data identity, provenance,
payload refs, versions, catalogs, lineage, and validation reports.

Implementation:

1. Add `src/data_core`.
2. Define `DataRef`, `ArtifactRef`, `DataSource`, `DatasetManifest`,
   `DatasetVersion`, `DataCatalog`, `LineageManifest`, and
   `ValidationReport`.
3. Add `data://` URI helpers and relative-path safety checks.
4. Add JSON round-trip and boundary tests.
5. Commit and push before adding filesystem behavior.

Exit criteria:

- `data_core` imports no Moonmoon domain packages.
- `data_core` contains no lunar, robot, UI, telemetry, or runtime-control
  vocabulary.
- Tests prove stable refs, catalog refs, lineage refs, and validation reports.

### Phase 2: Generic Data Store

Status: done.

Goal: create the local persistence boundary for the generic contracts.

Implementation:

1. Add `src/data_store`.
2. Own the data-root layout and path helpers.
3. Read and write generic JSON manifests.
4. Rebuild `indexes/catalog.json` from stored manifests.
5. Return typed store issues for missing or malformed files.
6. Commit and push before adding validation policy.

Exit criteria:

- `data_store` imports `data_core` and filesystem APIs only.
- Store tests prove root initialization, read/write, catalog rebuild, and typed
  missing-file failures.
- No lunar or robot concept appears in store code.

### Phase 3: Generic Data Validation

Status: done.

Goal: certify a data root without importing any domain model.

Implementation:

1. Add `src/data_validate`.
2. Check catalog freshness, manifest uniqueness, safe `data://` refs, local
   payload presence, byte counts, supported checksums, and lineage refs.
3. Store validation reports through `data_store`.
4. Keep unsupported checksum kinds as warnings unless they block correctness.
5. Commit and push before adding lunar products.

Exit criteria:

- `data_validate` imports only `data_core`, `data_store`, JSON, and filesystem
  APIs.
- Tests cover valid roots, unsafe refs, missing payloads, duplicate artifacts,
  checksum mismatch, stale catalogs, and broken lineage.
- Validation output is itself catalogable.

### Phase 4: Lunar Data Layer

Status: done.

Goal: move Moon-specific source records into a domain layer while projecting
their generic identities through `data_core`.

Implementation:

1. Add `src/lunar_data`.
2. Define lunar-only contracts for coverage, coordinate frame, product
   selection, extraction windows, source review status, and tile manifests.
3. Add first LOLA source records for the first trusted square.
4. Add first SPICE or ephemeris source records for the same site.
5. Expose generic `DataSource`, `DatasetManifest`, and `DataRef` projections
   for those records.
6. Add boundary tests proving `lunar_data` depends on `data_core` but not
   `data_store`, `data_validate`, robot packages, UI packages, or old dataset
   compatibility code.
7. Commit and push after tests pass.

Exit criteria:

- LOLA and ephemeris evidence can be listed as generic data sources and
  datasets.
- Lunar-specific fields stay in `lunar_data`, not in `data_core`.
- Existing first trusted square behavior still passes tests.

### Phase 5: Catalog-Backed First Trusted Square

Status: in progress.

Goal: make the first trusted square read its source authority from the generic
catalog instead of from a standalone first-site manifest shape.

Implementation:

1. Add `src/lunar_catalog` as the lunar store/validate adapter.
2. Write the lunar source and dataset manifests into the generic data root.
3. Copy committed first-site payload boundaries into that root.
4. Rebuild and validate the catalog.
5. Add a small query path that lists source authority, payload refs, coverage,
   and validation state for the first trusted square.
6. Shrink `src/dataset` into either a compatibility wrapper or a focused lunar
   projection facade.
7. Remove stale per-feature checks that duplicate `data_validate`.
8. Commit and push after the UI and mission tests still pass.

Exit criteria:

- The first trusted square can explain which LOLA and ephemeris records it is
  using through the catalog.
- `src/dataset` no longer owns generic data-layer concepts.
- No stale Python or per-feature check script remains for data integrity that
  belongs in MoonBit validation.

Current checkpoint:

- `src/lunar_catalog` materializes the first trusted square into a generic
  catalog root and validates it.
- `src/dataset` now projects migrated first-site source, product, extraction,
  and active DEM manifest fields from `src/lunar_data`.
- `src/lunar_data` now owns acquisition plans, route-window extractions, route
  terrain dataset records, and their generic dataset projections.
- `src/terrain` owns generated-grid fixture validation, while `data_validate`
  remains the data-root validation authority.
- Remaining cleanup: let product views read catalog-backed evidence directly.

Current step-by-step plan:

This is the working order for the next implementation passes. Do the earliest
unfinished step first unless a user-visible blocker forces a narrower fix. Each
step should end with tests, docs if the boundary changed, then a scoped commit
and push.

1. Move inline terrain fixture checks out of `src/dataset`.
   - Status: done.
   - Why: `src/dataset` should no longer own data integrity policy.
   - Code target: make terrain-owned fixture validation cover generated grid
     fingerprints, while `data_validate` remains the data-root authority.
   - Done when: terrain/site tests no longer depend on dataset validation
     types, and `src/dataset` has no duplicate validation API.

2. Make product-facing evidence read catalog-backed authority.
   - Status: done for the site dossier, kernel source gate, and UI source
     panel; continue widening this pattern as new evidence panels land.
   - Why: the product should explain source authority through the same catalog
     path that future data uses.
   - Code target: route the first trusted square source panel, dataset labels,
     and evidence summaries through `src/lunar_catalog` or through a narrow
     projection generated from it.
   - Done when: UI and kernel summaries can name the LOLA and ephemeris records
     from catalog entries, not from standalone first-site constants.

3. Shrink `src/dataset` to a focused projection facade.
   - Status: done for source candidates, acquisition plans, product
     selections, and extraction candidates; remaining surface is the terrain
     fixture manifest facade still consumed by `src/terrain`.
   - Why: it is currently the remaining historical package between lunar data
     and product views.
   - Code target: keep only product projection shapes that are still consumed by
     terrain, mission, site, kernel, or UI; move lunar facts into `lunar_data`
     and generic facts into `data_core`.
   - Done when: deleting any remaining `src/dataset` field would break a real
     product view or mission gate, not just compatibility.

4. Keep data-root commands at true build boundaries.
   - Status: done for the root `scripts/` directory; product-home layout is
     covered by MoonBit tests, not shell smoke scripts.
   - Why: scripts should exist only where MoonBit cannot yet own the boundary,
     such as downloading, preparing, or copying external payloads.
   - Code target: keep validation in MoonBit; keep external acquisition and
     asset preparation as small boundary commands.
   - Done when: stale per-feature check scripts are gone or replaced by
     MoonBit package tests and `data_validate` reports.

5. Add the robot-data landing contract after the lunar catalog path is clean.
   - Status: done for the pure domain landing contract: `src/robot_data`
     maps models, episodes, signals, replay artifacts, and quality reports
     onto `data_core`.
   - Why: robot migration needs a general layer, not a lunar-shaped layer.
   - Code target: define the minimal `robot_data` mapping for episodes, frames,
     signals, model refs, replay artifacts, and quality reports on top of
     `data_core`.
   - Done when: robot data can enter through `DataRef`, `DatasetManifest`,
     `DatasetVersion`, lineage, store, and validation without importing lunar
     packages.

6. Migrate robot data in small dataset families.
   - Why: each migrated family should be reviewable and reversible.
   - Code target: migrate one family at a time, with a catalog entry,
     validation report, and product-facing proof that the data is usable.
   - Done when: every robot migration commit has tests and can be pushed
     independently.

7. Keep the Moon view visible while data grows.
   - Why: the project should remain a product, not only a backend refactor.
   - Code target: keep the movable 3D Moon landscape as the first screen and
     connect visible labels to validated data as soon as each source lands.
   - Done when: every major data milestone improves terrain, lighting, site
     confidence, route review, or robot migration readiness in the product.

8. Promote the first external data ingest boundary.
   - Status: done for the first trusted square: `src/lunar_catalog` exposes a
     MoonBit ingest API and `cmd/main` exposes `data ingest-first-site`.
   - Why: the product needs real lunar data without letting download and
     conversion scripts become the application architecture.
   - Code target: one small boundary command that prepares a known lunar
     payload into the generic data root, plus MoonBit validation that certifies
     the result.
   - Done when: the catalog records a real acquired payload and the UI can show
     that payload's source, validation state, and site coverage.

9. Replace static first-site claims with catalog-backed live claims.
   - Status: done for the data-root product JSON path: `src/site_catalog`
     projects materialized catalog entries into `SiteDossier`, and `cmd/main`
     exposes `data site-json`.
   - Why: static fixtures are useful proof points, but the user should see
     product evidence coming from the same validated root that future data
     uses.
   - Code target: route source labels, data freshness, terrain confidence, and
     route blockers through catalog entries or domain projections generated
     from those entries.
   - Done when: deleting an old first-site constant no longer removes the
     product's source authority.

10. Revisit package boundaries before widening scope.
    - Why: the fastest route to a durable product is to keep the ecosystem
      small, directional, and easy to migrate.
    - Code target: inspect imports, public interfaces, tests, scripts, and root
      files before adding a new feature family.
    - Done when: the next feature starts from a clean boundary, not from
      compatibility glue.

Commit rhythm:

- Commit and push after each numbered step that changes code or public docs.
- Keep commits scoped to one boundary move.
- Run targeted tests first, then `moon check`, `moon test`, `moon info`, and
  `moon fmt` before a code checkpoint.

### Phase 6: Robot Data Landing Zone

Status: in progress. The pure `src/robot_data` landing contract is in place;
stored migration commands are still queued until the first robot dataset family
is selected.

Goal: prepare a general data layer that can accept robot data quickly without
copying lunar concepts.

Implementation:

1. Add `src/robot_data` as a pure domain package over `data_core`.
   - Status: done.
2. Map robot episodes, frames, signals, robot model refs, replay artifacts, and
   quality reports onto `data_core` refs and manifests.
   - Status: done for the first contract surface.
3. Keep URDF, telemetry, gait clips, and replay semantics in `robot_data`, not
   `data_core`.
   - Status: done for the boundary guard; future migration can add more
     robot-specific fields here without touching generic packages.
4. Decide whether existing `moondata://` refs become a domain alias or migrate
   to `data://`.
5. Add a migration script or command only at the data-root boundary.
6. Commit and push each migrated robot dataset family separately.

Exit criteria:

- Robot data can share refs, manifests, cataloging, lineage, storage, and
  validation with lunar data.
- Robot-specific data remains outside standalone lunar packages.
- The migration path does not require Moonmoon to import Moonrobo packages.

### Phase 7: Product Loop

Status: continuous.

Goal: keep every data-layer phase visible in the product instead of building an
unused backend.

Implementation:

1. Keep the live Moon view first: global lunar landscape, zoom into selected
   site, and show source-backed evidence.
2. Connect catalog entries to UI evidence labels only after the underlying
   manifests validate.
3. Keep operator-facing blockers tied to data validation, terrain gates, power
   windows, and review status.
4. Add higher-resolution lunar products only after the first site is cataloged
   and movable in the UI.
5. Commit and push any user-visible milestone with screenshots or generated
   artifacts kept out of source control unless they are true source fixtures.

Exit criteria:

- The user can see why the product is about the Moon before deep simulation is
  complete.
- New data sources improve a visible path: terrain, lighting, site confidence,
  route review, or future robot migration.
- The root directory stays clean and generated output remains ignored.

## Data Root Shape

The first generic root should stay small:

```text
data_root/
  sources/
  datasets/
  versions/
  artifacts/
  payloads/
  lineage/
  validations/
  indexes/
    catalog.json
```

Domain packages may define subfolders under `payloads/`, but the generic layer
owns the path safety rules and catalog surface.

## Step 1: `data_core`

Implement first because every other package depends on it.

Contracts:

- `DataRef`: ref id, kind, URI, content type, byte count, checksum.
- `ArtifactRef`: artifact kind, artifact id, manifest path, status, summary.
- `DataSource`: source id, authority, source URL, license, citation, created
  time, source payload refs.
- `DatasetManifest`: dataset id, kind, status, source refs, data refs,
  created time.
- `DatasetVersion`: immutable version id, dataset id, parent versions, status,
  data refs, created time.
- `CatalogEntry` and `DataCatalog`.
- `LineageEdge` and `LineageManifest`.
- `ValidationFinding` and `ValidationReport`.

Helpers:

- `data://` URI construction and relative-path extraction.
- Relative path safety checks.
- Payload-root classification.
- Checksum/status label helpers.
- Small constructors that keep defaults consistent.

Tests:

- `data://` accepts relative payload paths.
- Absolute paths, empty paths, backslashes, and parent-directory segments are
  rejected.
- JSON round trips preserve refs and manifests.
- Catalog refs become stable `ArtifactRef` values.

## Step 2: `data_store`

Implement only after `data_core` is stable.

Responsibilities:

- `initialize_root(root)`.
- Path helpers for sources, datasets, versions, artifacts, lineage,
  validations, and catalog.
- Read/write JSON manifests.
- Rebuild `indexes/catalog.json` from stored manifests.
- Return typed store issues instead of throwing raw filesystem errors.

Rules:

- Store code may depend on filesystem APIs.
- Store code must not know lunar or robot concepts.
- Store code must not perform domain validation beyond parse/read/write
  integrity.

Tests:

- Root initialization creates only the expected directories.
- Manifests persist and read back with stable JSON.
- Catalog rebuild discovers stored manifests.
- Missing files return typed issues.

## Step 3: `data_validate`

Implement after store read/write is working.

Checks:

- Catalog entries point to existing manifests.
- Manifest ids are unique within a root.
- Local `data://` refs are safe.
- Local payload refs resolve under the data root.
- Byte counts and checksums match when declared.
- Lineage edges reference known artifacts.
- Catalog can be rebuilt equivalently from manifests.

Output:

- A `ValidationReport` stored under `validations/`.
- Status is `passed`, `warning`, or `blocked`.

Tests:

- Valid tiny root passes.
- Missing payload blocks.
- Unsafe URI blocks.
- Duplicate id blocks.
- Checksum mismatch blocks.
- Broken lineage blocks.

## Step 4: `lunar_data`

Move Moonmoon-specific source concepts out of the generic layer.

Initial lunar contracts:

- `LunarSourceCandidate`
- `LunarProductSelection`
- `LunarExtractionCandidate`
- `LunarCoverage`
- `LunarCoordinateFrame`
- `LunarTileManifest`

Migration target:

- Wrap current LOLA and SPICE records from `src/dataset` with generic
  `DataSource`, `DatasetManifest`, and `DataRef`.
- Keep domain-specific fields such as projection, latitude/longitude bounds,
  resolution, source row/column windows, value offsets, and lunar frame in
  `lunar_data`.
- Keep existing `data/sources/lro_lola` and `data/sources/lunar_ephemeris`
  paths during the first migration.

Done when:

- The first trusted square still renders and tests pass.
- Current `src/dataset` can either become a compatibility wrapper or shrink to
  re-export lunar data constructs.
- LOLA/SPICE source metadata can be listed through the generic catalog.

## Step 5: Moonrobo Migration Path

After Moonmoon proves the generic core, Moonrobo can migrate its robot data
plane without copying lunar concepts.

Likely mapping:

- Moonrobo `DataRef`, catalog refs, lineage, validation reports, dataset
  manifests, dataset versions, and source manifests move toward `data_core`.
- Robot-specific episodes, frames, signals, URDF manifests, replay artifacts,
  and robot quality rules move toward `robot_data`.
- Existing Moonrobo `moondata://` refs can either remain as a domain alias or
  be migrated to `data://` with an adapter.

Do not start this migration until Moonmoon has:

- `data_core`
- `data_store`
- `data_validate`
- one lunar dataset visible through the generic catalog

## Boundary Tests

Add explicit tests early:

- `data_core` imports no project/domain packages.
- `data_store` imports `data_core` only.
- `data_validate` imports `data_core` and `data_store` only.
- `lunar_data` imports `data_core`; store/validate access should go through a
  small adapter only when needed.
- Generic data packages contain no Moon, robot, URDF, SPICE, LOLA, crater,
  telemetry, bridge, or UI vocabulary.

## Commit Plan

1. Docs and `data_core`.
2. `data_store`.
3. `data_validate`.
4. First `lunar_data` migration.
5. Catalog-backed first trusted square source listing.
6. Moonrobo migration plan after the Moonmoon data root is proven.
