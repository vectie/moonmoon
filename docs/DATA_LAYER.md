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
