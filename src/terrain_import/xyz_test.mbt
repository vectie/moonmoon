///|
let xyz_spec =
  #|{"contract_id":"moonmoon.xyz-grid.v1","tile_id":"points","coordinate_frame":"Synthetic local Cartesian frame","horizontal_unit":"m","source_note":"Synthetic Apache-2.0 example; not lunar measurements","rows":3,"cols":3,"origin_x":100,"origin_y":200,"cell_size":10}

///|
let xyz_plane = "x,y,elevation_m\n120,220,6\n100,200,0\n110,210,3\n120,200,2\n100,210,2\n110,200,1\n100,220,4\n120,210,4\n110,220,5\n"

///|
fn xyz_value(value : Json, key : String) -> Json {
  guard value is Object(fields) && fields.get(key) is Some(result) else {
    abort("Missing test field " + key)
  }
  result
}

///|
fn rejects_xyz(text : String, specification : String) -> Unit raise {
  try @terrain_import.import_xyz_bundle(text, specification) catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected XYZ import rejection")
  }
}

///|
test "XYZ intake maps unordered observations and preserves both raw inputs" {
  let csv = "x,y,elevation_m\r\n120,220,6\r\n100,200,-9999\r\n110,210,0\r\n"
  let bundle = @terrain_import.import_xyz_bundle(csv, xyz_spec)
  assert_eq(xyz_value(bundle, "source_text"), csv.to_json())
  assert_eq(xyz_value(bundle, "grid_specification_text"), xyz_spec.to_json())
  assert_eq(
    xyz_value(bundle, "contract_id"),
    "moonmoon.terrain-xyz-import.v1".to_json(),
  )
  assert_eq(
    xyz_value(bundle, "terrain_csv"),
    "tile_id,row,col,elevation_m\npoints,0,2,6\npoints,1,1,0\npoints,2,0,-9999\n".to_json(),
  )
  assert_eq(xyz_value(bundle, "sample_count"), (3).to_json())
  assert_eq(xyz_value(bundle, "nodata_count"), (6).to_json())
  assert_eq(xyz_value(bundle, "nodata_value"), Json::null())
  assert_eq(xyz_value(bundle, "minimum_elevation_m"), (-9999).to_json())
  assert_eq(xyz_value(bundle, "physical_readiness"), false.to_json())
  assert_eq(@terrain_import.reopen_bundle(bundle.stringify(indent=2)), bundle)
}

///|
test "XYZ empty coverage keeps the explicitly declared extent" {
  let bundle = @terrain_import.import_xyz_bundle("x,y,elevation_m\n", xyz_spec)
  assert_eq(xyz_value(bundle, "rows"), (3).to_json())
  assert_eq(xyz_value(bundle, "cols"), (3).to_json())
  assert_eq(xyz_value(bundle, "sample_count"), (0).to_json())
  assert_eq(xyz_value(bundle, "nodata_count"), (9).to_json())
  assert_eq(xyz_value(bundle, "minimum_elevation_m"), Json::null())
  assert_eq(
    xyz_value(bundle, "terrain_csv"),
    "tile_id,row,col,elevation_m\n".to_json(),
  )
}

///|
test "XYZ coordinate tolerance handles decimal notation without interpolation" {
  let spec = xyz_spec
    .replace(old="100", new="0.1")
    .replace(old="200", new="-0.2")
    .replace(old="10}", new="0.1}")
  let bundle = @terrain_import.import_xyz_bundle(
    "x,y,elevation_m\n0.3,0,1e2\n0.100000001,-0.2,-2\n", spec,
  )
  assert_eq(
    xyz_value(bundle, "terrain_csv"),
    "tile_id,row,col,elevation_m\npoints,0,2,100\npoints,2,0,-2\n".to_json(),
  )
  rejects_xyz("x,y,elevation_m\n0.1000001,-0.2,2\n", spec)
}

///|
test "XYZ rejects duplicate off-grid out-of-bounds and nonnumeric records" {
  for
    csv in [
      xyz_plane + "100,200,0\n",
      "x,y,elevation_m\n105,200,1\n",
      "x,y,elevation_m\n130,200,1\n",
      "x,y,elevation_m\n100,190,1\n",
      "x,y,elevation_m\n100,200,\n",
      "x,y,elevation_m\n100,200,nan\n",
      "x,y,elevation_m\n100,200,1e999\n",
      "x,y,elevation_m\n100,200,1,2\n",
      "x,y,elevation_m\n\"100\",200,1\n",
      "x,y,z\n100,200,1\n",
      "",
    ] {
    rejects_xyz(csv, xyz_spec)
  }
}

///|
test "XYZ validates explicit grid dimensions units frame and spacing" {
  for
    spec in [
      "{}",
      "[]",
      xyz_spec.replace(old="\"rows\":3", new="\"rows\":0"),
      xyz_spec.replace(old="\"rows\":3", new="\"rows\":1.5"),
      xyz_spec.replace(old="\"rows\":3", new="\"rows\":4096"),
      xyz_spec.replace(old="\"cell_size\":10", new="\"cell_size\":0"),
      xyz_spec.replace(old="\"cell_size\":10", new="\"cell_size\":-10"),
      xyz_spec.replace(old="\"origin_x\":100", new="\"origin_x\":1e300"),
      xyz_spec.replace(old="\"m\"", new="\"feet\""),
      xyz_spec.replace(old="Synthetic local Cartesian frame", new=""),
      xyz_spec.replace(old="\"origin_x\"", new="\"xllcorner\""),
    ] {
    rejects_xyz(xyz_plane, spec)
  }
}

///|
test "XYZ downstream analysis and routing retain complete source identity" {
  let source = @terrain_import.import_xyz_bundle(xyz_plane, xyz_spec)
  let analysis = @terrain_import.analyze_bundle(
    source.stringify(),
    "row",
    1,
    10.0,
  )
  assert_eq(xyz_value(analysis, "source_bundle"), source)
  assert_eq(
    xyz_value(xyz_value(analysis, "grid_summary"), "estimated_cells"),
    (1).to_json(),
  )
  assert_eq(
    xyz_value(xyz_value(analysis, "profile_summary"), "known_segments"),
    (2).to_json(),
  )
  let route = @terrain_import.route_bundle(
    source.stringify(),
    2,
    0,
    0,
    2,
    30.0,
    0.0,
  )
  assert_eq(xyz_value(route, "source_bundle"), source)
  assert_eq(xyz_value(route, "status"), "candidate-found".to_json())
  let waypoints = @terrain_import.route_waypoints_bundle(
    source.stringify(),
    "row,col\n2,0\n0,2\n",
    30.0,
    0.0,
  )
  assert_eq(xyz_value(waypoints, "route_complete"), true.to_json())
}

///|
test "XYZ missing cells remain unknown in analysis and waypoint outputs" {
  let sparse = "x,y,elevation_m\n100,200,0\n120,200,2\n"
  let source = @terrain_import.import_xyz_bundle(sparse, xyz_spec)
  let analysis = @terrain_import.analyze_bundle(
    source.stringify(),
    "row",
    2,
    10.0,
  )
  assert_eq(
    xyz_value(xyz_value(analysis, "profile_summary"), "known_segments"),
    (0).to_json(),
  )
  assert_eq(
    xyz_value(xyz_value(analysis, "profile_summary"), "unknown_segments"),
    (2).to_json(),
  )
  let waypoints = @terrain_import.route_waypoints_bundle(
    source.stringify(),
    "row,col\n2,0\n2,2\n",
    30.0,
    0.0,
  )
  assert_eq(xyz_value(waypoints, "route_complete"), false.to_json())
}

///|
test "XYZ reopen rejects altered source declaration metadata and samples" {
  let source = @terrain_import.import_xyz_bundle(xyz_plane, xyz_spec)
  for
    (key, replacement) in [
      ("source_text", (xyz_plane + "100,200,7\n").to_json()),
      (
        "grid_specification_text",
        xyz_spec.replace(old="\"rows\":3", new="\"rows\":4").to_json(),
      ),
      ("grid_specification_digest", "sha256:changed".to_json()),
      ("source_digest", "sha256:changed".to_json()),
      ("terrain_csv", "wrong".to_json()),
      ("sample_count", (8).to_json()),
      ("physical_readiness", true.to_json()),
    ] {
    let changed = @json.parse(source.stringify())
    guard changed is Object(fields) else { abort("Expected object") }
    fields[key] = replacement
    assert_true(
      @terrain_import.reopen_json(changed.stringify()).contains("\"ok\":false"),
    )
  }
}

///|
test "XYZ degree coordinates can be inspected but cannot become metric analysis" {
  let source = @terrain_import.import_xyz_bundle(
    xyz_plane,
    xyz_spec.replace(old="\"m\"", new="\"degrees\""),
  )
  assert_eq(@terrain_import.reopen_bundle(source.stringify()), source)
  try @terrain_import.analyze_bundle(source.stringify(), "row", 1, 10.0) catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected degree analysis rejection")
  }
  try
    @terrain_import.route_bundle(source.stringify(), 2, 0, 0, 2, 30.0, 0.0)
  catch {
    @terrain_import.ImportError::InvalidRaster(_) => ()
  } noraise {
    _ => fail("Expected degree routing rejection")
  }
}
