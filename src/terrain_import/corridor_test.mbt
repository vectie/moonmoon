///|
fn corridor_source(kind : String) -> String raise {
  let values : Array[String] = []
  for row in 0..<9 {
    for col in 0..<9 {
      values.push(
        if kind == "plane" {
          col.to_string()
        } else if row == 2 && col == 4 && kind == "bump" {
          "9"
        } else if row == 2 && col == 4 && kind == "gap" {
          "-9999"
        } else {
          "0"
        },
      )
    }
  }
  bundle(
    "ncols 9 nrows 9 xllcenter 0 yllcenter 0 cellsize 1 " + values.join(" "),
  )
}

///|
test "corridor unions overlapping square windows and retains repeat occurrences" {
  let source = corridor_source("flat")
  let path = "row,col\r\n4,3\r\n4,4\r\n4,4\r\n4,3\r\n"
  let result = @terrain_import.assess_corridor_bundle(source, path, 1, 0.0, 0.0)
  let summary = field(result, "summary")
  assert_eq(num(summary, "in_grid_cell_count"), 12.0)
  assert_eq(num(summary, "outside_grid_cell_count"), 0.0)
  assert_eq(num(summary, "estimated_shape_count"), 12.0)
  assert_eq(field(summary, "shape_coverage_complete"), true.to_json())
  assert_eq(field(result, "status"), "within-thresholds".to_json())
  assert_eq(field(result, "input_path_text"), path.to_json())
  assert_eq(field(result, "path_cells_text"), "4,3\n4,4\n4,4\n4,3\n".to_json())
  assert_eq(num(at(result, "stops", 3), "step"), 3.0)
  assert_eq(
    num(field(at(result, "stops", 3), "summary"), "in_grid_cell_count"),
    9.0,
  )
  assert_eq(num(at(result, "cells", 0), "row"), 3.0)
  assert_eq(num(at(result, "cells", 0), "col"), 2.0)
  assert_eq(field(result, "physical_readiness"), false.to_json())
  assert_eq(
    result,
    @terrain_import.assess_corridor_bundle(source, path, 1, 0.0, 0.0),
  )
}

///|
test "corridor surface slope is distinct from centerline grade and equality meets limit" {
  let source = corridor_source("plane")
  let path = "3,4\n4,4\n5,4"
  let assessment = @terrain_import.assess_path_bundle(source, path, 1.0, 0.0)
  assert_eq(field(assessment, "status"), "within-grade-cap".to_json())
  let result = @terrain_import.assess_corridor_bundle(
    source, path, 1, 40.0, 0.0000000001,
  )
  let summary = field(result, "summary")
  assert_eq(num(summary, "slope_exceeded_count"), 15.0)
  assert_eq(num(summary, "roughness_exceeded_count"), 0.0)
  assert_true((num(summary, "max_observed_slope_deg") - 45.0).abs() < 1.0e-10)
  let equality = @terrain_import.assess_corridor_bundle(
    source, path, 1, 45.0, 0.0000000001,
  )
  assert_eq(field(equality, "status"), "within-thresholds".to_json())
}

///|
test "widening corridor discovers off-centerline roughness and preserves previous result" {
  let source = corridor_source("bump")
  let path = "4,3\n4,4\n4,5"
  let narrow = @terrain_import.assess_corridor_bundle(
    source, path, 0, 89.0, 0.1,
  )
  let wide = @terrain_import.assess_corridor_bundle(source, path, 1, 89.0, 0.1)
  assert_eq(field(narrow, "status"), "within-thresholds".to_json())
  assert_eq(field(wide, "status"), "threshold-exceeded".to_json())
  assert_eq(num(field(wide, "summary"), "roughness_exceeded_count"), 3.0)
  assert_eq(num(field(narrow, "summary"), "in_grid_cell_count"), 3.0)
  assert_true(
    field(narrow, "corridor_digest") != field(wide, "corridor_digest"),
  )
}

///|
test "corridor distinguishes elevation and neighborhood coverage including outside band context" {
  let source = corridor_source("gap")
  let path = "4,3\n4,4\n4,5"
  let wide = @terrain_import.assess_corridor_bundle(
    source, path, 1, 89.0, 100.0,
  )
  let summary = field(wide, "summary")
  assert_eq(num(summary, "unknown_elevation_count"), 0.0)
  assert_eq(num(summary, "unknown_shape_count"), 3.0)
  assert_eq(field(summary, "elevation_coverage_complete"), true.to_json())
  assert_eq(field(summary, "shape_coverage_complete"), false.to_json())
  assert_eq(field(wide, "status"), "incomplete-coverage".to_json())
  let wider = @terrain_import.assess_corridor_bundle(
    source, path, 2, 89.0, 100.0,
  )
  assert_eq(num(field(wider, "summary"), "unknown_elevation_count"), 1.0)
  assert_eq(
    field(field(wider, "summary"), "elevation_coverage_complete"),
    false.to_json(),
  )
}

///|
test "outside-grid union is not silently clipped or double counted" {
  let source = corridor_source("flat")
  let result = @terrain_import.assess_corridor_bundle(
    source, "0,0\n0,0\n0,1", 1, 10.0, 1.0,
  )
  let summary = field(result, "summary")
  assert_eq(num(summary, "in_grid_cell_count"), 6.0)
  assert_eq(num(summary, "outside_grid_cell_count"), 6.0)
  assert_eq(
    num(field(at(result, "stops", 0), "summary"), "outside_grid_cell_count"),
    5.0,
  )
  assert_eq(
    num(field(at(result, "stops", 1), "summary"), "outside_grid_cell_count"),
    5.0,
  )
  assert_eq(
    num(field(at(result, "stops", 2), "summary"), "outside_grid_cell_count"),
    3.0,
  )
  assert_eq(field(result, "status"), "incomplete-coverage".to_json())
  let tiny = bundle("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0")
  let single = @terrain_import.assess_corridor_bundle(tiny, "0,0", 0, 10.0, 1.0)
  assert_eq(
    field(field(single, "summary"), "max_observed_slope_deg"),
    Json::null(),
  )
  let max_radius = @terrain_import.assess_corridor_bundle(
    tiny, "0,0", 8, 10.0, 1.0,
  )
  assert_eq(num(field(max_radius, "summary"), "outside_grid_cell_count"), 288.0)
}

///|
test "corridor rejects invalid path parameters units and tampered sources" {
  let source = corridor_source("flat")
  for path in ["", "1,1\n1,3", "1,1\n2,2", "9,1", "row,col\nrow,col"] {
    assert_true(
      (try? @terrain_import.assess_corridor_bundle(source, path, 1, 15.0, 1.0))
      is Err(_),
    )
  }
  for
    (radius, slope, roughness) in [
      (-1, 10.0, 1.0),
      (9, 10.0, 1.0),
      (0, 90.0, 1.0),
      (0, -1.0, 1.0),
      (0, 10.0, -1.0),
      (0, 1.0 / 0.0, 1.0),
      (0, 10.0, 0.0 / 0.0),
    ] {
    assert_true(
      (try? @terrain_import.assess_corridor_bundle(
        source, "4,4", radius, slope, roughness,
      ))
      is Err(_),
    )
  }
  let degrees = @terrain_import.import_bundle(
    "ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0", "sample", "Synthetic",
    "degrees", "Synthetic",
  ).stringify()
  assert_true(
    (try? @terrain_import.assess_corridor_bundle(degrees, "0,0", 1, 15.0, 1.0))
    is Err(_),
  )
  assert_true(
    (try? @terrain_import.assess_corridor_bundle(
      source.replace_all(old="sha256:", new="altered:"),
      "4,4",
      1,
      15.0,
      1.0,
    ))
    is Err(_),
  )
  let huge = bundle("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e308 0")
  assert_true(
    (try? @terrain_import.assess_corridor_bundle(huge, "0,0", 8, 15.0, 1.0))
    is Err(_),
  )
}

///|
test "corridor reopens revisions and carries known exceedances alongside missing coverage" {
  let source = corridor_source("bump")
  let revised = @terrain_import.revise_bundle(
    source, "row,col,expected_elevation_m,elevation_m\n3,2,0,unknown\n", "Synthetic missing survey cell",
  ).stringify()
  let result = @terrain_import.assess_corridor_bundle(
    revised, "4,3\n4,4\n4,5", 1, 89.0, 0.1,
  )
  let summary = field(result, "summary")
  assert_eq(field(result, "status"), "threshold-exceeded".to_json())
  assert_eq(field(summary, "shape_coverage_complete"), false.to_json())
  assert_eq(num(summary, "unknown_elevation_count"), 1.0)
  assert_true(num(summary, "roughness_exceeded_count") > 0.0)
  assert_eq(
    field(result, "source_bundle"),
    @terrain_import.reopen_bundle(revised),
  )
}
