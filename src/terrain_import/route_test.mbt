///|
let detour = "ncols 7 nrows 5 xllcorner 100 yllcorner 200 cellsize 10\n0 0 0 0 0 0 0\n0 0 0 15 0 0 0\n0 0 0 15 0 0 0\n0 0 -9999 15 0 0 0\n0 0 0 0 0 0 0\n"

///|
test "route finds shortest grade-limited detour with source coordinates and deterministic ties" {
  let source = bundle(detour)
  let result = @terrain_import.route_bundle(source, 2, 0, 2, 6, 20.0, 0.0)
  assert_eq(field(result, "status"), "candidate-found".to_json())
  let summary = field(result, "summary")
  assert_eq(num(summary, "horizontal_distance_m"), 100.0)
  assert_eq(num(summary, "ascent_m"), 0.0)
  assert_eq(num(summary, "objective_cost_m"), 100.0)
  assert_eq(num(summary, "cell_count"), 11.0)
  assert_eq(num(at(result, "path", 0), "x_m"), 105.0)
  assert_eq(num(at(result, "path", 0), "y_m"), 225.0)
  assert_eq(num(at(result, "path", 5), "row"), 0.0)
  assert_eq(field(at(result, "path", 0), "grade_deg"), Json::null())
  assert_eq(result, @terrain_import.route_bundle(source, 2, 0, 2, 6, 20.0, 0.0))
  assert_eq(field(result, "physical_readiness"), false.to_json())
  let direct = @terrain_import.route_bundle(source, 2, 0, 2, 6, 60.0, 0.0)
  assert_eq(num(field(direct, "summary"), "horizontal_distance_m"), 60.0)
  assert_eq(num(field(direct, "summary"), "ascent_m"), 15.0)
  assert_eq(num(field(direct, "summary"), "descent_m"), 15.0)
  assert_true(field(result, "route_digest") != field(direct, "route_digest"))
}

///|
test "uphill preference changes candidate and signed grades reverse" {
  let source = bundle(detour)
  let avoid_climb = @terrain_import.route_bundle(source, 2, 0, 2, 6, 60.0, 4.0)
  assert_eq(num(field(avoid_climb, "summary"), "horizontal_distance_m"), 100.0)
  assert_eq(num(field(avoid_climb, "summary"), "ascent_m"), 0.0)
  let incline = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 20",
  )
  let up = @terrain_import.route_bundle(incline, 0, 0, 0, 2, 45.0, 2.0)
  let down = @terrain_import.route_bundle(incline, 0, 2, 0, 0, 45.0, 2.0)
  assert_eq(num(field(up, "summary"), "objective_cost_m"), 60.0)
  assert_eq(num(field(down, "summary"), "objective_cost_m"), 20.0)
  assert_eq(num(at(up, "path", 1), "grade_deg"), 45.0)
  assert_eq(num(at(down, "path", 1), "grade_deg"), -45.0)
  assert_true(
    (num(field(up, "summary"), "piecewise_3d_distance_m") - 28.2842712474619).abs() <
    1.0e-12,
  )
}

///|
test "nodata and grade barriers return no path without invented zero totals" {
  for
    text in [
      "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 0", "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 20 0",
    ] {
    let result = @terrain_import.route_bundle(
      bundle(text),
      0,
      0,
      0,
      2,
      20.0,
      1.0,
    )
    assert_eq(field(result, "status"), "no-path".to_json())
    assert_eq(field(result, "summary"), Json::null())
    assert_eq(field(result, "path"), ([] : Array[Json]).to_json())
    assert_eq(field(result, "path_cells_text"), "".to_json())
  }
  let diagonal = bundle(
    "ncols 2 nrows 2 xllcenter 0 yllcenter 0 cellsize 10 0 -9999 -9999 0",
  )
  assert_eq(
    field(
      @terrain_import.route_bundle(diagonal, 0, 0, 1, 1, 80.0, 0.0),
      "status",
    ),
    "no-path".to_json(),
  )
  let same = @terrain_import.route_bundle(bundle(detour), 2, 0, 2, 0, 0.0, 0.0)
  assert_eq(num(field(same, "summary"), "cell_count"), 1.0)
  assert_eq(num(field(same, "summary"), "horizontal_distance_m"), 0.0)
}

///|
test "route rejects unsupported units invalid endpoints preferences and overflowing cost" {
  assert_true(
    (try? @terrain_import.route_bundle(
      bundle(detour, unit="degrees"),
      0,
      0,
      0,
      6,
      20.0,
      0.0,
    ))
    is Err(_),
  )
  for
    (r, c, grade, weight) in [
      (-1, 0, 20.0, 0.0),
      (0, 7, 20.0, 0.0),
      (3, 2, 20.0, 0.0),
      (0, 0, 90.0, 0.0),
      (0, 0, -1.0, 0.0),
      (0, 0, 20.0, -1.0),
    ] {
    assert_true(
      (try? @terrain_import.route_bundle(
        bundle(detour),
        r,
        c,
        2,
        6,
        grade,
        weight,
      ))
      is Err(_),
    )
  }
  let rise = bundle("ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10")
  assert_true(
    (try? @terrain_import.route_bundle(rise, 0, 0, 0, 1, 60.0, 1.0e308))
    is Err(_),
  )
}

///|
test "route artifacts preserve exact ordered route and identity binds metadata" {
  let source = bundle("ncols 2 nrows 1 xllcenter 5 yllcenter 6 cellsize 10 2 3")
  let result = @terrain_import.route_bundle(source, 0, 0, 0, 1, 20.0, 2.0)
  assert_eq(field(result, "path_cells_text"), "0,0\n0,1\n".to_json())
  assert_true(
    field(result, "route_csv") is String(csv) &&
    csv.contains("1,0,1,15,6,3,10,1,"),
  )
  assert_true(
    field(result, "route_svg") is String(svg) &&
    svg.contains("<polyline") &&
    svg.contains("<svg"),
  )
  let changed = @terrain_import.route_bundle(
    source.replace(old="Synthetic Cartesian frame", new="Another local frame"),
    0,
    0,
    0,
    1,
    20.0,
    2.0,
  )
  assert_true(field(result, "route_digest") != field(changed, "route_digest"))
  assert_eq(
    field(result, "source_bundle"),
    @terrain_import.reopen_bundle(source),
  )
}

///|
test "maximum supported grid produces a bounded adjacent route" {
  let text = "ncols 64 nrows 64 xllcenter 0 yllcenter 0 cellsize 1\n" +
    Array::make(4096, "0").join(" ")
  let result = @terrain_import.route_bundle(
    bundle(text),
    0,
    0,
    63,
    63,
    0.0,
    0.0,
  )
  assert_eq(num(field(result, "summary"), "cell_count"), 127.0)
  assert_eq(num(field(result, "summary"), "horizontal_distance_m"), 126.0)
  assert_eq(num(at(result, "path", 63), "row"), 0.0)
  assert_eq(num(at(result, "path", 63), "col"), 63.0)
  assert_eq(num(at(result, "path", 126), "row"), 63.0)
}

///|
test "source tampering nonfinite preferences and goal bounds are rejected" {
  let source = bundle(detour)
  for
    (grade, weight) in [
      (1.0 / 0.0, 0.0),
      (0.0 / 0.0, 0.0),
      (20.0, 1.0 / 0.0),
      (20.0, 0.0 / 0.0),
    ] {
    assert_true(
      (try? @terrain_import.route_bundle(source, 2, 0, 2, 6, grade, weight))
      is Err(_),
    )
  }
  assert_true(
    (try? @terrain_import.route_bundle(source, 2, 0, 5, 0, 20.0, 0.0)) is Err(_),
  )
  assert_true(
    (try? @terrain_import.route_bundle(source, 2, 0, 3, 2, 20.0, 0.0)) is Err(_),
  )
  assert_true(
    (try? @terrain_import.route_bundle(
      source.replace(old="\"sample_count\":34", new="\"sample_count\":35"),
      2,
      0,
      2,
      6,
      20.0,
      0.0,
    ))
    is Err(_),
  )
}
