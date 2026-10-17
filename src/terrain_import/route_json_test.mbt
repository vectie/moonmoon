///|
test "interactive route bridge preserves exact native route and no-path distinction" {
  let source = bundle(detour)
  let json = @json.parse(
    @terrain_import.route_json(source, 2, 0, 2, 6, 20.0, 0.0),
  )
  assert_eq(field(json, "ok"), true.to_json())
  assert_eq(
    field(json, "route"),
    @terrain_import.route_bundle(source, 2, 0, 2, 6, 20.0, 0.0),
  )
  let blocked = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 0",
  )
  let result = @json.parse(
    @terrain_import.route_json(blocked, 0, 0, 0, 2, 20.0, 0.0),
  )
  assert_eq(field(result, "ok"), true.to_json())
  assert_eq(field(field(result, "route"), "status"), "no-path".to_json())
  assert_eq(field(field(result, "route"), "summary"), Json::null())
}

///|
test "interactive route bridge returns recoverable source endpoint unit and parameter errors" {
  let source = bundle(detour)
  let degrees = @terrain_import.import_bundle(
    detour, "degrees", "synthetic degree grid", "degrees", "Synthetic only",
  ).stringify()
  for
    result in [
      @terrain_import.route_json("{}", 0, 0, 0, 1, 20.0, 0.0),
      @terrain_import.route_json(source, 3, 2, 0, 1, 20.0, 0.0),
      @terrain_import.route_json(source, -1, 0, 0, 1, 20.0, 0.0),
      @terrain_import.route_json(source, 0, 0, 0, 1, 90.0, 0.0),
      @terrain_import.route_json(source, 0, 0, 0, 1, 20.0, -1.0),
      @terrain_import.route_json(degrees, 0, 0, 0, 1, 20.0, 0.0),
    ] {
    let response = @json.parse(result)
    assert_eq(field(response, "ok"), false.to_json())
    assert_true(
      field(response, "error") is String(message) && !message.is_empty(),
    )
  }
}
