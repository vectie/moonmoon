# Assess a submitted path on imported terrain

Use `assess-path` when the question is what happens along a route you already
have. Every submitted cell remains in order. Unlike endpoint/waypoint routing,
this command does not search for a replacement path or hide a steep segment by
choosing a detour. Reuse a generated route's `path-cells.txt` directly, or write
an explicit cell path. This supports source-bound corridor inspection in PRD
MN-W02/B03 without changing authored requirement statuses.

## Try the synthetic example

Build the native `cmd/terrain_import` command using the repository's supported
pinned toolchain. Below, `terrain_import` means that executable. Run from the
repository root and choose new output directories:

```sh
terrain_import convert data/terrain_import/synthetic-route-ridge.asc SOURCE ridge "Synthetic local Cartesian frame" m "Synthetic example, Apache-2.0; not observed lunar terrain"
terrain_import assess-path SOURCE/terrain-import.json data/terrain_import/synthetic-submitted-path.csv DIRECT 20 4
terrain_import route SOURCE/terrain-import.json OPTIMIZED 2 0 2 6 20 4
terrain_import assess-path SOURCE/terrain-import.json OPTIMIZED/path-cells.txt RECHECK 20 4
terrain_import revise SOURCE/terrain-import.json data/terrain_import/synthetic-path-mask.csv MASKED "Withhold synthetic ridge cell; not a measured terrain correction"
terrain_import assess-path MASKED/terrain-import.json data/terrain_import/synthetic-submitted-path.csv REVISED 20 4
```

The submitted direct path stays 60 m long, with 15 m ascent and descent and two
segments exceeding 20 degrees. Its declared uphill-cost value is 120 metre-
equivalent units. Endpoint routing instead finds a 100 m flat detour. Rechecking
that exact exported detour reproduces its accounting. After withholding the
ridge cell, the submitted path still contains all seven points, but both
incident segments become unknown and whole-path totals are unavailable. The
original source and all previous results remain intact.

## Input and result rules

- Arguments: source bundle, path text file, new output directory, maximum
  absolute adjacent-center grade in degrees, and nonnegative uphill weight.
- Input: `row,col` integer lines, optional exact `row,col` header, blank lines
  and CRLF accepted. Rows/columns are zero-based in the source grid; row zero is
  the top row. At most 4096 point occurrences and 65536 UTF-16 code units.
- Every consecutive pair must be the same cell or one cardinal neighbor.
  Skipped cells and diagonals are rejected before output creation. To assess a
  longer step, explicitly supply every traversed cell. No interpolation or
  automatic routing connects it for you.
- Repeated cells and later return visits are preserved. A repeated known cell
  has zero distance and rise, with null grade because there is no movement
  direction. Repeated unknown cells still have unknown incident segments.
  A one-cell path is valid; it has no movement or grade measurement.
- Only metre grids are supported. Grade cap must be finite in [0,90); uphill
  weight must be finite and nonnegative. ASCII, XYZ and saved revision bundles
  all use the same existing verified source reopen operation.

The status is `within-grade-cap`, `grade-exceeded`, or `incomplete-coverage`.
`coverage_complete` and `grade_screening` are separate: a path can contain both
unknown segments and known over-cap segments. The latter remain counted and
visible even when status is incomplete. Equality meets the cap. No status means
safe, mission-ready or physically validated.

`summary` is present only when every submitted point is known. It includes all
submitted segments, even those over the cap. `observed_segments_summary` sums
only pairs with both elevations known; after a gap it resumes on later known
pairs. These partial totals can describe disjoint pieces and are never claimed
to be a connected prefix. Zero observed distance does not establish complete
coverage. `coverage.geometric_path_distance_m` is the length implied by the
submitted cell geometry, including unknown segments; it is not assessed or
traversable distance.

Every point retains its exact center, elevation or null, cumulative geometric
path distance and incoming segment outcome. The first point has no incoming
segment. Missing elevations produce null rise, grade and 3D length on both
incident segments. Whole-path ascent/descent/cost are never filled across gaps.
Maximum absolute grade is null when no moving known segment exists.

## Calculation and reusable files

For each known moving pair, signed grade is `atan(rise / cell_size)` in degrees.
3D length is `hypot(cell_size, rise)`; positive and negative rises contribute to
ascent and descent. Cost is horizontal distance plus uphill weight times ascent,
a metre-equivalent preference rather than energy. Reversing a route can change
that cost. Finite arithmetic overflow causes an error. Floating-point last bits
can differ across backends; digests bind the actual exported numbers.

The native command writes:

- `input-path.txt`: exact submitted text
- `path-cells.txt`: normalized pairs, preserving repetitions and order
- `path-assessment.csv`: every point and its incoming segment, with blanks for
  unknown metrics and explicit segment status
- `path-report.md`: readable coverage, assumptions and limitations
- `terrain-path-assessment.json`: the full source bundle, parameters, results,
  output text and SHA-256 identities

The report contract is `moonmoon.terrain-path-assessment.v1`. The public API is
`assess_path_bundle(source_bundle, path_cells_text, max_grade_deg, uphill_weight)`.
`assessment_digest` hashes the compact MoonBit JSON serialization of all other
report fields. It is an integrity identity, not a signature or evidence that
the source is true. Reports embed their reopened source; they are not themselves
source-import files. Keep JSON with the other exports.

All completed assessments exit zero, including over-cap and unknown paths.
Invalid input exits 2 and creates no output directory. Existing destinations
are refused without replacement. Multi-file output is not atomic; after an
interrupted save, choose a new destination and retain the partial evidence.

## Limits

This is a digital point-path calculation. Source/frame/unit declarations and
terrain uncertainty remain unverified. No subcell hazards, 3×3 surface slope,
roughness, footprint, clearance, illumination, energy, robot dynamics or physical
suitability are inferred. Stationary repeats do not model dwell time or energy.
There is no reprojection, mission run, approval workflow, device dispatch or
MoonRobo integration. Existing mission negative-energy blockers and optional
archive availability remain unchanged. Native/JS focused tests and the local
CLI workflow do not qualify an external dataset or graphical UI.

To inspect terrain revision effects without manually joining two assessments,
use [exact-path terrain comparison](TERRAIN_PATH_COMPARISON.md). It retains the
same submitted path and distinguishes coverage changes from numeric deltas.
