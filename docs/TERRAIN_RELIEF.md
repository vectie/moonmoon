# Parameterized imported-raster relief

Render an imported raster with a declared light, compare light directions and
display relief, and repeat on a retained terrain revision. This is a local
directional diffuse display, not actual lunar lighting or a mission decision.

## Import, shade, adjust and inspect

Build `cmd/terrain_import` with the project's pinned MoonBit native toolchain.
Use the resulting executable in place of `terrain_import` below. Every output
directory must be new; existing studies are never overwritten.

```text
terrain_import convert data/terrain_import/relief-hill.asc my-import relief-hill "Synthetic local XY, unverified" m "Synthetic Apache-2.0 example, not observations"
terrain_import relief my-import/terrain-import.json northwest 315 35 1
terrain_import relief my-import/terrain-import.json southeast 135 35 1
terrain_import relief my-import/terrain-import.json exaggerated 315 35 3
terrain_import relief my-import/terrain-import.json flat 315 35 0
terrain_import relief my-import/terrain-import.json overhead 315 90 1
```

Open each `relief.svg` side by side in an SVG-capable browser or viewer. The
opposite light changes apparent slopes; the exaggerated view emphasizes relief.
All retain identical imported samples and source identity. In the flat view,
known triangles share one intensity but gaps remain hatched. The synthetic hill
has 49 sample positions, one unknown sample, 32 complete neighborhoods and
64 shaded triangles. These are newly authored examples, not lunar observations.

The overhead view has no horizontal light direction. Its light indicator is a
labeled center dot rather than a directional arrow.

The `relief` command accepts saved ASCII, aligned XYZ, PDS3, mosaic, crop,
coarsened and revised bundles through the existing verified import boundary.
Its parameters, in order, are:

- Azimuth in degrees: finite `[0, 360)`, clockwise from source +Y toward +X.
  0 faces +Y, 90 faces +X, 180 faces -Y, 270 faces -X.
- Elevation in degrees: finite `[0, 90]` above the source XY plane.
- Display relief scale: finite `[0, 100]`; 1 uses original slopes, 0 flattens
  display normals, larger values exaggerate slopes. Source elevations never change.

Source XY coordinates and elevations must be metres. Grid +Y is up in the map,
and +X is right. The source frame and datum remain caller declarations. No
geographic north/east or lunar illumination direction is inferred.

## Revise the terrain and compare fairly

```text
terrain_import revise my-import/terrain-import.json data/terrain_import/relief-edit.csv revision "Synthetic gap declaration and peak edit; not observations"
terrain_import relief revision/terrain-import.json revised 315 35 1
terrain_import reopen-relief revised/terrain-relief.json
```

The example edit declares a 5 m value for the missing sample and raises the
center peak from 40 to 60 m. It produces 36 complete neighborhoods and 72 shaded
triangles. Compare `revised/relief.svg` with `northwest/relief.svg`, which uses
the same light and scale. Their source digests differ; the original raster and
prior displays remain unchanged. Filling the gap is a user declaration, not a
new measurement or qualified coverage.

## Outputs and replay

- `relief.svg`: annotated map, assumed light direction, grid axes, parameters,
  source digest, counts and hatched unknown neighborhoods
- `relief-faces.csv`: one row per known triangle, or per unknown neighborhood;
  upward display normal, diffuse coefficient, display intensity and gray byte
- `relief-report.md`: exact assumptions, formulas, source identity and limits
- `terrain-relief.json`: full source bundle, parameters, original-coordinate
  triangle vertices, numeric results and all outputs with digests

`reopen-relief` recomputes the source, parameters, faces and exports and rejects
changed content. JSON whitespace and key order may differ. The source-bound
study digest covers source identity, light/scale/ambient parameters and algorithm;
separate output digests cover SVG, CSV and report. It is not a signed attestation.
Keep all four outputs together. The JSON carries its entire imported source.

## Display model and limits

Each fully known 2×2 neighborhood is split along NW–SE into two flat triangles,
matching the existing OBJ and contour convention. A triangle's upward normal is
`normalize(-scale * dz/dx, -scale * dz/dy, 1)`. The vector toward the light is
`(cos(elevation) * sin(azimuth), cos(elevation) * cos(azimuth), sin(elevation))`.
Diffuse is the nonnegative normal-light dot product, clamped to `[0,1]`.
Intensity is `0.15 + 0.85 * diffuse`; the gray byte is nearest integer
`255 * intensity`. There is no gamma, material/albedo, horizon or shadow model.

Every neighborhood touching NODATA is omitted and marked by cyan hatching.
Darkness only means low local diffuse response. No unknown cell is silently
filled, and no known three-corner half-neighborhood is salvaged. The surface
spans sample centers only, with no outer half-cell rim, smoothing, bridging or
extrapolation. One-row, one-column and fully unsupported grids export an explicit
`no-surface` result, never an invented relief surface. Source grids remain bounded
to 4096 cells; saved relief bundles are limited to 16 MiB characters.

Incompatible units, invalid parameters, unrepresentable centers and numeric
overflow stop before output creation. Filesystem interruption after directory
creation can leave partial files; restart durability is not qualified. This
native CLI workflow does not add controls to the existing 3D browser cockpit.
No actual lunar illumination, terrain truth, route feasibility, energy,
navigation, robot suitability, mission acceptance or physical readiness is claimed.

## Verify the complete command journey

```text
moon --target-dir /absolute/external/automation-build run scripts/verify_relief.mbtx --target native --strip -j 1 -- /absolute/path/to/terrain_import.exe /absolute/path/to/source /absolute/new/journey
```

Use the project's private HOME/XDG and shared native lock, as in the retained
build guide. The journey imports the hill, adjusts light and relief, revises
terrain, verifies replay, shades the PDS3 example, checks refusals, and records
input/output hashes and command logs. It uses only local synthetic data.
