///|
test "coordinate report digest binds input mapping normalized cells and full route" {
  let source = import_bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1 0 0", "sample", "Synthetic",
    "m", "Synthetic test",
  ).stringify()
  let result = route_coordinate_waypoints_bundle(
    source, "x,y\n0,0\n1,0\n", 0.0, 0.0,
  )
  for
    (value, hash) in [
      ("coordinate_waypoints_csv", "coordinate_waypoints_csv_digest"),
      ("coordinate_mapping_csv", "coordinate_mapping_csv_digest"),
      ("waypoints_csv", "waypoints_csv_digest"),
    ] {
    assert_eq(digest(json_text(result, value)), json_text(result, hash))
  }
  let identity = json_text(result, "route_digest")
  guard result is Object(fields) else { fail("Expected result object") }
  fields.remove("route_digest")
  assert_eq(identity, digest(result.stringify()))
  fields["coordinate_frame"] = "Changed declaration".to_json()
  assert_true(identity != digest(result.stringify()))
}
