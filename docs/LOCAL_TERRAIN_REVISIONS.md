# Local terrain cell revisions

Use a new terrain revision when an analyst wants to declare a corrected
elevation, add a previously absent value, or withhold a suspect sample as
unknown. The original ASCII/XYZ source and each edit remain available. Existing
analysis, routes and ordered waypoints can consume the saved revision directly.
This is a native CLI/public API editing workflow. No graphical editing panel is
added, and a declared replacement is not authenticated terrain or a validated
measurement.

## Export, edit, apply

After building `cmd/terrain_import` natively, use the executable as
`terrain_import` below. Every output file/directory must be new.

```sh
terrain_import edit-template SOURCE/terrain-import.json edits.csv
terrain_import revise SOURCE/terrain-import.json edits.csv REVISION "Declared source of replacement values, reason, and uncertainty"
terrain_import reopen REVISION/terrain-import.json
terrain_import analyze REVISION/terrain-import.json ANALYSIS row 1 10
terrain_import route REVISION/terrain-import.json ROUTE 1 0 1 2 30 0
```

The template includes every cell in top-to-bottom row-major order:

```csv
row,col,expected_elevation_m,elevation_m
0,0,6,6
0,1,7,7
0,2,8,8
0,3,unknown,unknown
```

Edit only `elevation_m` for cells you want to change. Retain the expected value
in `expected_elevation_m`. You may remove unchanged rows to make a sparse edit;
leaving them in is supported. All retained rows check their expected values,
including unchanged rows. If a value has changed since the sheet was exported,
the command refuses it and asks for a fresh template. A template is not a signed
source reference: choose the intended input bundle explicitly.

- Use a finite number for a caller-declared metre elevation. Zero and `-9999`
  are real numeric values in the revision CSV, never missing-value sentinels.
- Use exactly `unknown` to withhold coverage or to name an absent expected value.
  Empty cells are rejected. There is no gap filling or interpolation.
- Row and column indices are zero-based in the original raster. Geometry,
  dimensions, tile ID, frame and horizontal units do not change.
- The four-column header is required. Numeric scientific notation, CRLF,
  blank lines and field-edge whitespace are supported; quoted CSV is not.
- Duplicate cells, out-of-range indices, nonfinite numbers, stale expected
  values and batches with no changed cells are rejected.
- Supply a nonempty source/reason declaration of at most 2000 characters. This
  records what the caller said, without implying independent review.

To continue, export a new template from `REVISION/terrain-import.json`, or
prepare a sparse edit using its current values. Apply it into another new
directory. To undo a change, explicitly set the previous value in a new
revision; this preserves the withdrawal and reason in the history.

## What is saved

- `terrain-import.json`: the reopenable `moonmoon.terrain-revision.v1` bundle.
- `terrain.csv`: current known cells, compatible with the existing sparse CSV
  readers. Keep its bundle beside it; CSV alone omits provenance and geometry.
- `edits.csv`: exact current input CSV.
- `revision-reason.txt`: the caller's current declaration.
- `revision-changes.csv`: changed cells only, with before/after values and
  `set-declared-value` or `mark-unknown` actions.
- `source-recipe.json`: the exact canonical recipe hashed as `source_digest`.

The bundle embeds the verified original ASCII/XYZ bundle once, preserving raw
source input, grid declaration when present, frame, units and original coverage.
It retains a flat list of exact edit CSVs and reasons. The current `source_text`
is the canonical revision recipe, rather than the original raster text;
`base_source_bundle` holds the latter. `base_source_bundle_digest` binds the
original bundle and `parent_bundle_digest` binds the preceding revision's full
canonical bundle. `source_digest` identifies the current recipe.

Reopening recomputes the original source and applies every edit in order,
checking expected values and every derived field/digest. Ordinary JSON
formatting/key order changes are accepted. The hashes establish consistency,
not authenticity; an author who changes all inputs and recomputes all hashes
has authored a new declared study, not established terrain truth.

Existing metric analysis and routing carry the whole revision bundle and its
digest. Marking a cell unknown removes it from routes and makes any affected
3×3 slope/roughness neighborhoods unknown. Filling a cell supplies the caller's
declared number to those calculations. It does not qualify that number as a
measurement. Degree grids can be edited/reopened, but metric analysis and routing
still reject them.

## Bounded example

Import `synthetic-xyz-points.csv` with `synthetic-xyz-grid.json`. Apply
`synthetic-revision-fill.csv` to declare the absent upper-right cell as 9 m.
Then apply `synthetic-revision-mask.csv` to withhold row 1/column 1 as unknown.
These are synthetic exercises, not corrections to observed lunar terrain.

The filled grid has 16 known cells and four supported interior estimates. The
masked grid has 15 known cells and no supported interior 3×3 estimates. Routing
from row 1/column 0 to row 1/column 2 at a 30° grade cap changes from 20 m to a
40 m detour. A required waypoint at the masked center remains incomplete.
Neither source files nor the first revision are rewritten.

## Limits and verification

The underlying grid remains bounded to 4096 cells. Each CSV is at most 256 KiB
characters with 4096 records. A history contains at most 32 revisions and 4096
cell-change operations total, counting repeated changes to the same cell.
Unchanged template rows do not consume that change count. A formatted output
bundle including its final newline must fit the existing 4 MiB character limit.
The workflow does not edit the grid frame, extent, units or original source
metadata. A different site/grid requires a separate import.

All inputs are validated before creating an output directory. Output paths are
never overwritten. An I/O interruption can leave a partial new directory;
choose another new destination and retain the original inputs. Do not treat
partial files as a saved revision. Atomic multi-file persistence and interrupted
save recovery have not been qualified here.

Focused native and JS tests cover ASCII/XYZ editing, expected-value conflicts,
unknown masks, sentinel-valued numbers, cumulative/history limits, preserved
originals, multi-revision reopening and existing analysis/routes/waypoints.
Native command verification exercises the same file workflow and no-overwrite
behavior. Full mission-runtime, graphical browser, external source truth,
archive, energy/robot suitability and physical qualification are outside this
change. `review_required` remains true and `physical_readiness` false.

A [terrain mosaic](LOCAL_TERRAIN_MOSAICS.md) can also be revised. Its complete
composite bundle and both source clips remain the original base. A revision of
a mosaic cannot itself be fed into another mosaic.
