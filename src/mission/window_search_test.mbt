///|
test "mission-window ranking chooses the strongest fixed-cadence interval" {
  let track : @lunar_ephemeris.SolarGeometryTrack = {
    time_start_utc: "2026-07-09T00:00:00Z",
    step_minutes: 60,
    sun_altitude_deg: Array::make(48, 1.0),
    sun_azimuth_deg: Array::make(48, 90.0),
  }
  let evidence = @mission.rank_route_mission_windows(
    "first-trusted-square",
    "northeast-stepout",
    @mission.first_trusted_square_route_candidates(),
    track,
    1783555200L,
    24,
    24,
    "kernel.bsp",
    "orientation.tpc",
    @mission.conservative_illumination_constraint(),
  ).unwrap()
  assert_eq(evidence.windows_per_route, 2)
  assert_eq(evidence.candidates.length(), 6)
  assert_eq(evidence.selected_candidate_index, 5)
  let selected = evidence.candidates[evidence.selected_candidate_index]
  assert_eq(selected.route_id, "northeast-stepout")
  assert_eq(selected.time_start_utc, "2026-07-09T00:00:00Z")
  assert_eq(selected.time_end_utc, "2026-07-10T00:00:00Z")
  assert_eq(selected.terrain_sunlit_hours, 24.0)
  assert_eq(selected.longest_dark_hours, 0.0)
  assert_true(selected.meets_illumination_constraint)
  assert_true(selected.decision == Allow)
}

///|
test "generated first-square search exposes a sunlit selected-route window" {
  let evidence = @mission.first_trusted_square_window_search_evidence()
  assert_eq(evidence.search_start_utc, "2026-07-09T00:00:00Z")
  assert_eq(evidence.search_end_utc, "2027-07-09T00:00:00Z")
  assert_eq(evidence.window_hours, 336)
  assert_eq(evidence.stride_hours, 24)
  assert_eq(evidence.windows_per_route, 352)
  assert_eq(
    evidence.generated_by,
    "vectie/moonmoon/src/mission/window_search.mbt",
  )
  assert_eq(evidence.candidates.length(), 6)
  assert_eq(evidence.selected_candidate_index, 5)
  let selected = evidence.candidates[evidence.selected_candidate_index]
  assert_eq(selected.route_id, "northeast-stepout")
  assert_eq(selected.time_start_utc, "2026-11-08T00:00:00Z")
  assert_eq(selected.time_end_utc, "2026-11-22T00:00:00Z")
  assert_eq(selected.terrain_sunlit_hours, 336.0)
  assert_eq(selected.longest_dark_hours, 0.0)
  assert_true(selected.terrain_available_energy_wh > 3997.0)
  assert_true(selected.minimum_solar_clearance_deg > 1.34)
  assert_true(selected.meets_illumination_constraint)
  assert_true(selected.decision == Allow)
}
