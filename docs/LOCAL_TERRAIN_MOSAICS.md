# Join local terrain clips for one analysis

`mosaic` composes two imported terrain clips into a single grid usable by the
existing analysis, routing, waypoint, exact-path and corridor commands. This
lets an analyst inspect local shape or route across a survey-clip seam while
keeping the contributing sources and missing coverage visible.

## Native example

Build `cmd/terrain_import` in your pinned environment, then run the executable.
Use fresh destinations, because existing output directories are refused:

```sh
terrain_import convert data/terrain_import/mosaic-west.asc west west "Synthetic Cartesian" m "Synthetic west clip, Apache-2.0; not lunar measurements"
terrain_import convert data/terrain_import/mosaic-east.asc east east "Synthetic Cartesian" m "Synthetic east clip, Apache-2.0; not lunar measurements"
terrain_import mosaic west/terrain-import.json east/terrain-import.json joined joined "Two synthetic clips, Apache-2.0; not observed terrain"
terrain_import reopen joined/terrain-import.json
terrain_import analyze joined/terrain-import.json analysis row 1 10
terrain_import route joined/terrain-import.json route 1 0 1 3 10 0
```

The result is a 3-row, 4-column grid. Its middle row rises from 0 to 3 metres in
one-metre increments over 30 horizontal metres. The route crosses the seam and
the two interior cells obtain full 3x3 shape neighborhoods spanning both inputs.
All other cells remain boundary estimates. These bundled clips are synthetic.

## Input and overlap rules

`mosaic LEFT_BUNDLE RIGHT_BUNDLE NEW_DIRECTORY TILE_ID SOURCE_NOTE`

- Inputs are two independently verified original ASCII or XYZ terrain bundles,
  or declared revisions of those originals. Their full contents, source notes,
  licenses/limitations and revision histories are retained. The output note
  describes the composition; it does not replace the original notes.
- Both inputs must declare horizontal metres, exactly the same coordinate-frame
  string and exactly equal cell spacing. Elevations are already metres. Matching
  declarations do not verify a CRS, vertical datum, measurement or license.
- Lower-left cell centers must align by exact integer cell offsets. Every mapped
  source center must equal the resulting grid center. Equivalent corner/center
  origins work. No tolerance, snapping, reprojection or resampling is inferred.
  Floating-point declarations that do not satisfy exact equality are rejected.
- The bounding rectangle includes every cell in both footprints and any gaps.
  It must contain at most 4096 cells. The saved indented bundle is limited to
  4 MiB characters, including both complete inputs.
- Two known overlapping elevations must be exactly equal, otherwise the whole
  operation fails. No source is silently preferred and no averaging occurs.
- Known plus unknown uses the known value. This includes a value withheld in a
  revision when the other input still declares a value. To withhold a cell from
  the combined source, explicitly revise the resulting mosaic to unknown.
- Unknown plus unknown and cells outside both source footprints remain unknown.
  Unknown is never zero-filled. The bounding rectangle is not a coverage claim.
- This bounded workflow accepts two clips, without nested/chained mosaics.
  Revisions of a mosaic remain usable by analysis and routing but cannot be
  inputs to another mosaic. Use an external GIS for larger multi-tile assembly.

Left/right order identifies contributors in the receipt. Reversing inputs gives
the same grid values and sparse terrain CSV but different ordered provenance.
Changing a source or revision requires a new composition and new output folder.
No imported source or previously saved result is modified.

## Saved outputs and replay

- `terrain-import.json`: canonical `moonmoon.terrain-mosaic.v1` bundle containing
  both original/revised source bundles, their complete-bundle SHA-256 identities,
  the composition recipe, exact output grid, all samples and output texts
- `terrain.csv`: the usual sparse known-elevation grid for downstream consumers
- `mosaic-cells.csv`: every output cell, coordinates, result, contribution and
  each input's local row/column/elevation
- `source-recipe.json`: deterministic method and exact ordered input identities
- `mosaic-report.md`: methods, coverage summary, interpretation and limits

In `mosaic-cells.csv`, blank input row/column means outside that input footprint.
A present input row/column with blank elevation means source NODATA. Blank result
elevation means unknown. `left-only` and `right-only` refer to known value
contributions, even where the other source has an unknown cell. The summary
separates footprint overlap, agreeing known overlap and gaps outside both inputs.

`reopen` independently rebuilds both source bundles and the entire mosaic and
compares every exported field. JSON whitespace and key order may differ; altered
source data, mapping, summaries, output text or digests are rejected. The source
recipe digest and per-output hashes are integrity identifiers, not signatures or
proof of external data quality. The complete bundle preserves provenance that
CSV alone cannot retain. Determinism is bounded to the tested environment.

A mosaic is accepted by the existing `edit-template`/`revise` flow. The revision
retains the entire composite as its base, including both inputs. Reopening
replays the composite first and then the ordered edits. Earlier receipts remain
unchanged. The normal source/size and revision-history limits still apply.

## Interpretation and limits

This supports authored PRD MN-W01, MN-W02, B01, B03, N01 and N03 by making local
source composition useful for traceable downstream analysis. It does not change
an authored requirement's acceptance status or qualify external lunar data.
The declared frame and vertical datum must actually match before an analyst
relies on the numbers. Equal overlapping values do not authenticate a source.

Saved analysis keeps gaps in its profile and local neighborhoods; routing cannot
cross unknown cells. A known joined seam is still only declared evidence.
There is no terrain truth, subcell hazard, energy feasibility, robot suitability,
mission acceptance or physical readiness inference. Existing negative-energy
mission blockers remain unchanged. No hardware, external dataset download,
provider or UI workflow is involved.

Input validation finishes before creating an output directory. Multi-file
persistence follows the existing CLI and is not atomic across I/O interruption;
retain the inputs and retry in a fresh directory if interrupted.
