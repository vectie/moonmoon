///|
fn maximum_uncertainty(result : @robot_mission.RobotMissionResult) -> Double {
  let mut maximum = 0.0
  for response in result.fault_responses {
    if response.uncertainty_fraction > maximum {
      maximum = response.uncertainty_fraction
    }
  }
  maximum
}

///|
fn dataset_evidence_ready(evidence : ExternalDatasetEvidence) -> Bool {
  safe_relative_ref(evidence.evidence_ref) &&
  !evidence.dataset_id.trim().is_empty() &&
  !evidence.license_class.trim().is_empty() &&
  evidence.status == "available" &&
  digest_valid(evidence.digest)
}

///|
fn external_dataset_coverage(provenance : MissionProvenanceRecord) -> String {
  if provenance.dataset_evidence.is_empty() {
    "conditional-not-declared"
  } else if provenance.dataset_evidence.all(dataset_evidence_ready) {
    "declared-available"
  } else {
    "conditional-incomplete"
  }
}

///|
fn route_coverage(result : @robot_mission.RobotMissionResult) -> String {
  if result.whole_grid_status == "verified" {
    "enumerated-path-with-declared-grid-verification"
  } else {
    "enumerated-path-only"
  }
}

///|
fn append_unique(values : Array[String], value : String) -> Unit {
  if !values.contains(value) {
    values.push(value)
  }
}

///|
fn evaluate_result(
  session_id : String,
  result_ref : String,
  result : @robot_mission.RobotMissionResult,
  provenance_ref : String,
  provenance : MissionProvenanceRecord,
  replay_ref : String,
  replay : MissionReplayReceipt,
  recorded_at : String,
) -> MissionEvaluationReport {
  let replay_verified = replay.byte_equivalent &&
    replay.completed_replays >= replay.required_replays &&
    replay.first_result_ref == result_ref
  let blockers = result.blockers.copy()
  if !replay_verified {
    append_unique(blockers, "deterministic replay evidence is incomplete")
  }
  let limitations = result.limitations.copy()
  let dataset_coverage = external_dataset_coverage(provenance)
  if dataset_coverage != "declared-available" {
    append_unique(
      limitations, "External lunar dataset coverage is conditional until the host supplies available, licensed, digest-bound evidence.",
    )
  }
  append_unique(
    limitations, "MoonMoon evaluates digital mission evidence only; physical readiness and robot command authority remain outside this product.",
  )
  {
    contract_id: "moonmoon.mission-evaluation-report.v1",
    session_id,
    design_id: result.design_id,
    revision: result.revision,
    scenario_id: result.scenario_id,
    seed: result.seed,
    decision: if replay_verified {
      result.result
    } else {
      "rejected"
    },
    result_ref,
    provenance_ref,
    replay_receipt_ref: replay_ref,
    replay_verified,
    result_claim: if replay_verified {
      result.evidence_claim
    } else {
      "bounded-digital-simulation"
    },
    claim_ceiling: "calibrated-digital-twin",
    physical_readiness: false,
    uncertainty: {
      maximum_modeled_fraction: maximum_uncertainty(result),
      modeled_fault_count: result.fault_responses.length(),
      calibration_claim: result.evidence_claim,
      external_dataset_coverage: dataset_coverage,
      route_coverage: route_coverage(result),
    },
    blockers,
    limitations,
    review_required: true,
    recorded_at,
  }
}

///|
fn object_field(
  value : Json,
  label : String,
) -> Result[Map[String, Json], AdapterRuntimeIssue] {
  match value {
    Object(fields) => Ok(fields)
    _ =>
      Err(
        issue(
          "invalid-integration-output", label, "MoonRobo integration output must be an object",
        ),
      )
  }
}

///|
fn required_output_string(
  fields : Map[String, Json],
  name : String,
) -> Result[String, AdapterRuntimeIssue] {
  match fields.get(name) {
    Some(String(value)) if !value.trim().is_empty() => Ok(value)
    _ =>
      Err(
        issue(
          "missing-integration-output",
          name,
          "MoonRobo integration receipt requires output.\{name}",
        ),
      )
  }
}

///|
fn integration_output_accepted(fields : Map[String, Json]) -> Bool {
  fields.get("accepted") == Some(Json::boolean(true))
}

///|
fn validate_integration_binding(
  receipt : MoonroboDigitalIntegrationReceipt,
  design : @robot_mission.RobotMissionDesign,
) -> Result[Unit, AdapterRuntimeIssue] {
  if receipt.contract_id != "moonrobo.digital-model-integration-receipt.v1" ||
    receipt.adapter_id != "moonrobo-local-v1" ||
    receipt.operation_id != "robot.integrate-digital-model" {
    return Err(
      issue(
        "integration-contract-mismatch",
        receipt.contract_id,
        "simulation requires a MoonRobo digital-model integration receipt",
      ),
    )
  }
  if receipt.status != "succeeded" || receipt.physical_execution_performed {
    return Err(
      issue(
        "integration-not-accepted",
        receipt.attempt_id,
        "MoonRobo integration must succeed without physical execution",
      ),
    )
  }
  let output = match object_field(receipt.output, "output") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !integration_output_accepted(output) {
    return Err(
      issue(
        "integration-output-refused",
        receipt.attempt_id,
        "MoonRobo integration output must be accepted",
      ),
    )
  }
  let robobook_ref = match required_output_string(output, "robobook_ref") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let model_ref = match required_output_string(output, "model_ref") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let validation_ref = match
    required_output_string(output, "validation_receipt_ref") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let binding = design.robot_artifact
  if robobook_ref != binding.artifact_root ||
    model_ref != robobook_ref + "/" + binding.robot_urdf_path ||
    validation_ref != robobook_ref + "/" + binding.validation_receipt_path {
    return Err(
      issue(
        "integration-design-binding-mismatch",
        receipt.attempt_id,
        "MoonRobo integration references do not match the serialized MoonMoon mission design",
      ),
    )
  }
  if !receipt.evidence_refs.contains(model_ref) ||
    !receipt.evidence_refs.contains(validation_ref) {
    return Err(
      issue(
        "integration-evidence-incomplete",
        receipt.attempt_id,
        "MoonRobo integration receipt must carry model and validation evidence",
      ),
    )
  }
  Ok(())
}
