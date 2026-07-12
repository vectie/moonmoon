# MoonMoon

MoonMoon is a MoonBit-native lunar terrain and mission model.

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
- `ui/rabbita-moon`: Rabbita-native browser app for the live 3D terrain view.
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
