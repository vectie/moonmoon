# Moonmoon

Moonmoon is a MoonBit-native lunar terrain and mission model.

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
- `src/robot_data`, `src/robot_catalog`: pure robot episode/model/signal/replay
  contracts and the robot data-root materialization adapter.
- `src/dataset`: the narrow terrain fixture manifest/provenance facade still
  consumed by terrain fixtures.
- `src/terrain`: checked DEM fixtures, grid analysis, slope, roughness, and
  hazard classification.
- `src/mission`: traverse scoring, corridor ranking, horizon evidence, terrain
  remediation, energy assessment, and route clearance.
- `src/site`: the assembled first trusted square dossier.
- `src/ui`: renderer-neutral view models plus a standalone MoonBit-rendered
  HTML inspection page.
- `ui/rabbita-moon`: Rabbita-native browser app for the live 3D terrain view.
- `src/kernel`: the compact product kernel, evidence gates, and near-term build
  queue.
- `cmd/main`: the native CLI.

## Run

```bash
moon run cmd/main
moon run cmd/main -- json
moon run cmd/main -- kernel
moon run cmd/main -- terrain
moon run cmd/main -- mission horizon
moon run cmd/main -- mission terrain
moon run cmd/main -- mission energy
moon run cmd/main -- data ingest-first-site target/data-roots/first-trusted-square
moon run cmd/main -- data ingest-first-site target/data-roots/first-trusted-square json
moon run cmd/main -- data site-json target/data-roots/first-trusted-square
moon run cmd/main -- data robot-json target/robot-catalog-tests/episode-directory-import
moon run cmd/main -- ui
moon run cmd/main -- ui json
moon run cmd/main -- ui html
```

Robot episode imports read top-level text payloads as signal frames. Optional
`replays/` and `quality/` subdirectories are staged as replay and quality
evidence in the same episode dataset.

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

Moonmoon owns lunar world claims. It may later export evidence to other Moon
suite products, but those adapters should be explicit boundary packages or
separate tools. The core repository should stay MoonBit-first and should not
grow around Python check scripts, committed `output/` trees, generated browser
asset bundles, or compatibility launch paths.
