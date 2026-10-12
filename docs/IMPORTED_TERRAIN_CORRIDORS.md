# Inspect terrain around a proposed path

Use `assess-corridor` to discover local slopes, roughness and missing survey
coverage around an imported-terrain route. Existing `assess-path` evaluates
along-path adjacent-center grades. This workflow selects a band of cells around
the same submitted path and applies the existing local 3×3 plane analysis.
A flat centerline can therefore pass grade screening while the nearby terrain
exceeds a shape threshold.

## A complete native example

Build `cmd/terrain_import` in your qualified environment, then run its native
executable. Choose new destinations for each output directory:

```sh
terrain_import convert data/terrain_import/synthetic-corridor.asc source corridor "Synthetic Cartesian frame" m "Synthetic off-path bump, Apache-2.0; not observed lunar terrain"
terrain_import route source/terrain-import.json route 4 3 4 5 10 0
terrain_import assess-corridor source/terrain-import.json route/path-cells.txt narrow 0 30 0.5
terrain_import assess-corridor source/terrain-import.json route/path-cells.txt wide 1 30 0.5
```

The exported path has three flat centerline samples. Radius 0 screens those
three samples and finds no exceedance. Radius 1 examines the union of their
3×3 windows: 15 cells. Three of those cells have local roughness above 0.5 m
because their analysis neighborhoods see the synthetic bump two rows above the
centerline. The centerline route and both prior results are preserved.

To explore an edited source, use the existing `edit-template`/`revise` commands
and assess the same `path-cells.txt` against the new terrain import. Removing or
masking data has different consequences: a declared flat revision removes the
bump's shape effect; an unknown revision leaves affected estimates unknown.
Neither declares a measurement true or changes a frozen mission.

## Arguments and selection

`assess-corridor BUNDLE PATH NEW_OUTPUT RADIUS_CELLS SLOPE_DEGREES ROUGHNESS_METRES`

- Source: any supported, independently reopened ASCII, XYZ or revised import
  bundle with declared metre coordinates and metre elevations
- Path: 1–4096 ordered `row,col` pairs, optional header; repeated cells and
  cardinal neighbors only, using the same rules as `assess-path`
- Radius: integer 0–8, inclusive. Radius r includes every cell-center offset
  with `abs(row_offset) <= r` and `abs(col_offset) <= r` around each occurrence.
  The cell-center half width is r × cell spacing along either grid axis.
- Slope limit: finite, from 0 inclusive to 90 exclusive, in degrees
- Roughness limit: finite and nonnegative, in metres RMS vertical residual

This is a square discrete sample band, including end stops and corners. It is
not a circular buffer, continuous swept footprint, robot width or clearance
model. Radius 0 still uses source neighbors when estimating each path cell's
local shape. The analysis neighborhood may extend beyond the selected band.

Overlapping windows and repeated visits are deduplicated in the global cell
summary. Per-stop rows keep every submitted occurrence, including repetitions
and return visits. Their counts overlap and must not be summed into the global
summary. In-grid cells are exported in row-major order. Outside-grid cells are
counted uniquely in the global summary and separately within each stop window;
they are never silently clipped from coverage accounting.

## Interpretation

Slope and roughness reuse the unweighted least-squares plane across all nine
samples in each centered 3×3 neighborhood. Slope is `atan(hypot(gx, gy))` in
degrees. Roughness is RMS vertical residual about the fitted plane in metres.
See [local terrain analysis](LOCAL_TERRAIN_ANALYSIS.md) for the derivation.

Missing centers, missing neighborhood samples and grid boundary cells have null
shape estimates. The result distinguishes elevation coverage from shape
coverage: a known center can still lack the required analysis neighborhood.
Outside-grid selection makes both coverage flags false. No padding,
interpolation or extrapolation is performed.

Either known slope or known roughness strictly above its limit is an exceedance;
equality meets that limit. The two exceedance counts can overlap. The overall
status is `threshold-exceeded` when any known exceedance exists, even if some
coverage is unknown. Otherwise it is `incomplete-coverage` if any selected
shape estimate or outside-grid sample is missing, else `within-thresholds`.
Always inspect the coverage flags as well as status. Observed maxima summarize
estimated cells only, are null when there are no estimates, and are not bounds
on unknown terrain. Tiny floating-point residuals can exist even for a plane;
choose scientifically meaningful thresholds rather than treating zero as a
numerical tolerance.

## Outputs

- `terrain-corridor.json`: canonical evidence with reopened source, parameters,
  global summary, every in-grid cell, ordered stop summaries and output text
- `corridor-cells.csv`: unique selected cells, source coordinates, whether on the
  submitted path, elevations, estimate statuses, slope and roughness screening
- `corridor-stops.csv`: per-occurrence counts, observed maxima and status
- `corridor.svg`: inspectable map with exact centerline, orange exceedances,
  blue within-threshold estimates, crossed unknown-shape cells and outside count
- `input-path.txt`, `path-cells.txt`: exact submitted and normalized reusable path
- `corridor-report.md`: methods, thresholds, coverage and limitations

The SVG displays only the source grid. Outside-grid cells cannot be shown in
this clipped map; read its count and the coverage report. It embeds no external
resources. CSV numeric nulls are empty fields, not invented zeroes. The complete
JSON preserves provenance that CSV/map alone do not carry. SHA-256 fields bind
the source bundle, submitted/normalized paths, CSVs and SVG. `corridor_digest`
hashes compact MoonBit serialization before adding that field; it is an
integrity identifier, not a signature or proof of data quality. Identical inputs
replay deterministically within the tested backend; floating-point bits may
vary across environments.

The output directory must not exist. Input/parameter validation completes before
creating it. Multi-file persistence retains the existing CLI behavior and is not
atomic across I/O interruption; retain inputs and retry in a new directory.

## Limits

Exploratory digital terrain evidence only. No new robot geometry, subcell hazard,
traction, footprint, clearance, uncertainty propagation, illumination or energy
calculation. Local surface slope is distinct from along-path grade. A smooth
plane fit can miss small obstacles. No new mission acceptance or physical
readiness is inferred. Existing mission blockers, including negative energy,
remain unchanged. No external dataset, source license or frame is independently
qualified here.

The feature supports PRD MN-W02, B03, N01 and N03. Focused acceptance does not
change the authored requirement status or historical cumulative qualification.
