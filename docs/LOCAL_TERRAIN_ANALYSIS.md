# Metric terrain profiles and local shape screening

In **Explore a local terrain raster**, import an Esri ASCII grid or reopen its
verified source bundle. With horizontal units declared as **metres**, choose a
row or column, its zero-based index, and a slope screening threshold. Choose
**Calculate terrain analysis**. The bundled synthetic example is a 7-by-5 ridge
with one missing cell; it is not observed lunar terrain.

The slope screening map and selected-cell text show an estimate, a
threshold exceedance, or an unknown neighborhood. Click a map cell or use the
existing accessible cell selector to inspect its slope and roughness. Change the
transect or threshold and calculate again to explore a different question.
Changing controls does not alter the previous calculation or its exports until
calculation succeeds. An invalid calculation keeps the previous result visible.
Importing a new source or clearing the source discards its in-page analysis.

The profile plots cell-center elevations and shows every sample in a table.
Missing values split the line; even the segment immediately after a missing cell
remains unknown. A row proceeds toward increasing source x. A column follows
input row order, from top to bottom toward decreasing source y. These directions
describe the declared frame; no lunar orientation is inferred from a CRS name.

## What the numbers mean

- **Local slope:** unweighted least-squares plane through all nine elevations in
  the centered 3-by-3 neighborhood. For offsets `dx,dy` in `{-h,0,h}` with `h`
  the cell spacing, plane gradients are `sum(z*dx)/(6*h*h)` and
  `sum(z*dy)/(6*h*h)`. The reported angle is `atan(hypot(gx,gy))` in degrees.
  Implementation subtracts the center elevation first for numerical stability.
- **Roughness:** RMS vertical residual of those nine elevations from that plane,
  in metres. It is a local scale-dependent shape statistic, not a rock size,
  traction model, or propagated uncertainty estimate.
- **Unknown estimates:** outer boundary cells lack a full neighborhood. A
  missing center is `nodata`; a missing neighbor is `unknown-neighborhood`.
  These cells have null slope/roughness and unknown screening. No edge-padding,
  interpolation, one-sided gradient, or coverage extrapolation is used.
- **Screening:** slope strictly greater than the user threshold is marked
  `threshold-exceeded`; equality is `within-threshold`. The threshold is an
  exploratory choice. Below-threshold and unknown cells are not declared safe.
  Roughness is displayed separately and does not enter this screening decision.
- **Profile grade:** signed rise divided by horizontal cell spacing, reported
  in percent and as `atan(rise/spacing)` in degrees. It describes the segment
  ending at each sample; the first sample has no preceding segment.
- **Distance and ascent/descent:** horizontal span is the distance between the
  first and last cell centers, not the width of the raster footprint. Measured
  distance and observed ascent/descent include consecutive known pairs only.
  They are explicitly partial when the transect contains any missing elevation.

Degree grids remain inspectable but metric analysis is unavailable. Reproject
externally to an appropriate, documented metre frame first. Entered CRS, source,
license, horizontal units, metre elevations and vertical datum are declarations,
not independently verified evidence. Finite calculations that overflow are
rejected rather than serialized as misleading results.

## Keep the evidence

- **Profile CSV** retains every selected sample, including blank elevations and
  blank grades for unknown segments.
- **Slope/roughness CSV** retains every raster cell, its center coordinates,
  null-derived blanks, estimate status and screening status.
- **Readable analysis report** explains the source digest, declared frame,
  method, parameter choices, coverage and summary.
- **Complete analysis evidence** is a JSON report containing the verified
  `moonmoon.terrain-import.v1` source bundle, selected parameters, exact method
  version, all cells and profile samples, both CSVs and SHA-256 digests. Its
  `analysis_digest` hashes the compact MoonBit serialization of every other
  report field. Revised parameters produce distinct evidence. It is an integrity
  identifier, not a signature or proof of dataset truth.

Floating-point last bits may differ between compiler backends or runtimes; the
identity binds the exact exported numbers. Analytical tests use tolerances for
nonexact calculations rather than asserting cross-runtime bitwise equivalence.

Save the complete JSON with the other exports; CSV alone does not retain all
provenance. The complete report embeds its source bundle, which can be extracted
and reopened through the existing source-bundle importer. The analysis report
itself is not a source-import file. Refresh does not persist the in-page result.

## Native workflow

From the repository root, use new output directories:

```sh
moon run --target native cmd/terrain_import -- convert data/terrain_import/synthetic-ridge.asc /tmp/ridge-source ridge "Synthetic Cartesian frame" m "Bundled synthetic ridge, Apache-2.0; not observed lunar terrain"
moon run --target native cmd/terrain_import -- analyze /tmp/ridge-source/terrain-import.json /tmp/ridge-row2 row 2 15
moon run --target native cmd/terrain_import -- analyze /tmp/ridge-source/terrain-import.json /tmp/ridge-column5 column 5 25
```

Each analysis directory contains `terrain-analysis.json`, `terrain-report.md`,
`terrain-cells.csv`, and `terrain-profile.csv`. Existing output directories are
never overwritten. The native command and cockpit use the same MoonBit source
validation and calculation function. Analysis first independently recomputes the
source bundle from its retained ASCII text; tampered source data is rejected.

## Scientific and verification limits

This supports PRD MN-W02/B03/N01/N03: inspectable derived terrain measures with
source, assumptions and missing coverage carried into results. It does not
change authored requirement statuses or qualify an external lunar dataset.

A 3-by-3 plane can smooth localized hazards, including a ridge crest with small
mean slope and high roughness. Raster sampling itself can miss smaller obstacles.
No lighting, geology, traction, rover clearance, route energy, robot suitability,
mission acceptance, or physical readiness is calculated here. Existing mission
energy blockers and frozen study inputs are unchanged.

Focused analytical plane, bump, gap, row-order, threshold, source-integrity and
numeric tests run on native and JavaScript. UI tests render the compiled panel
and exercise the file/DOM adapter's calculation, editing and stale-control
behavior. These are not graphical browser, layout, pointer or Mac acceptance.
