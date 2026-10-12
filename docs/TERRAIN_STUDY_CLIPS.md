# Source-bound terrain study clips

Extract a rectangular area from an imported terrain grid for a smaller route,
analysis or editing study. Keep the original source unchanged and retain a
replayable parent-to-clip receipt. This is exact cell selection, not resampling.
It implements the source-preparation gap in PRD MN-W01/B01 and the source-bound
study inputs needed by MN-W02/B03.

## CLI

```sh
terrain_import crop parent/terrain-import.json new-study 1 1 2 2 focus \
  'Focus on the surveyed area; synthetic example only'
terrain_import reopen-crop new-study/terrain-crop.json
terrain_import reopen new-study/terrain-import.json
terrain_import analyze new-study/terrain-import.json new-analysis row 0 15
```

The four numbers are start row, start column, number of rows and number of
columns. They are zero-based, with row zero at the top of the input. The window
must be nonempty and entirely inside the source. One-row, one-column,
one-cell and whole-grid windows are supported. Maximum source size remains
4096 cells. Tile IDs use 1–100 letters, numbers, underscores or hyphens; the
purpose/limitations text must contain 1–1500 characters.

The output directory must not already exist. A completed crop contains:

- `source.asc`: portable Esri ASCII raster, explicit lower-left center origin,
  original cell spacing and an explicit collision-free NODATA marker
- `terrain-import.json`: ordinary fully reopenable ASCII terrain bundle; pass
  it to existing analysis, routing, waypoint, energy, revision or mesh commands
- `crop-cells.csv`: every output cell, immediate parent row/column, unchanged
  source-frame X/Y, elevation in metres or blank for unknown, and coverage
- `crop-report.md`: selected window, coverage counts, source identity and limits
- `terrain-crop.json`: source-bound receipt retaining the entire verified parent,
  exact window and declarations, ASCII text, derived import, cell map and report

Retain the entire folder. `reopen-crop` recomputes the receipt's embedded data,
outputs and hashes. It does not read or repair sibling files; compare them with
the embedded fields if they have been moved or edited. `reopen` separately
validates the ordinary import. SHA-256 binds content; it does not authenticate
a source or grant permission to redistribute it.

## Coordinate example

An input has four columns, three rows, corner origin `(100, -20)` and cell size
2 metres. Selecting `1 1 2 2` keeps parent rows 1–2 and columns 1–2:

| Clip cell | Parent cell | X | Y |
|---|---|---:|---:|
| 0,0 | 1,1 | 103 | -17 |
| 0,1 | 1,2 | 105 | -17 |
| 1,0 | 2,1 | 103 | -19 |
| 1,1 | 2,2 | 105 | -19 |

The emitted raster has center origin `(103, -19)`. Its coordinates are in the
same declared frame. Elevation zero and negative elevations remain real values;
unknown cells stay unknown. The NODATA marker starts at -9999 and decreases
until absent from all known selected values. A valid -9999 elevation therefore
survives export without becoming missing data.

## Supported inputs and further work

Original ASCII and XYZ imports, declared revisions, mosaics and revisions of
mosaics all use the same crop command. Full-grid crops also provide portable
ASCII export from the other source formats. The parent is verified before any
output directory is created. Re-exporting changed terrain needs a new directory.

The generated normal import binds this immediate crop's text and includes the
parent digest in its source note. The complete parent and its license/provenance
notes live in `terrain-crop.json`, rather than inside the smaller normal import.
If you crop the generated import again, retain both crop receipts for the full
lineage. The newest receipt maps to its immediate parent only. Nothing is
silently rebased into an earlier ancestor's row/column frame.

## Boundaries and honest limits

- Cropping removes context. The new edges may have unknown slope/roughness, and
  routes cannot use excluded cells. Parent analyses and path indices are not
  automatically valid on the clip; rerun them using the new indices.
- No interpolation, gap fill, edge padding, reprojection, vertical conversion,
  automatic route remapping or data-quality inference is performed.
- Metre and degree grids may be clipped. Degree grids remain incompatible with
  metre-only analyses. ASCII itself has no authoritative CRS, units or license
  metadata; retain the sidecars and review the parent source terms.
- Every emitted center must equal the selected parent center exactly in the
  runtime's floating arithmetic. If the independent ASCII origin changes a
  coordinate through rounding, or adjacent centers collapse, the crop fails
  with an explanatory error instead of silently snapping. A smaller window or
  separately prepared exactly representable grid may be needed.
- A window of only unknown cells is allowed and explicitly `unknown-only`.
  `known-samples-only` describes selected input cells, not complete real-world
  coverage. The excluded area is not reclassified as unknown inside the clip.
- Receipt limit: 8 MiB characters. Parent imports retain their 4 MiB limit.
  Multi-file output is not atomic if I/O fails after directory creation; use a
  fresh directory on retry and retain the partial output for diagnosis.
- This is a digital terrain workflow. Existing negative-energy mission blockers
  remain unchanged. No terrain truth, mission acceptance, robot suitability or
  physical readiness is established. No external GIS application was qualified.
