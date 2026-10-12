///|
let sample = "ncols 3\nnrows 2\nxllcorner 100\nyllcorner -50\ncellsize 20\nNODATA_value -9999\n11 -9999 13\n10 12 14\n"

///|
test "corner raster preserves row order center coordinates and nodata gaps" {
  let grid = @terrain_import.parse_ascii_grid(sample)
  assert_eq(grid.rows, 2)
  assert_eq(grid.cols, 3)
  assert_eq(grid.cell_center(0, 0), (110.0, -20.0))
  assert_eq(grid.cell_center(1, 2), (150.0, -40.0))
  assert_eq(grid.values[1], None)
  assert_eq(
    grid.terrain_csv("clip"),
    "tile_id,row,col,elevation_m\nclip,0,0,11\nclip,0,2,13\nclip,1,0,10\nclip,1,1,12\nclip,1,2,14\n",
  )
  let output = @terrain_import.import_json(
    sample, "clip", "local synthetic frame", "m", "Synthetic regression source, Apache-2.0",
  )
  assert_true(output.contains("\"sample_count\":5"))
  assert_true(output.contains("\"nodata_count\":1"))
  assert_true(output.contains("\"physical_readiness\":false"))
  assert_true(output.contains("sha256:"))
}

///|
test "center origins case whitespace no-data default and all missing remain explicit" {
  let grid = @terrain_import.parse_ascii_grid(
    "NCOLS\t2\r\nNROWS 1\nXLLCENTER -5\nYLLCENTER 6\nCELLSIZE 0.25\n-9999 1e2",
  )
  assert_eq(grid.cell_center(0, 0), (-5.0, 6.0))
  assert_eq(grid.cell_center(0, 1), (-4.75, 6.0))
  assert_false(grid.nodata_declared)
  assert_eq(grid.values, [None, Some(100.0)])
  let missing = @terrain_import.parse_ascii_grid(
    "nrows 1 ncols 1 xllcenter 0 yllcenter 0 cellsize 1 -9999",
  )
  assert_eq(missing.terrain_csv("missing"), "tile_id,row,col,elevation_m\n")
  assert_true(
    @terrain_import.import_json(
      "nrows 1 ncols 1 xllcenter 0 yllcenter 0 cellsize 1 -9999", "missing", "unknown local frame",
      "degrees", "test source",
    ).contains("\"minimum_elevation_m\":null"),
  )
}

///|
test "ordinary malformed rasters are rejected before output" {
  for
    text in [
      sample + "9",
      sample.replace(old="13", new="nan"),
      sample.replace(old="yllcorner", new="yllcenter"),
      sample.replace(old="cellsize 20", new="cellsize 0"),
      sample.replace(old="ncols 3", new="ncols 3 ncols 3"),
      "ncols 4096 nrows 2 xllcenter 0 yllcenter 0 cellsize 1",
    ] {
    assert_true(
      @terrain_import.import_json(text, "clip", "local", "m", "test").contains(
        "\"ok\":false",
      ),
    )
  }
  assert_true(
    @terrain_import.import_json(sample, "bad,tile", "local", "m", "test").contains(
      "\"ok\":false",
    ),
  )
  assert_true(
    @terrain_import.import_json(sample, "clip", "", "m", "test").contains(
      "\"ok\":false",
    ),
  )
}

///|
test "source bundle reopens from retained bytes and rejects changed data" {
  let bundle = @terrain_import.import_bundle(
    sample, "clip", "local frame", "m", "Synthetic source, Apache-2.0",
  )
  let encoded = bundle.stringify(indent=2)
  assert_eq(@terrain_import.reopen_bundle(encoded), bundle)
  let tampered = encoded.replace(
    old="\"sample_count\": 5",
    new="\"sample_count\": 6",
  )
  assert_true(@terrain_import.reopen_json(tampered).contains("\"ok\":false"))
  assert_true(@terrain_import.reopen_json("{}").contains("\"ok\":false"))
}
