# Architecture

Moonmoon should be organized around a MoonBit core with optional surfaces and
sidecars around it.

```text
data sources
  -> dataset registry
  -> ingest adapters
  -> lunar coordinates
  -> terrain model
  -> derived layers
  -> site model
  -> mission constraints
  -> suite projections
```

## Package Direction

The first real implementation can follow this package shape:

- `src/core`
  Lunar identifiers, coordinates, tiles, terrain cells, provenance, uncertainty,
  and shared model types.
- `src/dataset`
  Dataset registry, source metadata, checksums, coverage, resolution, and
  citation records.
- `src/terrain`
  DEM fixtures, elevation sampling, slope, roughness, ridge/gully/crater hints,
  and deterministic terrain derivations.
- `src/site`
  Named lunar sites, site bounds, layer summaries, operational scorecards, and
  site dossiers.
- `src/mission`
  Route constraints, traverse windows, energy assumptions, construction-pad
  checks, mining-zone checks, and robot-facing task constraints.
- `src/adapters/moonbook`
  LunarBook dossier and evidence export contracts.
- `src/adapters/moonclaw`
  Modeling job packets and result receipts.
- `src/adapters/moonrobo`
  Robot simulation preconditions and route/hazard handoff contracts.
- `src/ui`
  Renderer-agnostic view models for terrain tiles, layers, inspectors, and
  uncertainty displays.
- `src/ui/rabbita-moon`
  Browser-facing lunar viewer and operator tool.
- `cmd/main`
  CLI entry point for fixtures, model summaries, exports, and later serve/bundle
  commands.

The root package can stay a thin facade once `src/` exists.

The current implementation has started this shape with:

- `src/core`
- `src/dataset`
- `src/terrain`
- `src/mission`
- `src/site`
- `src/adapters/moonbook`
- `cmd/main`

Each package owns typed contracts plus deterministic tests. The exported files
under `output/` are generated artifacts, not hand-maintained source of truth.

## Core Contracts

The important early types are:

- `LunarSite`
- `LunarBounds`
- `LunarCoordinate`
- `LocalFrame`
- `TerrainTile`
- `TerrainCell`
- `ElevationSample`
- `TerrainLayer`
- `HazardLayer`
- `IlluminationWindow`
- `ResourceSignal`
- `Provenance`
- `Uncertainty`
- `MissionConstraint`
- `RouteCandidate`
- `SiteDossier`

These should be small and boring. The project will grow around them.

## Data Sources

Moonmoon should start with explicit references to authoritative source families:

- LRO/LOLA global topography and gridded products through PDS.
- LROC imagery, mapping tools, and QuickMap/QuickMap3D references.
- Derived terrain products from open planetary reconstruction workflows such as
  Ames Stereo Pipeline, when used with clear warnings and validation status.
- Future lunar vision datasets such as MoonAnything when they become useful for
  perception experiments.

Large raster processing may require sidecars. That is acceptable if the
MoonBit-owned boundary remains the dataset manifest, derived model contract,
checksum, provenance, and validation report.

The first authoritative replacement target is a tiny LOLA-derived terrain
fixture. The PDS Geosciences LRO LOLA page identifies LOLA as the Lunar Orbiter
Laser Altimeter and points to derived/gridded data products, including GDR and
SLDEM families. Moonmoon should ingest only a small extracted fixture first, not
a full global raster. Moonmoon now pins the official GDR catalog metadata at
`data/sources/lro_lola/gdr_ds.cat` and checks its SHA-256 before dossier
generation, so product selection can proceed from durable evidence rather than
only a URL in prose. It also pins the selected
`ldem_875s_20m_float.xml` product label, whose metadata covers the first
trusted square with south-polar 20 m/pixel polar stereographic LOLA DEM data.
Moonmoon now also has a tiny active extraction at
`data/sources/lro_lola/first_trusted_square_dem.csv`, generated from HTTP byte
ranges against the selected IMG. The MoonBit contract should remain:

```text
authoritative source file
  -> source manifest with URL, citation, coverage, resolution, checksum
  -> extracted tiny fixture with reproducible checksum
  -> derived terrain metrics
  -> site dossier and LunarBook evidence queue
```

Because that source file is now selected, checked in, and reproducibly fetched,
the current trusted-square dataset is marked as `measured` and `authoritative`
for software proof.

Moonmoon also records the LOLA replacement path as a typed source candidate
inside the site dossier and MoonBook export. That candidate is now accepted for
software proof and names the official PDS LOLA page, ODE Moon access point,
local target path, and follow-up action.

The current fixture now has a checked source-file boundary:

- `data/sources/lro_lola/gdr_ds.cat`
- `data/sources/lro_lola/ldem_875s_20m_float.xml`
- `data/sources/lro_lola/first_trusted_square_dem.csv`
- `scripts/verify_moonmoon_sources.sh`

The active terrain source file is a LOLA byte-range extraction. Its SHA-256 is
pinned in the manifest and verified before reproducible outputs are built. The
pinned LOLA catalog proves the GDR family context; the pinned product label
records the exact product LID, projection, bounds, resolution, array shape, data
type, unit, and raw image file name. The extracted LOLA CSV proves bounded IMG
window reads and records a reproducible checksum. The MoonBit fixture mirrors
that CSV through
`scripts/generate_moonmoon_fixture.py`, which writes
`src/terrain/generated_first_trusted_square_fixture.mbt`. That generated module
is now the terrain package's source for the trusted-square elevations. Replacing
the CSV with a tiny authoritative LOLA-derived extraction should keep the same
pipeline shape.

## Old Terrain Project Lessons

The old `../tl-2022` project should be treated as a concept reference, not a
code dependency.

Useful ideas to preserve:

- DEM-first workflow
- terrain exaggeration for human inspection
- ridge and gully detection
- trench/path planning style derivations
- queryable terrain regions
- visual exports as evidence

Things to redesign:

- Python/Flask-era coupling between backend and UI
- ad hoc file/data conventions
- Earth/Australia-specific assumptions
- deployment shape
- untyped model boundaries

## UI Boundary

Rabbita should render Moonmoon view models. It should not own lunar science or
mission logic.

The first UI should include:

- tiled terrain viewport
- layer selector
- tile inspector
- source/provenance panel
- uncertainty badges
- route candidate overlay
- site scorecard

Lepusa should package the local operator experience once the browser surface is
useful.

## Trust Model

Moonmoon should classify every claim:

- `measured`: direct source data or minimally transformed source data
- `derived`: deterministic computation from measured or accepted data
- `simulated`: generated by a model or synthetic pipeline
- `assumed`: user/operator/model assumption
- `unknown`: explicitly missing or not trusted

Mission-facing decisions should expose blockers and confidence instead of
collapsing everything into one score.

The current trusted-square fixture deliberately marks its terrain source as
`simulated` and `curated-fixture`. Derived terrain metrics and mission traverse
decisions remain separate claims that cite the same dataset id and lower the
confidence where appropriate. This is the expected pattern: source evidence,
derived layers, and robot-facing decisions should be inspectable as distinct
claims.
