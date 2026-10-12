///|
test "area differences classify every cell and retain signed square-cell volume" {
  let a = bundle(
    "ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 1 2 3 4 5 6",
  )
  let b = bundle(
    "ncols 3 nrows 2 xllcenter 0 yllcenter 0 cellsize 2 4 0 3 5 4 6",
  )
  let result = @terrain_import.compare_area_bundle(a, b, 1.0)
  let counts = field(result, "counts")
  assert_eq(num(counts, "total_cells"), 6.0)
  assert_eq(num(counts, "changed_known_cells"), 4.0)
  assert_eq(num(counts, "rise_exceeds_threshold_cells"), 1.0)
  assert_eq(num(counts, "fall_exceeds_threshold_cells"), 1.0)
  assert_eq(num(counts, "within_threshold_cells"), 4.0)
  assert_eq(num(field(result, "areas_m2"), "total"), 24.0)
  let stats = field(result, "whole_grid_statistics")
  assert_eq(num(stats, "positive_volume_change_m3"), 16.0)
  assert_eq(num(stats, "negative_volume_change_m3"), -12.0)
  assert_eq(num(stats, "net_volume_change_m3"), 4.0)
  assert_true((num(stats, "mean_delta_m") - 1.0 / 6.0).abs() < 1.0e-14)
  assert_eq(num(stats, "minimum_delta_m"), -2.0)
  assert_eq(num(stats, "maximum_delta_m"), 3.0)
  assert_eq(field(result, "status"), "complete-comparison".to_json())
  assert_eq(field(result, "observed_statistics"), stats)
  assert_eq(num(at(result, "cells", 0), "x_m"), 0.0)
  assert_eq(num(at(result, "cells", 0), "y_m"), 2.0)
  assert_eq(num(at(result, "cells", 5), "x_m"), 4.0)
  assert_eq(num(at(result, "cells", 5), "y_m"), 0.0)
  assert_eq(num(at(result, "cells", 1), "signed_volume_change_m3"), -8.0)
  assert_eq(result, @terrain_import.compare_area_bundle(a, b, 1.0))
}

///|
test "area threshold equality affects classes only not numeric volumes" {
  let a = bundle("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 2 0 0 0")
  let b = bundle("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 2 1 -1 0")
  let low = @terrain_import.compare_area_bundle(a, b, 0.0)
  let high = @terrain_import.compare_area_bundle(a, b, 1.0)
  assert_eq(num(field(low, "counts"), "rise_exceeds_threshold_cells"), 1.0)
  assert_eq(num(field(low, "counts"), "fall_exceeds_threshold_cells"), 1.0)
  assert_eq(num(field(high, "counts"), "within_threshold_cells"), 3.0)
  assert_eq(
    field(low, "whole_grid_statistics"),
    field(high, "whole_grid_statistics"),
  )
  assert_true(
    field(low, "comparison_digest") != field(high, "comparison_digest"),
  )
  let reverse = @terrain_import.compare_area_bundle(b, a, 0.0)
  assert_eq(num(at(reverse, "cells", 0), "elevation_delta_m"), -1.0)
  assert_eq(num(at(reverse, "cells", 1), "elevation_delta_m"), 1.0)
}

///|
test "area coverage transitions never manufacture differences or whole-grid totals" {
  let a = bundle(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 1 -9999 -9999 0",
  )
  let b = bundle(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 -9999 9 -9999 2",
  )
  let result = @terrain_import.compare_area_bundle(a, b, 0.0)
  assert_eq(field(result, "status"), "incomplete-comparison".to_json())
  assert_eq(field(result, "whole_grid_statistics"), Json::null())
  assert_eq(
    num(field(result, "observed_statistics"), "net_volume_change_m3"),
    200.0,
  )
  for
    (i, label) in [
      (0, "coverage-lost"),
      (1, "coverage-gained"),
      (2, "unknown-both"),
    ] {
    let cell = at(result, "cells", i)
    assert_eq(field(cell, "coverage_change"), label.to_json())
    assert_eq(field(cell, "elevation_delta_m"), Json::null())
    assert_eq(field(cell, "signed_volume_change_m3"), Json::null())
  }
  for
    key in [
      "known_both_cells", "coverage_gained_cells", "coverage_lost_cells", "unknown_both_cells",
    ] {
    assert_eq(num(field(result, "counts"), key), 1.0)
  }
  for key in ["known_both", "coverage_gained", "coverage_lost", "unknown_both"] {
    assert_eq(num(field(result, "areas_m2"), key), 100.0)
  }
}

///|
test "area no shared observations is explicit and does not report zero change" {
  let a = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 2 1 -9999")
  let b = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 2 -9999 1")
  let result = @terrain_import.compare_area_bundle(a, b, 1.0)
  assert_eq(field(result, "status"), "no-shared-elevation-coverage".to_json())
  assert_eq(field(result, "observed_statistics"), Json::null())
  assert_eq(field(result, "whole_grid_statistics"), Json::null())
  assert_eq(num(field(result, "areas_m2"), "known_both"), 0.0)
}

///|
test "area same source zeros are known and corner center alignment is exact" {
  let a = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 2 -4 5")
  let b = bundle("ncols 2 nrows 1 xllcorner -1 yllcorner -1 cellsize 2 -4 5")
  let result = @terrain_import.compare_area_bundle(a, b, 0.0)
  assert_eq(
    num(field(result, "whole_grid_statistics"), "net_volume_change_m3"),
    0.0,
  )
  assert_eq(num(field(result, "counts"), "changed_known_cells"), 0.0)
  assert_eq(field(result, "coverage_complete"), true.to_json())
}

///|
test "area refuses frame units grid and threshold incompatibility" {
  let text = "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1"
  let a = bundle(text)
  for
    b in [
      @terrain_import.import_bundle(
        text, "other", "Another frame", "m", "Synthetic",
      ).stringify(),
      bundle(text, unit="degrees"),
      bundle("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1 2"),
      bundle("ncols 2 nrows 1 xllcenter 1 yllcenter 0 cellsize 10 0 1"),
      bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 20 0 1"),
    ] {
    assert_true((try? @terrain_import.compare_area_bundle(a, b, 0.0)) is Err(_))
  }
  for threshold in [-1.0, 1.0 / 0.0, 0.0 / 0.0] {
    assert_true(
      (try? @terrain_import.compare_area_bundle(a, a, threshold)) is Err(_),
    )
  }
}

///|
test "area reopens revised sources and rejects tampered input before calculation" {
  let a = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1")
  let b = @terrain_import.revise_bundle(
    a, "row,col,expected_elevation_m,elevation_m\n0,1,1,3\n", "Synthetic revision",
  ).stringify()
  let result = @terrain_import.compare_area_bundle(a, b, 0.0)
  assert_eq(
    num(field(result, "whole_grid_statistics"), "net_volume_change_m3"),
    200.0,
  )
  let modified = @json.parse(b)
  guard modified is Object(fields) else { fail("Expected source") }
  fields["source_note"] = "Tampered".to_json()
  assert_true(
    (try? @terrain_import.compare_area_bundle(a, modified.stringify(), 0.0))
    is Err(_),
  )
}

///|
test "area rejects nonfinite deltas volumes totals and unrepresentable cell areas" {
  for
    (text_a, text_b) in [
      (
        "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 -1e308", "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 1e308",
      ),
      (
        "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0", "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 1e308",
      ),
      (
        "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 0", "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 1e308 1e308",
      ),
      (
        "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e200 0", "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e200 0",
      ),
      (
        "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e-200 0", "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e-200 0",
      ),
      (
        "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e-100 0", "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e-100 1e-200",
      ),
    ] {
    let a = bundle(text_a)
    let b = bundle(text_b)
    assert_true((try? @terrain_import.compare_area_bundle(a, b, 0.0)) is Err(_))
  }
}

///|
test "area map and CSV retain coverage blanks and exclude metadata markup" {
  let text = "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 -9999 0"
  let a = @terrain_import.import_bundle(
    text, "sample", "<script>alert(1)</script>", "m", "Synthetic",
  ).stringify()
  let b = @terrain_import.revise_bundle(
    a, "row,col,expected_elevation_m,elevation_m\n0,0,0,2\n0,1,unknown,3\n0,2,0,unknown\n",
    "Synthetic",
  ).stringify()
  let result = @terrain_import.compare_area_bundle(a, b, 1.0)
  guard field(result, "change_map_svg") is String(svg) &&
    field(result, "changes_csv") is String(csv) else {
    fail("Missing outputs")
  }
  assert_true(!svg.contains("<script>"))
  assert_true(svg.contains("coverage-gained"))
  assert_true(svg.contains("coverage-lost"))
  assert_true(csv.contains("0,1,1,0,,3,,coverage-gained,unknown,1,"))
  assert_true(csv.contains("0,2,2,0,0,,,coverage-lost,unknown,1,"))
  assert_eq(field(result, "physical_readiness"), false.to_json())
}
