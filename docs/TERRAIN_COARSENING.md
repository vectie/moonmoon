# Coarse terrain overviews

Choose the scale of an imported terrain study without silently filling gaps,
trimming its extent, or losing the original source. This native workflow exports
an aligned block-mean overview, the full source-bound receipt, a side-by-side SVG,
and block statistics. It is for digital scale comparison and exchange.

## A complete example

Build `cmd/terrain_import` with the repository's pinned MoonBit toolchain. Use
private HOME/XDG directories and an absolute target directory outside the source.
Native builds/tests in the development kit use the shared native-build lock,
`--strip`, and `-j 1`. Set `TERRAIN` below to the resulting native executable,
`SOURCE` to this source root, and `WORK` to a fresh absolute output directory.

```text
$TERRAIN convert $SOURCE/data/terrain_import/synthetic-coarsening.asc $WORK/fine fine-demo "Synthetic local Cartesian frame" m "Synthetic fixture, Apache-2.0; not measured lunar terrain"
$TERRAIN coarsen $WORK/fine/terrain-import.json $WORK/coarse 2 overview "Compare scale and missing coverage; synthetic only"
$TERRAIN reopen-coarsening $WORK/coarse/terrain-coarsening.json
$TERRAIN contours $WORK/coarse/terrain-import.json $WORK/contours 3 5 7 9
$TERRAIN export-mesh $WORK/coarse/terrain-import.json $WORK/mesh
$TERRAIN convert $WORK/coarse/source.asc $WORK/exchange exchanged "Synthetic local Cartesian frame" m "Derived overview; retain terrain-coarsening.json and source license"
$TERRAIN revise $WORK/fine/terrain-import.json $SOURCE/data/terrain_import/synthetic-coarsening-edit.csv $WORK/revision "Synthetic declared replacement, not acquired terrain"
$TERRAIN coarsen $WORK/revision/terrain-import.json $WORK/revised-coarse 2 revised-overview "Recompute after declared edit"
```

The synthetic 6-row, 8-column source becomes 3 by 4. Cell spacing grows from 2 to
4 declared metres, with the corner origin still (100, -20). The original source
has a 32 m spike; its block mean is 8 m. One coarse cell is initially unknown
because one of its four source cells is missing. The declared revision supplies
that missing sample and the newly computed overview has twelve complete blocks.
The old source and overview remain usable and unchanged.

Open `overview.svg` to compare fine and coarse data on a common elevation color
scale. Row/column labels identify cells; hover text and `coarse-cells.csv` provide
observed extrema, valid counts, means, source windows and declared coordinates.
Crossed grey blocks have no exported mean. The SVG is a static inspection output,
not an interactive browser application. Color is not a safety assessment.

`scripts/verify_terrain_coarsening.mbtx` repeats the import, overview, reopen,
factor-one identity, ASCII exchange, contours, mesh, edit/recompute, explicit
crop-before-coarsening and refusal journey. Run it with three absolute arguments:
the built executable, source root, and a new evidence directory. It records every
CLI command, exit status, stdout/stderr, semantic checks and preserved hashes.

## Commands and exported files

```text
terrain_import coarsen INPUT/terrain-import.json NEW_OUTPUT INTEGER_FACTOR TILE_ID PURPOSE
terrain_import reopen-coarsening OUTPUT/terrain-coarsening.json
```

- `source.asc`: ordinary Esri ASCII raster with explicit origin and collision-free
  NODATA marker
- `terrain-import.json`: regular import consumed by existing digital tools
- `coarse-cells.csv`: one row per block, with fine source window, coordinates,
  valid/total counts, observed minimum/maximum, mean and coverage classification
- `overview.svg`: fine/coarse comparison, common source elevation range
- `coarsening-report.md`: method, source digest, assumptions and limits
- `terrain-coarsening.json`: complete parent, parameters, statistics and all
  derived outputs; reopen recomputes rather than trusting stored derived values

Keep the complete receipt with the ASCII and regular import. ASCII alone does not
convey the source frame, license or derivation. The ordinary import references the
parent digest in its source note; the receipt retains the actual parent. Earlier
crop/coarsening receipts remain separate if you chain derivations.

## Exact semantics

The factor is a positive integer that divides both row and column counts. Blocks
are anchored at source row 0, column 0, with no overlap. Factor 1 is allowed and
preserves sample values, centers and spacing, but need not preserve raw ASCII
bytes or the original NODATA marker. A nondivisible grid is rejected. Choose and
save an explicit `crop` first if a different extent is intended.

For each block of factor-squared samples:

- Valid count is the number of known source elevations, including zero and
  negative values. NODATA is never a numeric elevation.
- Observed minimum and maximum use only known samples. For a partially observed
  block these extrema are incomplete observations, not bounds on missing terrain.
- Mean is the equally weighted arithmetic mean of all source elevations, and is
  present only for a fully known block. Any missing source sample withholds the
  mean and exports NODATA for that whole block. An all-unknown block has no extrema.
- The new center is the midpoint of the block's corner sample centers. Spacing is
  multiplied by the factor. Corner lower-left origins remain fixed; center
  lower-left origins shift to the larger block center. Top-to-bottom row ordering
  and full raster footprint are retained. No reprojection or vertical conversion.

Means use floating-point arithmetic. Constant blocks retain their exact elevation,
including subnormal values and very large constants. Other blocks use error-
preserving partial summation before division so cancellation does not discard
representable small residuals. Nonfinite intermediate sums, a nonzero sum whose
mean rounds to zero, or a mean outside the observed extrema are explicitly
refused without emitting an output directory. Values are never clamped. Some
extreme mixed-sign row orders are therefore unsupported even when their final
mathematical mean could be finite; rescale inputs before retrying. Ordinary
floating-point rounding remains, including in nonconstant representable means.

Exact representability of the coordinate
mapping is checked; mismatches or collapsed centers are refused without snapping.
The existing 4096-source-cell and 1 MiB ASCII bounds apply. Receipt size is bounded
to 8 MiB characters. No source or existing output directory is overwritten.

## What this does not establish

Coarsening can erase narrow ridges, crater rims, roughness and slope hazards. A
mean is a synthetic overview value, not a measured point. Contours and meshes are
useful reference outputs, but do not recover lost detail. Do not transfer route,
energy, visibility, hazard or footprint conclusions between resolutions. Use the
original source for detailed analysis. A coarse route is not fine-scale clearance.

Degree grids are supported for numerical overviews but are not area-weighted and
remain ineligible for metre-only tools. Source/frame/unit and coverage claims are
unverified declarations. No navigation authority, mission acceptance, energy
feasibility, robot suitability or physical readiness is provided. External lunar
dataset, browser, installed lifecycle, hardware and release gates remain open.
