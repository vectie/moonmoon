# Moonmoon

Moonmoon is a MoonBit-native lunar terrain and mission model.

The project is intentionally small: source data lives under `data/`, domain
logic lives under `src/`, and the root package is only a facade. Generated
Markdown, JSON, HTML, screenshots, and future build products should not be
committed as source.

## Shape

- `src/core`: common lunar coordinates, provenance, uncertainty, and source
  claim types.
- `src/dataset`: source manifests, acquisition notes, product selections, and
  extraction candidates.
- `src/terrain`: checked DEM fixtures, grid analysis, slope, roughness, and
  hazard classification.
- `src/mission`: traverse scoring, corridor ranking, horizon evidence, terrain
  remediation, energy assessment, and route clearance.
- `src/site`: the assembled first trusted square dossier.
- `src/ui`: renderer-neutral view models plus a standalone MoonBit-rendered
  HTML inspection page.
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
moon run cmd/main -- ui
moon run cmd/main -- ui json
moon run cmd/main -- ui html
```

## Develop

```bash
moon check
moon test
moon info
moon fmt
```

`moon info` updates generated `.mbti` interfaces. Review those diffs as the
public API signal.

## Product Rule

Moonmoon owns lunar world claims. It may later export evidence to other Moon
suite products, but those adapters should be explicit boundary packages or
separate tools. The core repository should stay MoonBit-first and should not
grow around Python check scripts, committed `output/` trees, or stale browser
asset bundles.

