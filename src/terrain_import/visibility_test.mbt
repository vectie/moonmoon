///|
fn sight_rejected(action : () -> Json raise) -> Unit raise {
  try action() catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
    error => fail("Unexpected error: " + error.to_string())
  } noraise {
    _ => fail("Expected invalid visibility input")
  }
}

///|
test "visibility flat line retains exact source parameters clearances and deterministic outputs" {
  let source = bundle(
    "ncols 4 nrows 1 xllcorner 100 yllcorner 200 cellsize 10 0 0 0 0",
  )
  let result = @terrain_import.visibility_bundle(source, 0, 0, 0, 3, 2.0, 2.0)
  assert_eq(field(result, "status"), "clear-in-model".to_json())
  assert_eq(field(result, "coverage_complete"), true.to_json())
  let summary = field(result, "summary")
  assert_eq(num(summary, "horizontal_distance_m"), 30.0)
  assert_eq(num(summary, "whole_line_minimum_clearance_m"), 2.0)
  assert_eq(num(summary, "intersected_cells"), 4.0)
  assert_eq(num(field(result, "observer"), "x_m"), 105.0)
  assert_eq(num(field(result, "target"), "x_m"), 135.0)
  assert_eq(num(at(result, "cells", 0), "entry_distance_m"), 0.0)
  assert_eq(num(at(result, "cells", 0), "exit_distance_m"), 5.0)
  assert_eq(num(at(result, "cells", 3), "entry_distance_m"), 25.0)
  assert_eq(num(at(result, "cells", 3), "exit_distance_m"), 30.0)
  assert_eq(
    field(result, "source_bundle"),
    @terrain_import.reopen_bundle(source),
  )
  assert_eq(
    result,
    @terrain_import.visibility_bundle(source, 0, 0, 0, 3, 2.0, 2.0),
  )
  assert_eq(field(result, "physical_readiness"), false.to_json())
  assert_true(
    field(result, "profile_svg") is String(svg) &&
    svg.contains("No physical readiness") &&
    svg.contains("Observer to target sightline"),
  )
}

///|
test "visibility ridge and height sensitivity distinguish obstruction grazing and strictly clear" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 5 0",
  )
  let blocked = @terrain_import.visibility_bundle(source, 0, 0, 0, 2, 1.0, 1.0)
  let grazing = @terrain_import.visibility_bundle(source, 0, 0, 0, 2, 5.0, 5.0)
  let clear = @terrain_import.visibility_bundle(source, 0, 0, 0, 2, 6.0, 6.0)
  assert_eq(field(blocked, "status"), "blocked-known-terrain".to_json())
  assert_eq(
    num(field(blocked, "summary"), "whole_line_minimum_clearance_m"),
    -4.0,
  )
  assert_eq(field(grazing, "status"), "grazing".to_json())
  assert_eq(num(field(grazing, "summary"), "grazing_cells"), 1.0)
  assert_eq(field(clear, "status"), "clear-in-model".to_json())
  assert_eq(num(field(clear, "summary"), "whole_line_minimum_clearance_m"), 1.0)
  assert_true(
    field(blocked, "visibility_digest") != field(clear, "visibility_digest"),
  )
  let flat = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0")
  assert_eq(
    field(
      @terrain_import.visibility_bundle(flat, 0, 0, 0, 1, 0.0, 2.0),
      "status",
    ),
    "grazing".to_json(),
  )
}

///|
test "visibility checks full cell interval including endpoint terrain rather than only centers" {
  let source = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10",
  )
  let result = @terrain_import.visibility_bundle(source, 0, 0, 0, 1, 1.0, 1.0)
  assert_eq(field(result, "status"), "blocked-known-terrain".to_json())
  assert_eq(num(at(result, "cells", 1), "line_entry_elevation_m"), 6.0)
  assert_eq(num(at(result, "cells", 1), "line_exit_elevation_m"), 11.0)
  assert_eq(num(at(result, "cells", 1), "minimum_clearance_m"), -4.0)
  let reverse = @terrain_import.visibility_bundle(source, 0, 1, 0, 0, 1.0, 1.0)
  assert_eq(field(reverse, "status"), field(result, "status"))
  assert_eq(
    num(field(reverse, "summary"), "whole_line_minimum_clearance_m"),
    -4.0,
  )
}

///|
test "visibility unknown cells withhold whole line clearance without erasing known obstruction" {
  let source = bundle(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 0 0",
  )
  let result = @terrain_import.visibility_bundle(source, 0, 0, 0, 3, 1.0, 1.0)
  assert_eq(field(result, "status"), "incomplete-coverage".to_json())
  assert_eq(field(result, "coverage_complete"), false.to_json())
  assert_eq(
    field(field(result, "summary"), "whole_line_minimum_clearance_m"),
    Json::null(),
  )
  assert_eq(num(field(result, "summary"), "known_minimum_clearance_m"), 1.0)
  assert_eq(field(at(result, "cells", 1), "minimum_clearance_m"), Json::null())
  let blocked = @terrain_import.visibility_bundle(
    bundle("ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 5 0"),
    0,
    0,
    0,
    3,
    1.0,
    1.0,
  )
  assert_eq(field(blocked, "status"), "blocked-known-terrain".to_json())
  assert_eq(field(blocked, "coverage_complete"), false.to_json())
  let off_line = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 10 0 0 -9999 -9999",
  )
  assert_eq(
    field(
      @terrain_import.visibility_bundle(off_line, 0, 0, 0, 1, 1.0, 1.0),
      "status",
    ),
    "clear-in-model".to_json(),
  )
}

///|
test "visibility exact diagonal corner contacts cannot skip high or unknown adjacent cells" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 10 0 5 -9999 0",
  )
  let result = @terrain_import.visibility_bundle(source, 0, 0, 1, 1, 1.0, 1.0)
  let summary = field(result, "summary")
  assert_eq(num(summary, "intersected_cells"), 4.0)
  assert_eq(num(summary, "corner_contacts"), 2.0)
  assert_eq(num(summary, "blocked_cells"), 1.0)
  assert_eq(num(summary, "unknown_cells"), 1.0)
  assert_eq(field(result, "status"), "blocked-known-terrain".to_json())
  assert_eq(field(at(result, "cells", 1), "contact"), "corner".to_json())
  assert_eq(num(at(result, "cells", 1), "entry_fraction"), 0.5)
  assert_eq(num(at(result, "cells", 1), "exit_fraction"), 0.5)
  let reverse = @terrain_import.visibility_bundle(source, 1, 1, 0, 0, 1.0, 1.0)
  assert_eq(field(reverse, "summary"), summary)
}

///|
test "visibility oblique line exact clipping and transposed source axes" {
  let source = bundle(
    "ncols 4 nrows 3 xllcenter 0 yllcenter 0 cellsize 10 " +
    Array::make(12, "0").join(" "),
  )
  let result = @terrain_import.visibility_bundle(source, 0, 0, 2, 3, 2.0, 2.0)
  let expected = [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2), (2, 3)]
  assert_eq(num(field(result, "summary"), "intersected_cells"), 6.0)
  assert_eq(num(field(result, "summary"), "corner_contacts"), 0.0)
  for i, (r, c) in expected {
    assert_eq(num(at(result, "cells", i), "row"), r.to_double())
    assert_eq(num(at(result, "cells", i), "col"), c.to_double())
  }
  assert_eq(num(at(result, "cells", 1), "entry_fraction"), 1.0 / 6.0)
  assert_eq(num(at(result, "cells", 1), "exit_fraction"), 0.25)
  assert_true(
    (num(field(result, "summary"), "horizontal_distance_m") - 36.05551275463989).abs() <
    1.0e-10,
  )
  let vertical = @terrain_import.visibility_bundle(source, 2, 1, 0, 1, 2.0, 2.0)
  assert_eq(num(at(vertical, "cells", 0), "row"), 2.0)
  assert_eq(num(at(vertical, "cells", 2), "row"), 0.0)
  assert_eq(num(field(vertical, "target"), "y_m"), 20.0)
}

///|
test "visibility works on source revisions and joined mosaics with retained provenance" {
  let left = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0")
  let right = bundle("ncols 2 nrows 1 xllcenter 20 yllcenter 0 cellsize 10 5 0")
  let joined = @terrain_import.mosaic_bundle(
    left, right, "joined", "Synthetic clips",
  )
  let initial = @terrain_import.visibility_bundle(
    joined.stringify(),
    0,
    0,
    0,
    3,
    1.0,
    1.0,
  )
  assert_eq(field(initial, "status"), "blocked-known-terrain".to_json())
  let revised = @terrain_import.revise_bundle(
    joined.stringify(),
    "row,col,expected_elevation_m,elevation_m\n0,2,5,unknown\n",
    "Withheld synthetic ridge",
  )
  let changed = @terrain_import.visibility_bundle(
    revised.stringify(),
    0,
    0,
    0,
    3,
    1.0,
    1.0,
  )
  assert_eq(field(changed, "status"), "incomplete-coverage".to_json())
  assert_eq(field(changed, "source_bundle"), revised)
  assert_true(
    field(initial, "source_bundle_digest") !=
    field(changed, "source_bundle_digest"),
  )
  assert_eq(field(initial, "source_bundle"), joined)
}

///|
test "visibility rejects unsafe geometry unknown endpoints degree units and changed source" {
  let text = "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 0"
  let source = bundle(text)
  for
    (r, c, tr, tc, h, th) in [
      (0, 0, 0, 0, 1.0, 1.0),
      (-1, 0, 0, 2, 1.0, 1.0),
      (0, 0, 0, 3, 1.0, 1.0),
      (0, 0, 0, 1, 1.0, 1.0),
      (0, 1, 0, 2, 1.0, 1.0),
      (0, 0, 0, 2, -1.0, 1.0),
      (0, 0, 0, 2, 1.0, -1.0),
      (0, 0, 0, 2, 1.0 / 0.0, 1.0),
      (0, 0, 0, 2, 1.0, 0.0 / 0.0),
    ] {
    sight_rejected(() => {
      @terrain_import.visibility_bundle(source, r, c, tr, tc, h, th)
    })
  }
  sight_rejected(() => {
    @terrain_import.visibility_bundle(
      bundle(text, unit="degrees"),
      0,
      0,
      0,
      2,
      1.0,
      1.0,
    )
  })
  sight_rejected(() => {
    @terrain_import.visibility_bundle(
      source.replace(old="\"sample_count\":2", new="\"sample_count\":3"),
      0,
      0,
      0,
      2,
      1.0,
      1.0,
    )
  })
  let extreme = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 -1e308 1e308",
  )
  sight_rejected(() => {
    @terrain_import.visibility_bundle(extreme, 0, 0, 0, 1, 1.0, 1.0)
  })
}

///|
test "visibility maximum grid includes every diagonal corner without unbounded expansion" {
  let text = "ncols 64 nrows 64 xllcenter 0 yllcenter 0 cellsize 1 " +
    Array::make(4096, "0").join(" ")
  let result = @terrain_import.visibility_bundle(
    bundle(text),
    0,
    0,
    63,
    63,
    1.0,
    1.0,
  )
  assert_eq(num(field(result, "summary"), "intersected_cells"), 190.0)
  assert_eq(num(field(result, "summary"), "corner_contacts"), 126.0)
  assert_eq(field(result, "status"), "clear-in-model".to_json())
}

///|
test "visibility preserves endpoint elevations across unequal numeric magnitudes" {
  let source = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 1e20 10",
  )
  let result = @terrain_import.visibility_bundle(source, 0, 0, 0, 1, 0.0, 1.0)
  assert_eq(num(at(result, "cells", 1), "line_exit_elevation_m"), 11.0)
  assert_eq(num(at(result, "cells", 1), "minimum_clearance_m"), 1.0)
  let reverse = @terrain_import.visibility_bundle(source, 0, 1, 0, 0, 1.0, 0.0)
  assert_eq(num(at(reverse, "cells", 0), "line_entry_elevation_m"), 11.0)
}
