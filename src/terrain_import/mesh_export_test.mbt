///|
fn mesh_text(value : Json, name : String) -> String {
  guard field(value, name) is String(text) else { abort(name) }
  text
}

///|
test "mesh exports Z-up local metre vertices and upward NW-SE faces" {
  let source = bundle(
    "ncols 2 nrows 2 xllcorner 100 yllcorner -20 cellsize 2 4 5 -1 0",
  )
  let result = @terrain_import.export_mesh_bundle(source)
  let obj = mesh_text(result, "obj_text")
  assert_true(obj.contains("v 0 2 4\nv 2 2 5\nv 0 0 -1\nv 2 0 0\n"))
  assert_true(obj.contains("f 1 3 4\nf 1 4 2\n"))
  assert_eq(num(field(result, "source_translation_m"), "x"), 101.0)
  assert_eq(num(field(result, "source_translation_m"), "y"), -19.0)
  assert_eq(num(field(result, "counts"), "triangles"), 2.0)
  assert_eq(num(field(result, "counts"), "unreferenced_vertices"), 0.0)
  assert_eq(field(result, "status"), "complete-sampled-surface".to_json())
  assert_true(
    mesh_text(result, "cells_csv").contains("0,0,101,-17,4,1,0,2,true,known\n"),
  )
  assert_true(
    mesh_text(result, "faces_csv").contains("1,0,0,1,1,3,4\n2,0,0,2,1,4,2\n"),
  )
  assert_eq(field(result, "physical_readiness"), false.to_json())
}

///|
test "mesh NODATA removes whole touching quads without bridging holes" {
  let source = bundle(
    "ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 2 -9999 4 5 6",
  )
  let result = @terrain_import.export_mesh_bundle(source)
  let counts = field(result, "counts")
  assert_eq(num(counts, "known_vertices"), 5.0)
  assert_eq(num(counts, "unknown_samples"), 1.0)
  assert_eq(num(counts, "possible_quads"), 2.0)
  assert_eq(num(counts, "omitted_unknown_quads"), 1.0)
  assert_eq(num(counts, "triangles"), 2.0)
  assert_eq(num(counts, "unreferenced_vertices"), 1.0)
  assert_eq(field(result, "status"), "partial-surface".to_json())
  assert_true(mesh_text(result, "obj_text").contains("f 1 3 4\nf 1 4 2\n"))
  assert_true(
    mesh_text(result, "cells_csv").contains("0,2,2,1,,,,,false,unknown\n"),
  )
}

///|
test "mesh no surface distinguishes known isolated samples from unknown" {
  for
    (text, expected_vertices) in [
      ("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 1 0 2", 3),
      ("ncols 1 nrows 3 xllcenter 0 yllcenter 0 cellsize 1 1 0 2", 3),
      (
        "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 -9999 -9999 -9999 -9999",
        0,
      ),
      ("ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 1 2 -9999", 3),
    ] {
    let result = @terrain_import.export_mesh_bundle(bundle(text))
    assert_eq(field(result, "status"), "no-surface".to_json())
    assert_eq(
      num(field(result, "counts"), "known_vertices"),
      expected_vertices.to_double(),
    )
    assert_eq(
      num(field(result, "counts"), "unreferenced_vertices"),
      expected_vertices.to_double(),
    )
    assert_eq(num(field(result, "counts"), "triangles"), 0.0)
    assert_true(!mesh_text(result, "obj_text").contains("\nf "))
  }
}

///|
test "mesh replay recomputes output and refuses altered data or extra fields" {
  let result = @terrain_import.export_mesh_bundle(
    bundle("ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 2 3 4"),
  )
  assert_eq(
    @terrain_import.reopen_mesh_bundle(result.stringify(indent=4)),
    result,
  )
  for
    key in [
      "obj_text", "obj_digest", "coordinate_frame", "axis_convention", "unexpected",
    ] {
    let altered = @json.parse(result.stringify())
    guard altered is Object(fields) else { fail("Expected mesh") }
    fields[key] = "Changed".to_json()
    try @terrain_import.reopen_mesh_bundle(altered.stringify()) catch {
      _ => ()
    } noraise {
      _ => fail("Changed mesh accepted")
    }
  }
}

///|
test "mesh accepts revised and mosaic samples and binds distinct source identity" {
  let left = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 2 3 4",
  )
  let right = bundle(
    "ncols 2 nrows 2 xllcenter 2 yllcenter 0 cellsize 1 5 6 7 8",
  )
  let mosaic = @terrain_import.mosaic_bundle(
    left, right, "mesh-mosaic", "Synthetic joined clips",
  ).stringify()
  let result = @terrain_import.export_mesh_bundle(mosaic)
  assert_eq(num(field(result, "counts"), "known_vertices"), 8.0)
  assert_eq(num(field(result, "counts"), "triangles"), 6.0)
  let revised = @terrain_import.revise_bundle(
    mosaic, "row,col,expected_elevation_m,elevation_m\n0,1,2,unknown\n", "Synthetic missing observation",
  ).stringify()
  let next = @terrain_import.export_mesh_bundle(revised)
  assert_eq(num(field(next, "counts"), "triangles"), 2.0)
  assert_true(
    field(next, "source_bundle_digest") != field(result, "source_bundle_digest"),
  )
  assert_eq(@terrain_import.reopen_mesh_bundle(next.stringify()), next)
}

///|
test "mesh refuses degree units overflowing and collapsed source coordinates" {
  let text = "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 2 3 4"
  let inputs = [
    (text, "degrees"),
    ("ncols 2 nrows 2 xllcenter 1e20 yllcenter 0 cellsize 1 1 2 3 4", "m"),
    ("ncols 2 nrows 2 xllcenter 1e308 yllcenter 0 cellsize 1e308 1 2 3 4", "m"),
  ]
  for (raster, unit) in inputs {
    try @terrain_import.export_mesh_bundle(bundle(raster, unit~)) catch {
      _ => ()
    } noraise {
      _ => fail("Invalid mesh coordinates accepted")
    }
  }
}

///|
test "mesh deterministic export binds source and refuses stale imported samples" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 2 3 4",
  )
  let expected = @terrain_import.export_mesh_bundle(source)
  assert_eq(@terrain_import.export_mesh_bundle(source), expected)
  let altered = @json.parse(source)
  guard altered is Object(fields) else { fail("Expected source") }
  fields["samples"] = ([] : Array[Json]).to_json()
  try @terrain_import.export_mesh_bundle(altered.stringify()) catch {
    _ => ()
  } noraise {
    _ => fail("Stale source samples accepted")
  }
}
