///|
fn energy_assumptions() -> Json {
  {
    "contract_id": "moonmoon.path-energy-assumptions.v1",
    "assumption_note": "Synthetic rates for arithmetic testing, not calibrated robot performance.",
    "drive_wh_per_m": 1,
    "ascent_wh_per_m": 2,
    "cruise_speed_mps": 1,
    "auxiliary_power_w": 360,
    "initial_energy_wh": 50,
    "reserve_wh": 10,
    "max_grade_deg": 45,
  }
}

///|
fn energy_with(name : String, value : Json) -> String {
  let config = energy_assumptions()
  guard config is Object(fields)
  fields[name] = value
  config.stringify()
}

///|
fn energy_rejects(source : String, path : String, assumptions : String) -> Bool {
  try {
    @terrain_import.path_energy_bundle(source, path, assumptions) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
let energy_grid = "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 0"

///|
let energy_path = "row,col\n0,0\n0,1\n0,2\n"

///|
test "path energy sums drive ascent auxiliary and locates reserve shortfall" {
  let source = bundle(energy_grid)
  let config = energy_assumptions().stringify()
  let result = @terrain_import.path_energy_bundle(source, energy_path, config)
  assert_eq(field(result, "status"), "below-reserve".to_json())
  assert_eq(field(result, "coverage_complete"), true.to_json())
  assert_eq(num(result, "geometric_travel_time_s"), 20.0)
  assert_eq(num(field(result, "observed_segments"), "drive_wh"), 20.0)
  assert_eq(num(field(result, "observed_segments"), "ascent_wh"), 20.0)
  assert_eq(num(field(result, "observed_segments"), "auxiliary_wh"), 2.0)
  assert_eq(num(field(result, "summary"), "consumption_wh"), 42.0)
  assert_eq(num(field(result, "summary"), "remaining_energy_wh"), 8.0)
  assert_eq(num(field(result, "summary"), "reserve_margin_wh"), -2.0)
  assert_eq(num(result, "first_known_prefix_below_reserve_step"), 2.0)
  assert_eq(field(result, "first_known_prefix_insufficient_step"), Json::null())
  assert_eq(num(at(result, "segments", 1), "segment_consumption_wh"), 31.0)
  assert_eq(num(at(result, "segments", 2), "segment_consumption_wh"), 11.0)
  assert_eq(field(result, "assumptions_text"), config.to_json())
  assert_eq(field(result, "input_path_text"), energy_path.to_json())
  assert_eq(field(result, "grade_screening"), "within-threshold".to_json())
  assert_eq(field(result, "physical_readiness"), false.to_json())
  assert_eq(
    result,
    @terrain_import.path_energy_bundle(source, energy_path, config),
  )
}

///|
test "negative battery is retained and changing speed only changes declared auxiliary use" {
  let source = bundle(energy_grid)
  let depleted = @terrain_import.path_energy_bundle(
    source,
    energy_path,
    energy_with("initial_energy_wh", (20).to_json()),
  )
  assert_eq(field(depleted, "status"), "insufficient-energy".to_json())
  assert_eq(num(field(depleted, "summary"), "remaining_energy_wh"), -22.0)
  assert_eq(num(depleted, "first_known_prefix_insufficient_step"), 1.0)
  let faster = @terrain_import.path_energy_bundle(
    source,
    energy_path,
    energy_with("cruise_speed_mps", (2).to_json()),
  )
  assert_eq(num(faster, "geometric_travel_time_s"), 10.0)
  assert_eq(num(field(faster, "summary"), "consumption_wh"), 41.0)
  assert_eq(num(field(faster, "observed_segments"), "drive_wh"), 20.0)
  assert_true(
    field(faster, "energy_digest") != field(depleted, "energy_digest"),
  )
}

///|
test "reverse path has no descent energy credit and grade screening remains separate" {
  let source = bundle(
    "ncols 3 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 10 20",
  )
  let up = @terrain_import.path_energy_bundle(
    source,
    energy_path,
    energy_assumptions().stringify(),
  )
  let down = @terrain_import.path_energy_bundle(
    source,
    "0,2\n0,1\n0,0",
    energy_with("max_grade_deg", (20).to_json()),
  )
  assert_eq(num(field(up, "summary"), "consumption_wh"), 62.0)
  assert_eq(num(field(down, "summary"), "consumption_wh"), 22.0)
  assert_eq(field(down, "status"), "within-declared-budget".to_json())
  assert_eq(field(down, "grade_screening"), "exceeded".to_json())
  assert_eq(
    field(at(down, "segments", 1), "segment_status"),
    "grade-exceeded".to_json(),
  )
}

///|
test "energy gap withholds downstream balance while disconnected known energy is retained" {
  let source = bundle(
    "ncols 5 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 -9999 0 10",
  )
  let result = @terrain_import.path_energy_bundle(
    source,
    "0,0\n0,1\n0,2\n0,3\n0,4",
    energy_with("reserve_wh", (0).to_json()),
  )
  assert_eq(field(result, "status"), "incomplete-coverage".to_json())
  assert_eq(field(result, "summary"), Json::null())
  assert_eq(num(result, "geometric_travel_time_s"), 40.0)
  assert_eq(num(field(result, "observed_segments"), "consumption_wh"), 42.0)
  assert_eq(num(at(result, "segments", 1), "remaining_energy_wh"), 39.0)
  for step in [2, 3, 4] {
    assert_eq(
      field(at(result, "segments", step), "remaining_energy_wh"),
      Json::null(),
    )
  }
  assert_eq(
    field(at(result, "segments", 2), "segment_consumption_wh"),
    Json::null(),
  )
  assert_eq(num(at(result, "segments", 4), "segment_consumption_wh"), 31.0)
}

///|
test "known energy alone proves insufficiency across gaps without invented crossing" {
  let source = bundle(
    "ncols 5 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 0 0 -9999 0 10",
  )
  let path = "0,0\n0,1\n0,2\n0,3\n0,4"
  let result = @terrain_import.path_energy_bundle(
    source,
    path,
    energy_with("initial_energy_wh", (40).to_json()),
  )
  assert_eq(field(result, "status"), "insufficient-energy".to_json())
  assert_eq(field(result, "coverage_complete"), false.to_json())
  assert_eq(field(result, "summary"), Json::null())
  assert_eq(field(result, "first_known_prefix_insufficient_step"), Json::null())
  let prefix = @terrain_import.path_energy_bundle(
    source,
    path,
    energy_with("initial_energy_wh", (10).to_json()),
  )
  assert_eq(num(prefix, "first_known_prefix_insufficient_step"), 1.0)
}

///|
test "stationary points no dwell and exact reserve equality are explicit" {
  let source = bundle(energy_grid)
  let stationary = @terrain_import.path_energy_bundle(
    source,
    "0,0\n0,0",
    energy_with("reserve_wh", (50).to_json()),
  )
  assert_eq(field(stationary, "status"), "within-declared-budget".to_json())
  assert_eq(num(field(stationary, "summary"), "consumption_wh"), 0.0)
  assert_eq(num(field(stationary, "summary"), "reserve_margin_wh"), 0.0)
  assert_eq(num(stationary, "geometric_travel_time_s"), 0.0)
  assert_eq(
    field(stationary, "first_known_prefix_below_reserve_step"),
    Json::null(),
  )
  let below = @terrain_import.path_energy_bundle(
    source,
    "0,0",
    energy_with("reserve_wh", (51).to_json()),
  )
  assert_eq(field(below, "status"), "below-reserve".to_json())
  assert_eq(num(below, "first_known_prefix_below_reserve_step"), 0.0)
  let unknown = @terrain_import.path_energy_bundle(
    bundle("ncols 1 nrows 1 xllcenter 0 yllcenter 0 cellsize 10 -9999"),
    "0,0",
    energy_assumptions().stringify(),
  )
  assert_eq(field(unknown, "status"), "incomplete-coverage".to_json())
  assert_eq(field(unknown, "summary"), Json::null())
  let zero_rates = energy_assumptions()
  guard zero_rates is Object(zero_fields)
  for
    name in [
      "drive_wh_per_m", "ascent_wh_per_m", "auxiliary_power_w", "initial_energy_wh",
      "reserve_wh",
    ] {
    zero_fields[name] = (0).to_json()
  }
  let free_model = @terrain_import.path_energy_bundle(
    source,
    energy_path,
    zero_rates.stringify(),
  )
  assert_eq(field(free_model, "status"), "within-declared-budget".to_json())
  assert_eq(num(field(free_model, "summary"), "consumption_wh"), 0.0)
  let exact = energy_assumptions()
  guard exact is Object(exact_fields)
  exact_fields["initial_energy_wh"] = (42).to_json()
  exact_fields["reserve_wh"] = (0).to_json()
  let equality = @terrain_import.path_energy_bundle(
    source,
    energy_path,
    exact.stringify(),
  )
  assert_eq(field(equality, "status"), "within-declared-budget".to_json())
  assert_eq(num(field(equality, "summary"), "remaining_energy_wh"), 0.0)
}

///|
test "energy directly consumes existing route export without changing the path" {
  let source = bundle(detour)
  let route = @terrain_import.route_bundle(source, 2, 0, 2, 6, 20.0, 4.0)
  guard field(route, "path_cells_text") is String(path)
  let result = @terrain_import.path_energy_bundle(
    source,
    path,
    energy_assumptions().stringify(),
  )
  assert_eq(field(result, "path_cells_text"), path.to_json())
  assert_eq(num(field(result, "summary"), "consumption_wh"), 110.0)
  assert_eq(field(result, "status"), "insufficient-energy".to_json())
  assert_eq(num(result, "first_known_prefix_insufficient_step"), 5.0)
}

///|
test "energy rejects malformed incomplete misspelled negative and impossible assumptions" {
  let source = bundle(energy_grid)
  for
    config in [
      "invalid",
      "{}",
      "[]",
      energy_with("cruise_speed_mps", (0).to_json()),
      energy_with("reserve_wh", (-1).to_json()),
      energy_with("drive_wh_per_m", (-1).to_json()),
      energy_with("ascent_wh_per_m", (-1).to_json()),
      energy_with("initial_energy_wh", (-1).to_json()),
      energy_with("auxiliary_power_w", (-1).to_json()),
      energy_with("max_grade_deg", (90).to_json()),
      energy_with("drive_wh_per_meter", (1).to_json()),
      energy_with("drive_wh_per_m", "1".to_json()),
      energy_with("assumption_note", "".to_json()),
      energy_with("contract_id", "v2".to_json()),
    ] {
    assert_true(energy_rejects(source, energy_path, config))
  }
}

///|
test "energy rejects overflow and detected time or rate underflow" {
  let source = bundle(energy_grid)
  for
    config in [
      energy_with("drive_wh_per_m", 1.0e308.to_json()),
      energy_with("ascent_wh_per_m", 1.0e308.to_json()),
      energy_with("cruise_speed_mps", 1.0e-308.to_json()),
    ] {
    assert_true(energy_rejects(source, energy_path, config))
  }
  let tiny = bundle(
    "ncols 2 nrows 1 xllcenter 0 yllcenter 0 cellsize 1e-200 0 0",
  )
  assert_true(
    energy_rejects(
      tiny,
      "0,0\n0,1",
      energy_with("cruise_speed_mps", 1.0e308.to_json()),
    ),
  )
  assert_true(
    energy_rejects(
      tiny,
      "0,0\n0,1",
      energy_with("drive_wh_per_m", 1.0e-200.to_json()),
    ),
  )
}

///|
test "energy rejects skipped path tampered source and degree grid before estimating" {
  let source = bundle(energy_grid)
  let config = energy_assumptions().stringify()
  assert_true(energy_rejects(source, "0,0\n0,2", config))
  let degrees = @terrain_import.import_bundle(
    energy_grid, "degrees", "Declared angular", "degrees", "Synthetic test",
  ).stringify()
  assert_true(energy_rejects(degrees, energy_path, config))
  let changed = @json.parse(source)
  guard changed is Object(fields)
  fields["coordinate_frame"] = "Tampered".to_json()
  // Frame is declaration-bound and recomputation permits a changed declaration;
  // alter a derived field instead to verify integrity rejection.
  fields["sample_count"] = (999).to_json()
  assert_true(energy_rejects(changed.stringify(), energy_path, config))
}
