# Source-bound relief shading

The light is a declared display assumption in the source grid frame. Scale
changes display normals only. Saved results carry the original imported raster,
parameters, numeric faces, SVG, CSV and report, and can be fully recomputed.

```mbt check
///|
test "shade an imported plane and replay its complete study" {
  let imported = @terrain_import.import_bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 10 0 10 0 10", "relief-example",
    "Synthetic local XY, unverified", "m", "Newly authored synthetic Apache-2.0 example; not lunar observations",
  )
  let study = @terrain_import.relief_bundle(
    imported.stringify(),
    270.0,
    45.0,
    1.0,
  )
  assert_eq(@terrain_import.reopen_relief_bundle(study.stringify()), study)
}
```

Azimuth is clockwise from grid +Y toward +X in [0, 360); elevation is in [0, 90]
degrees above XY. Display relief scale is in [0, 100]. A 0.15 display ambient
fraction keeps dark surfaces distinct from cyan-hatched unknown neighborhoods.
This is local diffuse shading, with no cast shadows or real lunar illumination.
