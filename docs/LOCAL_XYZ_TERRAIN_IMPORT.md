# Import grid-aligned XYZ observations

An analyst can now take a small point export from a GIS or a spreadsheet and
import it directly into MoonMoon's existing terrain exploration workflow.
Provide a numeric `x,y,elevation_m` CSV and a JSON grid declaration. The native
`xyz` command writes a source-bound bundle usable by `reopen`, `analyze`, `route`
and `waypoints`. It does not change frozen mission terrain or grant mission
acceptance.

## Try the synthetic example

From the MoonMoon repository, with an unused output directory:

```sh
moon run --target native cmd/terrain_import -- xyz data/terrain_import/synthetic-xyz-points.csv data/terrain_import/synthetic-xyz-grid.json /tmp/xyz-source
moon run --target native cmd/terrain_import -- reopen /tmp/xyz-source/terrain-import.json
moon run --target native cmd/terrain_import -- analyze /tmp/xyz-source/terrain-import.json /tmp/xyz-analysis row 0 10
moon run --target native cmd/terrain_import -- route /tmp/xyz-source/terrain-import.json /tmp/xyz-route 3 0 0 2 30 0
```

The fixture is a synthetic 4×4 plane with 15 observations in deliberately
shuffled order. The upper-right cell is absent. It is not an external lunar
dataset. Row 0 therefore has 3 known elevations, 20 m of measured adjacent
segments and a 10 m unknown segment. The three complete interior neighborhoods
have slope approximately 12.604° and effectively zero plane-residual roughness
(about 9×10⁻¹⁷ m from floating-point roundoff in the retained native output).

The source directory contains the original `source.csv` and `grid.json`, a
row-major sparse `terrain.csv`, and `terrain-import.json`. Analysis exports the
existing cell/profile CSVs and human-readable report. No output directory is
overwritten.

## Grid declaration

```json
{
  "contract_id": "moonmoon.xyz-grid.v1",
  "tile_id": "my-grid",
  "coordinate_frame": "Name the actual source CRS and vertical datum",
  "horizontal_unit": "m",
  "source_note": "Record source, license, acquisition limits and uncertainty",
  "rows": 4,
  "cols": 4,
  "origin_x": 100,
  "origin_y": 200,
  "cell_size": 10
}
```

All ten fields are required; unknown keys are rejected. `origin_x,origin_y`
identify the **lower-left cell center**, not the lower-left corner. Coordinates
use one square, axis-aligned spacing. Extent is explicit rather than inferred
from the observations, so missing edge cells remain in the grid. Output row 0
has the largest source y; columns increase with x. No geographic orientation
is inferred from these numeric axes.

`horizontal_unit` is `m` or `degrees`. Degree inputs can be imported and
reopened, but metric analysis and routing reject them. Elevations must already
be metres; no unit or datum conversion occurs.

## CSV semantics

- Exact header: `x,y,elevation_m`. Records contain three finite numbers,
  including scientific notation; surrounding whitespace and CRLF are accepted.
- Records may be in any order. Missing records create null elevations. Numeric
  `-9999` and zero are real observations, never missing-value markers. Remove
  sentinel records before import when your upstream dataset uses them.
- Coordinates must match declared centers within `1e-7` cell units in each
  axis. The imported coordinate is that declared center; the original numeric
  text is preserved. This tolerance handles numeric representation only.
- A duplicate cell is rejected even if its elevation agrees. There is no
  averaging, interpolation, fill, binning, nearest-neighbor resampling or
  reprojection. Arbitrarily scattered point clouds are outside this workflow.
- Blank lines are ignored. Quoted fields, comments, extra columns, blank or
  nonfinite elevations and out-of-grid/off-center points are rejected.
- Header-only input is valid all-unknown coverage. Limits: 4096 grid cells,
  4096 point records, 1 MiB CSV characters and 16 KiB declaration characters.

## Traceability and reopening

The new `moonmoon.terrain-xyz-import.v1` contract preserves both original input
texts and their separate SHA-256 digests. It includes the declared extent,
coordinate semantics, nulls, counts and sparse CSV/digest. `nodata_value` is
null because this CSV format has no numeric sentinel.

Reopening recomputes the full bundle from the retained CSV and declaration.
Changing any sample, grid field, source digest or derived field without a fresh
import is rejected. Formatting the outer bundle JSON is harmless; the original
source and declaration text identities remain exact. Digests detect internal
inconsistency, not authenticity or lawful acquisition. Reordering input records
can yield identical terrain CSV but different raw-source identity.

Derived analysis and routes embed the complete XYZ bundle and its digest. The
existing Esri ASCII contract remains unchanged. XYZ intake is a native CLI and
public MoonBit API capability; no new graphical input panel or browser behavior
was qualified. This is local exploratory digital evidence, with
`review_required: true` and `physical_readiness: false` throughout.

Public API: `@terrain_import.import_xyz_bundle(csv_text, declaration_text)`.
Use `reopen_bundle`, `analyze_bundle`, `route_bundle` and
`route_waypoints_bundle` as for existing bundles. See also
[terrain analysis](LOCAL_TERRAIN_ANALYSIS.md) for estimator limits and
[routing](LOCAL_TERRAIN_ROUTING.md) for the point-path model's boundaries.
