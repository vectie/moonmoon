///|
fn crop_fixture() -> String raise {
  bundle(
    "ncols 4 nrows 3 xllcorner 100 yllcorner -20 cellsize 2 1 2 3 4 5 -9999 0 8 9 10 -1 12",
  )
}

///|
test "crop maps an interior window to original centers and reopens ordinary import" {
  let source = crop_fixture()
  let result = @terrain_import.crop_bundle(
    source, 1, 1, 2, 2, "study", "Synthetic focus area",
  )
  let terrain = field(result, "terrain_bundle")
  assert_eq(num(terrain, "rows"), 2.0)
  assert_eq(num(terrain, "cols"), 2.0)
  assert_eq(num(terrain, "origin_x"), 103.0)
  assert_eq(num(terrain, "origin_y"), -19.0)
  assert_eq(field(terrain, "origin_kind"), "center".to_json())
  assert_eq(num(result, "known_samples"), 3.0)
  assert_eq(num(result, "unknown_samples"), 1.0)
  assert_eq(num(result, "excluded_cells"), 8.0)
  assert_eq(field(result, "status"), "partial-coverage".to_json())
  assert_eq(
    mesh_text(result, "cells_csv"),
    "row,col,source_row,source_col,x,y,elevation_m,coverage\n0,0,1,1,103,-17,,unknown\n0,1,1,2,105,-17,0,known\n1,0,2,1,103,-19,10,known\n1,1,2,2,105,-19,-1,known\n",
  )
  assert_eq(@terrain_import.reopen_bundle(terrain.stringify()), terrain)
  assert_eq(
    @terrain_import.reopen_crop_bundle(result.stringify(indent=4)),
    result,
  )
  assert_eq(
    @terrain_import.crop_bundle(
      source, 1, 1, 2, 2, "study", "Synthetic focus area",
    ),
    result,
  )
  assert_eq(field(result, "physical_readiness"), false.to_json())
}

///|
test "crop marker avoids known sentinel values and preserves unknown zero and negative" {
  let source = bundle(
    "ncols 3 nrows 2 xllcenter -2 yllcenter 4 cellsize 0.5 NODATA_value 99 -9999 -10000 99 0 -1 2",
  )
  let result = @terrain_import.crop_bundle(
    source, 0, 0, 2, 3, "sentinel", "Full grid ASCII interchange",
  )
  let grid = @terrain_import.parse_ascii_grid(
    mesh_text(result, "ascii_grid_text"),
  )
  assert_eq(grid.nodata_value, -10001.0)
  assert_eq(grid.values, [
    Some(-9999.0),
    Some(-10000.0),
    None,
    Some(0.0),
    Some(-1.0),
    Some(2.0),
  ])
  assert_eq(num(result, "excluded_cells"), 0.0)
}

///|
test "crop supports one-cell unknown strips and degree geometry without metric claims" {
  for
    (row, col, rows, cols, known) in [
      (1, 1, 1, 1, 0),
      (0, 0, 1, 4, 4),
      (0, 3, 3, 1, 3),
    ] {
    let result = @terrain_import.crop_bundle(
      crop_fixture(),
      row,
      col,
      rows,
      cols,
      "strip",
      "Small window",
    )
    assert_eq(num(result, "known_samples"), known.to_double())
    assert_eq(@terrain_import.reopen_crop_bundle(result.stringify()), result)
    if known == 0 {
      assert_eq(field(result, "status"), "unknown-only".to_json())
    }
  }
  let source = bundle(
    "ncols 3 nrows 2 xllcenter 20.25 yllcenter -1.5 cellsize 0.25 1 2 3 4 5 6",
    unit="degrees",
  )
  let result = @terrain_import.crop_bundle(
    source, 0, 1, 2, 2, "degrees", "No reprojection",
  )
  let terrain = field(result, "terrain_bundle").stringify()
  assert_eq(field(result, "horizontal_unit"), "degrees".to_json())
  assert_eq(num(field(result, "terrain_bundle"), "origin_x"), 20.5)
  try @terrain_import.analyze_bundle(terrain, "row", 0, 10.0) catch {
    _ => ()
  } noraise {
    _ => fail("Degree clip incorrectly gained metric analysis")
  }
}

///|
test "crop accepts XYZ revisions mosaics and feeds existing route and editing" {
  let xyz = @terrain_import.import_xyz_bundle(
    "x,y,elevation_m\n0,0,1\n1,0,2\n0,1,3\n1,1,4\n", "{\"contract_id\":\"moonmoon.xyz-grid.v1\",\"tile_id\":\"xyz\",\"coordinate_frame\":\"test\",\"horizontal_unit\":\"m\",\"source_note\":\"Synthetic\",\"rows\":2,\"cols\":2,\"origin_x\":0,\"origin_y\":0,\"cell_size\":1}",
  ).stringify()
  let left = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 0 0 0",
  )
  let right = bundle(
    "ncols 2 nrows 2 xllcenter 2 yllcenter 0 cellsize 1 0 0 0 0",
  )
  let mosaic = @terrain_import.mosaic_bundle(
    left, right, "joined", "Synthetic union",
  ).stringify()
  let revision = @terrain_import.revise_bundle(
    mosaic, "row,col,expected_elevation_m,elevation_m\n0,0,0,unknown\n", "Withhold sample",
  ).stringify()
  for source in [xyz, left, mosaic, revision] {
    let result = @terrain_import.crop_bundle(
      source, 0, 1, 2, 1, "column", "Source-kind coverage",
    )
    assert_eq(@terrain_import.reopen_crop_bundle(result.stringify()), result)
    assert_eq(
      field(result, "source_bundle"),
      @terrain_import.reopen_bundle(source),
    )
  }
  let result = @terrain_import.crop_bundle(
    mosaic, 0, 1, 2, 3, "route-study", "Retain the seam",
  )
  let terrain = field(result, "terrain_bundle").stringify()
  let route = @terrain_import.route_bundle(terrain, 0, 0, 1, 2, 20.0, 1.0)
  assert_eq(field(route, "status"), "candidate-found".to_json())
  let revised = @terrain_import.revise_bundle(
    terrain, "row,col,expected_elevation_m,elevation_m\n0,0,0,1\n", "Declared change",
  )
  assert_eq(@terrain_import.reopen_bundle(revised.stringify()), revised)
}

///|
test "crop refuses invalid windows and invalid purpose before emitting a clip" {
  for
    (row, col, rows, cols) in [
      (-1, 0, 1, 1),
      (0, -1, 1, 1),
      (3, 0, 1, 1),
      (0, 4, 1, 1),
      (0, 0, 0, 1),
      (0, 0, 1, 0),
      (2, 0, 2, 1),
      (0, 3, 1, 2),
      (2147483647, 0, 1, 1),
      (0, 0, 2147483647, 1),
    ] {
    try
      @terrain_import.crop_bundle(
        crop_fixture(),
        row,
        col,
        rows,
        cols,
        "bad",
        "Window",
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("Invalid window accepted")
    }
  }
  for (tile, reason) in [("bad id", "Purpose"), ("ok", "  ")] {
    try
      @terrain_import.crop_bundle(crop_fixture(), 0, 0, 1, 1, tile, reason)
    catch {
      _ => ()
    } noraise {
      _ => fail("Invalid crop declaration accepted")
    }
  }
}

///|
test "crop replay rejects modified selection maps source and ordinary terrain import" {
  let result = @terrain_import.crop_bundle(
    crop_fixture(),
    1,
    1,
    2,
    2,
    "study",
    "Synthetic focus area",
  )
  for
    key in [
      "ascii_grid_text", "cells_csv", "report_markdown", "terrain_bundle", "source_bundle",
      "window", "unexpected",
    ] {
    let altered = @json.parse(result.stringify())
    guard altered is Object(fields) else { fail("Expected crop object") }
    fields[key] = "Changed".to_json()
    try @terrain_import.reopen_crop_bundle(altered.stringify()) catch {
      _ => ()
    } noraise {
      _ => fail("Changed crop accepted")
    }
  }
  let altered = @json.parse(crop_fixture())
  guard altered is Object(fields) else { fail("Expected source") }
  fields["samples"] = ([] : Array[Json]).to_json()
  try
    @terrain_import.crop_bundle(
      altered.stringify(),
      0,
      0,
      1,
      1,
      "bad",
      "Changed source",
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("Changed source accepted")
  }
}

///|
test "crop rejects collapsed or rounded coordinates rather than shifting samples" {
  for
    (raster, col, cols, message) in [
      (
        "ncols 2 nrows 1 xllcenter 1e20 yllcenter 0 cellsize 1 1 2", 0, 2, "collapse",
      ),
      (
        "ncols 4 nrows 1 xllcenter 100.1 yllcenter 0 cellsize 0.1 1 2 3 4", 1, 3,
        "represented exactly",
      ),
    ] {
    try
      @terrain_import.crop_bundle(
        bundle(raster),
        0,
        col,
        1,
        cols,
        "bad",
        "No snapping",
      )
    catch {
      @terrain_import.ImportError::InvalidRaster(actual) =>
        assert_true(actual.contains(message))
      _ => fail("Unexpected fixture construction error")
    } noraise {
      _ => fail("Inexact crop coordinates accepted")
    }
  }
}
