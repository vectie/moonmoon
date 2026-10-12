///|
/// An editable proposal, never a result or an inherited review.
pub(all) struct MissionDraftEdits {
  route_id : String
  path_cells : Array[Array[Int]]
  terrain_available_energy_wh : Double
  commanded_speed_mps : Double
  seed : Int
  injected_faults : Array[String]
  assumption_note : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionDraft {
  contract_id : String
  study_id : String
  revision : String
  parent_envelope_json : String
  parent_digest : String
  base_session_id : String
  robot_envelope_json : String
  edits : MissionDraftEdits
  review_required : Bool
  physical_execution_allowed : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionDraftEnvelope {
  contract_id : String
  draft_digest : String
  draft_json : String
} derive(Debug, Eq, ToJson, FromJson)

///|
struct RobotInputEnvelope {
  contract_id : String
  package_digest : String
  package_json : String
} derive(FromJson)

///|
struct RobotSimulationInput {
  contract_id : String
  design_id : String
  revision : String
  design_ref : String
  integration_receipt_ref : String
  robot_artifact : @robot_mission.RobotArtifactBinding
  sources : Array[StudySource]
  review_required : Bool
  physical_execution_allowed : Bool
} derive(FromJson)

///|
fn draft_local_ref(ref : String) -> Bool {
  safe_relative_ref(ref) &&
  !ref.contains(":") &&
  !ref.contains("\\") &&
  ref == ref.trim().to_owned()
}

///|
fn draft_check_sources(sources : Array[StudySource]) -> Unit raise StudyError {
  study_need(sources.length() <= 64, "Too many frozen sources")
  let seen : Map[String, Bool] = {}
  let mut total = 0
  for source in sources {
    study_need(
      draft_local_ref(source.artifact_ref) &&
      !seen.contains(source.artifact_ref),
      "Unsafe or duplicate frozen source",
    )
    seen[source.artifact_ref] = true
    let size = @utf8.encode(source.text).length()
    total += size
    study_need(
      size <= 1048576 &&
      total <= 4194304 &&
      source.digest == sha256_text(source.text),
      "Frozen source size or digest mismatch",
    )
  }
}

///|
fn draft_robot(text : String) -> RobotSimulationInput raise StudyError {
  let envelope : RobotInputEnvelope = study_decode(text)
  study_need(
    envelope.contract_id == "moonrobo.simulation-input-envelope.v1" &&
    envelope.package_digest == sha256_text(envelope.package_json),
    "Robot package digest mismatch",
  )
  let robot : RobotSimulationInput = study_decode(envelope.package_json)
  study_need(
    robot.contract_id == "moonrobo.simulation-input.v1" &&
    robot.review_required &&
    !robot.physical_execution_allowed,
    "Unsupported or physical robot package",
  )
  draft_check_sources(robot.sources)
  let binding = robot.robot_artifact
  study_need(
    study_component(robot.design_id) &&
    study_component(robot.revision) &&
    binding.robot_id == robot.design_id &&
    binding.robot_revision == robot.revision &&
    binding.validation_status == "accepted" &&
    !binding.physical_transport_enabled,
    "Robot identity or validation mismatch",
  )
  ignore(study_source(robot.sources, robot.design_ref))
  let integration : MoonroboDigitalIntegrationReceipt = study_decode(
    study_source(robot.sources, robot.integration_receipt_ref).text,
  )
  study_need(
    draft_local_ref(binding.artifact_root),
    "Unsafe robot artifact root",
  )
  for
    (path, hash) in [
      (binding.robot_json_path, binding.robot_json_sha256),
      (binding.robot_urdf_path, binding.robot_urdf_sha256),
      (binding.validation_receipt_path, binding.validation_receipt_sha256),
    ] {
    study_need(
      draft_local_ref(path) &&
      study_source(robot.sources, binding.artifact_root + "/" + path).digest ==
      "sha256:" + hash,
      "Robot artifact hash mismatch",
    )
  }
  study_need(
    draft_local_ref(binding.bridge_config_path),
    "Unsafe robot bridge reference",
  )
  let bridge : Json = study_decode(
    study_source(
      robot.sources,
      binding.artifact_root + "/" + binding.bridge_config_path,
    ).text,
  )
  study_need(
    match bridge {
      Object(fields) =>
        fields.get("mode") == Some(Json::string("simulation-only")) &&
        fields.get("physical_transport_enabled") == Some(Json::boolean(false)) &&
        fields.get("design_id") == Some(Json::string(binding.robot_id))
      _ => false
    },
    "Robot bridge must remain simulation-only",
  )
  for reference in integration.evidence_refs {
    ignore(study_source(robot.sources, reference))
  }
  robot
}

///|
/// Checks the exact parent and robot sources without writing or simulating a draft.
pub fn decode_mission_draft(text : String) -> MissionDraft raise StudyError {
  study_need(
    @utf8.encode(text).length() <= 16777216,
    "Draft envelope exceeds 16 MiB",
  )
  let envelope : MissionDraftEnvelope = study_decode(text)
  study_need(
    envelope.contract_id == "moonmoon.mission-draft-envelope.v1" &&
    envelope.draft_digest == sha256_text(envelope.draft_json),
    "Draft digest mismatch",
  )
  let draft : MissionDraft = study_decode(envelope.draft_json)
  validate_single_draft(draft)
  draft
}

///|
fn validate_single_draft(draft : MissionDraft) -> Unit raise StudyError {
  study_need(
    draft.contract_id == "moonmoon.mission-draft.v1" &&
    draft.review_required &&
    !draft.physical_execution_allowed &&
    study_component(draft.study_id) &&
    study_component(draft.revision),
    "Unsupported or physical mission draft",
  )
  let parent = decode_study(draft.parent_envelope_json)
  let parent_envelope : StudyEnvelope = study_decode(draft.parent_envelope_json)
  study_need(
    draft.parent_digest == parent_envelope.dossier_digest,
    "Draft parent digest mismatch",
  )
  study_need(
    draft.study_id != parent.study_id || draft.revision != parent.revision,
    "Fork requires a new study or revision; original review is preserved",
  )
  study_need(
    parent.alternatives.any(item => item.session_id == draft.base_session_id),
    "Unknown parent alternative",
  )
  draft_check_sources(parent.sources)
  draft_validate_edits(draft.edits)
  if draft.robot_envelope_json != "" {
    let robot = draft_robot(draft.robot_envelope_json)
    let alternative = parent.alternatives.filter(item => {
        item.session_id == draft.base_session_id
      })[0]
    let original : @robot_mission.RobotMissionDesign = study_decode(
      study_source(parent.sources, alternative.design_ref).text,
    )
    let integration : MoonroboDigitalIntegrationReceipt = study_decode(
      study_source(robot.sources, robot.integration_receipt_ref).text,
    )
    match
      validate_integration_binding(integration, {
        ..original,
        design_id: robot.design_id,
        revision: robot.revision,
        robot_artifact: robot.robot_artifact,
      }) {
      Ok(_) => ()
      Err(error) => raise InvalidStudy(error.message)
    }
  }
}

///|
fn draft_validate_edits(edits : MissionDraftEdits) -> Unit raise StudyError {
  study_need(
    study_component(edits.route_id) &&
    edits.assumption_note.trim() != "" &&
    edits.assumption_note.length() <= 2000,
    "Name the route and document the changed assumptions",
  )
  study_need(
    edits.path_cells.length() >= 2 &&
    edits.path_cells.length() <= 256 &&
    edits.path_cells.all(cell => {
      cell.length() == 2 && cell.all(value => value >= 0 && value <= 1000000)
    }),
    "Route needs 2–256 nonnegative row/column pairs",
  )
  study_need(
    edits.terrain_available_energy_wh >= 0.0 &&
    edits.terrain_available_energy_wh <= 1000000000.0 &&
    edits.commanded_speed_mps > 0.0 &&
    edits.commanded_speed_mps <= 1000.0 &&
    edits.seed > 0,
    "Invalid finite energy, speed or deterministic seed",
  )
  study_need(
    edits.injected_faults.length() <= 16 &&
    edits.injected_faults.all(study_component) &&
    unique_strings(edits.injected_faults).length() ==
    edits.injected_faults.length(),
    "Fault IDs must be unique safe names, at most 16",
  )
}

///|
fn draft_write(
  root : String,
  ref : String,
  text : String,
) -> Unit raise StudyError {
  study_need(draft_local_ref(ref), "Unsafe draft output path")
  let path = root + "/" + ref
  if @fsx.path_exists(path) {
    study_need(
      study_read(path) == text,
      "Frozen source collision; nothing is overwritten: " + ref,
    )
  } else {
    match write_text(path, text) {
      Ok(_) => ()
      Err(error) => raise InvalidStudy(error.message)
    }
  }
}

///|
/// Recompute expected numeric fields with the existing simulator, never JS physics.
/// Constraints, calibration, unknown hazards and safety gates remain unchanged.
fn draft_prepare(
  design : @robot_mission.RobotMissionDesign,
  terrain : String,
) -> @robot_mission.RobotMissionDesign {
  let result = @robot_mission.simulate(design, terrain)
  let path = design.verification_criteria.path
  {
    ..design,
    verification_criteria: {
      ..design.verification_criteria,
      path: {
        ..path,
        distance_m: result.distance_m,
        waypoint_count: (result.distance_m / path.waypoint_spacing_m)
        .ceil()
        .to_int() +
        1,
        drive_duration_s: result.duration_s,
        maximum_measured_segment_slope_deg: result.maximum_measured_segment_slope_deg,
      },
      energy: {
        drive_energy_wh: result.energy.drive_wh,
        comms_energy_wh: result.energy.comms_wh,
        thermal_survival_energy_wh: result.energy.thermal_survival_wh,
        reserve_wh: result.energy.reserve_wh,
        bounded_required_energy_wh: result.energy.required_wh,
        verified_available_energy_wh: result.energy.available_wh,
        expected_margin_wh: result.energy.margin_wh,
      },
    },
  }
}

///|
fn draft_run_session(
  root : String,
  session : String,
  integration_ref : String,
  design : @robot_mission.RobotMissionDesign,
  dataset_evidence : Array[ExternalDatasetEvidence],
  draft_ref : String,
) -> Unit raise StudyError {
  let design_ref = "authored/" + session + "/design.json"
  let run_ref = "authored/" + session + "/run.json"
  draft_write(root, design_ref, design.to_json().stringify(indent=2) + "\n")
  let input : RobotMissionRunRequest = {
    contract_id: "moonmoon.robot-mission-run-request.v1",
    session_id: session,
    moonrobo_integration_receipt_ref: integration_ref,
    mission_design_ref: design_ref,
    dataset_evidence,
  }
  draft_write(root, run_ref, input.to_json().stringify(indent=2) + "\n")
  let input_digest = match
    input_artifact_set_digest(root, [run_ref, draft_ref]) {
    Ok(value) => value
    Err(error) => raise InvalidStudy(error.message)
  }
  let request : MoonflowAdapterRequest = {
    request_id: session,
    run_id: session,
    book_id: design.design_id,
    work_item_id: session,
    declaration_id: "local-mission-authoring-v1",
    attempt_id: session,
    idempotency_key: session,
    product_id: "moonmoon",
    operation: "simulation.robot-mission",
    requested_authority: "sandbox-execution",
    acceptance_criteria: ["deterministic replay", "physical readiness false"],
    input_contracts: ["moonmoon/robot-mission-run-request@1.0.0"],
    output_contracts: ["moonmoon/mission-simulation-receipt@1.0.0"],
    required_claim: "simulation-evidence",
    input_digest,
    input_artifacts: [run_ref, draft_ref],
    timeout_ms: 60000,
    created_at: "local-frozen-draft",
  }
  match invoke(root, request) {
    Ok(value) =>
      study_need(
        value.status == "succeeded",
        "Draft simulation failed; preserve its evidence and inspect the adapter receipt",
      )
    Err(error) => raise InvalidStudy(error.message)
  }
}

///|
/// Execute a frozen proposal into a NEW workspace. Never overwrite parent evidence.
/// V1 produces a reference and edited run; v2 produces one reference plus all
/// named variants. Robot adoption clears calibration on every alternative.
pub fn run_mission_draft(
  text : String,
  new_root : String,
) -> StudyEnvelope raise StudyError {
  study_need(
    @utf8.encode(text).length() <= 16777216,
    "Draft envelope exceeds 16 MiB",
  )
  let input : MissionDraftEnvelope = study_decode(text)
  let (draft, variants) = if input.contract_id ==
    "moonmoon.mission-draft-envelope.v2" {
    let sensitivity = decode_sensitivity_draft(text)
    (sensitivity_single(sensitivity), sensitivity.variants)
  } else {
    let single = decode_mission_draft(text)
    (
      single,
      [
        {
          variant_id: "alternative",
          name: "Edited mission",
          edits: single.edits,
        },
      ],
    )
  }
  study_need(
    new_root.trim() != "" && !@fsx.path_exists(new_root),
    "Output workspace must not exist; choose a new directory",
  )
  let parent = decode_study(draft.parent_envelope_json)
  let alternative = parent.alternatives.filter(item => {
      item.session_id == draft.base_session_id
    })[0]
  let original : @robot_mission.RobotMissionDesign = study_decode(
    study_source(parent.sources, alternative.design_ref).text,
  )
  let provenance : MissionProvenanceRecord = study_decode(
    study_source(parent.sources, alternative.provenance_ref).text,
  )
  let robot = if draft.robot_envelope_json == "" {
    None
  } else {
    Some(draft_robot(draft.robot_envelope_json))
  }
  let baseline = match robot {
    None => original
    Some(robot) =>
      {
        ..original,
        design_id: robot.design_id,
        revision: robot.revision,
        robot_artifact: robot.robot_artifact,
        environment: {
          ..original.environment,
          calibration: {
            ..original.environment.calibration,
            qualified: false,
            fault_models: [],
            testbed_reference: "unqualified:robot-input-adoption",
          },
        },
      }
  }
  let integration_ref = match robot {
    None => provenance.moonrobo_integration_receipt_ref
    Some(robot) => robot.integration_receipt_ref
  }
  let integration_sources = match robot {
    None => parent.sources
    Some(robot) => robot.sources
  }
  let integration : MoonroboDigitalIntegrationReceipt = study_decode(
    study_source(integration_sources, integration_ref).text,
  )
  match validate_integration_binding(integration, baseline) {
    Ok(_) => ()
    Err(error) => raise InvalidStudy(error.message)
  }
  // Preflight collisions before any file writes.
  let sources = parent.sources.copy()
  if robot is Some(robot) {
    for source in robot.sources {
      if sources.any(item => item.artifact_ref == source.artifact_ref) {
        study_need(
          study_source(sources, source.artifact_ref) == source,
          "Robot source collides with frozen parent; use a distinct robot revision",
        )
      } else {
        sources.push(source)
      }
    }
  }
  draft_check_sources(sources)
  let suffix = sha256_text(text)[7:23].to_owned()
  let reference_session = "authored-" + suffix + "-reference"
  let sessions = [reference_session] +
    variants.map(item => "authored-" + suffix + "-" + item.variant_id)
  let draft_ref = "authored/" + suffix + "/draft.json"
  study_need(
    sources.all(source => {
      sessions.all(session => {
        !source.artifact_ref.has_prefix("authored/" + session + "/")
      }) &&
      source.artifact_ref != draft_ref
    }),
    "Draft output identity collides with frozen parent",
  )
  let terrain = study_source(
      parent.sources,
      original.environment.terrain_source_path,
    ).text
  for source in sources {
    draft_write(new_root, source.artifact_ref, source.text)
  }
  draft_write(new_root, draft_ref, text)
  // One shared reference adapter session per batch. Its normal deterministic
  // replay and dossier integrity checks remain mandatory, as for every variant.
  draft_run_session(
    new_root,
    reference_session,
    integration_ref,
    draft_prepare(baseline, terrain),
    provenance.dataset_evidence,
    draft_ref,
  )
  for index, variant in variants {
    let edits = variant.edits
    let edited = {
      ..baseline,
      mission: { ..baseline.mission, route_id: edits.route_id, },
      scenario: {
        ..baseline.scenario,
        scenario_id: "authored-" + variant.variant_id,
        seed: edits.seed,
        scenario_kind: if edits.injected_faults.is_empty() {
          "nominal"
        } else {
          "fault-injection"
        },
        injected_faults: edits.injected_faults.copy(),
      },
      environment: {
        ..baseline.environment,
        path_cells: edits.path_cells.copy(),
        illumination: {
          ..baseline.environment.illumination,
          terrain_available_energy_wh: edits.terrain_available_energy_wh,
        },
      },
      verification_criteria: {
        ..baseline.verification_criteria,
        path: {
          ..baseline.verification_criteria.path,
          commanded_speed_mps: edits.commanded_speed_mps,
        },
      },
    }
    draft_run_session(
      new_root,
      sessions[index + 1],
      integration_ref,
      draft_prepare(edited, terrain),
      provenance.dataset_evidence,
      draft_ref,
    )
  }
  let envelope = create_study(
    new_root,
    draft.study_id,
    draft.revision,
    draft.parent_digest,
    parent.site,
    sessions,
  )
  let study : MissionStudy = study_decode(envelope.dossier_json)
  let updated = {
    ..study,
    limitations: study.limitations +
    (if input.contract_id == "moonmoon.mission-draft-envelope.v1" {
      ["Authored assumption: " + draft.edits.assumption_note]
    } else {
      variants.map(item => {
        let description : Json = {
          "variant_id": item.variant_id,
          "name": item.name,
          "assumption_note": item.edits.assumption_note,
        }
        "Authored variant: " + description.stringify()
      })
    }) +
    [
      "Expected numeric criteria were prepared by the native simulator. They are not independent measured validation. Original constraints and safety gates remain in force.",
      if robot is Some(_) {
        if input.contract_id == "moonmoon.mission-draft-envelope.v1" {
          "Robot baseline changed. Both displayed alternatives use the newly imported robot; comparison to the parent robot is not supported. Prior calibration was cleared."
        } else {
          "Robot baseline changed. Every displayed alternative uses the newly imported robot; comparison to the parent robot is not supported. Prior calibration was cleared."
        }
      } else if input.contract_id == "moonmoon.mission-draft-envelope.v1" {
        "Reference and edited run share the exact parent robot, site, terrain and calibration baseline."
      } else {
        "Reference and all variants share the exact parent robot, site, terrain and calibration baseline."
      },
    ],
  }
  validate_study(updated)
  let dossier_json = updated.to_json().stringify(indent=2) + "\n"
  let result : StudyEnvelope = {
    contract_id: "moonmoon.mission-study-envelope.v1",
    dossier_digest: sha256_text(dossier_json),
    dossier_json,
  }
  ignore(save_study(new_root, result))
  result
}
