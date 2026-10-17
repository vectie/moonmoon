///|
test "contours trace known analytic plane in source metre coordinates" {
  let result = @terrain_import.contour_bundle(
    bundle("ncols 2 nrows 2 xllcenter 100 yllcenter -20 cellsize 2 0 2 0 2"),
    [1.0],
  )
  assert_eq(num(result, "segment_count"), 2.0)
  guard field(result, "segments") is Array(lines) else { fail("segments") }
  for line in lines {
    for key in ["start_m", "end_m"] {
      guard field(line, key) is Array(point) else { fail("point") }
      assert_eq(point[0], 101.0.to_json())
    }
  }
  assert_eq(field(result, "status"), "sampled-contours".to_json())
  assert_eq(field(result, "physical_readiness"), false.to_json())
}

///|
test "contours saddle uses explicit NW-SE diagonal with reproducible segments" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 2 0 0 2",
  )
  let result = @terrain_import.contour_bundle(source, [1.0])
  // The high NW-SE diagonal creates one separate segment in each triangle.
  assert_eq(num(result, "segment_count"), 2.0)
  assert_true(mesh_text(result, "segments_csv").contains("1,0,0,1,0,1,1,0"))
  assert_true(mesh_text(result, "segments_csv").contains("1,0,0,2,2,1,1,2"))
  assert_eq(result, @terrain_import.contour_bundle(source, [1.0]))
}

///|
test "contours preserve nodata neighborhoods and single row no-surface" {
  let result = @terrain_import.contour_bundle(
    bundle("ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 -9999 0 2 4"),
    [1.0, 3.0],
  )
  assert_eq(num(result, "complete_quads"), 1.0)
  assert_eq(num(result, "unknown_quads"), 1.0)
  assert_eq(num(result, "segment_count"), 2.0)
  assert_eq(field(result, "status"), "partial-coverage".to_json())
  assert_true(mesh_text(result, "contour_svg").contains("Grey: unknown"))
  assert_eq(
    field(
      @terrain_import.contour_bundle(
        bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 2"),
        [1.0],
      ),
      "status",
    ),
    "no-surface".to_json(),
  )
}

///|
test "contours level ordering plateau maxima and exact shared-edge deduplication" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 0 2",
  )
  assert_eq(
    @terrain_import.contour_bundle(source, [1.5, 0.5]),
    @terrain_import.contour_bundle(source, [0.5, 1.5]),
  )
  assert_eq(
    num(@terrain_import.contour_bundle(source, [2.0]), "segment_count"),
    0.0,
  )
  assert_eq(
    num(
      @terrain_import.contour_bundle(
        bundle("ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 1 1 1"),
        [1.0],
      ),
      "segment_count",
    ),
    0.0,
  )
  assert_eq(
    num(
      @terrain_import.contour_bundle(
        bundle("ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1 2 2 1"),
        [1.0],
      ),
      "segment_count",
    ),
    1.0,
  )
}

///|
test "contours invalid levels and units reject without modifying sources" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 0 2",
  )
  for levels in [[], [1.0, 1.0], Array::make(33, 1.0), [1.0 / 0.0]] {
    try @terrain_import.contour_bundle(source, levels) catch {
      _ => ()
    } noraise {
      _ => fail("invalid levels accepted")
    }
  }
  try
    @terrain_import.contour_bundle(
      bundle(
        "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 0 2",
        unit="degrees",
      ),
      [1.0],
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("degrees accepted")
  }
  assert_eq(@terrain_import.reopen_bundle(source), @json.parse(source))
}

///|
test "contours revised terrain changes source and does not bridge masked samples" {
  let source = bundle(
    "ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 2 4 0 2 4",
  )
  let first = @terrain_import.contour_bundle(source, [1.0, 3.0])
  let revised = @terrain_import.revise_bundle(
    source, "row,col,expected_elevation_m,elevation_m\n0,2,4,unknown\n", "Synthetic coverage withdrawal",
  ).stringify()
  let next = @terrain_import.contour_bundle(revised, [1.0, 3.0])
  assert_eq(num(first, "segment_count"), 4.0)
  assert_eq(num(next, "segment_count"), 2.0)
  assert_true(
    field(first, "source_bundle_digest") != field(next, "source_bundle_digest"),
  )
}

///|
test "contours reject tiny interior crossings rounded onto source coordinates" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 1 yllcenter 1 cellsize 1 0 1 1 1",
  )
  try @terrain_import.contour_bundle(source, [1.0e-20]) catch {
    @terrain_import.ImportError::InvalidRaster(message) =>
      assert_true(message.contains("collapse"))
  } noraise {
    _ => fail("Interior contour silently disappeared into no-crossings")
  }
}

///|
test "contours reject interior fraction underflow and rounding to one" {
  for
    (text, level) in [
      (
        "ncols 2 nrows 2 xllcenter 1 yllcenter 1 cellsize 1 0 1e308 1e308 1e308",
        1.0e-300,
      ),
      ("ncols 2 nrows 2 xllcenter 1 yllcenter 1 cellsize 1 -1e308 1 1 1", 0.0),
    ] {
    let source = bundle(text)
    try @terrain_import.contour_bundle(source, [level]) catch {
      @terrain_import.ImportError::InvalidRaster(message) =>
        assert_true(message.contains("collapse"))
    } noraise {
      _ => fail("Unrepresentable strict interior fraction accepted")
    }
  }
}

///|
test "contours retain real isolated equal-vertex contacts and representable nearby levels" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 1 yllcenter 1 cellsize 1 0 1 1 1",
  )
  let contact = @terrain_import.contour_bundle(source, [0.0])
  assert_eq(field(contact, "status"), "no-crossings".to_json())
  assert_eq(num(contact, "segment_count"), 0.0)
  let nearby = @terrain_import.contour_bundle(source, [1.0e-8])
  assert_eq(field(nearby, "status"), "sampled-contours".to_json())
  assert_eq(num(nearby, "segment_count"), 2.0)
}
