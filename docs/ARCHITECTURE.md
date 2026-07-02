# Architecture

Moonmoon is organized as a standalone MoonBit module.

```text
data/sources
  -> src/data_core
  -> src/data_store
  -> src/data_validate
  -> src/lunar_data
  -> src/lunar_catalog
  -> src/dataset
  -> src/terrain
  -> src/mission
  -> src/site
  -> src/site_catalog
  -> src/ui
  -> cmd/main
```

The package boundary is the main design tool. Files inside a package are split
by responsibility, but package imports define the actual dependency graph.

## Boundaries

- `core` has no product policy. It defines reusable lunar data types.
- `data_core` will define the domain-neutral data contracts: refs, manifests,
  catalog entries, lineage, checksums, and validation reports.
- `data_store` will own local persistence for those contracts.
- `data_validate` will own generic integrity certification.
- `lunar_data` will own Moon-specific source metadata, coordinate frames,
  product selections, and terrain tile extraction records.
- `lunar_catalog` materializes lunar records into the generic data root and
  exposes catalog-backed first-site listings.
- `dataset` describes source evidence and extraction metadata.
- `terrain` turns checked source fixtures into terrain metrics.
- `mission` turns terrain and power evidence into route decisions.
- `site` assembles one coherent dossier for the first trusted square.
- `site_catalog` is the narrow adapter that replaces static first-site catalog
  claims with evidence read from a materialized generic data root.
- `ui` projects the dossier into renderer-neutral state, standalone HTML, and
  the route-motion contract exposed by `src/ui/motion_contract.mbt`.
- `kernel` summarizes product layers, evidence gates, and next work.
- `cmd/main` is presentation only.

## Locomotion Boundary

The current locomotion surface is deliberately not a robot gait implementation.
Moonmoon exposes `TraverseMotionContract` from `src/ui` to state whether the
selected route is ready for a future motion adapter. The contract names
`src/moonphys` as the generic physics core and `future-suite-adapter` as the
owner of robot-specific gait assets.

This keeps Moonphys clean: it may model vectors, transforms, articulated
kinematics, contacts, joints, and rigid-body worlds, but it does not own Noetix,
URDF walking clips, Rabbita browser bundles, or any robot-specific walk
primitive. When Moonrobo returns as a suite adapter, it should consume the
route-motion contract and provide robot gait assets outside the standalone
domain packages.

The phased implementation path is documented in
`docs/LOCOMOTION_PHASE_GUIDANCE.md`.

The general data-layer migration path is documented in `docs/DATA_LAYER.md`.

Generated artifacts belong outside source control. If a future workflow needs
durable exports, generate them from the CLI into an ignored directory.
