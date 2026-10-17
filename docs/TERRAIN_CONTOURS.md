# Explore terrain elevation contours

The native `terrain_import contours INPUT/terrain-import.json NEW-DIRECTORY LEVEL...`
command turns an imported, revised, cropped or mosaic terrain into a portable
contour map. Select 1–32 unique finite elevations in metres. Existing output
directories are refused; previous terrain and contour exports stay unchanged.

## Try the crater and the saddle

Build/run `cmd/terrain_import` with the existing MoonBit toolchain. Use `convert`
to import `data/terrain_import/synthetic-contour-crater.asc`, declaring a local
metre coordinate frame and a synthetic-data source note. Then run:

```
terrain_import contours CRATER/terrain-import.json CRATER-CONTOURS -1 0 1 3 5
terrain_import contours SADDLE/terrain-import.json SADDLE-CONTOURS -5 0 5
```

Import `synthetic-contour-saddle.asc` separately with `convert` for the second
command. These are synthetic demonstration datasets, not qualified lunar data.
Open `contours.svg` in an SVG viewer. The first segment of each level is labeled,
and segment tooltips identify elevation and source neighborhood. Grey squares
are omitted NODATA neighborhoods. The map uses source +Y upward, not an inferred
lunar north. Inspect exact endpoints and selected elevations in
`contour-segments.csv`; retain `terrain-contours.json` with its full editable
terrain source, source digest, segments and SVG/CSV digests.

To explore a different interpretation, edit elevations through the existing
terrain revision workflow and rerun into a fresh directory. Revised contours
bind a different source identity. Levels outside the surface range produce
zero crossings, rather than an invented contour. A one-row/column source has
no surface; its output is explicitly `no-surface`.

## Model and limitations

Complete 2×2 sample neighborhoods split on the northwest/southeast diagonal,
exactly as terrain OBJ export. Linear interpolation in each triangle resolves
saddles deterministically. A bilinear or differently triangulated surface can
produce different contours. Segments are independent, not stitched polygons.
Equal-level plateaus and isolated level vertices do not produce lines; equal
edges bordering higher terrain are retained once. The high side of the
crossing rule is exclusive, so a surface's flat maximum does not outline itself.

Every neighborhood touching NODATA is omitted, including triangles whose other
three corners are known. No interpolation across gaps, smoothing, hole filling,
reprojection or extrapolation is performed. Sample centers bound the surface;
the outer raster half-cell rim is absent. At most 40,000 segments are exported.
Collapsed/nonfinite coordinates are refused. Multi-file writes are not atomic;
retain interrupted output and retry into a fresh directory.

Strictly interior crossings must remain interior after floating-point division
and coordinate interpolation. A fraction that underflows to zero or rounds to
one, an interpolated point rounded onto an edge endpoint, or two distinct
crossings rounded onto the same point are rejected with a precision error.
They must not silently become a `no-crossings` study. A genuine isolated contact
at an exact source vertex still produces no line, as defined above.

Source/frame/vertical datum remain user-declared and unverified. The contour
model is exploration data, not new measured evidence, mission acceptance,
robot suitability, engineering accuracy or physical authority. Opening an SVG
does not qualify a renderer, external dataset, installed application or release.
