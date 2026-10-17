///|
fn relief_first(result : Json) -> Json {
  at(result, "faces", 0)
}

///|
test "relief flat plane uses declared elevation and overhead light is azimuth independent" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 10 10 10 10",
  )
  let result = @terrain_import.relief_bundle(source, 0.0, 30.0, 1.0)
  assert_eq(num(result, "triangle_count"), 2.0)
  assert_true((num(relief_first(result), "diffuse") - 0.5).abs() < 1.0e-12)
  assert_true(
    (num(relief_first(result), "display_intensity") - 0.575).abs() < 1.0e-12,
  )
  assert_eq(num(relief_first(result), "gray_8bit"), 147.0)
  let a = @terrain_import.relief_bundle(source, 0.0, 90.0, 1.0)
  let b = @terrain_import.relief_bundle(source, 270.0, 90.0, 1.0)
  assert_eq(field(a, "faces"), field(b, "faces"))
  assert_eq(num(relief_first(a), "diffuse"), 1.0)
  assert_true(mesh_text(a, "relief_svg").contains("Overhead: no XY direction"))
  assert_true(
    !mesh_text(a, "relief_svg").contains("marker-end=\"url(#arrow)\""),
  )
  assert_eq(field(result, "physical_readiness"), false.to_json())
}

///|
test "relief positive X slope faces negative X light with explicit grid azimuth" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 100 yllcenter -20 cellsize 2 0 2 0 2",
  )
  let west = @terrain_import.relief_bundle(source, 270.0, 45.0, 1.0)
  let east = @terrain_import.relief_bundle(source, 90.0, 45.0, 1.0)
  for i in 0..<2 {
    assert_true((num(at(west, "faces", i), "diffuse") - 1.0).abs() < 1.0e-12)
    assert_true(num(at(east, "faces", i), "diffuse") < 1.0e-12)
  }
  assert_eq(
    field(west, "source_bundle_digest"),
    field(east, "source_bundle_digest"),
  )
  assert_true(field(west, "relief_digest") != field(east, "relief_digest"))
  assert_true(
    field(west, "relief_svg_digest") != field(east, "relief_svg_digest"),
  )
}

///|
test "relief positive Y slope respects top to bottom rows and south light" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 2 2 0 0",
  )
  let south = @terrain_import.relief_bundle(source, 180.0, 45.0, 1.0)
  let north = @terrain_import.relief_bundle(source, 0.0, 45.0, 1.0)
  assert_true((num(relief_first(south), "diffuse") - 1.0).abs() < 1.0e-12)
  assert_true(num(relief_first(north), "diffuse") < 1.0e-12)
}

///|
test "relief scale changes normals but leaves source samples and vertices unchanged" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 0 2 0 2",
  )
  let flat = @terrain_import.relief_bundle(source, 270.0, 45.0, 0.0)
  let actual = @terrain_import.relief_bundle(source, 270.0, 45.0, 1.0)
  let exaggerated = @terrain_import.relief_bundle(source, 270.0, 45.0, 3.0)
  assert_eq(field(flat, "source_bundle"), field(exaggerated, "source_bundle"))
  assert_eq(
    field(relief_first(flat), "vertices_m"),
    field(relief_first(exaggerated), "vertices_m"),
  )
  assert_eq(
    field(relief_first(flat), "display_normal"),
    [0.0, 0.0, 1.0].to_json(),
  )
  assert_true(
    num(relief_first(actual), "diffuse") >
    num(relief_first(exaggerated), "diffuse"),
  )
  assert_true(
    num(relief_first(exaggerated), "diffuse") >
    num(relief_first(flat), "diffuse"),
  )
}

///|
test "relief saddle follows the same explicit NW SE split as reference mesh" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 2 0 0 2",
  )
  let result = @terrain_import.relief_bundle(source, 225.0, 30.0, 1.0)
  let a = at(result, "faces", 0)
  let b = at(result, "faces", 1)
  assert_eq(
    field(a, "vertices_m"),
    [[0.0, 2.0, 2.0], [0.0, 0.0, 0.0], [2.0, 0.0, 2.0]].to_json(),
  )
  assert_eq(
    field(b, "vertices_m"),
    [[0.0, 2.0, 2.0], [2.0, 0.0, 2.0], [2.0, 2.0, 0.0]].to_json(),
  )
  assert_true(num(a, "diffuse") > 0.9)
  assert_eq(num(b, "diffuse"), 0.0)
}

///|
test "relief nodata omits entire quad and remains visibly separate from darkness" {
  let source = bundle(
    "ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 -9999 0 2 4",
  )
  let result = @terrain_import.relief_bundle(source, 90.0, 0.0, 1.0)
  assert_eq(num(result, "complete_quads"), 1.0)
  assert_eq(num(result, "unknown_quads"), 1.0)
  assert_eq(num(result, "triangle_count"), 2.0)
  assert_eq(field(result, "status"), "partial-surface".to_json())
  assert_true(mesh_text(result, "faces_csv").contains("0,1,,unknown,,,,,,"))
  assert_true(
    mesh_text(result, "relief_svg").contains("fill=\"url(#unknown)\""),
  )
  assert_true(
    mesh_text(result, "relief_svg").contains("darkness = local diffuse shading"),
  )
  assert_eq(num(relief_first(result), "display_intensity"), 0.15)
}

///|
test "relief one dimensional and all unknown grids report no surface" {
  for
    text in [
      "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 2", "ncols 1 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2",
      "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 -9999 -9999 -9999 -9999",
    ] {
    let result = @terrain_import.relief_bundle(bundle(text), 0.0, 45.0, 1.0)
    assert_eq(num(result, "triangle_count"), 0.0)
    assert_eq(field(result, "status"), "no-surface".to_json())
    assert_true(
      mesh_text(result, "relief_svg").contains("No supported surface"),
    )
  }
}

///|
test "relief revision adds declared coverage with distinct source and keeps original" {
  let source = bundle(
    "ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 -9999 0 2 4",
  )
  let before = @terrain_import.relief_bundle(source, 270.0, 45.0, 1.0)
  let revised = @terrain_import.revise_bundle(
    source, "row,col,expected_elevation_m,elevation_m\n0,2,unknown,4\n", "Synthetic gap declaration",
  ).stringify()
  let after = @terrain_import.relief_bundle(revised, 270.0, 45.0, 1.0)
  assert_eq(num(after, "triangle_count"), 4.0)
  assert_true(
    field(before, "source_bundle_digest") !=
    field(after, "source_bundle_digest"),
  )
  assert_eq(before, @terrain_import.relief_bundle(source, 270.0, 45.0, 1.0))
}

///|
test "relief replay reconstructs all outputs and ignores JSON formatting" {
  let result = @terrain_import.relief_bundle(bundle(plane), 315.0, 35.0, 2.0)
  assert_eq(
    @terrain_import.reopen_relief_bundle(result.stringify(indent=2)),
    result,
  )
  assert_eq(@terrain_import.reopen_relief_bundle(result.stringify()), result)
}

///|
test "relief replay rejects changes to parameters source numeric output and displayed output" {
  let original = @terrain_import.relief_bundle(bundle(plane), 315.0, 35.0, 2.0)
  for
    key in [
      "relief_svg", "faces_csv", "report_markdown", "relief_digest", "physical_readiness",
      "source_bundle", "faces", "parameters",
    ] {
    let tampered = @json.parse(original.stringify())
    guard tampered is Object(fields) else { fail("object") }
    fields[key] = "changed".to_json()
    try @terrain_import.reopen_relief_bundle(tampered.stringify()) catch {
      _ => ()
    } noraise {
      _ => fail("accepted changed " + key)
    }
  }
  guard original is Object(fields) &&
    fields.get("parameters") is Some(Object(parameters)) else {
    fail("parameters")
  }
  parameters["light_azimuth_deg"] = 135.0.to_json()
  try @terrain_import.reopen_relief_bundle(original.stringify()) catch {
    _ => ()
  } noraise {
    _ => fail("accepted changed valid parameter without recomputation")
  }
}

///|
test "relief refuses invalid light scale and incompatible coordinate units" {
  let source = bundle(plane)
  for
    (azimuth, elevation, scale) in [
      (-1.0, 45.0, 1.0),
      (360.0, 45.0, 1.0),
      (0.0, -1.0, 1.0),
      (0.0, 91.0, 1.0),
      (0.0, 45.0, -1.0),
      (0.0, 45.0, 101.0),
      (1.0 / 0.0, 45.0, 1.0),
      (0.0, 0.0 / 0.0, 1.0),
      (0.0, 45.0, 1.0 / 0.0),
    ] {
    try @terrain_import.relief_bundle(source, azimuth, elevation, scale) catch {
      _ => ()
    } noraise {
      _ => fail("invalid relief accepted")
    }
  }
  try
    @terrain_import.relief_bundle(bundle(plane, unit="degrees"), 0.0, 45.0, 1.0)
  catch {
    _ => ()
  } noraise {
    _ => fail("degrees accepted")
  }
}

///|
test "relief refuses overflowing elevation differences and collapsed coordinate centers" {
  for
    text in [
      "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 -1e308 1e308 -1e308 1e308",
      "ncols 2 nrows 2 xllcenter 1e20 yllcenter 0 cellsize 1 0 2 0 2",
    ] {
    try @terrain_import.relief_bundle(bundle(text), 270.0, 45.0, 1.0) catch {
      _ => ()
    } noraise {
      _ => fail("unrepresentable surface accepted")
    }
  }
}
