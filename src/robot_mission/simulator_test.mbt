///|
fn test_design(path_cells : Array[Array[Int]]) -> RobotMissionDesign {
  {
    contract_id: "moonsuite.robot-design.v1",
    design_id: "test-rover",
    revision: "r1",
    mission: {
      authority: "digital-only",
      payload: { mass_kg: 5.0, delivery_count: 1 },
      route_id: "bounded-path",
      source_route_id: "blocked-grid",
    },
    environment: {
      terrain_source_path: "terrain.csv",
      cell_size_m: 20.0,
      path_cells,
      whole_grid_max_neighbor_grade_deg: 35.81,
      whole_grid_status: "blocked",
      illumination: {
        terrain_available_energy_wh: 3997.25881056032,
        longest_dark_hours: 0.0,
        decision: "Allow",
      },
      dust_and_thermal: { thermal_survival_power_w: 35.0 },
    },
    subsystems: [
      {
        id: "power",
        kind: "solar-battery-digital-model",
        battery_capacity_wh: Some(1200.0),
        reserve_wh: Some(600.0),
        drive_power_w: Some(120.0),
        comms_power_w: Some(20.0),
        minimum_energy_margin_wh: Some(250.0),
      },
    ],
    constraints: {
      payload_mass_kg: { min: 0.0, max: 5.0 },
      route_length_m: { min: 60.0, max: 60.0 },
      max_path_slope_deg: { min: 0.0, max: 15.0 },
      waypoint_spacing_m: { min: 0.1, max: 4.5 },
      commanded_speed_mps: { min: 0.01, max: 0.1 },
      replay_count: { min: 2.0, max: 2.0 },
      delivery_count: { min: 1.0, max: 1.0 },
    },
    verification_criteria: {
      path: {
        distance_m: 60.0,
        waypoint_spacing_m: 4.0,
        waypoint_count: 16,
        commanded_speed_mps: 0.1,
        drive_duration_s: 600.0,
        maximum_measured_segment_slope_deg: 13.172957936,
        blocked_cell_count: 0,
      },
      energy: {
        drive_energy_wh: 20.0,
        comms_energy_wh: 3.3333333333333335,
        thermal_survival_energy_wh: 0.0,
        reserve_wh: 600.0,
        bounded_required_energy_wh: 623.3333333333334,
        verified_available_energy_wh: 3997.25881056032,
        expected_margin_wh: 3373.9254772269866,
      },
      delivery: {
        expected_payload_mass_kg: 5.0,
        expected_delivery_count: 1,
        final_state: "stopped-at-south-endpoint",
      },
      safety: {
        fail_closed: true,
        unverified_route_bypass_allowed: false,
        physical_deployment_claim_allowed: false,
      },
      replay: { required_runs: 2 },
    },
  }
}

///|
fn test_dem() -> String {
  (
    #|tile_id,row,col,elevation_m
    #|tile,0,0,341.536
    #|tile,0,1,332.075
    #|tile,0,2,325.045
    #|tile,0,3,318.160
    #|tile,1,0,339.786
    #|tile,1,1,330.196
    #|tile,1,2,321.057
    #|tile,1,3,313.479
    #|tile,2,0,337.032
    #|tile,2,1,326.753
    #|tile,2,2,318.107
    #|tile,2,3,309.947
    #|tile,3,0,331.956
    #|tile,3,1,324.070
    #|tile,3,2,315.028
    #|tile,3,3,305.726
    #|
  )
}

///|
test "path-aware simulation accepts only the measured corridor and preserves the grid blocker" {
  let result = simulate(
    test_design([[0, 3], [1, 3], [2, 3], [3, 3]]),
    test_dem(),
  )
  assert_eq(result.result, "accepted")
  assert_true(result.whole_grid_blocker_preserved)
  assert_eq(result.segment_evidence.length(), 3)
  assert_true(result.maximum_measured_segment_slope_deg < 15.0)
  assert_eq(result.distance_m, 60.0)
  assert_eq(result.delivery_count, 1)
  assert_true(result.blockers.is_empty())
}

///|
test "path-aware simulation rejects a steep segment without bypassing it" {
  let design = test_design([[0, 3], [0, 2], [0, 1], [0, 0]])
  let result = simulate(design, test_dem())
  assert_eq(result.result, "rejected")
  assert_eq(result.delivery_count, 0)
  assert_eq(result.final_state, "stopped-with-blocker")
  assert_true(result.maximum_measured_segment_slope_deg > 15.0)
  assert_true(!result.blockers.is_empty())
}

///|
test "identical inputs produce byte-equivalent deterministic receipts" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let first = simulate(design, test_dem()).to_json().stringify()
  let second = simulate(design, test_dem()).to_json().stringify()
  assert_eq(first, second)
}
