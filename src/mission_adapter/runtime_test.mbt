///|
fn test_ensure_dir(path : String) -> Unit {
  if !@fsx.path_exists(path) {
    @fsx.create_dir(path) catch {
      _ => ()
    }
  }
}

///|
fn test_workspace() -> String {
  "/tmp/moonmoon-mission-adapter-v3"
}

///|
fn study_hash(text : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text)))
}

///|
test "mission dossier freezes two adapter sessions and reopens without live sources" {
  let root = "/tmp/moonmoon-q11-study-20261004-v3"
  for
    path in [
      root,
      root + "/books",
      root + "/books/test-rover",
      root + "/books/test-rover/model",
      root + "/books/test-rover/design",
      root + "/books/test-rover/bridge",
      root + "/terrain",
      root + "/inputs",
      root + "/evidence",
    ] {
    test_ensure_dir(path)
  }
  let profile = "{ \"id\": \"test-rover\" }"
  let urdf = "<robot name=\"test-rover\"></robot>"
  let validation = "{ \"status\": \"accepted\", \"book_id\": \"test-rover\", \"physical_transport_enabled\": false }"
  let bridge = "{ \"mode\": \"simulation-only\", \"physical_transport_enabled\": false, \"design_id\": \"test-rover\" }"
  for
    (path, text) in [
      ("books/test-rover/robot.json", profile),
      ("books/test-rover/model/robot.urdf", urdf),
      ("books/test-rover/design/validation-receipt.json", validation),
      ("books/test-rover/bridge/bridge.json", bridge),
      ("terrain/route.csv", test_dem()),
      (
        "evidence/mission-approval.json", "{\"scope\":\"inert-local-regression-fixture\"}",
      ),
    ] {
    @fsx.write_string_to_file(root + "/" + path, text)
  }
  let original = test_design()
  let design = {
    ..original,
    robot_artifact: {
      ..original.robot_artifact,
      robot_json_sha256: study_hash(profile),
      robot_urdf_sha256: study_hash(urdf),
      validation_receipt_sha256: study_hash(validation),
    },
    environment: {
      ..original.environment,
      calibration: {
        ..original.environment.calibration,
        qualified: false,
        testbed_reference: "fixture://local-digital-only",
      },
    },
  }
  let integration : @mission_adapter.MoonroboDigitalIntegrationReceipt = {
    contract_id: "moonrobo.digital-model-integration-receipt.v1",
    adapter_id: "moonrobo-local-v1",
    operation_id: "robot.integrate-digital-model",
    request_id: "q11-fixture",
    attempt_id: "q11-fixture",
    idempotency_key: "q11-fixture",
    status: "succeeded",
    physical_execution_performed: false,
    evidence_refs: [
      "books/test-rover/robot.json", "books/test-rover/design/validation-receipt.json",
      "books/test-rover/model/robot.urdf",
    ],
    output: {
      "accepted": true,
      "robobook_ref": "books/test-rover",
      "build_receipt_ref": "books/test-rover/robot.json",
      "validation_receipt_ref": "books/test-rover/design/validation-receipt.json",
      "model_ref": "books/test-rover/model/robot.urdf",
      "physical_ready": false,
    },
  }
  @fsx.write_string_to_file(
    root + "/inputs/moonrobo-integration.json",
    integration.to_json().stringify(indent=2),
  )
  let poor_energy = {
    ..design,
    mission: { ..design.mission, route_id: "negative-energy-alternative", },
    environment: {
      ..design.environment,
      path_cells: [[0, 3], [1, 3], [2, 3], [3, 3], [4, 3]],
      illumination: {
        ..design.environment.illumination,
        terrain_available_energy_wh: 1.0,
      },
    },
  }
  let revised_assumption = {
    ..design,
    mission: { ..design.mission, route_id: "revised-energy-assumption", },
    environment: {
      ..design.environment,
      illumination: {
        ..design.environment.illumination,
        terrain_available_energy_wh: 2.0,
      },
    },
  }
  for
    (session, proposal) in [
      ("q11-a", design),
      ("q11-b", poor_energy),
      ("q11-c", revised_assumption),
    ] {
    let design_ref = "inputs/" + session + "-design.json"
    let run_ref = "inputs/" + session + "-run.json"
    @fsx.write_string_to_file(
      root + "/" + design_ref,
      proposal.to_json().stringify(indent=2),
    )
    let run : @mission_adapter.RobotMissionRunRequest = {
      contract_id: "moonmoon.robot-mission-run-request.v1",
      session_id: session,
      moonrobo_integration_receipt_ref: "inputs/moonrobo-integration.json",
      mission_design_ref: design_ref,
      dataset_evidence: [],
    }
    @fsx.write_string_to_file(
      root + "/" + run_ref,
      run.to_json().stringify(indent=2),
    )
    let refs = [run_ref, "evidence/mission-approval.json"]
    let request = {
      ..simulation_request(
        "robotics-simulation-v2",
        test_artifact_set_digest(root, refs),
      ),
      request_id: session,
      attempt_id: session,
      idempotency_key: session,
      input_artifacts: refs,
    }
    guard @mission_adapter.invoke(root, request) is Ok(result) else {
      fail("local fixture simulation failed")
    }
    assert_eq(result.status, "succeeded")
  }
  let site : @mission_adapter.StudySite = {
    site_id: "local-test-grid",
    revision: "r1",
    frame: "local-test-grid row/column",
    distance_unit: "m",
    elevation_unit: "m",
    coverage: "Only enumerated 4x4 fixture cells; outside coverage unknown",
    uncertainty: "Inert regression fixture, not external lunar truth or calibrated hardware",
  }
  let envelope = @mission_adapter.create_study(
    root,
    "local-study",
    "r1",
    "",
    site,
    ["q11-a", "q11-b"],
  )
  let reference = @mission_adapter.save_study(root, envelope)
  assert_eq(@mission_adapter.save_study(root, envelope), reference)
  let saved = @fsx.read_file_to_string(root + "/" + reference)
  let revised = @mission_adapter.create_study(
    root,
    "local-study",
    "r2",
    envelope.dossier_digest,
    site,
    ["q11-a", "q11-c"],
  )
  ignore(@mission_adapter.save_study(root, revised))
  assert_true(revised.dossier_digest != envelope.dossier_digest)
  let revised_study = @mission_adapter.decode_study(
    revised.to_json().stringify(),
  )
  assert_eq(revised_study.parent_digest, envelope.dossier_digest)
  assert_true(revised_study.review_required)
  assert_eq(revised_study.alternatives[1].session_id, "q11-c")
  let reopened = @mission_adapter.decode_study(saved)
  assert_eq(reopened.alternatives.length(), 2)
  assert_eq(
    reopened.alternatives[0].baseline_digest,
    reopened.alternatives[1].baseline_digest,
  )
  assert_false(reopened.physical_readiness)
  guard reopened.sources
    .filter(source => source.artifact_ref == reopened.alternatives[1].result_ref)
    .get(0)
    is Some(result_source) else {
    fail("missing exact result")
  }
  let result : @robot_mission.RobotMissionResult = @json.from_json(
    @json.parse(result_source.text),
  )
  assert_true(result.energy.margin_wh < 0)
  assert_eq(result.result, "rejected")
  assert_true(
    result.blockers.any(blocker => {
      blocker.contains("absent from terrain source")
    }),
  )
  @fsx.write_string_to_file(root + "/terrain/route.csv", "changed live source")
  assert_eq(@mission_adapter.decode_study(saved), reopened)
  assert_true(
    (try? @mission_adapter.create_study(
      root,
      "local-study",
      "r2",
      envelope.dossier_digest,
      site,
      ["q11-a", "q11-b"],
    ))
    is Err(_),
  )
  @fsx.write_string_to_file(root + "/terrain/route.csv", test_dem())
  let interrupted = @mission_adapter.create_study(
    root,
    "interrupted-study",
    "r1",
    "",
    site,
    ["q11-a", "q11-b"],
  )
  let interrupted_ref = @mission_adapter.save_study(root, interrupted)
  @fsx.remove_file(root + "/" + interrupted_ref)
  let replacement = @mission_adapter.create_study(
    root,
    "interrupted-study",
    "r1",
    envelope.dossier_digest,
    site,
    ["q11-a", "q11-b"],
  )
  assert_true((try? @mission_adapter.save_study(root, replacement)) is Err(_))
  assert_eq(@mission_adapter.save_study(root, interrupted), interrupted_ref)
  assert_eq(
    @mission_adapter.decode_study(
      @fsx.read_file_to_string(root + "/" + interrupted_ref),
    ).study_id,
    "interrupted-study",
  )
  let changed = { ..reopened, site: { ..site, frame: "changed-frame", }, }
  assert_true((try? @mission_adapter.validate_study(changed)) is Err(_))
  let physical = { ..reopened, physical_readiness: true, }
  assert_true((try? @mission_adapter.validate_study(physical)) is Err(_))
  let lowered_replays = reopened.sources.map(source => {
    if source.artifact_ref == reopened.alternatives[0].replay_ref {
      let receipt : @mission_adapter.MissionReplayReceipt = @json.from_json(
        @json.parse(source.text),
      ) catch {
        _ => fail("invalid regression replay")
      }
      let text = { ..receipt, required_replays: 1, }
        .to_json()
        .stringify(indent=2)
      { ..source, text, digest: "sha256:" + study_hash(text), }
    } else {
      source
    }
  })
  assert_true(
    (try? @mission_adapter.validate_study({
      ..reopened,
      sources: lowered_replays,
    }))
    is Err(_),
  )
  let misleading_bridge = "{\"mode\":\"physical\",\"physical_transport_enabled\":true,\"design_id\":\"test-rover\",\"old\":{\"mode\":\"simulation-only\",\"physical_transport_enabled\": false}}"
  let misleading_sources = reopened.sources.map(source => {
    if source.artifact_ref == "books/test-rover/bridge/bridge.json" {
      {
        ..source,
        text: misleading_bridge,
        digest: "sha256:" + study_hash(misleading_bridge),
      }
    } else {
      source
    }
  })
  assert_true(
    (try? @mission_adapter.validate_study({
      ..reopened,
      sources: misleading_sources,
    }))
    is Err(_),
  )
  let corrupt = { ..envelope, dossier_json: envelope.dossier_json + " ", }
  assert_true(
    (try? @mission_adapter.decode_study(corrupt.to_json().stringify()))
    is Err(_),
  )
  @fsx.write_string_to_file(
    root + "/site.json",
    site.to_json().stringify(indent=2),
  )
  @fsx.write_string_to_file(root + "/exact-export.json", result_source.text)
}

///|
fn test_artifact_set_digest(
  workspace_root : String,
  artifact_refs : Array[String],
) -> String raise {
  let identities : Array[String] = []
  for artifact_ref in artifact_refs {
    let text = @fsx.read_file_to_string(workspace_root + "/" + artifact_ref)
    identities.push(
      artifact_ref +
      "|sha256:" +
      @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text))),
    )
  }
  "sha256:" +
  @crypto.bytes_to_hex_string(
    @crypto.sha256(@utf8.encode(identities.join("\n"))),
  )
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
fn test_design() -> @robot_mission.RobotMissionDesign {
  {
    contract_id: "moonsuite.robot-design.v1",
    design_id: "test-rover",
    revision: "r1",
    robot_artifact: {
      robot_id: "test-rover",
      robot_revision: "r1",
      artifact_root: "books/test-rover",
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
      payload: { mass_kg: 5.0, delivery_count: 1, },
      route_id: "bounded-path",
      source_route_id: "blocked-grid",
    },
    environment: {
      terrain_source_path: "terrain/route.csv",
      cell_size_m: 20.0,
      path_cells: [[0, 3], [1, 3], [2, 3], [3, 3]],
      whole_grid_max_neighbor_grade_deg: 35.81,
      whole_grid_status: "blocked",
      illumination: {
        terrain_available_energy_wh: 3997.25881056032,
        longest_dark_hours: 0.0,
        decision: "Allow",
      },
      dust_and_thermal: { thermal_survival_power_w: 35.0, },
      calibration: {
        contract_id: "moonmoon.digital-twin-calibration.v1",
        testbed_reference: "testbed://traction-rig/run-42",
        authoritative_source: "evidence/calibration/manifest.json",
        qualified: true,
        fault_models: [],
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
      payload_mass_kg: { min: 0.0, max: 5.0, },
      route_length_m: { min: 60.0, max: 60.0, },
      max_path_slope_deg: { min: 0.0, max: 15.0, },
      waypoint_spacing_m: { min: 0.1, max: 4.5, },
      commanded_speed_mps: { min: 0.01, max: 0.1, },
      replay_count: { min: 2.0, max: 2.0, },
      delivery_count: { min: 1.0, max: 1.0, },
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
      replay: { required_runs: 2, },
    },
  }
}

///|
fn prepare_test_workspace() -> Unit raise {
  let root = test_workspace()
  test_ensure_dir(root)
  test_ensure_dir(root + "/books")
  test_ensure_dir(root + "/books/test-rover")
  test_ensure_dir(root + "/books/test-rover/model")
  test_ensure_dir(root + "/books/test-rover/design")
  test_ensure_dir(root + "/books/test-rover/bridge")
  test_ensure_dir(root + "/terrain")
  test_ensure_dir(root + "/inputs")
  test_ensure_dir(root + "/evidence")
  @fsx.write_string_to_file(
    root + "/books/test-rover/robot.json",
    "{ \"id\": \"test-rover\" }",
  )
  @fsx.write_string_to_file(
    root + "/books/test-rover/model/robot.urdf",
    "<robot name=\"test-rover\"></robot>",
  )
  @fsx.write_string_to_file(
    root + "/books/test-rover/design/validation-receipt.json",
    "{ \"status\": \"accepted\", \"book_id\": \"test-rover\", \"physical_transport_enabled\": false }",
  )
  @fsx.write_string_to_file(
    root + "/books/test-rover/bridge/bridge.json",
    "{ \"mode\": \"simulation-only\", \"physical_transport_enabled\": false, \"design_id\": \"test-rover\" }",
  )
  @fsx.write_string_to_file(root + "/terrain/route.csv", test_dem())
  @fsx.write_string_to_file(
    root + "/inputs/mission-design.json",
    test_design().to_json().stringify(indent=2),
  )
  let integration : @mission_adapter.MoonroboDigitalIntegrationReceipt = {
    contract_id: "moonrobo.digital-model-integration-receipt.v1",
    adapter_id: "moonrobo-local-v1",
    operation_id: "robot.integrate-digital-model",
    request_id: "moonrobo-request-1",
    attempt_id: "moonrobo-attempt-1",
    idempotency_key: "moonrobo-idempotency-1",
    status: "succeeded",
    physical_execution_performed: false,
    evidence_refs: [
      "books/test-rover/design/build-receipt.json", "books/test-rover/design/validation-receipt.json",
      "books/test-rover/model/robot.urdf",
    ],
    output: {
      "accepted": true,
      "robobook_ref": "books/test-rover",
      "build_receipt_ref": "books/test-rover/design/build-receipt.json",
      "validation_receipt_ref": "books/test-rover/design/validation-receipt.json",
      "model_ref": "books/test-rover/model/robot.urdf",
      "physical_ready": false,
    },
  }
  @fsx.write_string_to_file(
    root + "/inputs/moonrobo-integration.json",
    integration.to_json().stringify(indent=2),
  )
  let run : @mission_adapter.RobotMissionRunRequest = {
    contract_id: "moonmoon.robot-mission-run-request.v1",
    session_id: "session-1",
    moonrobo_integration_receipt_ref: "inputs/moonrobo-integration.json",
    mission_design_ref: "inputs/mission-design.json",
    dataset_evidence: [],
  }
  @fsx.write_string_to_file(
    root + "/inputs/run.json",
    run.to_json().stringify(indent=2),
  )
  @fsx.write_string_to_file(
    root + "/evidence/mission-approval.json",
    "{\"contract_id\":\"moonsuite.immutable-dependency-evidence.v1\"}\n",
  )
}

///|
fn simulation_request(
  declaration_id : String,
  input_digest : String,
) -> @mission_adapter.MoonflowAdapterRequest {
  {
    request_id: "moonmoon-request-1",
    run_id: "moonflow-run-1",
    book_id: "test-rover",
    work_item_id: "simulate-1",
    declaration_id,
    attempt_id: "simulate-attempt-1",
    idempotency_key: "simulate-idempotency-1",
    product_id: "moonmoon",
    operation: "simulation.robot-mission",
    requested_authority: "sandbox-execution",
    acceptance_criteria: ["deterministic replay", "physical readiness false"],
    input_contracts: ["moonmoon/robot-mission-run-request@1.0.0"],
    output_contracts: ["moonmoon/mission-simulation-receipt@1.0.0"],
    required_claim: "scenario-qualified",
    input_digest,
    input_artifacts: ["inputs/run.json", "evidence/mission-approval.json"],
    timeout_ms: 60000,
    created_at: "2026-07-31T00:00:00Z",
  }
}

///|
fn inspection_request(
  input_digest : String,
) -> @mission_adapter.MoonflowAdapterRequest {
  {
    request_id: "moonmoon-request-2",
    run_id: "moonflow-run-1",
    book_id: "test-rover",
    work_item_id: "inspect-1",
    declaration_id: "robotics-simulation-v2",
    attempt_id: "inspect-attempt-1",
    idempotency_key: "inspect-idempotency-1",
    product_id: "moonmoon",
    operation: "simulation.mission-result.inspect",
    requested_authority: "observe",
    acceptance_criteria: ["replay and provenance inspected"],
    input_contracts: ["moonmoon/mission-result-ref@1.0.0"],
    output_contracts: ["moonmoon/mission-inspection-receipt@1.0.0"],
    required_claim: "simulation-evidence",
    input_digest,
    input_artifacts: [
      "inputs/result-ref.json", "evidence/mission-approval.json",
    ],
    timeout_ms: 60000,
    created_at: "2026-07-31T00:01:00Z",
  }
}

///|
test "graph declaration identity is required and path-safe, not the adapter identity" {
  let fixture_digest = "sha256:" + "a".repeat(64)
  let valid = simulation_request("robotics-simulation-v2", fixture_digest)
  assert_eq(valid.quality_issues(), [])
  let blank = simulation_request("  ", fixture_digest)
  assert_true(blank.quality_issues().contains("declaration_id is required"))
  let unsafe_request = simulation_request(
    "../robotics-simulation-v2", fixture_digest,
  )
  assert_true(
    unsafe_request
    .quality_issues()
    .contains("declaration_id must be a safe graph declaration identifier"),
  )
}

///|
test "adapter v2 executes, replays, inspects, reconciles, and attests without physical authority" {
  prepare_test_workspace()
  let root = test_workspace()
  let simulation_inputs = ["inputs/run.json", "evidence/mission-approval.json"]
  let simulation = simulation_request(
    "robotics-simulation-v2",
    test_artifact_set_digest(root, simulation_inputs),
  )
  assert_eq(simulation.input_artifacts[0], "inputs/run.json")
  assert_eq(simulation.input_artifacts.length(), 2)
  guard @mission_adapter.invoke(root, simulation) is Ok(first) else {
    fail("expected simulation adapter success")
  }
  assert_eq(first.status, "succeeded")
  assert_true(
    first.output_artifacts.contains(
      ".moonsuite/products/moonmoon/mission-sessions/session-1/evaluation.json",
    ),
  )
  guard @mission_adapter.invoke(root, simulation) is Ok(replayed) else {
    fail("expected idempotent adapter replay")
  }
  assert_eq(first, replayed)
  let evaluation = @fsx.read_file_to_string(
    root +
    "/.moonsuite/products/moonmoon/mission-sessions/session-1/evaluation.json",
  )
  assert_true(evaluation.contains("\"replay_verified\": true"))
  assert_true(
    evaluation.contains(
      "\"external_dataset_coverage\": \"conditional-not-declared\"",
    ),
  )
  assert_true(evaluation.contains("\"physical_readiness\": false"))
  let result_ref : @mission_adapter.MissionResultRef = {
    contract_id: "moonmoon.mission-result-ref.v1",
    session_id: "session-1",
    result_ref: ".moonsuite/products/moonmoon/mission-sessions/session-1/mission-result.json",
    provenance_ref: ".moonsuite/products/moonmoon/mission-sessions/session-1/provenance.json",
    replay_receipt_ref: ".moonsuite/products/moonmoon/mission-sessions/session-1/replay-receipt.json",
  }
  @fsx.write_string_to_file(
    root + "/inputs/result-ref.json",
    result_ref.to_json().stringify(indent=2),
  )
  let inspection_inputs = [
    "inputs/result-ref.json", "evidence/mission-approval.json",
  ]
  let inspection = inspection_request(
    test_artifact_set_digest(root, inspection_inputs),
  )
  guard @mission_adapter.invoke(root, inspection) is Ok(inspected) else {
    fail("expected persisted mission inspection")
  }
  assert_eq(inspected.status, "succeeded")
  assert_true(
    inspected.output_artifacts.contains(
      ".moonsuite/products/moonmoon/mission-sessions/session-1/inspections/inspect-attempt-1.json",
    ),
  )
  @fsx.remove_file(
    root +
    "/.moonsuite/products/moonmoon/adapter-attempts/simulate-attempt-1/adapter-result.json",
  ) catch {
    _ => ()
  }
  guard @mission_adapter.reconcile(root, simulation) is Ok(reconciled) else {
    fail("expected restart reconciliation")
  }
  assert_eq(reconciled.decision, "recovered-terminal")
  assert_false(reconciled.retry_allowed)
  guard @mission_adapter.health_attestation(
      root, "2026-07-31T00:02:00Z", "2026-07-31T00:07:00Z",
    )
    is Ok(health) else {
    fail("expected expiring adapter health evidence")
  }
  assert_eq(health.protocol, "moonflow.adapter.v2")
  assert_true(health.evidence_digest.has_prefix("sha256:"))
  assert_true(
    health.operation_refs.contains("moonmoon/simulation.robot-mission@0.1.0"),
  )
  assert_false(@mission_adapter.readiness(root).physical_effects_exposed)
}
