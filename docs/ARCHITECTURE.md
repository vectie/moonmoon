# Architecture

Moonmoon is organized as a standalone MoonBit module.

```text
data/sources
  -> src/dataset
  -> src/terrain
  -> src/mission
  -> src/site
  -> src/ui
  -> cmd/main
```

The package boundary is the main design tool. Files inside a package are split
by responsibility, but package imports define the actual dependency graph.

## Boundaries

- `core` has no product policy. It defines reusable lunar data types.
- `dataset` describes source evidence and extraction metadata.
- `terrain` turns checked source fixtures into terrain metrics.
- `mission` turns terrain and power evidence into route decisions.
- `site` assembles one coherent dossier for the first trusted square.
- `ui` projects the dossier into renderer-neutral state and standalone HTML.
- `kernel` summarizes product layers, evidence gates, and next work.
- `cmd/main` is presentation only.

Generated artifacts belong outside source control. If a future workflow needs
durable exports, generate them from the CLI into an ignored directory.

