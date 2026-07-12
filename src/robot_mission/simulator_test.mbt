///|
fn test_design(path_cells : Array[Array[Int]]) -> RobotMissionDesign {
  {
    contract_id: "moonsuite.robot-design.v1",
    design_id: "test-rover",
    revision: "r1",
    robot_artifact: {
      robot_id: "test-rover",
      robot_revision: "r1",
      artifact_root: "artifacts/test-rover",
      robot_json_path: "robot.json",
      robot_urdf_path: "model/robot.urdf",
      validation_receipt_path: "design/validation-receipt.json",
      bridge_config_path: "bridge/bridge.json",
      robot_json_sha256: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      robot_urdf_sha256: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      validation_receipt_sha256: "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
      validation_status: "accepted",
      physical_transport_enabled: false,
    },
    scenario: {
      scenario_id: "nominal-cycle",
      seed: 1101,
      scenario_kind: "nominal",
      injected_faults: [],
    },
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
      calibration: {
        contract_id: "moonmoon.digital-twin-calibration.v1",
        testbed_reference: "testbed://traction-rig/run-42",
        authoritative_source: "evidence/calibration/manifest.json",
        qualified: true,
        fault_models: [
          {
            fault_id: "low-traction",
            severity: 3,
            observable: true,
            recoverable: true,
            retained_performance: 0.8,
            energy_multiplier: 1.0,
            recovery_action: "reduce wheel torque and replan",
            calibration_reference: "testbed://traction-rig/run-42#low-traction",
            uncertainty_fraction: 0.08,
          },
          {
            fault_id: "sensor-loss",
            severity: 8,
            observable: false,
            recoverable: false,
            retained_performance: 0.0,
            energy_multiplier: 1.0,
            recovery_action: "return using independent localization",
            calibration_reference: "testbed://sensor-rig/run-7",
            uncertainty_fraction: 0.12,
          },
        ],
      },
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
  assert_true(result.artifact_binding_verified)
  assert_eq(result.scenario_id, "nominal-cycle")
  assert_eq(result.seed, 1101)
  assert_true(result.blockers.is_empty())
}

///|
test "simulation rejects an unvalidated or physical MoonRobo binding" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let robot_artifact = {
    ..design.robot_artifact,
    validation_status: "pending",
    physical_transport_enabled: true,
  }
  let unqualified = { ..design, robot_artifact, }
  let result = simulate(unqualified, test_dem())
  assert_eq(result.result, "rejected")
  assert_false(result.artifact_binding_verified)
  assert_true(
    result.blockers.contains(
      "MoonRobo artifact binding is incomplete, mismatched, unsafe, or unvalidated",
    ),
  )
}

///|
test "calibrated adverse fault recovers with an auditable state transition" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let scenario : MissionScenario = {
    scenario_id: "low-traction-recovery",
    seed: 4404,
    scenario_kind: "adverse",
    injected_faults: ["low-traction"],
  }
  let adverse = { ..design, scenario, }
  let result = simulate(adverse, test_dem())
  assert_eq(result.result, "accepted")
  assert_eq(result.scenario_outcome, "recovered")
  assert_eq(result.evidence_claim, "calibrated-digital-twin")
  assert_false(result.physical_readiness)
  assert_eq(result.fault_responses[0].states, [
    "normal", "degraded", "diagnosis", "recovery-attempt", "recovered",
  ])
}

///|
test "unobservable fault returns safely and unknown fault fails closed" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let safe = {
    ..design,
    scenario: {
      scenario_id: "sensor-loss",
      seed: 5505,
      scenario_kind: "adverse",
      injected_faults: ["sensor-loss"],
    },
  }
  let safe_result = simulate(safe, test_dem())
  assert_eq(safe_result.result, "rejected")
  assert_eq(safe_result.scenario_outcome, "safe-return")
  assert_eq(safe_result.final_state, "safe-return")
  let unknown = {
    ..design,
    scenario: {
      scenario_id: "unknown",
      seed: 6606,
      scenario_kind: "adverse",
      injected_faults: ["unmodeled-fault"],
    },
  }
  let unknown_result = simulate(unknown, test_dem())
  assert_eq(unknown_result.scenario_outcome, "fail-closed")
  assert_true(!unknown_result.blockers.is_empty())
}

///|
test "provisional referenced model remains scenario-qualified" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let calibration = { ..design.environment.calibration, qualified: false }
  let provisional = {
    ..design,
    environment: { ..design.environment, calibration, },
    scenario: {
      scenario_id: "provisional-low-traction",
      seed: 7707,
      scenario_kind: "adverse",
      injected_faults: ["low-traction"],
    },
  }
  let result = simulate(provisional, test_dem())
  assert_eq(result.result, "accepted")
  assert_eq(result.scenario_outcome, "recovered")
  assert_eq(result.evidence_claim, "scenario-qualified")
  assert_false(result.physical_readiness)
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
test "simulation rejects drift in declared component energy instead of trusting totals" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let energy = { ..design.verification_criteria.energy, drive_energy_wh: 1.0 }
  let verification = { ..design.verification_criteria, energy, }
  let drifted = { ..design, verification_criteria: verification }
  let result = simulate(drifted, test_dem())
  assert_eq(result.result, "rejected")
  assert_true(
    result.blockers.contains(
      "computed drive energy does not match verification criteria",
    ),
  )
}

///|
test "identical inputs produce byte-equivalent deterministic receipts" {
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  let first = simulate(design, test_dem()).to_json().stringify()
  let second = simulate(design, test_dem()).to_json().stringify()
  assert_eq(first, second)
}

///|
fn ensure_test_dir(path : String) -> Unit {
  if !@fsx.path_exists(path) {
    @fsx.create_dir(path) catch {
      _ => ()
    }
  }
}

///|
test "file simulation verifies staged MoonRobo identity and bridge safety" {
  let root = "/tmp/moonmoon-bound-robot-mission-test"
  let artifact = root + "/artifacts/test-rover"
  ensure_test_dir(root)
  ensure_test_dir(root + "/artifacts")
  ensure_test_dir(artifact)
  ensure_test_dir(artifact + "/model")
  ensure_test_dir(artifact + "/design")
  ensure_test_dir(artifact + "/bridge")
  ensure_test_dir(root + "/terrain")
  @fsx.write_string_to_file(
    artifact + "/robot.json",
    "{ \"id\": \"test-rover\" }",
  )
  @fsx.write_string_to_file(
    artifact + "/model/robot.urdf",
    "<robot name=\"test-rover\"></robot>",
  )
  @fsx.write_string_to_file(
    artifact + "/design/validation-receipt.json",
    "{ \"status\": \"accepted\", \"book_id\": \"test-rover\", \"physical_transport_enabled\": false }",
  )
  @fsx.write_string_to_file(
    artifact + "/bridge/bridge.json",
    "{ \"mode\": \"simulation-only\", \"physical_transport_enabled\": false, \"design_id\": \"test-rover\" }",
  )
  @fsx.write_string_to_file(root + "/terrain.csv", test_dem())
  let design = test_design([[0, 3], [1, 3], [2, 3], [3, 3]])
  @fsx.write_string_to_file(root + "/design.json", design.to_json().stringify())
  guard simulate_files(
      root + "/design.json",
      root,
      root + "/accepted-result.json",
    )
    is Ok(accepted) else {
    fail("expected bound simulation success")
  }
  assert_eq(accepted.result, "accepted")
  assert_true(accepted.artifact_binding_verified)
  @fsx.write_string_to_file(
    artifact + "/bridge/bridge.json",
    "{ \"mode\": \"simulation-only\", \"physical_transport_enabled\": true, \"design_id\": \"test-rover\" }",
  )
  guard simulate_files(
      root + "/design.json",
      root,
      root + "/rejected-result.json",
    )
    is Ok(rejected) else {
    fail("expected a persisted rejection receipt")
  }
  assert_eq(rejected.result, "rejected")
  assert_false(rejected.artifact_binding_verified)
  assert_true(
    rejected.blockers.contains("staged MoonRobo bridge is not simulation-only"),
  )
}
