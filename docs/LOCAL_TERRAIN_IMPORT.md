# Local terrain raster exploration

To join two exactly aligned metre-frame clips for analysis or routing across a
seam, use [local terrain mosaics](LOCAL_TERRAIN_MOSAICS.md). Both sources and
per-cell contributors are retained; gaps remain unknown.

For grid-aligned point exports, use [XYZ CSV terrain intake](LOCAL_XYZ_TERRAIN_IMPORT.md)
with an explicit grid declaration through the native CLI. It preserves absent
cells and feeds the same analysis/routing tools without an intermediate ASCII raster.

Open **Explore a local terrain raster** in the Rabbita cockpit. Import an Esri
ASCII grid (`.asc` or `.txt`), name its tile and coordinate frame, choose metres or
degrees for horizontal coordinates, record its source/license/limitations, and
confirm that its elevations are already metres. **Import and inspect terrain**
reads the selected local file. No upload, provider call, mission run or hardware
operation occurs.

The workflow accepts **up to 4096 cells and 1 MiB of ASCII text**. Clip large DEMs
in your GIS application first and export Esri ASCII with metre elevations. The
ASCII format does not identify the CRS or vertical datum; the frame, units and
source note you enter are preserved as unverified source declarations. A degree
grid is useful for inspection but requires a separate reviewed reprojection
before it can become metric mission terrain.

## Inspect and export

- The preview colors nonmissing elevation values from blue (low) to orange
  (high). Gray crossed cells are **NODATA / unknown**, never zero-filled.
- Choose any row/column in the cell selector, use Previous/Next, or click the
  preview. The detail shows that cell's exact center coordinates and elevation.
  The selected row's full text table provides the same data without relying on
  color or the SVG. Color is not a slope or hazard assessment.
- **Download sparse terrain CSV** produces `tile_id,row,col,elevation_m` in input
  row-major order. Missing cells are omitted, so downstream readers must preserve
  unknown coverage. Row/column indices are not projected coordinates.
- **Download source bundle** retains the source text, metadata, source and CSV
  SHA-256 digests, all cells (including null elevations), and the CSV. Keep the
  bundle beside the CSV to preserve the coordinate mapping and provenance.
- Choose a downloaded bundle JSON and import it to reopen. The MoonBit parser
  recomputes all fields and digests from retained source text before opening it.
  Reformatting JSON is supported; changed derived data or digests are rejected.
- Failed imports preserve the previous source. Changes to form inputs do not
  alter an already imported source until Import is chosen again. Clear discards
  the imported in-page view. Refresh does not retain files; export first.
- **Explore synthetic example** demonstrates missing cells and a nonsquare
  raster. It is explicitly synthetic, not acquired lunar terrain.

For metre grids, continue in **Analyze slopes, roughness and a terrain profile**
to explore row/column elevation profiles and local 3×3 slope/roughness estimates,
with explicit unknown coverage and inspectable CSV/report output. See
[Local terrain analysis](LOCAL_TERRAIN_ANALYSIS.md) for methods and limits.

To connect two known cells with a candidate path that can bend around steep
steps or missing cells, use [Local terrain routing](LOCAL_TERRAIN_ROUTING.md).
The native command exports an offline route map, ordered cells and route profile
with configurable adjacent-grade and uphill-cost preferences.

To declare replacement elevations or withhold suspect cells without rewriting
the original source, use [Local terrain cell revisions](LOCAL_TERRAIN_REVISIONS.md).
The native workflow exports an editable sheet, checks previous values, and
retains the original bundle and complete edit history for downstream analysis.

## Coordinate rules

The importer follows the [Esri ASCII raster format](https://help.arcgis.com/en/arcgisdesktop/10.0/help/009t/009t0000000z000000.htm).
It supports matching lower-left corner or center origins, case-insensitive
headers, arbitrary row whitespace, finite decimal values and scientific
notation. When NODATA_VALUE is omitted, the format default is -9999.

Input row zero is the **top** row. For a corner-origin grid, a cell's center is
`x = xllcorner + (col + 0.5) * cellsize` and
`y = yllcorner + (nrows - row - 0.5) * cellsize`.
For center-origin input, omit the half-cell offsets. Coordinates stay in the
declared source units. There is no reprojection, interpolation or vertical-unit
conversion. An entirely missing grid remains inspectable and exports CSV with
only the header. Malformed sizes, mismatched origin types, duplicate headers and
nonfinite numbers are rejected.

## Native file workflow

Run from the MoonMoon repository:

```sh
moon run --target native cmd/terrain_import -- convert data/terrain_import/example-local.asc /tmp/new-terrain-clip demo "Synthetic local Cartesian frame" m "Bundled synthetic fixture, Apache-2.0; not observed lunar terrain"
moon run --target native cmd/terrain_import -- reopen /tmp/new-terrain-clip/terrain-import.json
```

The output directory must not already exist. It receives `source.asc`,
`terrain.csv`, and `terrain-import.json`. `inspect` takes the same source and
metadata arguments as `convert` without an output directory and prints the
bundle without writing files. `reopen` independently verifies an exported bundle.

The CLI and Rabbita use the same MoonBit `src/terrain_import` parser, coordinate
mapping, CSV writer, digest generation and reopen validator. The imported source
does **not** replace frozen study terrain or supply mission acceptance. Digital
exploration only; `review_required` stays true and `physical_readiness` false.

## Verification

Focused tests cover corner/center origins, row ordering, NODATA/default handling,
all-missing data, CSV, source-bundle reopen and malformed inputs. The Rabbita
panel is compiled and rendered in MoonBit UI tests. Native command verification
checks the retained source, exact digests, sparse CSV, reopen and no-overwrite
behavior. These checks do not claim graphical browser/pointer/layout acceptance.
