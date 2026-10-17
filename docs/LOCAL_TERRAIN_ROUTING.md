# Find a candidate route on imported terrain

For an existing submitted path or an exported `path-cells.txt`, use
[exact path assessment](EXACT_TERRAIN_PATH_ASSESSMENT.md) to inspect its grades
and missing coverage without replacing it with an optimized route.

For mandatory intermediate stops or return trips, use the
[ordered waypoint workflow](ORDERED_TERRAIN_WAYPOINTS.md). It reuses this search
for each successive pair and keeps impossible legs explicit.

Use the native terrain command to connect two known cells in a local imported
DEM. This complements the row/column profiles and 3×3 slope analysis: the new
route can bend around steep adjacent steps or missing cells. It does not replace
the existing frozen mission study, automatically run a mission, or modify inputs.

## Try the synthetic ridge

From the MoonMoon repository, choose output paths that do not exist:

```sh
moon run --target native cmd/terrain_import -- convert data/terrain_import/synthetic-route-ridge.asc /tmp/ridge-source ridge "Synthetic local Cartesian frame" m "Synthetic Apache-2.0 example; not observed lunar terrain"
moon run --target native cmd/terrain_import -- route /tmp/ridge-source/terrain-import.json /tmp/ridge-gentle 2 0 2 6 20 0
moon run --target native cmd/terrain_import -- route /tmp/ridge-source/terrain-import.json /tmp/ridge-short 2 0 2 6 60 0
moon run --target native cmd/terrain_import -- route /tmp/ridge-source/terrain-import.json /tmp/ridge-less-climb 2 0 2 6 60 4
```

The four endpoint arguments are zero-based start row, start column, goal row,
goal column. Row zero is the top input row. The final two arguments are maximum
absolute adjacent-center grade in degrees and a nonnegative uphill weight.

For this 7-column, 5-row example, the 20° cap finds a 100 m flat detour around the
15 m ridge. A 60° cap with zero uphill weight finds the 60 m direct route, with
15 m ascent and 15 m descent. Keeping the 60° cap and increasing uphill weight
to 4 chooses the flat detour instead: its cost of 100 is less than the direct
route's 60 + 4×15 = 120. The example has one NODATA cell, which is never entered.
These numbers demonstrate preferences on an invented terrain, not rover limits.

## Read and reuse the output

- Open `route.svg` in an SVG viewer or browser for an offline map. Elevation
  colors run from blue to orange; crossed gray cells are NODATA. The white
  polyline joins every chosen cell center. Green marks start and pink marks goal.
- `route.csv` contains the ordered cells, exact source-frame center coordinates,
  elevation, cumulative horizontal distance, signed incoming grade, ascent,
  descent, and objective cost. The first point has no incoming segment, so its
  rise and grade fields are blank. JSON uses explicit nulls for these fields.
- `path-cells.txt` contains the same ordered `row,col` pairs without a header.
  It is suitable for manual copy/paste into tools accepting that representation.
  The existing frozen-study route editor accepts only 2–256 cells and needs the
  corresponding frozen source. This command does not bridge imported terrain
  into that study or make long generated routes runnable there.
- `route-report.md` explains the selected assumptions and route totals.
- `terrain-route.json` embeds the reopened source bundle, parameters, full path,
  output text and digests. Its `route_digest` is SHA-256 of the compact MoonBit
  JSON representation before adding that field. Retain the entire directory.
  It is an output report, not an input to the terrain-source `reopen` command.

`candidate-found` means a path exists in the specified graph. `no-path` is a
successful completed search, with an empty path and null summary, not invented
zero-distance or zero-energy results. Its SVG still shows the source/endpoints.
The command exits zero for either search outcome; inspect `status` in JSON for
automation. Invalid inputs exit 2. An existing output directory is never reused.

## What is optimized

The algorithm uses Dijkstra's shortest-path method on known cell centers with
four cardinal neighbors and no diagonals. Each edge must meet:

`abs(atan((next_elevation - current_elevation) / cell_size)) <= grade_cap`

Angles are converted to degrees. Edge cost is:

`cell_size + uphill_weight × max(next_elevation - current_elevation, 0)`

The uphill weight is a dimensionless preference. Cost is expressed in
metre-equivalent units, not joules or predicted battery usage. At weight zero,
the algorithm minimizes horizontal grid distance among permitted paths. The
output additionally reports the piecewise 3D center-to-center distance, which is
not the optimized quantity. Equal-cost unsettled cells are selected in row-major
order; an equal-cost candidate retains the first predecessor. This produces one
deterministic alternative, not all alternatives. Reverse routing can differ
because uphill cost is directional. Matching start and goal returns one cell
with zero distance when the cell is known.

Calculations use floating-point arithmetic. Last bits, exact-threshold decisions
or near-equal costs can vary across runtimes; reproducibility means repeating
the same inputs and toolchain. Output digests bind the actual exported bytes.

The importer bounds the grid at 4096 cells. Routing is O(cells²) time with O(cells)
search storage. The existing parser validates and reopens the retained source;
metric routing requires declared metre coordinates and metre elevations.
It performs no reprojection or conversion. Endpoints must be inside the grid and
have known elevation. The cap must be finite in [0,90), and the weight finite
and nonnegative. Numeric overflow is an error, never an alternative cost.

## Interpretation limits

An adjacent-center grade is different from the existing 3×3 fitted-plane slope.
Neither resolves subcell hazards. A route can border unknown terrain, and this
point-path model has no vehicle width or clearance. NODATA remains excluded, not
filled. The graph does not model cross-slope, roughness, illumination, energy,
robot dynamics, risk, a geographic orientation, or physical suitability. Its
optimality applies only to this discrete graph and declared cost. The source,
frame, datum, accuracy and units remain user declarations. It is useful for
exploring digital candidates and preparing further analysis, not mission or
physical readiness.

The native command and public MoonBit `route_bundle` API use the same engine.
No new cockpit controls are included. Tests cover detours, grade-cap equality,
uphill weighting, signed grades, deterministic repeat, directional costs,
same-cell endpoints, unknown barriers, diagonal exclusion, rejected inputs and
overflow. The compiled native sample workflow writes the actual reusable files.

## Explore destinations first

If you know a start and a travel-cost budget but have not chosen an endpoint,
use [terrain destination exploration](TERRAIN_DESTINATION_EXPLORATION.md).
It maps minimum objective costs across the known-cell graph, distinguishes
over-budget, disconnected and unknown cells, and lets you select one candidate
for the existing corridor and energy assessment workflows.
