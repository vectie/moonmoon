///|
fn coarse_fixture() -> String raise {
  bundle(
    "ncols 4 nrows 4 xllcorner 100 yllcorner -20 cellsize 2 1 3 10 -9999 5 7 14 18 -9999 -9999 0 -4 -9999 -9999 4 0",
  )
}

///|
fn coarse_cells(result : Json) -> Array[Json] {
  guard field(result, "cells") is Array(cells) else { abort("cells") }
  cells
}

///|
test "coarsen averages only complete blocks and records observed partial extrema" {
  let result = @terrain_import.coarsen_bundle(
    coarse_fixture(),
    2,
    "coarse",
    "Synthetic overview",
  )
  let cells = coarse_cells(result)
  assert_eq(num(cells[0], "known_count"), 4.0)
  assert_eq(num(cells[0], "mean_elevation_m"), 4.0)
  assert_eq(num(cells[0], "observed_min_m"), 1.0)
  assert_eq(num(cells[0], "observed_max_m"), 7.0)
  assert_eq(num(cells[1], "known_count"), 3.0)
  assert_eq(num(cells[1], "observed_min_m"), 10.0)
  assert_eq(num(cells[1], "observed_max_m"), 18.0)
  assert_eq(field(cells[1], "mean_elevation_m"), Json::null())
  assert_eq(field(cells[1], "coverage"), "partial-block-withheld".to_json())
  assert_eq(num(cells[2], "known_count"), 0.0)
  assert_eq(field(cells[2], "observed_min_m"), Json::null())
  assert_eq(field(cells[2], "observed_max_m"), Json::null())
  assert_eq(num(cells[3], "mean_elevation_m"), 0.0)
  assert_eq(num(result, "known_coarse_cells"), 2.0)
  assert_eq(num(result, "unknown_coarse_cells"), 2.0)
  assert_eq(field(result, "status"), "partial-coverage".to_json())
  assert_eq(field(result, "navigation_authority"), false.to_json())
  assert_eq(field(result, "physical_readiness"), false.to_json())
  assert_true(
    mesh_text(result, "cells_csv").contains(
      "0,1,0,2,2,2,106,-14,3,4,10,18,,partial-block-withheld\n",
    ),
  )
}

///|
test "coarsen keeps corner extent spacing and top to bottom block centers" {
  let result = @terrain_import.coarsen_bundle(
    coarse_fixture(),
    2,
    "coarse",
    "Aligned overview",
  )
  let terrain = field(result, "terrain_bundle")
  assert_eq(num(terrain, "rows"), 2.0)
  assert_eq(num(terrain, "cols"), 2.0)
  assert_eq(num(terrain, "origin_x"), 100.0)
  assert_eq(num(terrain, "origin_y"), -20.0)
  assert_eq(num(terrain, "cell_size"), 4.0)
  assert_eq(field(terrain, "origin_kind"), "corner".to_json())
  let grid = @terrain_import.parse_ascii_grid(
    mesh_text(result, "ascii_grid_text"),
  )
  assert_eq(grid.cell_center(0, 0), (102.0, -14.0))
  assert_eq(grid.cell_center(1, 1), (106.0, -18.0))
  assert_eq(grid.values, [Some(4.0), None, None, Some(0.0)])
  assert_eq(@terrain_import.reopen_bundle(terrain.stringify()), terrain)
}

///|
test "coarsen adjusts center origin to the center of the lower left block" {
  let source = bundle(
    "ncols 4 nrows 2 xllcenter -10 yllcenter 20 cellsize 0.5 1 3 5 7 5 7 9 11",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 2, "coarse", "Center origin",
  )
  let grid = @terrain_import.parse_ascii_grid(
    mesh_text(result, "ascii_grid_text"),
  )
  assert_eq(grid.origin_x, -9.75)
  assert_eq(grid.origin_y, 20.25)
  assert_eq(grid.cell_size, 1.0)
  assert_eq(grid.cell_center(0, 1), (-8.75, 20.25))
  assert_eq(grid.values, [Some(4.0), Some(8.0)])
  // Both source and output lower-left boundaries remain (-10.25, 19.75).
  assert_eq(grid.origin_x - grid.cell_size / 2.0, -10.25)
  assert_eq(grid.origin_y - grid.cell_size / 2.0, 19.75)
}

///|
test "coarsen factor one preserves every sample coordinate and unknown without byte identity claim" {
  for
    text in [
      "ncols 3 nrows 2 xllcenter -2 yllcenter 4 cellsize 0.5 NODATA_value 99 -9999 -10000 99 0 -1 2",
      "ncols 2 nrows 2 xllcorner 1 yllcorner -5 cellsize 2 0 2 -9999 -4",
    ] {
    let before = @terrain_import.parse_ascii_grid(text)
    let result = @terrain_import.coarsen_bundle(
      bundle(text),
      1,
      "same",
      "Same resolution export",
    )
    let after = @terrain_import.parse_ascii_grid(
      mesh_text(result, "ascii_grid_text"),
    )
    assert_eq(before.values, after.values)
    assert_eq(before.cell_size, after.cell_size)
    for row in 0..<before.rows {
      for col in 0..<before.cols {
        assert_eq(before.cell_center(row, col), after.cell_center(row, col))
      }
    }
    assert_eq(@terrain_import.reopen_coarsen_bundle(result.stringify()), result)
  }
}

///|
test "coarsen avoids a nodata sentinel collision with a known block mean" {
  let source = bundle(
    "ncols 4 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 NODATA_value 99 -9999 -9999 99 1 -9999 -9999 2 3",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 2, "sentinel", "Known negative elevations",
  )
  let grid = @terrain_import.parse_ascii_grid(
    mesh_text(result, "ascii_grid_text"),
  )
  assert_eq(grid.nodata_value, -10000.0)
  assert_eq(grid.values, [Some(-9999.0), None])
}

///|
test "coarsen all unknown and degree inputs remain explicitly limited" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 0.5 -9999 -9999 -9999 -9999",
    unit="degrees",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 2, "unknown", "No coverage",
  )
  assert_eq(field(result, "status"), "unknown-only".to_json())
  assert_eq(field(result, "horizontal_unit"), "degrees".to_json())
  assert_true(
    mesh_text(result, "overview_svg").contains("All source elevations unknown"),
  )
  try
    @terrain_import.export_mesh_bundle(
      field(result, "terrain_bundle").stringify(),
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("Degree grid gained metric mesh")
  }
}

///|
test "coarsen supports imported XYZ and terrain revisions with source-bound recomputation" {
  let xyz = @terrain_import.import_xyz_bundle(
    "x,y,elevation_m\n0,0,1\n1,0,2\n0,1,3\n1,1,4\n", "{\"contract_id\":\"moonmoon.xyz-grid.v1\",\"tile_id\":\"xyz\",\"coordinate_frame\":\"test\",\"horizontal_unit\":\"m\",\"source_note\":\"Synthetic\",\"rows\":2,\"cols\":2,\"origin_x\":0,\"origin_y\":0,\"cell_size\":1}",
  )
  let revised = @terrain_import.revise_bundle(
    xyz.stringify(),
    "row,col,expected_elevation_m,elevation_m\n0,0,3,unknown\n",
    "Withhold sample",
  )
  for (source, status) in [(xyz, "complete-blocks"), (revised, "unknown-only")] {
    let result = @terrain_import.coarsen_bundle(
      source.stringify(),
      2,
      "coarse",
      "Declared revision",
    )
    assert_eq(field(result, "source_bundle"), source)
    assert_eq(field(result, "status"), status.to_json())
    assert_eq(
      @terrain_import.reopen_coarsen_bundle(result.stringify(indent=4)),
      result,
    )
  }
}

///|
test "coarsen overview feeds contours and mesh while fine peak detail disappears" {
  let source = bundle(
    "ncols 4 nrows 4 xllcorner 0 yllcorner 0 cellsize 1 0 0 0 0 0 40 0 0 0 0 0 0 0 0 0 0",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 2, "overview", "Observe lost relief",
  )
  let terrain = field(result, "terrain_bundle")
  assert_eq(num(terrain, "maximum_elevation_m"), 10.0)
  assert_eq(num(coarse_cells(result)[0], "observed_max_m"), 40.0)
  let mesh = @terrain_import.export_mesh_bundle(terrain.stringify())
  assert_eq(num(field(mesh, "counts"), "triangles"), 2.0)
  let contours = @terrain_import.contour_bundle(terrain.stringify(), [5.0])
  assert_true(mesh_text(contours, "segments_csv").contains("5"))
  assert_true(
    mesh_text(result, "report_markdown").contains("erase narrow ridges"),
  )
}

///|
test "coarsen rejects nondivisible out of range and invalid declarations without trimming" {
  for factor in [-1, 0, 3, 5, 2147483647] {
    try
      @terrain_import.coarsen_bundle(
        coarse_fixture(),
        factor,
        "bad",
        "No trimming",
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("Invalid factor accepted")
    }
  }
  for (tile, reason) in [("bad id", "Purpose"), ("ok", "  ")] {
    try
      @terrain_import.coarsen_bundle(coarse_fixture(), 2, tile, reason)
    catch {
      _ => ()
    } noraise {
      _ => fail("Invalid declaration accepted")
    }
  }
}

///|
test "coarsen receipt reopens deterministically and refuses changed outputs and parameters" {
  let result = @terrain_import.coarsen_bundle(
    coarse_fixture(),
    2,
    "coarse",
    "Replay",
  )
  assert_eq(
    @terrain_import.coarsen_bundle(coarse_fixture(), 2, "coarse", "Replay"),
    result,
  )
  for
    key in [
      "factor", "source_bundle", "terrain_bundle", "cells", "cells_csv", "ascii_grid_text",
      "overview_svg", "report_markdown", "unexpected",
    ] {
    let altered = @json.parse(result.stringify())
    guard altered is Object(fields) else { fail("object") }
    fields[key] = "changed".to_json()
    try @terrain_import.reopen_coarsen_bundle(altered.stringify()) catch {
      _ => ()
    } noraise {
      _ => fail("Changed receipt accepted")
    }
  }
  for factor in [1.5, -1.0, 4097.0] {
    let altered = @json.parse(result.stringify())
    guard altered is Object(fields) else { fail("object") }
    fields["factor"] = factor.to_json()
    try @terrain_import.reopen_coarsen_bundle(altered.stringify()) catch {
      _ => ()
    } noraise {
      _ => fail("Noninteger factor accepted")
    }
  }
}

///|
test "coarsen handles a large representable mean without summing overflowing elevations" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1e308 1e308 1e308 1e308",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 2, "large", "Numerical bound",
  )
  assert_eq(num(coarse_cells(result)[0], "mean_elevation_m"), 1.0e308)
  assert_true(!mesh_text(result, "overview_svg").contains("NaN"))
}

///|
test "coarsen rejects collapsed coordinate centers" {
  for
    text in [
      "ncols 4 nrows 2 xllcenter 1e20 yllcenter 0 cellsize 1 1 2 3 4 5 6 7 8",
    ] {
    try
      @terrain_import.coarsen_bundle(bundle(text), 2, "bad", "No snapping")
    catch {
      _ => ()
    } noraise {
      _ => fail("Inexact coordinate mapping accepted")
    }
  }
}

///|
test "reviewer constant subnormal block preserves representable mean" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 1e-323 1e-323 1e-323 1e-323",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 2, "tiny", "Constant finite source",
  )
  let cell = coarse_cells(result)[0]
  let minimum = num(cell, "observed_min_m")
  let maximum = num(cell, "observed_max_m")
  let mean = num(cell, "mean_elevation_m")
  assert_eq(mean, minimum)
  assert_eq(mean, maximum)
  assert_true(mean > 0.0)
}

///|
test "coarsen supports tiny variation and negative constant subnormal blocks" {
  for
    (samples, expected) in [
      ("5e-324 1e-323 1e-323 1.5e-323", 1.0e-323),
      ("-1e-323 -1e-323 -1e-323 -1e-323", -1.0e-323),
      ("5e-324 5e-324 5e-324 5e-324", 5.0e-324),
      ("1e-323 -1e-323 1e-323 -1e-323", 0.0),
    ] {
    let source = bundle(
      "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 " + samples,
    )
    let result = @terrain_import.coarsen_bundle(
      source, 2, "tiny", "Tiny finite arithmetic",
    )
    assert_eq(num(coarse_cells(result)[0], "mean_elevation_m"), expected)
    assert_eq(@terrain_import.reopen_coarsen_bundle(result.stringify()), result)
  }
}

///|
test "coarsen retains tiny residues after huge opposite signs cancel" {
  for
    (samples, expected) in [
      ("1e308 1e-323 -1e308 1e-323", 5.0e-324),
      ("1e308 -1e308 1e308 -1e308", 0.0),
      ("-1e308 8 1e308 8", 4.0),
      ("1e100 1 -1e100 3", 1.0),
      ("-8 4 -4 12", 1.0),
    ] {
    let source = bundle(
      "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 " + samples,
    )
    let result = @terrain_import.coarsen_bundle(
      source, 2, "mixed", "Mixed-sign arithmetic",
    )
    assert_eq(num(coarse_cells(result)[0], "mean_elevation_m"), expected)
  }
  // Multiple expansion levels survive both large and medium cancellations.
  let source = bundle(
    "ncols 3 nrows 3 xllcenter 0 yllcenter 0 cellsize 1 1e308 1 9e-323 -1e308 -1 0 0 0 0",
  )
  let result = @terrain_import.coarsen_bundle(
    source, 3, "levels", "Multiple cancellation scales",
  )
  assert_eq(num(coarse_cells(result)[0], "mean_elevation_m"), 1.0e-323)
}

///|
test "coarsen explicitly refuses unsupported sum overflow and zero underflow" {
  for
    (samples, expected_message) in [
      ("1e308 1e308 -1e308 -1e308", "intermediate sum overflows"),
      ("1e308 1e308 1e308 8e307", "intermediate sum overflows"),
      ("5e-324 0 0 0", "underflows"),
      ("-5e-324 0 0 0", "underflows"),
    ] {
    let source = bundle(
      "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 " + samples,
    )
    try
      @terrain_import.coarsen_bundle(
        source, 2, "unsupported", "Numerical limit",
      )
    catch {
      @terrain_import.ImportError::InvalidRaster(message) =>
        assert_true(message.contains(expected_message))
    } noraise {
      _ => fail("Unsupported mean emitted a result")
    }
  }
}
