# Route through ordered terrain stops

The native `waypoints` command connects an explicit sequence of source-grid
cells. Each adjacent pair uses the [existing grade-limited, uphill-weighted
route search](LOCAL_TERRAIN_ROUTING.md). Stop order is fixed; no visit-order
optimization is performed. This is exploratory digital terrain analysis.

## Run a synthetic loop

Choose output directories that do not exist. From the repository:

```sh
moon run --target native cmd/terrain_import -- convert data/terrain_import/synthetic-route-ridge.asc /tmp/waypoint-source ridge "Synthetic local Cartesian frame" m "Synthetic Apache-2.0 example; not observed lunar terrain"
moon run --target native cmd/terrain_import -- waypoints /tmp/waypoint-source/terrain-import.json data/terrain_import/synthetic-waypoints-loop.csv /tmp/waypoint-loop 20 0
```

The input starts with exactly `row,col`, then 2–32 stops with integer,
zero-based row and column coordinates. Row zero is the top source row. The
first stop is the start, the last is the final destination. Blank data lines,
spaces around coordinates and CRLF line endings are accepted; quoted fields,
extra columns, fractional coordinates and out-of-bounds stops are rejected.
The CSV is bounded to 16,384 characters. The original CSV is retained in JSON.

The supplied loop repeats the starting stop, visits (0,3), visits (2,6), then
returns to (2,0). At a 20-degree grade cap and zero uphill weight it has 200 m
horizontal distance, zero ascent and 21 path cells. The repeated stop is a
successful zero-length leg. Shared leg junctions occur once in the combined
path, but later revisits are retained. `stops[].connected_path_step` identifies
the arrival associated with each stop, including equal indices for repeated
stops. The last two command arguments are the existing maximum grade in
degrees and nonnegative uphill weight, with unchanged metre-equivalent costs.

## Read the outcomes

- `waypoint-legs.csv`: one row per adjacent stop pair, in input order. Includes
  status, whether the leg belongs to the connected path, and per-leg totals.
  Failed legs have blank totals, not fabricated zero-distance routes.
- `waypoint-report.md`: route completeness, each leg's outcome, and limits.
- `terrain-waypoint-route.json`: validated source and its digest, input CSV,
  ordered stops, all leg paths and summaries, first failed leg, connected path,
  output digests and whole-route summary. `route_digest` hashes the compact
  MoonBit JSON before that field is added. This is a result report, not a
  terrain-source bundle accepted by `reopen`.
- Complete routes export `complete-route.csv` and `complete-cells.txt`.
  The CSV keeps the existing full coordinates, elevation, segment grades and
  cumulative distance/ascent/descent/cost columns. The text has row,col pairs
  without a header for manual reuse in a compatible source-bound tool.
- Incomplete routes export only `incomplete-prefix-route.csv` and
  `incomplete-prefix-cells.txt`. These stop before the first failed leg and can
  be empty. They are never the requested complete route. JSON has
  `route_complete: false`, `summary: null`, and
  `connected_path_scope: "connected-prefix-only"`. `connected_summary` applies
  only to this prefix and is null when there is no successful first leg.

Every leg is attempted even after an earlier failure. A later feasible leg
keeps its own path and metrics in JSON, with `in_connected_path: false`; it is
never concatenated across a gap. `no-path` means the known-cell graph has no
connection under the grade cap. `unknown-start`, `unknown-goal`, and
`unknown-endpoints` identify NODATA stops. A repeated NODATA stop remains
unknown, not a successful zero-length route. All stop and leg indexes are
zero-based. A path may pass another requested stop incidentally; the recorded
ordered arrivals still refer to their explicit successive legs.

## Inspect a failed middle leg

```sh
moon run --target native cmd/terrain_import -- convert data/terrain_import/synthetic-waypoints-gap.asc /tmp/gap-source gap "Synthetic local Cartesian frame" m "Synthetic Apache-2.0 NODATA gap; not observed terrain"
moon run --target native cmd/terrain_import -- waypoints /tmp/gap-source/terrain-import.json data/terrain_import/synthetic-waypoints-gap.csv /tmp/waypoint-gap 20 0
```

Leg 0 succeeds for 10 m, leg 1 cannot cross the NODATA gap, and leg 2 succeeds
independently for 20 m. The only exported connected prefix is (0,0) → (0,1).
No whole-route total or continuous path across the unknown cell is invented.

The command exits 0 when all requested searches have been reported, including
incomplete routes. Automation must inspect `route_complete` or `status`.
Malformed input, unsupported units, invalid preferences or numeric overflow
exit 2 before an output directory is created. Existing outputs are not reused.

## API and limits

`@terrain_import.route_waypoints_bundle(source_json, waypoints_csv, grade, weight)`
returns the same JSON as the CLI and raises `ImportError` for invalid inputs.
The source is reopened and verified once, and each leg runs the same search as
`route_bundle`. All grids require declared metre spacing/elevations and at most
4096 cells. Search time is O(legs × cells²), with bounded 31 legs maximum;
result storage grows with the retained paths. Known stops and a found graph
path do not qualify real terrain or a robot. No energy, clearance, footprint,
surface roughness, illumination, physical readiness or mission authority is
added. Source declarations, floating-point limitations and the frozen study's
separate input requirements remain unchanged.

## Source-frame x,y inputs

Use [`waypoints-xy`](COORDINATE_TERRAIN_WAYPOINTS.md) to import ordered source
cell-center coordinates directly. It retains the input and coordinate mapping,
exports reusable row/column CSV, and uses these same routing outcomes.
