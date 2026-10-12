///|
fn mosaic_source(text : String) -> String raise {
  @terrain_import.import_bundle(
    text, "clip", "Synthetic Cartesian", "m", "Synthetic Apache-2.0 source; not lunar measurements",
  ).stringify()
}

///|
fn join_mosaic(left : String, right : String) -> Json raise {
  @terrain_import.mosaic_bundle(
    left, right, "joined", "Two synthetic clips, Apache-2.0; not observed terrain",
  )
}

///|
test "mosaic joins adjacent clips and feeds routing and shape analysis across seam" {
  let left = mosaic_source(
    "ncols 2 nrows 3 xllcorner -5 yllcorner -5 cellsize 10 0 1 0 1 0 1",
  )
  let right = mosaic_source(
    "ncols 2 nrows 3 xllcenter 20 yllcenter 0 cellsize 10 2 3 2 3 2 3",
  )
  let joined = join_mosaic(left, right)
  assert_eq(num(joined, "cols"), 4.0)
  assert_eq(num(joined, "rows"), 3.0)
  assert_eq(num(joined, "sample_count"), 12.0)
  assert_eq(num(at(joined, "samples", 2), "x"), 20.0)
  assert_eq(num(at(joined, "samples", 2), "y"), 20.0)
  assert_eq(
    field(joined, "source_bundles"),
    [@json.parse(left), @json.parse(right)].to_json(),
  )
  assert_eq(@terrain_import.reopen_bundle(joined.stringify(indent=2)), joined)
  assert_eq(join_mosaic(left, right), joined)
  assert_eq(
    field(join_mosaic(right, left), "terrain_csv"),
    field(joined, "terrain_csv"),
  )
  let route = @terrain_import.route_bundle(
    joined.stringify(),
    1,
    0,
    1,
    3,
    10.0,
    0.0,
  )
  assert_eq(field(route, "status"), "candidate-found".to_json())
  assert_eq(num(field(route, "summary"), "horizontal_distance_m"), 30.0)
  let analysis = @terrain_import.analyze_bundle(
    joined.stringify(),
    "row",
    1,
    10.0,
  )
  assert_eq(num(field(analysis, "grid_summary"), "estimated_cells"), 2.0)
  assert_eq(field(joined, "physical_readiness"), false.to_json())
}

///|
test "mosaic vertical negative offsets preserve top row and source row mapping" {
  let north = mosaic_source(
    "ncols 2 nrows 1 xllcenter -20 yllcenter 0 cellsize 10 5 6",
  )
  let south = mosaic_source(
    "ncols 2 nrows 2 xllcenter -20 yllcenter -20 cellsize 10 3 4 1 2",
  )
  let joined = join_mosaic(north, south)
  assert_eq(num(joined, "rows"), 3.0)
  assert_eq(num(joined, "origin_y"), -20.0)
  assert_eq(num(at(joined, "samples", 0), "elevation_m"), 5.0)
  assert_eq(num(at(joined, "samples", 4), "elevation_m"), 1.0)
  assert_true(
    field(joined, "mosaic_cells_csv")
    .stringify()
    .contains("2,0,-20,-20,1,right-only,,,,1,0,1"),
  )
}

///|
test "mosaic gaps remain unknown in saved coverage profile and routing" {
  let left = mosaic_source(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 1",
  )
  let right = mosaic_source(
    "ncols 1 nrows 1 xllcenter 20 yllcenter 0 cellsize 10 3",
  )
  let joined = join_mosaic(left, right)
  assert_eq(
    num(field(joined, "mosaic_summary"), "outside_both_footprints_cells"),
    1.0,
  )
  assert_eq(num(joined, "nodata_count"), 1.0)
  assert_eq(field(at(joined, "samples", 1), "elevation_m"), Json::null())
  let profile = @terrain_import.analyze_bundle(
    joined.stringify(),
    "row",
    0,
    80.0,
  )
  assert_eq(
    field(field(profile, "profile_summary"), "complete_elevation_coverage"),
    false.to_json(),
  )
  assert_eq(num(field(profile, "profile_summary"), "unknown_segments"), 2.0)
  let route = @terrain_import.route_bundle(
    joined.stringify(),
    0,
    0,
    0,
    2,
    80.0,
    0.0,
  )
  assert_eq(field(route, "status"), "no-path".to_json())
}

///|
test "mosaic distinguishes agreeing overlap known plus nodata and both unknown" {
  let left = mosaic_source(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 7 2 -9999 -9999",
  )
  let right = mosaic_source(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 7 -9999 3 -9999",
  )
  let joined = join_mosaic(left, right)
  let summary = field(joined, "mosaic_summary")
  assert_eq(num(summary, "agreeing_known_overlap_cells"), 1.0)
  assert_eq(num(summary, "left_only_known_cells"), 1.0)
  assert_eq(num(summary, "right_only_known_cells"), 1.0)
  assert_eq(num(summary, "unknown_cells"), 1.0)
  assert_eq(num(summary, "footprint_overlap_cells"), 4.0)
  assert_eq(num(summary, "outside_both_footprints_cells"), 0.0)
  assert_eq(field(at(joined, "samples", 3), "elevation_m"), Json::null())
  let conflict = mosaic_source(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 8 -9999 3 -9999",
  )
  try join_mosaic(left, conflict) catch {
    @terrain_import.ImportError::InvalidRaster(message) =>
      assert_true(message.contains("Conflicting known elevations"))
    _ => fail("Unexpected error type")
  } noraise {
    _ => fail("Expected conflicting elevation rejection")
  }
}

///|
test "mosaic consumes revised XYZ preserving minus 9999 as known and retains later edits" {
  let spec = "{\"contract_id\":\"moonmoon.xyz-grid.v1\",\"tile_id\":\"xyz\",\"coordinate_frame\":\"Synthetic Cartesian\",\"horizontal_unit\":\"m\",\"source_note\":\"Synthetic\",\"rows\":1,\"cols\":2,\"origin_x\":0,\"origin_y\":0,\"cell_size\":10}"
  let xyz = @terrain_import.import_xyz_bundle(
    "x,y,elevation_m\n0,0,-9999\n", spec,
  )
  let revised = @terrain_import.revise_bundle(
    xyz.stringify(),
    "row,col,expected_elevation_m,elevation_m\n0,1,unknown,4\n",
    "Declared synthetic addition",
  )
  let right = mosaic_source(
    "ncols 1 nrows 1 xllcenter 20 yllcenter 0 cellsize 10 5",
  )
  let joined = join_mosaic(revised.stringify(), right)
  assert_eq(num(at(joined, "samples", 0), "elevation_m"), -9999.0)
  assert_eq(num(at(joined, "samples", 1), "elevation_m"), 4.0)
  assert_eq(at(joined, "source_bundles", 0), revised)
  let edited = @terrain_import.revise_bundle(
    joined.stringify(),
    "row,col,expected_elevation_m,elevation_m\n0,2,5,unknown\n",
    "Withhold synthetic sample",
  )
  assert_eq(@terrain_import.reopen_bundle(edited.stringify()), edited)
  assert_eq(field(edited, "base_source_bundle"), joined)
  assert_eq(num(edited, "nodata_count"), 1.0)
  assert_eq(num(joined, "nodata_count"), 0.0)
}

///|
test "mosaic rejects alignment spacing frame unit and excessive bounding extent" {
  let original = "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0"
  let left = mosaic_source(original)
  let candidates = [
    mosaic_source("ncols 1 nrows 1 xllcenter 5 yllcenter 0 cellsize 10 0"),
    mosaic_source(
      "ncols 1 nrows 1 xllcenter 10.0000000001 yllcenter 0 cellsize 10 0",
    ),
    mosaic_source("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 20 0"),
    mosaic_source("ncols 1 nrows 1 xllcenter 40960 yllcenter 0 cellsize 10 0"),
    mosaic_source("ncols 1 nrows 1 xllcenter 640 yllcenter 640 cellsize 10 0"),
    @terrain_import.import_bundle(
      original, "different", "Other frame", "m", "Synthetic",
    ).stringify(),
    @terrain_import.import_bundle(
      original, "degrees", "Synthetic Cartesian", "degrees", "Synthetic",
    ).stringify(),
  ]
  for right in candidates {
    try join_mosaic(left, right) catch {
      _ => ()
    } noraise {
      _ => fail("Expected invalid composition rejection")
    }
  }
}

///|
test "mosaic reopen rejects altered outputs provenance and nested source graphs" {
  let left = mosaic_source(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 1",
  )
  let right = mosaic_source(
    "ncols 1 nrows 1 xllcenter 10 yllcenter 0 cellsize 10 2",
  )
  let joined = join_mosaic(left, right)
  let original = joined.stringify()
  for
    key in [
      "terrain_csv", "mosaic_cells_csv", "source_digest", "mosaic_summary", "source_bundle_digests",
      "report_markdown",
    ] {
    let altered = @json.parse(original)
    guard altered is Object(fields) else { fail("Expected object") }
    fields[key] = "tampered".to_json()
    assert_true(
      @terrain_import.reopen_json(altered.stringify()).contains("\"ok\":false"),
    )
  }
  let altered = @json.parse(original)
  guard altered is Object(fields) else { fail("Expected object") }
  fields["source_bundles"] = [@json.parse(left), @json.parse(left)].to_json()
  assert_true(
    @terrain_import.reopen_json(altered.stringify()).contains("\"ok\":false"),
  )
  try join_mosaic(original, right) catch {
    _ => ()
  } noraise {
    _ => fail("Nested mosaic accepted")
  }
  let edited = @terrain_import.revise_bundle(
    original, "row,col,expected_elevation_m,elevation_m\n0,0,1,3", "Synthetic edit",
  )
  try join_mosaic(edited.stringify(), right) catch {
    _ => ()
  } noraise {
    _ => fail("Nested revised mosaic accepted")
  }
  assert_eq(@terrain_import.reopen_bundle(original), joined)
}

///|
test "mosaic enforces combined cell bound allows fully missing source and rejects collapsed coordinates" {
  let empty = mosaic_source(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 -9999",
  )
  let far = mosaic_source(
    "ncols 1 nrows 1 xllcenter 4095 yllcenter 0 cellsize 1 -9999",
  )
  let joined = join_mosaic(empty, far)
  assert_eq(num(joined, "cols"), 4096.0)
  assert_eq(num(joined, "sample_count"), 0.0)
  assert_eq(num(joined, "nodata_count"), 4096.0)
  let collapsed = mosaic_source(
    "ncols 2 nrows 1 xllcenter 1e20 yllcenter 0 cellsize 1 1 1",
  )
  try join_mosaic(collapsed, collapsed) catch {
    _ => ()
  } noraise {
    _ => fail("Collapsed spacing accepted")
  }
}

///|
test "mosaic offset overlap preserves uncovered bounding corners" {
  let a = mosaic_source(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 10 1 7 2 3",
  )
  let b = mosaic_source(
    "ncols 2 nrows 2 xllcenter 10 yllcenter 10 cellsize 10 8 9 7 10",
  )
  let joined = join_mosaic(a, b)
  assert_eq(num(joined, "rows"), 3.0)
  assert_eq(num(joined, "cols"), 3.0)
  assert_eq(
    num(field(joined, "mosaic_summary"), "agreeing_known_overlap_cells"),
    1.0,
  )
  assert_eq(
    num(field(joined, "mosaic_summary"), "outside_both_footprints_cells"),
    2.0,
  )
  assert_eq(field(at(joined, "samples", 0), "elevation_m"), Json::null())
  assert_eq(field(at(joined, "samples", 8), "elevation_m"), Json::null())
  assert_eq(num(at(joined, "samples", 4), "elevation_m"), 7.0)
  assert_eq(
    field(joined, "terrain_csv"),
    field(join_mosaic(b, a), "terrain_csv"),
  )
}
