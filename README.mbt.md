# MoonMoon

> **Domain product · digital simulation alpha.** Read the
> [product contract](docs/PRODUCT_CONTRACT.md) for evidence claims, the
> MoonRobo boundary, capability status and release gates.

MoonMoon is a MoonBit-native lunar terrain and mission model.

[Imported-raster relief shading](docs/TERRAIN_RELIEF.md) makes source-bound SVG
maps with adjustable grid-relative light direction and display relief scale.
Compare light or terrain revisions with replayable JSON and per-face CSVs;
unknown neighborhoods remain hatched. This is not real lunar illumination.

[Detached PDS3 elevation intake](docs/PDS3_IMPORT.md) decodes local signed-16-bit
IMG clips with explicit grid, datum and uncertainty declarations. Inspect raw
codes and scaled elevations, preserve unknown cells, then edit and export through
the terrain tools. No projection, radius conversion or dataset qualification.

[Coarse terrain overviews](docs/TERRAIN_COARSENING.md) turn aligned blocks into
portable lower-resolution grids, with side-by-side maps and per-block observed
extrema and coverage. Missing fine cells withhold the whole block mean; reduced
relief can hide hazards and supplies no navigation authority.

[Terrain destination exploration](docs/TERRAIN_DESTINATION_EXPLORATION.md)
maps every known-cell destination under a declared one-way travel-cost budget.
Choose a candidate, carry its exact path into corridor and energy assessment,
then edit terrain or assumptions and compare the new exploration.

[Terrain contour exploration](docs/TERRAIN_CONTOURS.md) exports source-bound
SVG maps, segment CSVs and retained-source JSON from imported terrain at chosen
elevations. Inspect crater or saddle terrain without filling missing coverage.

The study UI supports [frozen mission authoring](docs/MISSION_AUTHORING.md):
fork and edit inputs, run the exported proposal with the native simulator, and
reimport compatible comparison results. The native command step is currently
required; browser execution and physical authority are not provided.

The cockpit also supports [local terrain raster exploration](docs/LOCAL_TERRAIN_IMPORT.md):
import an Esri ASCII clip, inspect cell-center coordinates and NODATA coverage,
then export sparse terrain CSV and a reopenable source bundle.
The native [OBJ export workflow](docs/TERRAIN_OBJ_EXPORT.md) creates source-bound
metre/Z-up reference meshes for 3D tools, retaining NODATA holes and vertex/face
mappings with a replayable JSON sidecar. The same MoonBit
parser is available through `cmd/terrain_import`; importing does not change a
frozen mission study.

The native [terrain revision workflow](docs/LOCAL_TERRAIN_REVISIONS.md) exports
editable cell sheets and applies declared elevations or unknown masks as new
reopenable sources. It preserves original inputs and edit reasons while existing
analysis and routes use the revised coverage.

The project is intentionally small: source data lives under `data/`, domain
logic lives under `src/`, and the root package is only a facade. Generated
Markdown, JSON, HTML, screenshots, and future build products should not be
committed as source.

## Shape

- `src/core`: common lunar coordinates, provenance, uncertainty, and source
  claim types.
- `src/data_core`, `src/data_store`, `src/data_validate`: generic data refs,
  local data-root persistence, and data-root validation.
- `src/lunar_data`, `src/lunar_catalog`, `src/site_catalog`: lunar source
  records, catalog materialization, and catalog-backed first-site evidence.
- `src/robot_data`, `src/robot_catalog`: pure robot
  episode/model/signal/replay/telemetry/gait contracts and the robot data-root
  materialization adapter.
- `src/terrain`: terrain source manifests, checked DEM fixtures, grid analysis,
  slope, roughness, and hazard classification.
- `src/mission`: traverse scoring, corridor ranking, horizon evidence, terrain
  remediation, energy assessment, and route clearance.
- `src/site`: the assembled first trusted square dossier.
- `src/ui`: renderer-neutral view models plus a standalone MoonBit-rendered
  HTML inspection page.
- `ui/rabbita-moon`: Rabbita-native app for the live 3D terrain view, built as
  relative static assets for browser or Lepusa packaging.
- `lepusa.json`: least-privilege static desktop manifest; domain and UI behavior
  remain in MoonBit and Rabbita.
- `src/kernel`: the compact product kernel, evidence gates, and near-term build
  queue.
- `cmd/main`: the native CLI.

## Docs

- [docs/README.md](docs/README.md): documentation guide, scope, testing, and
  future plan.
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): package and product boundary.
- [docs/DATA_LAYER.md](docs/DATA_LAYER.md): general data-root design.
- [docs/ROADMAP.md](docs/ROADMAP.md): staged product direction.
- [docs/STEP_BY_STEP_PLAN.md](docs/STEP_BY_STEP_PLAN.md): implementation
  sequence and validation gates.
- [docs/UI_GUIDE.md](docs/UI_GUIDE.md): operator, Moonbook, and bookkeeper
  usage.
- [docs/UI_RELEASE_READINESS.md](docs/UI_RELEASE_READINESS.md): UI acceptance
  evidence, installed-app smoke results, and public-signing status.
- [docs/CAPABILITY_PACK.md](docs/CAPABILITY_PACK.md): executable pack tools,
  serialized MoonRobo handoff, replay/provenance receipts, and reconciliation.

## Run

```bash
moon run cmd/main
moon run cmd/main -- json
moon run cmd/main -- kernel
moon run cmd/main -- terrain
moon run cmd/main -- mission horizon
moon run cmd/main -- mission terrain
moon run cmd/main -- mission energy
moon run cmd/main -- robot-mission simulate <design-json> <moonmoon-root> <output-json>
moon run cmd/main -- data root-json target/data-roots/first-trusted-square
moon run cmd/main -- data ingest-first-site target/data-roots/first-trusted-square
moon run cmd/main -- data ingest-first-site target/data-roots/first-trusted-square json
moon run cmd/main -- data site-json target/data-roots/first-trusted-square
moon run cmd/main -- data ui-json target/data-roots/first-trusted-square
moon run cmd/main -- data ui-html target/data-roots/first-trusted-square
moon run cmd/main -- data robot-json target/robot-catalog-tests/episode-directory-import
moon run cmd/main -- data robot-readiness-json target/robot-catalog-tests/episode-directory-import
moon run cmd/main -- data ingest-robot-telemetry target/data-roots/robot-telemetry data/robot_telemetry/input telemetry-alpha robot-alpha session-alpha
moon run cmd/main -- data robot-telemetry-json target/data-roots/robot-telemetry telemetry-alpha
moon run cmd/main -- ui
moon run cmd/main -- ui json
moon run cmd/main -- ui html
moon run cmd/moonflow_adapter -- capability
moon run cmd/moonflow_adapter -- declaration
```

## Bound robot mission simulation

`robot-mission simulate` requires a typed `moonsuite.robot-design.v1` mission
that binds the MoonRobo robot/revision, staged `robot.json`, URDF, accepted
validation receipt, simulation bridge, and their SHA-256 identities. All staged
paths must remain relative to the supplied MoonMoon root. MoonMoon inspects the
profile, URDF identity, accepted simulation-only receipt, and disabled physical
bridge before a scenario can be accepted.

Every scenario records an ID, positive deterministic seed, kind, and injected
faults. A qualified `moonmoon.digital-twin-calibration.v1` input supplies the
testbed/source references, uncertainty, severity, observability, retained
performance, energy multiplier, and recovery action for each modeled fault.
The simulator records `normal -> degraded -> diagnosis -> recovery-attempt`
transitions and distinguishes recovered, reduced-mission, safe-return, and
fail-closed outcomes. Unknown or invalidly calibrated faults still fail closed.
Identical inputs produce byte-equivalent receipts.

An accepted result may claim `calibrated-digital-twin` only when its calibration
is qualified and referenced. This remains bounded digital evidence for the
enumerated terrain path; `physical_readiness` is always false.
It preserves broader-terrain blockers and explicitly does not establish slip,
sinkage, localization, dust, thermal-vacuum, manufacturing, launch, landing,
or physical lunar readiness.

The product-owned `pack.json` exposes the simulation as
`moonmoon/simulation.robot-mission@0.1.0` and exposes independent result
inspection as
`moonmoon/simulation.mission-result.inspect@0.1.0`. The `moonflow.adapter.v2`
runtime consumes serialized workspace artifacts, persists replay, provenance,
evaluation and attempt receipts, and supports restart reconciliation. It never
loads a sibling MoonRobo source checkout.

Robot episode imports read top-level text payloads as signal frames. Optional
`replays/` and `quality/` subdirectories are staged as replay and quality
evidence in the same episode dataset.

Robot telemetry imports are a separate data-root boundary. They create
`robot-telemetry-stream` datasets instead of hiding streams inside episode
frames.

The catalog-backed UI commands read the same validated first-site data root as
`data site-json`, so source labels and catalog manifest paths can come from the
materialized root instead of static product defaults.

Run the live browser view through Rabbita, not through generated `output/`
artifacts:

```bash
cd ui/rabbita-moon
npm install
npm run dev
```

Open `http://127.0.0.1:8766/first_trusted_square.html`.

The production build uses relative asset URLs so the same Rabbita output works
inside `lepusa://packaged/main/`:

```bash
cd ui/rabbita-moon
npm run build
```

The desktop release boundary is defined by `lepusa.json`. See
`docs/UI_RELEASE_READINESS.md` for the strict Lepusa verification, DMG,
installed-copy UI run, checksum, and signing limitations.

## Develop

```bash
moon check
moon test
moon info
moon fmt
```

`moon info` updates generated `.mbti` interfaces. Review those diffs as the
public API signal.

The product-home layout contract is covered by MoonBit tests in
`moonmoon_test.mbt`; keep root-level shell smoke scripts out of the core
development loop unless they guard a true external data or build boundary.

## Product Rule

MoonMoon owns lunar world claims. It may later export evidence to other Moon
suite products, but those adapters should be explicit boundary packages or
separate tools. The core repository should stay MoonBit-first and should not
grow around Python check scripts, committed `output/` trees, generated browser
asset bundles, or compatibility launch paths.

## Local metric terrain analysis

[XYZ CSV terrain intake](docs/LOCAL_XYZ_TERRAIN_IMPORT.md) imports grid-aligned
point observations with an explicit extent, original CSV/declaration digests,
and unknown missing cells. Use the native `terrain_import xyz` command before
the same metric analysis and routing commands; no manual ASCII conversion is needed.

Imported metre grids support editable row/column transects, local 3×3
least-squares slope and RMS roughness estimates, explicit missing coverage, and
source-bound CSV/report exports. See [the workflow and scientific
limits](docs/LOCAL_TERRAIN_ANALYSIS.md). No mission inputs or physical authority
are changed.

## Source-bound terrain study clips

Use `terrain_import crop` to select an exact rectangular row/column window from
an imported, revised or mosaic terrain source. Export reusable ASCII and a normal
terrain import while retaining the parent, provenance and cell mapping in a
replayable crop receipt. Existing analysis and routing use the new clip indices;
new boundaries can lose neighborhood coverage. See [study clips](docs/TERRAIN_STUDY_CLIPS.md).

## Candidate routes on imported terrain

Find a least-cost path between two known metric DEM cells with an editable
adjacent-grade cap and uphill preference. The native workflow produces a route
map, ordered row/column cells, elevation/grade CSV, and a source-bound report.
Try the [synthetic ridge routing example](docs/LOCAL_TERRAIN_ROUTING.md) to compare
a short climb with a longer flat detour. This is exploratory grid routing;
existing mission studies and energy semantics are unchanged.

Supply a `row,col` CSV to [route through ordered terrain waypoints](docs/ORDERED_TERRAIN_WAYPOINTS.md),
including repeated stops and return trips. Per-leg outcomes stay inspectable;
an impossible middle leg leaves an explicitly incomplete connected prefix.

## Coordinate terrain waypoints

The native `terrain_import waypoints-xy` command connects ordered x/y cell
centers in an imported source's declared metre frame, retains a coordinate
mapping and exports reusable row/column stops. See
[coordinate terrain waypoints](docs/COORDINATE_TERRAIN_WAYPOINTS.md).

## Exact imported-terrain path assessment

Assess an existing cell path, including exported `path-cells.txt`, without
optimizing or filling gaps. The native `assess-path` command preserves submitted
order, reports grade exceedances and unknown segments, and supports reassessment
on a revised source. See [the practical guide](docs/EXACT_TERRAIN_PATH_ASSESSMENT.md).

### Compare terrain revisions on an unchanged path

The native `terrain_import compare-path` command aligns an exact submitted path
across two compatible terrain sources and exports elevation changes, coverage
gains/losses and incident grade-status transitions. See
[terrain path comparison](docs/TERRAIN_PATH_COMPARISON.md) for the CLI and limits.

### Screen terrain around an exact path

Use `terrain_import assess-corridor` to inspect a configurable band of cells
around a submitted route, with local slope/roughness thresholds, missing-coverage
counts, per-stop summaries and a review map. See [imported terrain corridors](docs/IMPORTED_TERRAIN_CORRIDORS.md)
for the synthetic off-path bump workflow and limits.

### Explore imported-terrain visibility

Use `terrain_import visibility` to assess an elevated straight line between two
cell-center sites. Inspect exact cell clearances and an exported profile, then
vary the observer/target heights without changing the source. Known obstruction,
grazing and missing coverage remain distinct. See [terrain line-of-sight studies](docs/IMPORTED_TERRAIN_VISIBILITY.md)
for the synthetic ridge example and the explicit local flat-cell assumptions.

## Whole-area terrain revision inspection

Compare two aligned imported terrain bundles with `terrain_import compare-area`
to inspect all-cell elevation changes, gained/lost coverage, a standalone map
and declared square-cell observed volume differences. See
[the workflow guide](docs/WHOLE_AREA_TERRAIN_CHANGE.md). Unknown differences and
whole-grid totals stay null when coverage is incomplete.
