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

future src/robot_data
  Robot domain layer: episodes, frames, signals, robot models, replay/export
  projections, telemetry-specific quality.
```

Dependency direction:

```text
data_core
data_store     -> data_core
data_validate  -> data_core + data_store
lunar_data     -> data_core
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

Status: next.

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

Status: queued after Phase 4.

Goal: make the first trusted square read its source authority from the generic
catalog instead of from a standalone first-site manifest shape.

Implementation:

1. Write the lunar source and dataset manifests into the generic data root.
2. Rebuild and validate the catalog.
3. Add a small query path that lists source authority, payload refs, coverage,
   and validation state for the first trusted square.
4. Shrink `src/dataset` into either a compatibility wrapper or a focused lunar
   projection facade.
5. Remove stale per-feature checks that duplicate `data_validate`.
6. Commit and push after the UI and mission tests still pass.

Exit criteria:

- The first trusted square can explain which LOLA and ephemeris records it is
  using through the catalog.
- `src/dataset` no longer owns generic data-layer concepts.
- No stale Python or per-feature check script remains for data integrity that
  belongs in MoonBit validation.

### Phase 6: Robot Data Landing Zone

Status: queued after the Moonmoon catalog is proven.

Goal: prepare a general data layer that can accept robot data quickly without
copying lunar concepts.

Implementation:

1. Add `future src/robot_data` only when the first robot migration begins.
2. Map robot episodes, frames, signals, robot model refs, replay artifacts, and
   quality reports onto `data_core` refs and manifests.
3. Keep URDF, telemetry, gait clips, and replay semantics in `robot_data`, not
   `data_core`.
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
