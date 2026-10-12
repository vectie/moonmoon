///|
fn rejects_coordinates(source : String, csv : String) -> Bool {
  try {
    @terrain_import.route_coordinate_waypoints_bundle(source, csv, 45.0, 0.0)
    |> ignore
    false
  } catch {
    _ => true
  }
}

///|
test "coordinate waypoints use corner cell centers and north-to-south source rows" {
  let source = bundle(
    "ncols 3 nrows 2 xllcorner -30 yllcorner -20 cellsize 10 0 0 0 0 0 0",
  )
  let csv = "x,y\r\n -25, -15\r\n\r\n -5, -5\r\n-25,-15\r\n"
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source, csv, 0.0, 0.0,
  )
  assert_eq(field(route, "waypoints_csv"), "row,col\n1,0\n0,2\n1,0\n".to_json())
  assert_eq(field(route, "coordinate_waypoints_csv"), csv.to_json())
  assert_eq(
    field(route, "contract_id"),
    "moonmoon.terrain-coordinate-waypoint-route.v1".to_json(),
  )
  assert_eq(num(field(route, "summary"), "horizontal_distance_m"), 60.0)
  assert_eq(
    field(route, "coordinate_mapping_csv"),
    "stop,input_x,input_y,row,col,center_x,center_y\n0,-25,-15,1,0,-25,-15\n1,-5,-5,0,2,-5,-5\n2,-25,-15,1,0,-25,-15\n".to_json(),
  )
  assert_eq(field(route, "physical_readiness"), false.to_json())
  assert_eq(field(route, "review_required"), true.to_json())
  assert_eq(
    route,
    @terrain_import.route_coordinate_waypoints_bundle(source, csv, 0.0, 0.0),
  )
  assert_true(rejects_coordinates(source, "x,y\n-30,-20\n-10,-10"))
}

///|
test "coordinate waypoints preserve center origin and source frame" {
  let source = @terrain_import.import_bundle(
    "ncols 2 nrows 2 xllcenter -10 yllcenter -20 cellsize 10 0 0 0 0", "sample",
    "Declared local frame α", "m", "Synthetic",
  ).stringify()
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n-1e1,-2e1\n0,-10\n", 0.0, 0.0,
  )
  assert_eq(field(route, "waypoints_csv"), "row,col\n1,0\n0,1\n".to_json())
  assert_eq(
    field(route, "coordinate_frame"),
    "Declared local frame α".to_json(),
  )
  assert_eq(field(route, "horizontal_unit"), "m".to_json())
  assert_eq(num(at(route, "coordinate_stops", 0), "input_x"), -10.0)
  assert_eq(num(at(route, "coordinate_stops", 1), "center_y"), -10.0)
}

///|
test "coordinate route exactly reuses row-col legs path accounting and repeated stops" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 20",
  )
  let coordinates = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n0,0\n0,0\n20,0\n0,0\n", 45.0, 2.0,
  )
  let cells = @terrain_import.route_waypoints_bundle(
    source, "row,col\n0,0\n0,0\n0,2\n0,0\n", 45.0, 2.0,
  )
  for
    key in [
      "source_bundle", "source_bundle_digest", "waypoints_csv", "waypoints_csv_digest",
      "stops", "legs", "status", "summary", "connected_path", "connected_summary",
      "connected_route_csv", "connected_cells_text", "legs_csv",
    ] {
    assert_eq(field(coordinates, key), field(cells, key))
  }
  assert_eq(num(field(coordinates, "summary"), "objective_cost_m"), 80.0)
  assert_eq(num(at(coordinates, "stops", 1), "connected_path_step"), 0.0)
}

///|
test "coordinate input keeps missing stops unknown and never joins across a gap" {
  let source = bundle(
    "ncols 6 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 -9999 0 0 0",
  )
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n0,0\n10,0\n30,0\n50,0\n", 0.0, 0.0,
  )
  assert_eq(field(route, "route_complete"), false.to_json())
  assert_eq(field(route, "summary"), Json::null())
  assert_eq(field(route, "connected_cells_text"), "0,0\n0,1\n".to_json())
  assert_eq(field(at(route, "legs", 1), "status"), "no-path".to_json())
  assert_eq(field(at(route, "legs", 2), "in_connected_path"), false.to_json())
  let missing = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n20,0\n20,0\n30,0", 0.0, 0.0,
  )
  assert_eq(
    field(at(missing, "legs", 0), "status"),
    "unknown-endpoints".to_json(),
  )
  assert_eq(field(missing, "connected_summary"), Json::null())
}

///|
test "coordinate intake supports XYZ and revised terrain without changing source identities" {
  let spec = "{\"contract_id\":\"moonmoon.xyz-grid.v1\",\"tile_id\":\"sample\",\"coordinate_frame\":\"local\",\"horizontal_unit\":\"m\",\"source_note\":\"Synthetic\",\"rows\":2,\"cols\":2,\"origin_x\":-10,\"origin_y\":-20,\"cell_size\":10}"
  let source = @terrain_import.import_xyz_bundle(
    "x,y,elevation_m\n-10,-20,0\n0,-20,0\n-10,-10,0\n0,-10,0\n", spec,
  )
  let revised = @terrain_import.revise_bundle(
    source.stringify(),
    "row,col,expected_elevation_m,elevation_m\n0,1,0,unknown\n",
    "Withheld synthetic sample",
  )
  let csv = "x,y\n-10,-20\n0,-10\n"
  let original_route = @terrain_import.route_coordinate_waypoints_bundle(
    source.stringify(),
    csv,
    0.0,
    0.0,
  )
  let revised_route = @terrain_import.route_coordinate_waypoints_bundle(
    revised.stringify(),
    csv,
    0.0,
    0.0,
  )
  assert_eq(field(original_route, "route_complete"), true.to_json())
  assert_eq(field(revised_route, "route_complete"), false.to_json())
  assert_eq(
    field(at(revised_route, "legs", 0), "status"),
    "unknown-goal".to_json(),
  )
  assert_eq(field(original_route, "source_bundle"), source)
  assert_eq(field(revised_route, "source_bundle"), revised)
  assert_eq(
    field(revised_route, "waypoints_csv"),
    "row,col\n1,0\n0,1\n".to_json(),
  )
}

///|
test "coordinate tolerance includes both exact boundaries and rejects just outside" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 1 0 0 0 0",
  )
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n-0.0000001,0.0000001\n0.0000001,-0.0000001\n", 0.0, 0.0,
  )
  assert_eq(field(route, "waypoints_csv"), "row,col\n1,0\n1,0\n".to_json())
  for
    csv in [
      "x,y\n-0.00000010000001,0\n0,0", "x,y\n0.00000010000001,0\n0,0", "x,y\n0,-0.00000010000001\n0,0",
      "x,y\n0,0.00000010000001\n0,0",
    ] {
    assert_true(rejects_coordinates(source, csv))
  }
}

///|
test "coordinate tolerance scales with cell size without accepting arbitrary points" {
  let source = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 0.1 0 0 0 0",
  )
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n0.000000005,0\n0.1,0.1\n", 0.0, 0.0,
  )
  assert_eq(field(route, "waypoints_csv"), "row,col\n1,0\n0,1\n".to_json())
  assert_true(rejects_coordinates(source, "x,y\n0.00000002,0\n0.1,0.1"))
  assert_true(rejects_coordinates(source, "x,y\n0.05,0\n0.1,0.1"))
}

///|
test "coordinate intake rejects headers quoting extra fields and malformed numbers" {
  let source = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 0")
  for
    csv in [
      "", "row,col\n0,0\n0,1", "y,x\n0,0\n0,1", "\"x\",\"y\"\n0,0\n1,0", "x,y\n\"0\",0\n1,0",
      "x,y\n0,0,1\n1,0", "x,y\n,0\n1,0", "x,y\n0,\n1,0", "x,y\nabc,0\n1,0", "x,y\nNaN,0\n1,0",
      "x,y\n0,Infinity\n1,0", "x,y\n1e400,0\n1,0", "x,y\n-1,0\n1,0", "x,y\n2,0\n1,0",
      "x,y\n0,1\n1,0",
    ] {
    assert_true(rejects_coordinates(source, csv))
  }
}

///|
test "coordinate intake enforces 2 to 32 stops and raw input size bounds" {
  let source = bundle("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0")
  assert_true(rejects_coordinates(source, "x,y\n"))
  assert_true(rejects_coordinates(source, "x,y\n0,0\n"))
  let stops = Array::make(32, "0,0").join("\n")
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source,
    "x,y\n" + stops,
    0.0,
    0.0,
  )
  assert_eq(num(field(route, "summary"), "cell_count"), 1.0)
  assert_true(rejects_coordinates(source, "x,y\n" + stops + "\n0,0"))
  assert_true(
    rejects_coordinates(
      source,
      "x,y\n0,0\n0,0\n" + Array::make(16384, " ").join(""),
    ),
  )
}

///|
test "coordinate intake refuses degree grids and numerically ambiguous centers" {
  let degree = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 0",
    unit="degrees",
  )
  assert_true(rejects_coordinates(degree, "x,y\n0,0\n1,0"))
  for
    (grid, csv) in [
      (
        "ncols 2 nrows 1 xllcenter 1e20 yllcenter 0 cellsize 1 0 0", "x,y\n1e20,0\n1e20,0",
      ),
      (
        "ncols 1 nrows 2 xllcenter 0 yllcenter 1e20 cellsize 1 0 0", "x,y\n0,1e20\n0,1e20",
      ),
      (
        "ncols 2 nrows 1 xllcenter 1e16 yllcenter 0 cellsize 3 0 0", "x,y\n1e16,0\n1e16,0",
      ),
    ] {
    assert_true(rejects_coordinates(bundle(grid), csv))
  }
}

///|
test "coordinate intake verifies the bound source before route calculations" {
  let source = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 0")
  assert_true(
    rejects_coordinates(
      source.replace_all(old="terrain-import.v1", new="terrain-import.v0"),
      "x,y\n0,0\n1,0",
    ),
  )
  let route = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n0,0\n1,0", 0.0, 0.0,
  )
  let formatted = @terrain_import.route_coordinate_waypoints_bundle(
    source, "x,y\n0.0,0.0\n1,0\n", 0.0, 0.0,
  )
  assert_eq(field(route, "connected_path"), field(formatted, "connected_path"))
  assert_true(
    field(route, "coordinate_waypoints_csv_digest") !=
    field(formatted, "coordinate_waypoints_csv_digest"),
  )
  assert_true(field(route, "route_digest") != field(formatted, "route_digest"))
}

///|
test "coordinate route rejects invalid route preferences and tampered source evidence" {
  let source = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 0")
  for
    (grade, weight) in [
      (-1.0, 0.0),
      (90.0, 0.0),
      (0.0, -1.0),
      (@double.infinity, 0.0),
      (0.0, Double::nan()),
    ] {
    let rejected = try {
      @terrain_import.route_coordinate_waypoints_bundle(
        source, "x,y\n0,0\n1,0", grade, weight,
      )
      |> ignore
      false
    } catch {
      _ => true
    }
    assert_true(rejected)
  }
  let changed = @json.parse(source)
  guard changed is Object(fields) else { fail("Expected source object") }
  fields["source_digest"] = "tampered".to_json()
  assert_true(rejects_coordinates(changed.stringify(), "x,y\n0,0\n1,0"))
}
