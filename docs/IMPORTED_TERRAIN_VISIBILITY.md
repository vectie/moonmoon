# Inspect a terrain line of sight

Use an imported local Cartesian metre grid to explore whether a ridge obstructs
an elevated straight line between two cell-center sites. Vary the two heights
and inspect the exact intersected cells and a profile. This fills the imported
terrain horizon/visibility exploration gap in PRD MN-W02, B03, N01 and N03.
It does not qualify a lunar horizon, radio link or solar forecast.

## Synthetic example

With a native `cmd/terrain_import` executable built in the pinned environment,
run these commands from the repository using unused output directories:

```sh
terrain_import convert data/terrain_import/synthetic-visibility.asc source visibility "Synthetic local Cartesian" m "Synthetic ridge, Apache-2.0; not observed lunar terrain"
terrain_import visibility source/terrain-import.json blocked 1 0 1 4 1 1
terrain_import visibility source/terrain-import.json grazing 1 0 1 4 5 5
terrain_import visibility source/terrain-import.json raised 1 0 1 4 6 6
```

The sites are 40 metres apart. The 5-metre ridge blocks the 1-metre line with
minimum clearance -4 m; the 5-metre line grazes it; the 6-metre line has 1 m
minimum clearance and is `clear-in-model`. The fixture's off-line NODATA cell
does not affect these particular straight segments. All data is synthetic.

`visibility BUNDLE NEW_DIRECTORY OBSERVER_ROW OBSERVER_COL TARGET_ROW TARGET_COL OBSERVER_HEIGHT_M TARGET_HEIGHT_M`

Rows/columns are zero based. Row zero is the source's top row; columns increase
with source x, rows increase toward decreasing source y. No geographic compass
orientation is inferred. Both endpoints must be distinct in-bounds cells with
known terrain elevations. Heights above each endpoint's own terrain must be
finite and nonnegative. Zero height is allowed but contact is grazing, not clear.

The existing original ASCII, XYZ, revised and mosaic bundles are supported.
Each source is fully reopened/recomputed before analysis. Degree grids are
rejected. Frame, units, vertical datum and source quality remain declarations;
use a genuinely appropriate local Cartesian frame. Existing 4096-cell and
4 MiB input-bundle limits apply. Overflow/underflow detected in calculations
is refused before output creation. No new dependency or MoonRobo input is needed.

## What is saved

- `visibility.json`: source-bound `moonmoon.terrain-visibility.v1` result with
  the entire verified source bundle, parameters, endpoints, ordered cell trace,
  summaries, export texts and their SHA-256 digests
- `visibility-cells.csv`: cell-center coordinates, intersection entry/exit
  fractions and distances, terrain elevation, line entry/exit elevations,
  minimum clearance, contact kind and per-cell status
- `visibility-profile.svg`: standalone accessible profile, straight white line,
  colored constant-height terrain spans, gray unknown regions and corner dots
- `visibility-report.md`: outcome, exact input identity, assumptions and limits

The profile exaggerates vertical scale independently of horizontal scale.
Read the CSV for exact values. The SVG uses no external resources or source
strings as markup. The JSON's visibility digest binds the result before the
digest field is inserted. These hashes identify integrity, not signatures,
provenance authentication or external terrain truth.

Repeat the same command into a new directory to reproduce the output. Changing
either height or the source creates a distinct result. The original source and
previous results remain untouched. To reassess missing or revised data, use the
existing `edit-template`/`revise` workflow and analyze the new bundle. Retain the
full source and results; CSV alone does not preserve provenance. There is no
special reopen command for the visibility result: rerun from its retained
source and parameter values to compare canonical output. Determinism is bounded
to the qualified environment.

## Geometry and coverage rules

This is a flat, local geometric model. Each closed square grid cell is modeled
as a constant-height prism using its one declared elevation. The sightline joins
the elevated endpoint centers. Its intersection with every grid cell is computed
with exact integer ratios, so a diagonal passing through a corner also includes
the two cells touched only at that corner. Shared boundary contacts evaluate
both neighbors. Unknown corner-only cells still make coverage incomplete.

Within each known intersection, clearance is the lower of line entry/exit
heights minus that cell's terrain height. This checks the entire cell span,
including both endpoint cells, rather than just samples on the centerline.
A steep step can therefore block a line whose endpoints are both above ground.
Line elevations/clearances use floating point; exact zero means grazing, with
no tolerance inferred. Extremely different numeric scales lose precision and
should be rescaled or evaluated with a suitable external model.

Outcome precedence is:

1. `blocked-known-terrain`: at least one strictly negative known clearance,
   even if another intersected cell is unknown
2. `incomplete-coverage`: no known negative clearance, but at least one unknown
   intersected cell
3. `grazing`: complete coverage with at least one exactly zero clearance
4. `clear-in-model`: complete coverage and all clearances strictly positive

The result separately reports blocked, grazing, unknown and corner-contact
counts. Unknown elevation and clearance are JSON null/blank CSV, never zero.
The whole-line minimum is null whenever a required cell is unknown. The known
minimum is only over observed cells and does not bound unknown obstructions.
Output order is entry fraction, exit fraction, then row-major cell identity.

## Important limits

Constant-height cells are an explicit exploratory assumption, not a verified
terrain surface. Corner inclusion is conservative within that model only.
No subcell structure, uncertainty propagation, spherical lunar curvature,
refraction, Fresnel clearance, antenna pattern, radio link budget or ephemeris
is modeled. The result cannot certify communication, illumination, energy,
robot suitability or physical mission readiness. The original negative-energy
mission remains blocked. This is a new source-bound analysis tool, not a
change to mission acceptance or PRD release qualification.

Validation completes before output directory creation and existing destinations
are refused. As with the existing CLI, multi-file persistence is not atomic
under I/O interruption. Preserve inputs and retry in a new directory if a save
is interrupted. No automatic source correction or gap filling is performed.
