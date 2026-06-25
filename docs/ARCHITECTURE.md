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

- `src/kernel`
  Standalone MoonMoon product kernel. Names layer ownership, evidence gates,
  MoonSuite boundaries, and the build queue that keeps the project focused on
  the fastest path to a robot-facing lunar world model.
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
  MoonBook dossier and evidence export contracts.
- `src/adapters/moonclaw`
  Modeling job proposal packets and result receipts.
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

- `src/kernel`
- `src/core`
- `src/dataset`
- `src/terrain`
- `src/mission`
- `src/site`
- `src/adapters/moonbook`
- `src/adapters/moonclaw`
- `src/adapters/moonrobo`
- `src/ui`
- `cmd/main`

Each package owns typed contracts plus deterministic tests. The exported files
under `output/` are generated artifacts, not hand-maintained source of truth.
MoonBook workspace files are materialized from the generated site and MoonBook
JSON dossiers by `scripts/materialize_moonbook_workspace.py`.

The kernel sits above the first trusted-square proof slice. It is not a
compatibility layer; it is the product-facing contract for the standalone
project. If a future package does not help a kernel layer, clear an evidence
gate, improve a suite boundary, or complete a build-queue task, it should not be
added yet.

The first `src/ui` slice is renderer-neutral. It projects the trusted-square
dossier into terrain cells, route rows, selected-route state, and inspector
facts that a CLI or future Rabbita/Lepusa browser surface can render without
owning terrain derivation.

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
  -> site dossier and MoonBook evidence queue
```

Because that source file is now selected, checked in, and reproducibly fetched,
the current trusted-square dataset is marked as `measured` and `authoritative`
for software proof.

Moonmoon also records the LOLA replacement path as a typed source candidate
inside the site dossier and MoonBook export. That candidate is now accepted for
software proof and names the official PDS LOLA page, ODE Moon access point,
local target path, and follow-up action.

Moonmoon separately records the missing south-pole power evidence as a typed
ephemeris source candidate. The current candidate points at official NAIF SPICE
data discovery and the generic kernel source family, but remains
`needs-source-upgrade` until exact kernel/product files, byte counts, SHA-256
checksums, local paths, computed sunlit/dark hours, and generated MoonBit
power-window evidence are present. This keeps terrain proof and power proof
separate: measured LOLA windows can be accepted for software proof while
Moonrobo still stays blocked by absent time-windowed solar evidence.

The first power-window evidence boundary is now executable but intentionally
negative. `data/sources/lunar_ephemeris/first_trusted_square_power_window.json`
records the source-files-ready status, target coordinate, intended local
evidence path, pinned NAIF source files, computation placeholder, zero verified
Wh, and blocking reasons. The source-file entries are locally checksummed, but
the sunlit/dark window remains uncomputed. `scripts/generate_power_window.py`
mirrors that JSON into
`src/mission/generated_first_trusted_square_power_window.mbt`, and the mission
energy/illumination gates read the generated evidence instead of hard-coding the
absence of ephemeris input. MoonBook indexes this generated boundary as a
standalone `power-window-evidence` entry before the derived energy budget, so
the source state remains reviewable independently from route scoring. The
MoonBook review queue treats that evidence as a high-severity computation
blocker until a real time window replaces the checked source-files-ready
fixture. Moonrobo handoff packets include the same
`power-window-evidence` precondition before the derived energy-window gate, so
robot-facing simulation packets preserve the difference between missing source
evidence and computed energy margin.

The current fixture now has a checked source-file boundary:

- `data/sources/lro_lola/gdr_ds.cat`
- `data/sources/lro_lola/ldem_875s_20m_float.xml`
- `data/sources/lro_lola/first_trusted_square_dem.csv`
- `data/sources/lro_lola/first_trusted_square_west_contour_dem.csv`
- `data/sources/lro_lola/first_trusted_square_north_rim_dem.csv`
- `data/sources/lro_lola/first_trusted_square_southwest_bypass_dem.csv`
- `data/sources/lro_lola/first_trusted_square_south_stepout_dem.csv`
- `data/sources/lro_lola/first_trusted_square_corridor_scan.csv`
- `data/sources/lro_lola/first_trusted_square_corridor_scan_v2.csv`
- `scripts/verify_moonmoon_sources.sh`

The active terrain source file is a LOLA byte-range extraction. Its SHA-256 is
pinned in the manifest and verified before reproducible outputs are built. The
pinned LOLA catalog proves the GDR family context; the pinned product label
records the exact product LID, projection, bounds, resolution, array shape, data
type, unit, and raw image file name. The extracted LOLA CSV proves bounded IMG
window reads and records a reproducible checksum. The MoonBit fixture mirrors
that CSV through
`scripts/generate_moonmoon_fixture.py`, which writes
`src/terrain/generated_first_trusted_square_fixture.mbt`. The ranked corridor
scan is mirrored separately by `scripts/generate_corridor_scan.py` into
`src/mission/generated_first_trusted_square_corridor_scan.mbt`. Those generated
modules are now the terrain and mission packages' source for the
trusted-square elevations, the first adjacent route-window elevations, the first
widened corridor elevations, and the active 81-window corridor ranking. The 5x5
CSV remains a pinned baseline, while the pinned v2 9x9 CSV is the generated
MoonBit mission scan. Replacing or extending the CSV set with tiny
authoritative LOLA-derived extractions should keep the same pipeline shape.

The first measured LOLA patch blocks the conservative rover profile. Moonmoon
therefore records route alternatives as derived mission-planning claims tied to
local measured evidence windows, not as safe corridor claims. The direct route
preserves the measured blocked result; west-contour and north-rim alternatives
now point at adjacent measured LOLA windows, and both remain `block` because
their local grade and roughness still exceed the conservative rover limits. A
first 5x5 corridor scan then promoted southwest-bypass and south-stepout
windows; those named route fixtures remain `block`. The active 9x9 corridor
scan finds `r-12-c+16` as the lowest-grade measured window and promotes it as
the `northeast-stepout` route fixture. That route still remains `block`, so the
system records real progress without pretending it found a safe route.

Moonmoon now also attaches a conservative illumination/power gate to each route
candidate. The first version is intentionally limited: it uses local measured
relief as a shadow-risk proxy and marks the gate `block` when no time-windowed
solar ephemeris is attached. That keeps Moonmoon honest about the difference
between "we have a terrain sample" and "a robot can survive this route in a
specific lunar day/night window." Moonmoon also records a conservative rover
energy-window budget: estimated drive hours, dark survival hours, required Wh,
verified available Wh, and margin. With no time-windowed ephemeris attached,
the verified available energy is deliberately zero and the energy gate blocks.
The next modeling step is to execute the ephemeris acquisition plan so the
relief/energy proxies can be replaced with ephemeris-backed sun/thermal
windows.

The current MoonBook boundary is a generated workspace tree under
`output/moonbook/workspaces/first-trusted-square/`. Its `index.json` preserves
the aggregate entry list, each entry path contains the full typed payload behind
that evidence claim, `review_queue.json` records the current review status
snapshot, and `review_transitions.json` records the deterministic transition
log that produced that snapshot. That makes the workspace inspectable as files,
while the authoritative source remains the MoonBit-generated site and MoonBook
dossiers.

The current Moonrobo boundary is deliberately one-way: Moonmoon emits
simulation precondition packets under `output/moonrobo/`, and MoonBook indexes
those packets as evidence. A packet names the route candidate, target body, task
kind, combined decision, and the route, illumination, energy, and corridor
preconditions that must be cleared. It does not command hardware or imply
physical execution authority.

The current MoonClaw boundary is also one-way: Moonmoon emits bounded modeling
proposal packets, executable task packets, and deterministic receipt packets
under `output/moonclaw/`, and MoonBook indexes them as evidence. The first
proposals request ephemeris-backed power windows, wider LOLA corridor search,
and route-scoring receipts. The ephemeris task packet turns the critical
proposal into an operator/agent checklist: current inputs, required source
artifacts, readiness booleans, blocker reasons, generator commands, validation
gates, and the Moonrobo safety condition that must stay blocked until power
evidence is ready. The corridor task packet does the same for terrain search:
it names the baseline 5x5 scan, the active 9x9/81-window extraction, exact
commands, and the safety condition that prevents route promotion before the
best measured window has its own route fixture. The first route receipt
validates the current route-scoring job against route IDs, selected route,
source checksums, proposal blockers, energy blocker, and Moonrobo handoff
compatibility. The first corridor receipt validates that the bounded 9x9 LOLA
search ran, that 81 sampled windows are present, and that every sampled window
remains blocked. The first ephemeris receipt validates the
current absence of time-windowed solar evidence, records the missing output
contract, and keeps the power gate in review. Together these task and receipt
packets separate agent progress from physical execution authority.

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
