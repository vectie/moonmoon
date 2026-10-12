# Route through source-frame coordinate stops

The native `waypoints-xy` command takes a GIS/spreadsheet export of ordered
`x,y` cell-center coordinates in a terrain source's declared metre frame. It
produces the existing ordered, grade-limited route plus an inspectable mapping
to source-grid rows and columns. Stop order and repeated visits are retained.
This closes the gap between coordinate-bearing terrain and row/column routing.

## Run the synthetic example

Build `cmd/terrain_import` with the pinned toolchain and an external build
target. The following commands use that executable as `terrain_import`.
Choose new output directories; existing destinations are refused.

```sh
terrain_import convert data/terrain_import/synthetic-route-ridge.asc SOURCE ridge "Synthetic local Cartesian frame" m "Synthetic Apache-2.0 example; not observed lunar terrain"
terrain_import waypoints-xy SOURCE/terrain-import.json data/terrain_import/synthetic-waypoints-xy-loop.csv COORDINATE_ROUTE 20 0
terrain_import waypoints SOURCE/terrain-import.json COORDINATE_ROUTE/waypoints.csv CELL_ROUTE 20 0
```

The last command reproduces the identical paths and leg/whole-route metrics
using the exported `row,col` input. The source uses a lower-left corner at
(100,200), 10 m cells and five rows. Coordinate (105,225) is row 2/column 0;
(135,245) is row 0/column 3. Row zero is the top source row, so y increases
opposite to row numbers. The supplied repeated-start loop has 200 m horizontal
distance and 21 path cells under these preferences.

The input is plain numeric CSV:

```csv
x,y
105,225
105,225
135,245
165,225
105,225
```

## Input contract

- Header must be `x,y`, in that order. Never use latitude/longitude implicitly.
- Coordinates must use the same caller-declared frame and metres as the source.
  There is no frame inference, axis swap, reprojection or unit conversion.
- Each axis must be within `1e-7` cell units of a cell center. This only tolerates
  numeric representation noise; arbitrary points, corners, halfway points and
  values beyond the grid are rejected. No nearest-cell search or interpolation.
  A point within the tolerance of an edge center may be accepted on either side
  of that center. The exact input and selected center are both recorded.
- ASCII lower-left corner origins receive the half-cell offset; center-origin
  ASCII, XYZ and saved terrain revisions use their own retained geometry.
  Grids whose centers are indistinguishable or cannot roundtrip within the
  tolerance are rejected by this command.
- Negative coordinates, scientific notation, surrounding whitespace, blank
  data lines and CRLF are accepted. Quoted fields/headers, extra/missing columns,
  nonfinite numbers and off-center points are rejected.
- Input has 2–32 ordered stops and at most 16,384 characters; sources have at
  most 4096 cells. Existing grade and uphill-weight limits apply.

## Saved evidence

`coordinates.csv` is the byte-equivalent original decoded UTF-8 text supplied
to the command. `coordinate-mapping.csv` records stop number, original numeric
x/y, selected row/column and actual source center x/y. `waypoints.csv` is the
normalized row/column CSV, reusable with the original `waypoints` command.

`terrain-waypoint-route.json` uses contract
`moonmoon.terrain-coordinate-waypoint-route.v1`. It retains the verified source,
frame, exact coordinate CSV, normalized CSV, coordinate records, tolerance,
mapping CSV and their SHA-256 digests. `waypoints_csv` continues to mean the
normalized `row,col` CSV; `coordinate_waypoints_csv` holds the original `x,y`
input. `route_digest` hashes compact MoonBit JSON before adding that digest.
The result is a report, not an input bundle accepted by `reopen`.

The existing route outputs and incomplete-route meanings are unchanged:
`waypoint-legs.csv`, `waypoint-report.md`, and either `complete-route.csv` plus
`complete-cells.txt`, or `incomplete-prefix-route.csv` plus
`incomplete-prefix-cells.txt`. Unknown stops remain unknown even when their
coordinates are valid; later successful legs are never joined across a failed
leg. Incomplete routes have `route_complete: false` and null whole-route totals.
See [ordered waypoints](ORDERED_TERRAIN_WAYPOINTS.md) for all outcome fields.

The CLI exits 0 after reporting every leg, including incomplete routes. Inspect
`route_complete`. Invalid input, tampered sources or existing outputs exit 2.
All inputs are validated before creating output. Multi-file saves are not
atomic; an I/O failure can leave a partial new directory, so use a fresh one.

## API and scientific limits

`route_coordinate_waypoints_bundle(source_json, coordinate_csv, grade, weight)`
returns the same JSON without filesystem access. It verifies the source once,
maps stops, and calls the same ordered four-neighbor search/accounting as
`route_waypoints_bundle`. Row/column behavior is preserved unchanged.

This is exploratory digital terrain planning. Declared frames, source truth and
uncertainty remain unverified. There is no new energy, clearance, footprint,
robot suitability, physical readiness or mission approval. `review_required`
remains true and `physical_readiness` false. External datasets, full mission
runtime, UI/browser and robotics integration are outside this feature.
