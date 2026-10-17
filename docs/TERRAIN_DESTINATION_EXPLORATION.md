# Explore destinations under a travel-cost budget

## Combined outbound and return budget

The separate `cmd/terrain_roundtrip` MoonBit entrypoint adds a Node CLI for a
combined outbound + return objective-cost budget. Existing `terrain_import reach`
remains one-way. Build with the repository's pinned dependencies:

```
moon build --frozen --target js --target-dir /absolute/ROUNDTRIP-BUILD cmd/terrain_roundtrip
node /absolute/ROUNDTRIP-BUILD/js/debug/build/cmd/terrain_roundtrip/terrain_roundtrip.js explore IMPORT/terrain-import.json ROUNDTRIP 2 0 20 2 140
node /absolute/ROUNDTRIP-BUILD/js/debug/build/cmd/terrain_roundtrip/terrain_roundtrip.js select ROUNDTRIP/terrain-roundtrip.json SELECTED-ROUNDTRIP 4 5
terrain_import assess-path SELECTED-ROUNDTRIP/terrain-import.json SELECTED-ROUNDTRIP/outbound-path-cells.txt OUTBOUND-ASSESS 20 2
terrain_import assess-path SELECTED-ROUNDTRIP/terrain-import.json SELECTED-ROUNDTRIP/return-path-cells.txt RETURN-ASSESS 20 2
terrain_import assess-corridor SELECTED-ROUNDTRIP/terrain-import.json SELECTED-ROUNDTRIP/outbound-path-cells.txt OUTBOUND-CORRIDOR 1 30 5
terrain_import assess-corridor SELECTED-ROUNDTRIP/terrain-import.json SELECTED-ROUNDTRIP/return-path-cells.txt RETURN-CORRIDOR 1 30 5
terrain_import energy-path SELECTED-ROUNDTRIP/terrain-import.json SELECTED-ROUNDTRIP/outbound-path-cells.txt data/terrain_import/synthetic-energy-assumptions.json OUTBOUND-ENERGY
terrain_import energy-path SELECTED-ROUNDTRIP/terrain-import.json SELECTED-ROUNDTRIP/return-path-cells.txt data/terrain_import/synthetic-energy-assumptions.json RETURN-ENERGY
```

Use the import command below first. Node is required for the new CLI, while the
unchanged assessment commands use the native `terrain_import` executable. Every
output directory must be new. No browser, provider or hardware is involved.

Open `ROUNDTRIP/reachability.svg` and `reachability-cells.csv`: each cell has
outbound, return, combined and remaining-budget costs. The synthetic `(4,5)`
destination fits exactly at 140 (70 each way); `(0,5)` is over budget. A grade
limit or coverage gap remains distinct from an unknown cell. Change assumptions
by exploring again into a new directory, optionally after the existing `revise`
command. Selection recomputes the saved study against its retained source and
rejects edited assumptions or results.

Selection retains `terrain-roundtrip-path.json`, the source `terrain-import.json`,
`outbound-route.json`, `return-route.json`, and each leg's `*-path-cells.txt`, CSV,
SVG and report. The ordered paths are distinct records with their actual travel
directions. They may share or retrace geometry. Both use the existing route
contract; no new parser is needed by path, corridor or energy assessment tools.
Keep the exploration with the selection to retain its bound study identity.

The algorithm solves two Dijkstra searches: forward edge costs from the start
and reversed edge costs from the start, giving costs back to the start. Uphill
cost is evaluated in the actual travel direction. It does not double outbound
cost: for elevations `0 10 20`, spacing 10 and uphill weight 2, outbound costs 60,
return costs 20 and combined cost is 80. The inclusive budget and deterministic
row-major ties follow the existing graph rules. The sum is checked for overflow.

This is still an objective-cost budget, not energy, time or a reserve. Assess
both legs independently. Two sufficient leg energy results do not establish
combined battery adequacy. The bundled example produces insufficient energy
and corridor threshold violations despite fitting the round-trip cost budget.
No frozen mission, physical readiness or approval changes. Each leg has at most
4096 cells; no potentially oversized concatenated path is passed to consumers.
Round-trip inputs and saved study bundles are bounded to 8 MiB. As with existing
commands, multi-file writes are not atomic: retain partial output and use a new
directory after interruption.

Verification uses the complete exact production terrain package with frozen
`moonbitlang/x@0.4.50` in a reduced module: 214 JS-target tests and the compiled
production Node CLI, followed by actual unchanged native assessment consumers.
The full root dependency graph, a new native build and browser interaction were
not qualified by this addition. `roundtrip_test.mbt` covers directional costs,
inclusive budgets, ordered leg paths, endpoint-route agreement, unknown and
disconnected cells, invalid/tampered studies, overflow and the 4096-cell grid.

## Existing one-way exploration

Before choosing a goal, find which known terrain cell centers fit a declared
one-way objective-cost budget. `terrain_import reach` expands the existing
grade-limited routing graph from one start to every possible destination in a
single Dijkstra search. The map distinguishes four outcomes:

- **Within budget:** a minimum-cost known-cell path fits, including equality.
- **Over budget:** a path exists in this graph, but its minimum cost is too high.
- **Not connected in model:** a known cell has no path from this start under the
  grade limit and known coverage. This does not establish real-world impossibility.
- **Unknown:** no elevation, so no path or cost is assigned to the cell.

This helps choose a destination without repeatedly guessing endpoints. A saved
exploration can then produce one exact candidate path for the existing corridor
and energy assessments. Imported ASCII, XYZ, revised, cropped and mosaic terrain
bundles use the same supported import contract. Metre cells and metre elevations
are required; grids with degree coordinates must be reprojected separately.

## Try a synthetic ridge and coverage gap

Build `cmd/terrain_import` using the repository's pinned MoonBit dependencies.
Below, `terrain_import` means the resulting native executable. All output
directories must be new. Names are examples; use absolute paths as appropriate.

```
terrain_import convert data/terrain_import/synthetic-reachability.asc IMPORT destination-demo "Synthetic local Cartesian frame" m "Bundled synthetic fixture, Apache-2.0; not measured lunar terrain"
terrain_import reach IMPORT/terrain-import.json EXPLORE 2 0 20 2 70
terrain_import reach-path EXPLORE/terrain-reachability.json SELECTED 4 5
terrain_import assess-corridor SELECTED/terrain-import.json SELECTED/path-cells.txt CORRIDOR 1 30 5
terrain_import energy-path SELECTED/terrain-import.json SELECTED/path-cells.txt data/terrain_import/synthetic-energy-assumptions.json ENERGY
```

Open `EXPLORE/reachability.svg`. Hover cells for exact row, column, status and
minimum cost, or inspect `reachability-cells.csv`. For small grids, row/column
labels are visible directly. Green darkens towards the budget boundary. The
white circle marks the start; grey crossed cells remain unknown. The map has no
external assets or scripts. Its orientation follows source rows/columns, with no
geographic north inferred.

The selected `(4,5)` cell costs exactly 70 metre-equivalent units. Its path bends
around the ridge. `(0,5)` costs 110 and cannot be selected from the 70-budget
exploration. `(2,7)` is a known cell on the other side of a coverage gap and is
not connected in the model. `(2,6)` is unknown. The downstream synthetic energy
assessment remains **insufficient-energy** even though the selected path fits
the geometric objective budget. Budget fit never substitutes for energy analysis.

`SELECTED` includes `terrain-import.json`, the exact retained terrain input;
`path-cells.txt`, reusable by path/corridor/energy tools; and the existing
`terrain-route.json`, `route.csv`, `route.svg`, and `route-report.md` outputs.
`terrain-reachable-path.json` binds that candidate to the saved exploration's
digest and explicit cost budget. Keep the original exploration with the selection.

## Revise assumptions or edit terrain

Run a larger budget into a new directory to consider `(0,5)`:

```
terrain_import reach IMPORT/terrain-import.json LARGER 2 0 20 2 110
terrain_import reach-path LARGER/terrain-reachability.json FARTHER 0 5
```

Or declare a new elevation in the opening of the ridge, preserving the original:

```
terrain_import revise IMPORT/terrain-import.json data/terrain_import/synthetic-reachability-edit.csv REVISED "Synthetic what-if: extend ridge; not a new measurement"
terrain_import reach REVISED/terrain-import.json REVISED-EXPLORE 2 0 20 2 70
```

The former `(4,5)` candidate now costs 90 and is over budget. The former saved
exploration still opens against its own original terrain. It is not silently
updated. Recompute with budget 90 into a further directory to select the revised
detour. Editing a saved exploration's parameters/results directly is refused;
use `reach` for new assumptions and `revise` for deliberate source changes.

## Exact model and limits

- Four cardinal neighbors, no diagonals. NODATA cells are excluded, not filled.
- Edges must satisfy the absolute adjacent-center grade cap in degrees, less
  than 90. This is not 3×3 slope, maximum subcell slope or a robot limit.
- Each edge costs horizontal cell spacing plus `uphill_weight * positive rise`.
  The uphill weight is a nonnegative dimensionless preference. Cost is in
  metre-equivalent units, and equals horizontal distance only when the weight
  is zero (or there is no ascent on the selected path).
- The full graph is solved beyond the budget boundary so disconnected and
  over-budget states remain distinct. Ties settle cells in row-major order and
  retain the first equal-cost predecessor. Costs use floating-point arithmetic.
- This is a **one-way** budget. No return trip, time, battery, reserve, clearance,
  cross-slope, roughness, illumination, wheel traction or dynamics is included.
  Run the relevant independent assessments. A graph path can border unknown data.
- Inputs remain bounded by the existing importer (4096 cells). Saved exploration
  bundles are bounded to 8 MiB. All source/frame/unit declarations remain
  unverified. No interpolation, smoothing, reprojection or source acquisition.
- This native offline workflow provides derived digital exploration only. It
  changes no mission acceptance, physical authority, optional archive availability
  or release qualification. External data quality, renderer/browser interaction,
  installed application lifecycle and physical validation remain separate gates.
- Existing output directories are refused. Multi-file writes are not atomic;
  preserve partial output after an interruption and retry with a new directory.

## Verification

`src/terrain_import/reachability_test.mbt` covers inclusive budget boundaries,
unknown vs disconnected cells, uphill direction, grade changes, zero budget,
deterministic comparison against endpoint routing, exact path/corridor reuse,
saved-source selection, malformed/changed studies, overflow and the full 4096-cell
grid. Existing route and terrain tests exercise the shared search refactor.

`scripts/verify_terrain_destinations.mbtx` drives the built native CLI through
import → explore → select → corridor/energy assessment → revise → recompute,
with budget changes, refusal cases, output preservation and source digests. It
keeps openable maps and all command transcripts in a fresh evidence directory.
