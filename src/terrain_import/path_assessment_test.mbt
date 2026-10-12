///|
fn rejects_path(
  source : String,
  path : String,
  grade? : Double = 45.0,
  weight? : Double = 0.0,
) -> Bool {
  try {
    @terrain_import.assess_path_bundle(source, path, grade, weight) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
test "submitted ridge path is assessed exactly rather than replaced by gentler search" {
  let source = bundle(detour)
  let input = "row,col\n2,0\n2,1\n2,2\n2,3\n2,4\n2,5\n2,6\n"
  let result = @terrain_import.assess_path_bundle(source, input, 20.0, 4.0)
  assert_eq(field(result, "status"), "grade-exceeded".to_json())
  assert_eq(field(result, "coverage_complete"), true.to_json())
  assert_eq(field(result, "grade_screening"), "exceeded".to_json())
  assert_eq(num(field(result, "coverage"), "grade_exceeded_segment_count"), 2.0)
  let summary = field(result, "summary")
  assert_eq(num(summary, "horizontal_distance_m"), 60.0)
  assert_eq(num(summary, "ascent_m"), 15.0)
  assert_eq(num(summary, "descent_m"), 15.0)
  assert_eq(num(summary, "objective_cost_m"), 120.0)
  assert_eq(num(at(result, "path", 3), "col"), 3.0)
  assert_eq(num(at(result, "path", 3), "elevation_m"), 15.0)
  let optimized = @terrain_import.route_bundle(source, 2, 0, 2, 6, 20.0, 4.0)
  assert_eq(num(field(optimized, "summary"), "horizontal_distance_m"), 100.0)
  assert_eq(field(result, "input_path_text"), input.to_json())
  assert_eq(
    result,
    @terrain_import.assess_path_bundle(source, input, 20.0, 4.0),
  )
  assert_eq(field(result, "review_required"), true.to_json())
  assert_eq(field(result, "physical_readiness"), false.to_json())
}

///|
test "path assessment directly reuses route exports with matching complete accounting" {
  let source = bundle(detour)
  for (cap, weight) in [(20.0, 0.0), (60.0, 4.0), (60.0, 0.0)] {
    let route = @terrain_import.route_bundle(source, 2, 0, 2, 6, cap, weight)
    guard field(route, "path_cells_text") is String(path) else {
      fail("Missing path")
    }
    let assessment = @terrain_import.assess_path_bundle(
      source, path, cap, weight,
    )
    for
      key in [
        "horizontal_distance_m", "piecewise_3d_distance_m", "ascent_m", "descent_m",
        "max_absolute_grade_deg", "objective_cost_m",
      ] {
      assert_eq(
        field(field(assessment, "summary"), key),
        field(field(route, "summary"), key),
      )
    }
    assert_eq(field(assessment, "status"), "within-grade-cap".to_json())
    assert_eq(field(assessment, "path_cells_text"), path.to_json())
  }
}

///|
test "path grade equality directional cost and source center orientation are explicit" {
  let source = bundle(
    "ncols 2 nrows 2 xllcorner -20 yllcorner -30 cellsize 10 0 10 0 0",
  )
  let up = @terrain_import.assess_path_bundle(source, "0,0\n0,1", 45.0, 2.0)
  let down = @terrain_import.assess_path_bundle(source, "0,1\n0,0", 45.0, 2.0)
  assert_eq(field(up, "grade_screening"), "within-threshold".to_json())
  assert_eq(num(field(up, "summary"), "objective_cost_m"), 30.0)
  assert_eq(num(field(down, "summary"), "objective_cost_m"), 10.0)
  assert_eq(num(at(up, "path", 1), "grade_deg"), 45.0)
  assert_eq(num(at(down, "path", 1), "grade_deg"), -45.0)
  assert_eq(num(at(up, "path", 0), "x_m"), -15.0)
  assert_eq(num(at(up, "path", 0), "y_m"), -15.0)
  let exceeded = @terrain_import.assess_path_bundle(
    source, "0,0\n0,1", 44.9999, 0.0,
  )
  assert_eq(field(exceeded, "status"), "grade-exceeded".to_json())
}

///|
test "unknown incident segments stay unknown while later known segments are separately measured" {
  let source = bundle(
    "ncols 5 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 -9999 0 10",
  )
  let result = @terrain_import.assess_path_bundle(
    source, "0,0\n0,1\n0,2\n0,3\n0,4", 20.0, 2.0,
  )
  assert_eq(field(result, "status"), "incomplete-coverage".to_json())
  assert_eq(field(result, "summary"), Json::null())
  assert_eq(field(result, "grade_screening"), "exceeded".to_json())
  assert_eq(num(field(result, "coverage"), "unknown_point_count"), 1.0)
  assert_eq(num(field(result, "coverage"), "unknown_segment_count"), 2.0)
  assert_eq(num(field(result, "coverage"), "known_segment_count"), 2.0)
  assert_eq(num(field(result, "coverage"), "geometric_path_distance_m"), 40.0)
  assert_eq(
    num(field(result, "observed_segments_summary"), "horizontal_distance_m"),
    20.0,
  )
  assert_eq(
    num(field(result, "observed_segments_summary"), "objective_cost_m"),
    40.0,
  )
  for step in [2, 3] {
    assert_eq(field(at(result, "path", step), "grade_deg"), Json::null())
    assert_eq(field(at(result, "path", step), "rise_m"), Json::null())
    assert_eq(
      field(at(result, "path", step), "segment_3d_distance_m"),
      Json::null(),
    )
    assert_eq(
      field(at(result, "path", step), "segment_status"),
      "unknown-elevation".to_json(),
    )
  }
  assert_eq(
    field(at(result, "path", 4), "segment_status"),
    "grade-exceeded".to_json(),
  )
  assert_eq(num(at(result, "path", 4), "path_distance_m"), 40.0)
  let unknown_screen = @terrain_import.assess_path_bundle(
    source, "0,0\n0,1\n0,2\n0,3\n0,4", 60.0, 0.0,
  )
  assert_eq(field(unknown_screen, "grade_screening"), "unknown".to_json())
}

///|
test "stationary repeats and return visits retain order with no invented grade or travel" {
  let source = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10",
  )
  let input = "\r\n row,col\r\n 0,0 \r\n0,0\r\n\r\n0,1\r\n0,0\r\n"
  let result = @terrain_import.assess_path_bundle(source, input, 45.0, 1.0)
  assert_eq(field(result, "input_path_text"), input.to_json())
  assert_eq(field(result, "path_cells_text"), "0,0\n0,0\n0,1\n0,0\n".to_json())
  assert_eq(num(field(result, "coverage"), "point_count"), 4.0)
  assert_eq(num(field(result, "coverage"), "stationary_segment_count"), 1.0)
  assert_eq(num(field(result, "summary"), "horizontal_distance_m"), 20.0)
  assert_eq(num(field(result, "summary"), "objective_cost_m"), 30.0)
  assert_eq(
    field(at(result, "path", 1), "segment_status"),
    "stationary".to_json(),
  )
  assert_eq(field(at(result, "path", 1), "grade_deg"), Json::null())
  assert_eq(num(at(result, "path", 1), "segment_3d_distance_m"), 0.0)
}

///|
test "single known and unknown cells plus repeated unknowns have honest empty movement totals" {
  let source = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999",
  )
  let known = @terrain_import.assess_path_bundle(source, "0,0", 0.0, 0.0)
  assert_eq(num(field(known, "summary"), "horizontal_distance_m"), 0.0)
  assert_eq(
    field(field(known, "summary"), "max_absolute_grade_deg"),
    Json::null(),
  )
  assert_eq(
    field(at(known, "path", 0), "segment_horizontal_distance_m"),
    Json::null(),
  )
  for input in ["0,1", "0,1\n0,1\n0,1"] {
    let unknown = @terrain_import.assess_path_bundle(source, input, 0.0, 0.0)
    assert_eq(field(unknown, "summary"), Json::null())
    assert_eq(field(unknown, "grade_screening"), "unknown".to_json())
    assert_eq(
      field(
        field(unknown, "observed_segments_summary"),
        "max_absolute_grade_deg",
      ),
      Json::null(),
    )
    assert_eq(num(field(unknown, "coverage"), "geometric_path_distance_m"), 0.0)
  }
}

///|
test "source revisions reassess identical submitted cells without mutating either source" {
  let source = @terrain_import.reopen_bundle(
    bundle("ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 0"),
  )
  let original_bytes = source.stringify()
  let changed = @terrain_import.revise_bundle(
    original_bytes, "row,col,expected_elevation_m,elevation_m\n0,1,0,20", "Synthetic declared ridge",
  )
  let masked = @terrain_import.revise_bundle(
    changed.stringify(),
    "row,col,expected_elevation_m,elevation_m\n0,1,20,unknown",
    "Withheld synthetic cell",
  )
  let path = "0,0\n0,1\n0,2\n"
  let a = @terrain_import.assess_path_bundle(original_bytes, path, 20.0, 0.0)
  let b = @terrain_import.assess_path_bundle(
    changed.stringify(),
    path,
    20.0,
    0.0,
  )
  let c = @terrain_import.assess_path_bundle(
    masked.stringify(),
    path,
    20.0,
    0.0,
  )
  assert_eq(field(a, "status"), "within-grade-cap".to_json())
  assert_eq(field(b, "status"), "grade-exceeded".to_json())
  assert_eq(field(c, "status"), "incomplete-coverage".to_json())
  assert_eq(field(c, "summary"), Json::null())
  for value in [a, b, c] {
    assert_eq(field(value, "input_path_text"), path.to_json())
    assert_eq(field(value, "path_cells_text"), path.to_json())
  }
  assert_true(field(a, "assessment_digest") != field(b, "assessment_digest"))
  assert_true(field(b, "assessment_digest") != field(c, "assessment_digest"))
  assert_eq(field(a, "source_bundle"), source)
  assert_eq(field(b, "source_bundle"), changed)
  assert_eq(field(c, "source_bundle"), masked)
  assert_eq(source.stringify(), original_bytes)
}

///|
test "path assessment consumes sparse XYZ sources and preserves missing endpoint" {
  let spec = "{\"contract_id\":\"moonmoon.xyz-grid.v1\",\"tile_id\":\"sample\",\"coordinate_frame\":\"local\",\"horizontal_unit\":\"m\",\"source_note\":\"Synthetic\",\"rows\":1,\"cols\":2,\"origin_x\":0,\"origin_y\":0,\"cell_size\":10}"
  let source = @terrain_import.import_xyz_bundle("x,y,elevation_m\n0,0,5", spec)
  let result = @terrain_import.assess_path_bundle(
    source.stringify(),
    "0,0\n0,1",
    45.0,
    0.0,
  )
  assert_eq(field(result, "summary"), Json::null())
  assert_eq(field(result, "source_bundle"), source)
  assert_eq(field(at(result, "path", 1), "elevation_m"), Json::null())
  assert_eq(num(field(result, "coverage"), "unknown_segment_count"), 1.0)
}

///|
test "nonadjacent diagonal malformed empty and out of grid paths are rejected" {
  let source = bundle(detour)
  for
    input in [
      "", "\n\r\n", "row,col\n", "row,col\nrow,col\n0,0", "0,0\n0,2", "0,0\n1,1",
      "0,6\n1,0", "0,0\n4,0", "row,column\n0,0", "0", "0,0,1", "\"0\",0", "0.0,0",
      "-1,0", "0,7", "5,0", "2147483648,0", "0,0\nrow,col",
    ] {
    assert_true(rejects_path(source, input))
  }
}

///|
test "path assessment rejects source tampering unsupported units and invalid parameters" {
  let source = bundle(detour)
  assert_true(
    rejects_path(
      source.replace(old="\"sample_count\":34", new="\"sample_count\":33"),
      "0,0\n0,1",
    ),
  )
  assert_true(rejects_path(bundle(detour, unit="degrees"), "0,0\n0,1"))
  for
    (grade, weight) in [
      (-1.0, 0.0),
      (90.0, 0.0),
      (0.0, -1.0),
      (1.0e308 * 2.0, 0.0),
      (0.0, 1.0e308 * 2.0),
      (1.0e308 * 2.0 - 1.0e308 * 2.0, 0.0),
    ] {
    assert_true(rejects_path(source, "0,0\n0,1", grade~, weight~))
  }
}

///|
test "path arithmetic overflow never becomes assessed distance grade or cost" {
  let extreme = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 -1e308 1e308",
  )
  assert_true(rejects_path(extreme, "0,0\n0,1"))
  let rise = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10")
  assert_true(rejects_path(rise, "0,0\n0,1", weight=1.0e308))
  let wide = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 8e307 0 0",
  )
  assert_true(rejects_path(wide, "0,0\n0,1\n0,0\n0,1"))
}

///|
test "path count and text bounds support maximum repeated route without increasing travel" {
  let source = bundle("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0")
  let maximum = Array::make(4096, "0,0").join("\n")
  let result = @terrain_import.assess_path_bundle(source, maximum, 0.0, 0.0)
  assert_eq(num(field(result, "coverage"), "point_count"), 4096.0)
  assert_eq(num(field(result, "summary"), "horizontal_distance_m"), 0.0)
  assert_true(rejects_path(source, maximum + "\n0,0"))
  let at_limit = "0,0" + Array::make(65533, " ").join("")
  assert_eq(
    num(
      field(
        @terrain_import.assess_path_bundle(source, at_limit, 0.0, 0.0),
        "coverage",
      ),
      "point_count",
    ),
    1.0,
  )
  assert_true(rejects_path(source, at_limit + " "))
}
