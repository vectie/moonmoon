///|
fn field(value : Json, name : String) -> Json {
  guard value is Object(fields) && fields.get(name) is Some(result) else {
    abort(name)
  }
  result
}

///|
fn num(value : Json, name : String) -> Double {
  guard field(value, name) is Number(n, ..) else { abort(name) }
  n
}

///|
fn at(value : Json, name : String, index : Int) -> Json {
  guard field(value, name) is Array(values) else { abort(name) }
  values[index]
}

///|
fn bundle(text : String, unit? : String = "m") -> String raise {
  @terrain_import.import_bundle(
    text, "analysis-test", "Synthetic Cartesian frame", unit, "Synthetic test; not observed terrain",
  ).stringify()
}

///|
let plane = "ncols 3 nrows 3 xllcenter 0 yllcenter 0 cellsize 10\n40 50 60\n20 30 40\n0 10 20\n"

///|
test "3x3 plane produces analytical slope zero residual and explicit unknown borders" {
  let source = bundle(plane)
  let analysis = @terrain_import.analyze_bundle(source, "row", 1, 60.0)
  let center = at(analysis, "cells", 4)
  assert_true((num(center, "slope_deg") - 65.9051574478893).abs() < 1.0e-10)
  assert_true(num(center, "roughness_rms_m").abs() < 1.0e-12)
  assert_eq(field(center, "slope_screening"), "threshold-exceeded".to_json())
  assert_eq(
    field(at(analysis, "cells", 0), "estimate_status"),
    "boundary".to_json(),
  )
  assert_eq(field(at(analysis, "cells", 0), "slope_deg"), Json::null())
  assert_eq(num(field(analysis, "grid_summary"), "unknown_cells"), 8.0)
  assert_eq(num(field(analysis, "profile_summary"), "observed_ascent_m"), 20.0)
  assert_eq(num(at(analysis, "profile", 1), "grade_percent"), 100.0)
  assert_eq(num(at(analysis, "profile", 1), "grade_deg"), 45.0)
  assert_eq(analysis, @terrain_import.analyze_bundle(source, "row", 1, 60.0))
  let revised = @terrain_import.analyze_bundle(source, "row", 1, 70.0)
  assert_true(
    field(analysis, "analysis_digest") != field(revised, "analysis_digest"),
  )
  assert_eq(
    field(at(revised, "cells", 4), "slope_screening"),
    "within-threshold".to_json(),
  )
}

///|
test "profile follows source row order and never joins across a nodata gap" {
  let source = bundle(
    "ncols 5 nrows 1 xllcorner 100 yllcorner -10 cellsize 20\n5 8 -9999 1 0",
  )
  let result = @terrain_import.analyze_bundle(source, "row", 0, 12.0)
  let summary = field(result, "profile_summary")
  assert_eq(num(summary, "observed_ascent_m"), 3.0)
  assert_eq(num(summary, "observed_descent_m"), 1.0)
  assert_eq(num(summary, "measured_segment_distance_m"), 40.0)
  assert_eq(num(summary, "unknown_segments"), 2.0)
  assert_eq(num(summary, "horizontal_span_m"), 80.0)
  assert_eq(field(summary, "complete_elevation_coverage"), false.to_json())
  assert_eq(field(at(result, "profile", 3), "grade_percent"), Json::null())
  assert_eq(
    field(at(result, "cells", 2), "estimate_status"),
    "nodata".to_json(),
  )
  let column = @terrain_import.analyze_bundle(bundle(plane), "column", 1, 20.0)
  assert_eq(num(at(column, "profile", 0), "y_m"), 20.0)
  assert_eq(num(at(column, "profile", 2), "y_m"), 0.0)
  assert_eq(num(field(column, "profile_summary"), "observed_descent_m"), 40.0)
  assert_eq(num(at(column, "profile", 1), "grade_percent"), -200.0)
}

///|
test "curved roughness missing neighborhoods flat equality and all missing are distinguishable" {
  let bump = bundle(
    "ncols 3 nrows 3 xllcenter 0 yllcenter 0 cellsize 10\n0 0 0 0 9 0 0 0 0",
  )
  let result = @terrain_import.analyze_bundle(bump, "row", 1, 0.0)
  let center = at(result, "cells", 4)
  assert_eq(num(center, "slope_deg"), 0.0)
  assert_true(
    (num(center, "roughness_rms_m") - 2.82842712474619).abs() < 1.0e-12,
  )
  assert_eq(field(center, "slope_screening"), "within-threshold".to_json())
  let missing = @terrain_import.analyze_bundle(
    bundle(plane.replace(old="40 50", new="-9999 50")),
    "row",
    1,
    20.0,
  )
  assert_eq(
    field(at(missing, "cells", 4), "estimate_status"),
    "unknown-neighborhood".to_json(),
  )
  let empty = @terrain_import.analyze_bundle(
    bundle("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 -9999"),
    "row",
    0,
    20.0,
  )
  assert_eq(num(field(empty, "profile_summary"), "known_samples"), 0.0)
  assert_eq(num(field(empty, "profile_summary"), "known_segments"), 0.0)
  assert_eq(field(empty, "physical_readiness"), false.to_json())
}

///|
test "analysis rejects degrees changed source invalid selection and numeric overflow" {
  assert_true(
    @terrain_import.analysis_json(bundle(plane, unit="degrees"), "row", 0, 20.0).contains(
      "\"ok\":false",
    ),
  )
  for
    (axis, index, threshold) in [
      ("line", 0, 20.0),
      ("row", -1, 20.0),
      ("column", 3, 20.0),
      ("row", 0, 90.0),
      ("row", 0, -1.0),
    ] {
    assert_true(
      @terrain_import.analysis_json(bundle(plane), axis, index, threshold).contains(
        "\"ok\":false",
      ),
    )
  }
  assert_true(
    @terrain_import.analysis_json(
      bundle(plane).replace(old="\"sample_count\":9", new="\"sample_count\":8"),
      "row",
      0,
      20.0,
    ).contains("\"ok\":false"),
  )
  assert_true(
    @terrain_import.analysis_json(
      bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 1e308 -1e308"),
      "row",
      0,
      20.0,
    ).contains("\"ok\":false"),
  )
}
