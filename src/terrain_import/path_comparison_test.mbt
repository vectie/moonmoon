///|
test "comparison reports signed changes and grade transitions without rerouting" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 0",
  )
  let candidate = @terrain_import.revise_bundle(
    source, "row,col,expected_elevation_m,elevation_m\n0,1,0,10\n", "Synthetic rise",
  ).stringify()
  let result = @terrain_import.compare_path_bundle(
    source, candidate, "0,0\n0,1\n0,2", 20.0, 2.0,
  )
  assert_eq(
    num(field(result, "counts"), "changed_known_point_occurrences"),
    1.0,
  )
  assert_eq(num(field(result, "counts"), "segment_status_transitions"), 2.0)
  assert_eq(num(at(result, "changes", 1), "elevation_delta_m"), 10.0)
  assert_eq(num(at(result, "changes", 1), "grade_delta_deg"), 45.0)
  assert_eq(num(at(result, "changes", 2), "grade_delta_deg"), -45.0)
  assert_eq(num(field(result, "summary_delta"), "ascent_m"), 10.0)
  assert_eq(num(field(result, "summary_delta"), "objective_cost_m"), 20.0)
  let reverse = @terrain_import.compare_path_bundle(
    candidate, source, "0,0\n0,1\n0,2", 20.0, 2.0,
  )
  assert_eq(num(field(reverse, "summary_delta"), "objective_cost_m"), -20.0)
  assert_eq(num(at(reverse, "changes", 1), "elevation_delta_m"), -10.0)
  assert_eq(
    result,
    @terrain_import.compare_path_bundle(
      source, candidate, "0,0\n0,1\n0,2", 20.0, 2.0,
    ),
  )
}

///|
test "coverage changes are distinct and incomplete totals never subtracted" {
  let source = bundle(
    "ncols 4 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 -9999 0",
  )
  let candidate = @terrain_import.revise_bundle(
    source, "row,col,expected_elevation_m,elevation_m\n0,0,0,unknown\n0,1,unknown,2\n",
    "Synthetic coverage swap",
  ).stringify()
  let result = @terrain_import.compare_path_bundle(
    source, candidate, "0,0\n0,1\n0,2\n0,3", 20.0, 0.0,
  )
  for
    (step, expected) in [
      (0, "coverage-lost"),
      (1, "coverage-gained"),
      (2, "unknown-both"),
      (3, "known-both"),
    ] {
    assert_eq(
      field(at(result, "changes", step), "coverage_change"),
      expected.to_json(),
    )
  }
  assert_eq(field(result, "summary_delta"), Json::null())
  assert_eq(field(at(result, "changes", 1), "elevation_delta_m"), Json::null())
  assert_eq(field(at(result, "changes", 1), "grade_delta_deg"), Json::null())
  assert_eq(
    num(field(result, "counts"), "coverage_gained_point_occurrences"),
    1.0,
  )
  assert_eq(
    num(field(result, "counts"), "coverage_lost_point_occurrences"),
    1.0,
  )
}

///|
test "identical sources retain stationary repeats and null undefined grade" {
  let source = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1")
  let path = "row,col\r\n0,0\r\n0,0\r\n0,1\r\n0,0\r\n"
  let result = @terrain_import.compare_path_bundle(
    source, source, path, 45.0, 1.0,
  )
  assert_eq(field(result, "input_path_text"), path.to_json())
  assert_eq(num(field(result, "counts"), "segment_status_transitions"), 0.0)
  assert_eq(num(field(result, "summary_delta"), "objective_cost_m"), 0.0)
  assert_eq(field(at(result, "changes", 1), "grade_delta_deg"), Json::null())
  assert_eq(num(at(result, "changes", 3), "path_distance_m"), 20.0)
  let single = @terrain_import.compare_path_bundle(
    source, source, "0,0", 45.0, 0.0,
  )
  assert_eq(
    field(field(single, "summary_delta"), "max_absolute_grade_deg"),
    Json::null(),
  )
}

///|
test "mismatched frames units dimensions centers and spacing are rejected" {
  let text = "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1"
  let source = bundle(text)
  for
    candidate in [
      @terrain_import.import_bundle(
        text, "sample", "Other frame", "m", "Synthetic",
      ).stringify(),
      @terrain_import.import_bundle(
        text, "sample", "Synthetic Cartesian frame", "degrees", "Synthetic",
      ).stringify(),
      bundle("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1 2"),
      bundle("ncols 2 nrows 1 xllcenter 1 yllcenter 0 cellsize 10 0 1"),
      bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 20 0 1"),
    ] {
    assert_true(
      (try? @terrain_import.compare_path_bundle(
        source, candidate, "0,0", 45.0, 0.0,
      ))
      is Err(_),
    )
  }
  // Corner and center declarations may describe exactly the same cells.
  let corner = bundle(
    "ncols 2 nrows 1 xllcorner -5 yllcorner -5 cellsize 10 0 1",
  )
  let result = @terrain_import.compare_path_bundle(
    source, corner, "0,0\n0,1", 45.0, 0.0,
  )
  assert_eq(num(field(result, "summary_delta"), "ascent_m"), 0.0)
}

///|
test "comparison inherits invalid path and parameter rejection" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 1 2",
  )
  for path in ["", "0,0\n0,2", "0,3", "bad"] {
    assert_true(
      (try? @terrain_import.compare_path_bundle(source, source, path, 45.0, 0.0))
      is Err(_),
    )
  }
  for (grade, weight) in [(90.0, 0.0), (-1.0, 0.0), (45.0, -1.0)] {
    assert_true(
      (try? @terrain_import.compare_path_bundle(
        source, source, "0,0", grade, weight,
      ))
      is Err(_),
    )
  }
}
