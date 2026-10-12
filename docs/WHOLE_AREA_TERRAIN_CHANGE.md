# Inspect changes across a whole terrain area

When a terrain dataset or coverage revision arrives, compare every cell before
choosing which routes or corridors need another look. `compare-area` gives a
source-bound map, cell CSV and explicitly modeled elevation-change volumes for
two exactly aligned grids. Unlike `compare-path`, it does not require a route or
omit changes away from one. It does not assess route feasibility or repeat the
path energy calculation.

## Synthetic example

After building the native `cmd/terrain_import` executable in the pinned
environment, run from the repository with fresh output directories:

```sh
terrain_import convert data/terrain_import/area-reference.asc reference area-reference "Synthetic local Cartesian" m "Synthetic Apache-2.0 example; not observed lunar terrain"
terrain_import convert data/terrain_import/area-candidate.asc candidate area-candidate "Synthetic local Cartesian" m "Synthetic Apache-2.0 example; not observed lunar terrain"
terrain_import compare-area reference/terrain-import.json candidate/terrain-import.json area-study 1
```

The two 3-by-3 grids cover 900 m2. Five shared known cells cover 500 m2; two
cells gain coverage, one loses it, and one is unknown in both. One 2 m rise
strictly exceeds the 1 m threshold. The +1 m rise and -1 m fall equal the
threshold and are classified within it. Known positive volume is +300 m3,
negative volume is -100 m3, and the observed net is +200 m3. Whole-grid
statistics remain null because four cells have no known difference.

These are differences between synthetic inputs. They do not describe observed
lunar change, excavation quantities or deposited material.

## Inputs and alignment

`compare-area REFERENCE_BUNDLE CANDIDATE_BUNDLE NEW_DIRECTORY THRESHOLD_METRES`

The public API is `compare_area_bundle(reference, candidate, change_threshold_m)`.
It independently reopens and recomputes both sources. Original ASCII, XYZ,
revised and mosaic bundles use the same workflow. Retain the complete JSON,
which includes both source bundles, for replay; CSV alone lacks provenance.

Both sources must declare metre horizontal and elevation units and an identical
coordinate-frame string. Dimensions, cell spacing and first cell center must
match exactly. Equivalent corner/center origin declarations are accepted. No
floating tolerance, resampling, reprojection, clipping or automatic registration
is inferred. Matching labels cannot establish a shared real-world vertical datum,
source accuracy or a parent-child revision relationship. Confirm those separately.
The existing source limits (4096 cells and 4 MiB per input bundle) still apply.

Threshold must be finite and nonnegative. It is a chosen magnitude for map
classification, not measurement uncertainty or statistical significance. A delta
strictly greater than threshold is a rise exceedance; a delta strictly less than
negative threshold is a fall exceedance. Equality and zero are within threshold.
Changing the threshold never discards small differences from statistics or volume.

## Outputs and interpretation

- `terrain-area-comparison.json`: exact sources, method, threshold, cells, counts,
  area accounting, statistics, export texts and SHA-256 identities
- `area-changes.csv`: every cell in row-major order, source center coordinates,
  before/after elevation, signed delta, coverage class, change class and volume
- `area-change.svg`: accessible standalone map. Orange rises, blue falls and pale
  within-threshold cells have known deltas. Crossed green means gained coverage,
  crossed red means lost coverage, and crossed gray means unknown in both
- `area-report.md`: human-readable findings, source/frame/units, assumptions and
  coverage limits

All differences are candidate minus reference. Positive/negative/net volume is
computed over shared known cells only. The explicit model treats each source
sample as a constant-height square of area cell_size squared. Cell volume is
height difference times area. Negative volume stays signed, so net volume is the
sum of positive and negative volume. Values are not threshold filtered. No density,
mass, subcell geometry or interpolation is modeled.

The map uses classes, not a continuous magnitude scale. Row zero appears at the
top, columns increase toward source +x, and rows increase toward source -y. The
map does not infer geographic orientation. Hover titles and the CSV give exact
cell identities and values. Source metadata is not inserted into SVG markup.

Coverage gained/lost is useful information, but neither yields an elevation delta
or volume. Those fields stay null in JSON and blank in CSV. If even one cell lacks
paired elevations, `whole_grid_statistics` is null and status is
`incomplete-comparison`. Observed statistics remain useful for the measured subset
but cannot bound unknown changes. With no shared observations, observed statistics
are also null and status is `no-shared-elevation-coverage`. With complete paired
coverage, status is `complete-comparison`, never a physical readiness label.

## Replay and limits

Repeat the exact sources and threshold into another fresh output directory for
byte-identical replay in the qualified environment. Source identities and the
comparison digest bind the full result. Individual CSV, SVG and report digests
bind exported bytes. SHA-256 is an integrity identifier, not a signature or
provenance authentication. Floating-point last bits can differ across backends;
no cross-runtime bitwise guarantee is made. Extremely different numeric scales
can lose precision. Nonfinite results and detected area/volume underflow are
rejected rather than exported.

Validation happens before output creation. Existing destinations are refused and
source/prior outputs remain unchanged. Multi-file persistence is not atomic under
I/O interruption; preserve the inputs and rerun in a fresh directory. There is
no special reopen command for the comparison: its embedded source bundles and
threshold are the reusable inputs.

This supports the PRD terrain analyst revision job and MN-W02/B03/N01/N03 with a
new exploration workflow. It does not upgrade the authored requirement statuses.
There is no uncertainty propagation, statistical change detection, physical terrain
truth, automatic route requalification, energy analysis, robot suitability,
mission acceptance or physical readiness. Existing negative-energy blockers remain.
