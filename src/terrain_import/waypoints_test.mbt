///|
fn rejects_waypoints(
  source : String,
  csv : String,
  grade : Double,
  weight : Double,
) -> Bool {
  try {
    @terrain_import.route_waypoints_bundle(source, csv, grade, weight) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
test "ordered waypoints retain reversals and remove only shared junctions" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 0",
  )
  let csv = "row,col\n0,0\n0,2\n0,1\n"
  let route = @terrain_import.route_waypoints_bundle(source, csv, 0.0, 0.0)
  assert_eq(field(route, "status"), "complete-candidate".to_json())
  assert_eq(field(route, "route_complete"), true.to_json())
  assert_eq(
    field(route, "connected_cells_text"),
    "0,0\n0,1\n0,2\n0,1\n".to_json(),
  )
  assert_eq(num(field(route, "summary"), "horizontal_distance_m"), 30.0)
  assert_eq(num(field(route, "summary"), "cell_count"), 4.0)
  for (stop, col, step) in [(0, 0, 0), (1, 2, 2), (2, 1, 3)] {
    assert_eq(num(at(route, "stops", stop), "col"), col.to_double())
    assert_eq(
      num(at(route, "stops", stop), "connected_path_step"),
      step.to_double(),
    )
  }
  assert_eq(num(at(route, "legs", 1), "connected_start_step"), 2.0)
  assert_eq(num(at(route, "legs", 1), "connected_end_step"), 3.0)
  assert_eq(field(route, "waypoints_csv"), csv.to_json())
  assert_eq(
    route,
    @terrain_import.route_waypoints_bundle(source, csv, 0.0, 0.0),
  )
  assert_eq(field(route, "physical_readiness"), false.to_json())
}

///|
test "repeated stops and a return trip preserve directional cost without duplicate junctions" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 20",
  )
  let route = @terrain_import.route_waypoints_bundle(
    source, "row,col\n0,0\n0,0\n0,2\n0,0\n", 45.0, 2.0,
  )
  assert_eq(
    field(route, "connected_cells_text"),
    "0,0\n0,1\n0,2\n0,1\n0,0\n".to_json(),
  )
  assert_eq(num(field(at(route, "legs", 0), "summary"), "cell_count"), 1.0)
  assert_eq(
    num(field(at(route, "legs", 0), "summary"), "objective_cost_m"),
    0.0,
  )
  assert_eq(
    num(field(at(route, "legs", 1), "summary"), "objective_cost_m"),
    60.0,
  )
  assert_eq(
    num(field(at(route, "legs", 2), "summary"), "objective_cost_m"),
    20.0,
  )
  assert_eq(num(field(route, "summary"), "objective_cost_m"), 80.0)
  assert_eq(num(field(route, "summary"), "ascent_m"), 20.0)
  assert_eq(num(field(route, "summary"), "descent_m"), 20.0)
  assert_eq(num(at(route, "stops", 1), "connected_path_step"), 0.0)
  let stationary = @terrain_import.route_waypoints_bundle(
    source, "row,col\n0,0\n0,0\n0,0", 0.0, 0.0,
  )
  assert_eq(num(field(stationary, "summary"), "cell_count"), 1.0)
  assert_eq(num(field(stationary, "summary"), "horizontal_distance_m"), 0.0)
}

///|
test "failed middle leg retains only prefix and separately computes later useful leg" {
  let source = bundle(
    "ncols 6 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 -9999 0 0 0",
  )
  let route = @terrain_import.route_waypoints_bundle(
    source, "row,col\n0,0\n0,1\n0,3\n0,5\n", 0.0, 0.0,
  )
  assert_eq(field(route, "status"), "incomplete-route".to_json())
  assert_eq(field(route, "route_complete"), false.to_json())
  assert_eq(field(route, "summary"), Json::null())
  assert_eq(num(route, "first_failed_leg"), 1.0)
  assert_eq(
    field(route, "connected_path_scope"),
    "connected-prefix-only".to_json(),
  )
  assert_eq(field(route, "connected_cells_text"), "0,0\n0,1\n".to_json())
  assert_eq(
    num(field(route, "connected_summary"), "horizontal_distance_m"),
    10.0,
  )
  assert_eq(field(at(route, "legs", 1), "status"), "no-path".to_json())
  assert_eq(field(at(route, "legs", 1), "summary"), Json::null())
  assert_eq(field(at(route, "legs", 2), "status"), "candidate-found".to_json())
  assert_eq(field(at(route, "legs", 2), "in_connected_path"), false.to_json())
  assert_eq(
    num(field(at(route, "legs", 2), "summary"), "horizontal_distance_m"),
    20.0,
  )
  assert_eq(num(at(at(route, "legs", 2), "path_cells", 0), "col"), 3.0)
  assert_eq(field(at(route, "stops", 2), "connected_path_step"), Json::null())
  assert_eq(field(at(route, "stops", 3), "connected_path_step"), Json::null())
  assert_true(
    field(route, "legs_csv") is String(csv) &&
    csv.contains("no-path,false,,,,,"),
  )
  assert_true(
    field(route, "report_markdown") is String(report) &&
    report.contains("INCOMPLETE ROUTE"),
  )
}

///|
test "failed first leg never fabricates a path from later successes" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 0",
  )
  let route = @terrain_import.route_waypoints_bundle(
    source, "row,col\n0,0\n0,2\n0,2\n", 0.0, 0.0,
  )
  assert_eq(num(route, "first_failed_leg"), 0.0)
  assert_eq(field(route, "connected_path"), ([] : Array[Json]).to_json())
  assert_eq(field(route, "connected_cells_text"), "".to_json())
  assert_eq(field(route, "connected_summary"), Json::null())
  assert_eq(field(at(route, "legs", 1), "status"), "candidate-found".to_json())
  assert_eq(field(at(route, "legs", 1), "connected_start_step"), Json::null())
  let unknown = @terrain_import.route_waypoints_bundle(
    source, "row,col\n0,0\n0,1\n0,1\n0,2", 0.0, 0.0,
  )
  for
    (leg, expected) in [
      (0, "unknown-goal"),
      (1, "unknown-endpoints"),
      (2, "unknown-start"),
    ] {
    assert_eq(field(at(unknown, "legs", leg), "status"), expected.to_json())
    assert_eq(field(at(unknown, "legs", leg), "summary"), Json::null())
  }
}

///|
test "waypoint legs reuse single-pair grade cost and deterministic paths" {
  let source = bundle(detour)
  for (grade, weight) in [(20.0, 0.0), (60.0, 0.0), (60.0, 4.0)] {
    let route = @terrain_import.route_waypoints_bundle(
      source, "row,col\n2,0\n2,6\n2,0", grade, weight,
    )
    let there = @terrain_import.route_bundle(source, 2, 0, 2, 6, grade, weight)
    let back = @terrain_import.route_bundle(source, 2, 6, 2, 0, grade, weight)
    assert_eq(field(at(route, "legs", 0), "summary"), field(there, "summary"))
    assert_eq(field(at(route, "legs", 1), "summary"), field(back, "summary"))
    assert_eq(
      num(field(route, "summary"), "horizontal_distance_m"),
      num(field(there, "summary"), "horizontal_distance_m") +
      num(field(back, "summary"), "horizontal_distance_m"),
    )
  }
  let blocked = @terrain_import.route_waypoints_bundle(
    bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 20"),
    "row,col\n0,0\n0,1",
    20.0,
    0.0,
  )
  assert_eq(field(at(blocked, "legs", 0), "status"), "no-path".to_json())
}

///|
test "CSV validates bounds shape count and integer coordinates before routing" {
  let source = bundle(detour)
  for
    csv in [
      "",
      "0,0\n0,1",
      "col,row\n0,0\n0,1",
      "row,col\n0,0",
      "row,col\n0,0\n0,1,2",
      "row,col\n0,0\n0.5,1",
      "row,col\n0,0\n,1",
      "row,col\n0,0\n-1,0",
      "row,col\n0,0\n5,0",
      "row,col\n0,0\n0,7",
      "row,col\n0,0\n999999999999999999999,0",
      "row,col\n" + Array::make(33, "0,0").join("\n"),
      "row,col\n" + Array::make(16385, " ").join(""),
    ] {
    assert_true(rejects_waypoints(source, csv, 20.0, 0.0))
  }
  let accepted = @terrain_import.route_waypoints_bundle(
    source, "row,col\r\n 0 , 0 \r\n\r\n0,1\r\n", 20.0, 0.0,
  )
  assert_eq(field(accepted, "route_complete"), true.to_json())
  let maximum = @terrain_import.route_waypoints_bundle(
    source,
    "row,col\n" + Array::make(32, "0,0").join("\n"),
    20.0,
    0.0,
  )
  assert_eq(num(at(maximum, "stops", 31), "stop"), 31.0)
  assert_eq(num(at(maximum, "legs", 30), "leg"), 30.0)
}

///|
test "waypoint routes validate source and parameters and bind source stop order and CSV" {
  let csv = "row,col\n0,0\n0,1\n0,2\n"
  let source = bundle(detour)
  assert_true(rejects_waypoints(bundle(detour, unit="degrees"), csv, 20.0, 0.0))
  assert_true(
    rejects_waypoints(
      source.replace(old="\"sample_count\":34", new="\"sample_count\":35"),
      csv,
      20.0,
      0.0,
    ),
  )
  for
    (grade, weight) in [
      (-1.0, 0.0),
      (90.0, 0.0),
      (20.0, -1.0),
      (1.0 / 0.0, 0.0),
      (0.0 / 0.0, 0.0),
      (20.0, 1.0 / 0.0),
      (20.0, 0.0 / 0.0),
    ] {
    assert_true(rejects_waypoints(source, csv, grade, weight))
  }
  let route = @terrain_import.route_waypoints_bundle(source, csv, 20.0, 0.0)
  for
    changed in [
      @terrain_import.route_waypoints_bundle(
        source, "row,col\n0,0\n0,2\n0,1", 20.0, 0.0,
      ),
      @terrain_import.route_waypoints_bundle(source, csv + "\n", 20.0, 0.0),
      @terrain_import.route_waypoints_bundle(
        source.replace(old="Synthetic Cartesian frame", new="Another frame"),
        csv,
        20.0,
        0.0,
      ),
    ] {
    assert_true(field(route, "route_digest") != field(changed, "route_digest"))
  }
}
