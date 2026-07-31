///|
fn decode_run_request(
  path : String,
  text : String,
) -> Result[RobotMissionRunRequest, AdapterRuntimeIssue] {
  let value = @json.parse(text) catch {
    _ =>
      return Err(
        issue(
          "parse-mission-run-request", path, "failed to parse moonmoon.robot-mission-run-request.v1",
        ),
      )
  }
  let input : RobotMissionRunRequest = @json.from_json(value) catch {
    _ =>
      return Err(
        issue(
          "decode-mission-run-request", path, "failed to decode moonmoon.robot-mission-run-request.v1",
        ),
      )
  }
  if input.contract_id != "moonmoon.robot-mission-run-request.v1" {
    return Err(
      issue(
        "unsupported-mission-run-contract", path, "expected moonmoon.robot-mission-run-request.v1",
      ),
    )
  }
  if !safe_component(input.session_id) {
    return Err(
      issue(
        "invalid-session-id",
        input.session_id,
        "mission session id must be a safe path component",
      ),
    )
  }
  if !safe_relative_ref(input.moonrobo_integration_receipt_ref) ||
    !safe_relative_ref(input.mission_design_ref) {
    return Err(
      issue(
        "unsafe-mission-input-ref", path, "integration and mission design references must be workspace-relative",
      ),
    )
  }
  for evidence in input.dataset_evidence {
    if !safe_relative_ref(evidence.evidence_ref) {
      return Err(
        issue(
          "unsafe-dataset-evidence-ref",
          evidence.evidence_ref,
          "dataset evidence references must be workspace-relative",
        ),
      )
    }
  }
  Ok(input)
}

///|
fn decode_result_ref(
  path : String,
  text : String,
) -> Result[MissionResultRef, AdapterRuntimeIssue] {
  let value = @json.parse(text) catch {
    _ =>
      return Err(
        issue(
          "parse-mission-result-ref", path, "failed to parse moonmoon.mission-result-ref.v1",
        ),
      )
  }
  let input : MissionResultRef = @json.from_json(value) catch {
    _ =>
      return Err(
        issue(
          "decode-mission-result-ref", path, "failed to decode moonmoon.mission-result-ref.v1",
        ),
      )
  }
  if input.contract_id != "moonmoon.mission-result-ref.v1" ||
    !safe_component(input.session_id) ||
    !safe_relative_ref(input.result_ref) ||
    !safe_relative_ref(input.provenance_ref) ||
    !safe_relative_ref(input.replay_receipt_ref) {
    return Err(
      issue(
        "invalid-mission-result-ref", path, "mission result reference has an unsupported contract, session, or artifact path",
      ),
    )
  }
  Ok(input)
}

///|
fn session_artifact_refs(session_id : String) -> Array[String] {
  [
    mission_result_ref(session_id),
    replay_result_ref(session_id),
    replay_receipt_ref(session_id),
    provenance_ref(session_id),
    evaluation_ref(session_id),
  ]
}

///|
fn simulation_receipt_from_session(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  contract : AdapterOperationContract,
  input_ref : String,
  input : RobotMissionRunRequest,
) -> Result[AdapterOperationReceipt, AdapterRuntimeIssue] {
  let refs = session_artifact_refs(input.session_id)
  if !all_exist(workspace_root, refs) {
    return Err(
      issue(
        "mission-session-incomplete",
        session_root_ref(input.session_id),
        "mission session does not contain complete result, replay, provenance, and evaluation evidence",
      ),
    )
  }
  let provenance_path = match
    resolve_ref(workspace_root, provenance_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let provenance : MissionProvenanceRecord = match read_typed(provenance_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if provenance.session_id != input.session_id ||
    provenance.moonrobo_integration_receipt_ref !=
    input.moonrobo_integration_receipt_ref ||
    provenance.mission_design_ref != input.mission_design_ref {
    return Err(
      issue(
        "mission-session-identity-conflict",
        provenance_ref(input.session_id),
        "existing mission session belongs to different serialized inputs",
      ),
    )
  }
  let evaluation_path = match
    resolve_ref(workspace_root, evaluation_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let evaluation : MissionEvaluationReport = match read_typed(evaluation_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    contract_id: output_artifact_contract_id(contract),
    adapter_id: adapter_id(),
    operation_id: contract.operation_id,
    operation_version: contract.version,
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    status: "succeeded",
    authority_class: contract.authority_class,
    physical_execution_performed: false,
    input_digest: request.input_digest,
    observed_input_digests: provenance.source_digests.copy(),
    evidence_refs: [input_ref] + refs,
    output_contract: contract.output_contracts[0],
    output: {
      "accepted": evaluation.decision == "accepted",
      "session_id": input.session_id,
      "result_ref": mission_result_ref(input.session_id),
      "replay_receipt_ref": replay_receipt_ref(input.session_id),
      "provenance_ref": provenance_ref(input.session_id),
      "evaluation_ref": evaluation_ref(input.session_id),
      "result_claim": evaluation.result_claim,
      "physical_readiness": false,
      "review_required": true,
      "recovered_from_session": true,
    },
    error_kind: "",
    message: "MoonMoon reused the exact durable digital mission session; no physical effect occurred.",
    recorded_at: request.created_at,
  })
}

///|
fn execute_simulation(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  contract : AdapterOperationContract,
) -> Result[AdapterOperationReceipt, AdapterRuntimeIssue] {
  let (input_ref, input_path, input_text) = match
    input_artifact(workspace_root, request) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let input = match decode_run_request(input_path, input_text) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let refs = session_artifact_refs(input.session_id)
  if all_exist(workspace_root, refs) {
    return simulation_receipt_from_session(
      workspace_root, request, contract, input_ref, input,
    )
  }
  if any_exist(workspace_root, refs) {
    return Err(
      issue(
        "mission-session-partial",
        session_root_ref(input.session_id),
        "partial mission session evidence exists; reconcile before retry",
      ),
    )
  }
  let integration_path = match
    resolve_ref(workspace_root, input.moonrobo_integration_receipt_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let integration_text = match read_text(integration_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let integration : MoonroboDigitalIntegrationReceipt = match
    read_typed(integration_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let design_path = match
    resolve_ref(workspace_root, input.mission_design_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let design_text = match read_text(design_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let design : @robot_mission.RobotMissionDesign = @json.from_json(
    @json.parse(design_text),
  ) catch {
    _ =>
      return Err(
        issue(
          "decode-mission-design",
          input.mission_design_ref,
          "failed to decode the serialized MoonMoon robot mission design",
        ),
      )
  }
  match validate_integration_binding(integration, design) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  if !safe_relative_ref(design.environment.terrain_source_path) {
    return Err(
      issue(
        "unsafe-terrain-ref",
        design.environment.terrain_source_path,
        "terrain source must be workspace-relative",
      ),
    )
  }
  let terrain_path = match
    resolve_ref(workspace_root, design.environment.terrain_source_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let terrain_text = match read_text(terrain_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let result_path = match
    resolve_ref(workspace_root, mission_result_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let replay_path = match
    resolve_ref(workspace_root, replay_result_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match ensure_directory_tree(@pathx.dirname(result_path).to_owned()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let first = match
    @robot_mission.simulate_files(design_path, workspace_root, result_path) {
    Ok(value) => value
    Err(error) =>
      return Err(
        issue("mission-simulation-failed", input.mission_design_ref, error),
      )
  }
  let first_text = first.to_json().stringify(indent=2) + "\n"
  let completed_replays = if first.replay_count > 1 {
    first.replay_count
  } else {
    2
  }
  let mut replay_text = ""
  let mut replay_matches = true
  for _ in 1..<completed_replays {
    let replayed = match
      @robot_mission.simulate_files(design_path, workspace_root, replay_path) {
      Ok(value) => value
      Err(error) =>
        return Err(
          issue("mission-replay-failed", input.mission_design_ref, error),
        )
    }
    replay_text = replayed.to_json().stringify(indent=2) + "\n"
    if first_text != replay_text {
      replay_matches = false
    }
  }
  let replay_receipt : MissionReplayReceipt = {
    contract_id: "moonmoon.mission-replay-receipt.v1",
    session_id: input.session_id,
    design_id: first.design_id,
    scenario_id: first.scenario_id,
    seed: first.seed,
    required_replays: first.replay_count,
    completed_replays,
    byte_equivalent: replay_matches,
    first_result_ref: mission_result_ref(input.session_id),
    replay_result_ref: replay_result_ref(input.session_id),
    first_result_digest: sha256_text(first_text),
    replay_result_digest: sha256_text(replay_text),
    recorded_at: request.created_at,
  }
  let replay_receipt_path = match
    resolve_ref(workspace_root, replay_receipt_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(replay_receipt_path, replay_receipt.to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let provenance : MissionProvenanceRecord = {
    contract_id: "moonmoon.mission-provenance.v1",
    session_id: input.session_id,
    moonrobo_integration_receipt_ref: input.moonrobo_integration_receipt_ref,
    mission_design_ref: input.mission_design_ref,
    terrain_ref: design.environment.terrain_source_path,
    result_ref: mission_result_ref(input.session_id),
    replay_receipt_ref: replay_receipt_ref(input.session_id),
    source_refs: [
      input.moonrobo_integration_receipt_ref,
      input.mission_design_ref,
      design.environment.terrain_source_path,
    ] +
    integration.evidence_refs,
    source_digests: [
      sha256_text(integration_text),
      sha256_text(design_text),
      sha256_text(terrain_text),
      sha256_text(first_text),
    ],
    dataset_evidence: input.dataset_evidence.copy(),
    recorded_at: request.created_at,
  }
  let provenance_path = match
    resolve_ref(workspace_root, provenance_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(provenance_path, provenance.to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let evaluation = evaluate_result(
    input.session_id,
    mission_result_ref(input.session_id),
    first,
    provenance_ref(input.session_id),
    provenance,
    replay_receipt_ref(input.session_id),
    replay_receipt,
    request.created_at,
  )
  let evaluation_path = match
    resolve_ref(workspace_root, evaluation_ref(input.session_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(evaluation_path, evaluation.to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok({
    contract_id: output_artifact_contract_id(contract),
    adapter_id: adapter_id(),
    operation_id: contract.operation_id,
    operation_version: contract.version,
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    status: if replay_matches {
      "succeeded"
    } else {
      "failed"
    },
    authority_class: contract.authority_class,
    physical_execution_performed: false,
    input_digest: request.input_digest,
    observed_input_digests: provenance.source_digests.copy(),
    evidence_refs: [input_ref] + session_artifact_refs(input.session_id),
    output_contract: contract.output_contracts[0],
    output: {
      "accepted": replay_matches && evaluation.decision == "accepted",
      "session_id": input.session_id,
      "result_ref": mission_result_ref(input.session_id),
      "replay_receipt_ref": replay_receipt_ref(input.session_id),
      "provenance_ref": provenance_ref(input.session_id),
      "evaluation_ref": evaluation_ref(input.session_id),
      "result_claim": evaluation.result_claim,
      "external_dataset_coverage": evaluation.uncertainty.external_dataset_coverage,
      "physical_readiness": false,
      "review_required": true,
    },
    error_kind: if replay_matches {
      ""
    } else {
      "replay-diverged"
    },
    message: if replay_matches {
      "MoonMoon completed a deterministic, replayed digital mission evaluation; result acceptance remains reviewable and never establishes physical readiness."
    } else {
      "MoonMoon preserved divergent replay evidence and refused the simulation result."
    },
    recorded_at: request.created_at,
  })
}

///|
fn execute_inspection(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  contract : AdapterOperationContract,
) -> Result[AdapterOperationReceipt, AdapterRuntimeIssue] {
  let (input_ref, input_path, input_text) = match
    input_artifact(workspace_root, request) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let input = match decode_result_ref(input_path, input_text) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let result_path = match resolve_ref(workspace_root, input.result_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let result_text = match read_text(result_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let result : @robot_mission.RobotMissionResult = match
    read_typed(result_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let provenance_path = match
    resolve_ref(workspace_root, input.provenance_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let provenance : MissionProvenanceRecord = match read_typed(provenance_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let replay_path = match
    resolve_ref(workspace_root, input.replay_receipt_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let replay : MissionReplayReceipt = match read_typed(replay_path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if provenance.session_id != input.session_id ||
    replay.session_id != input.session_id ||
    provenance.result_ref != input.result_ref {
    return Err(
      issue(
        "mission-result-identity-conflict", input_ref, "result, provenance, and replay artifacts do not share one mission session",
      ),
    )
  }
  let evaluation = evaluate_result(
    input.session_id,
    input.result_ref,
    result,
    input.provenance_ref,
    provenance,
    input.replay_receipt_ref,
    replay,
    request.created_at,
  )
  let output_ref = inspection_ref(input.session_id, request.attempt_id)
  let output_path = match resolve_ref(workspace_root, output_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if @fsx.path_exists(output_path) {
    let persisted : MissionEvaluationReport = match read_typed(output_path) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    if persisted != evaluation {
      return Err(
        issue(
          "inspection-attempt-conflict", output_ref, "inspection attempt already contains a different evaluation",
        ),
      )
    }
  } else {
    match write_json(output_path, evaluation.to_json()) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok({
    contract_id: output_artifact_contract_id(contract),
    adapter_id: adapter_id(),
    operation_id: contract.operation_id,
    operation_version: contract.version,
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    status: "succeeded",
    authority_class: contract.authority_class,
    physical_execution_performed: false,
    input_digest: request.input_digest,
    observed_input_digests: [sha256_text(input_text), sha256_text(result_text)],
    evidence_refs: [
      input_ref,
      input.result_ref,
      input.provenance_ref,
      input.replay_receipt_ref,
      output_ref,
    ],
    output_contract: contract.output_contracts[0],
    output: {
      "session_id": input.session_id,
      "evaluation_ref": output_ref,
      "decision": evaluation.decision,
      "result_claim": evaluation.result_claim,
      "replay_verified": evaluation.replay_verified,
      "physical_readiness": false,
      "review_required": true,
    },
    error_kind: "",
    message: "MoonMoon independently inspected persisted mission, replay, provenance, and uncertainty evidence.",
    recorded_at: request.created_at,
  })
}

///|
fn execute_operation(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  contract : AdapterOperationContract,
) -> Result[AdapterOperationReceipt, AdapterRuntimeIssue] {
  match request.operation {
    "simulation.robot-mission" =>
      execute_simulation(workspace_root, request, contract)
    "simulation.mission-result.inspect" =>
      execute_inspection(workspace_root, request, contract)
    operation =>
      Err(
        issue(
          "unsupported-operation", operation, "MoonMoon adapter does not expose this operation",
        ),
      )
  }
}

///|
fn operation_failure_receipt(
  request : MoonflowAdapterRequest,
  contract : AdapterOperationContract,
  error : AdapterRuntimeIssue,
) -> AdapterOperationReceipt {
  {
    contract_id: output_artifact_contract_id(contract),
    adapter_id: adapter_id(),
    operation_id: contract.operation_id,
    operation_version: contract.version,
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    status: "failed",
    authority_class: contract.authority_class,
    physical_execution_performed: false,
    input_digest: request.input_digest,
    observed_input_digests: [],
    evidence_refs: [],
    output_contract: contract.output_contracts[0],
    output: { "issue": error },
    error_kind: error.code,
    message: error.message,
    recorded_at: request.created_at,
  }
}

///|
fn running_record(request : MoonflowAdapterRequest) -> AdapterAttemptRecord {
  {
    contract_id: "moonmoon.adapter-attempt.v1",
    adapter_id: adapter_id(),
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    operation: request.operation,
    status: "running",
    request_ref: request_ref(request.attempt_id),
    operation_receipt_ref: operation_receipt_ref(request.attempt_id),
    adapter_result_ref: adapter_result_ref(request.attempt_id),
    started_at: request.created_at,
    updated_at: request.created_at,
  }
}

///|
fn adapter_result_from_receipt(
  request : MoonflowAdapterRequest,
  receipt : AdapterOperationReceipt,
) -> MoonflowAdapterResult {
  let receipt_ref = operation_receipt_ref(request.attempt_id)
  let artifacts = receipt.evidence_refs.copy()
  if !artifacts.contains(receipt_ref) {
    artifacts.push(receipt_ref)
  }
  {
    result_id: "moonmoon-result-\{request.attempt_id}-\{receipt.status}",
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    product_id: "moonmoon",
    external_job_id: "moonmoon-local-\{request.attempt_id}",
    status: receipt.status,
    output_digest: if receipt.status == "succeeded" {
      sha256_text(receipt.to_json().stringify())
    } else {
      ""
    },
    output_artifacts: artifacts,
    error_kind: receipt.error_kind,
    compensable: false,
    recorded_at: receipt.recorded_at,
  }
}

///|
fn persist_terminal(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  receipt : AdapterOperationReceipt,
) -> Result[MoonflowAdapterResult, AdapterRuntimeIssue] {
  let receipt_path = match
    resolve_ref(workspace_root, operation_receipt_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(receipt_path, receipt.to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let result = adapter_result_from_receipt(request, receipt)
  let result_path = match
    resolve_ref(workspace_root, adapter_result_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(result_path, result.to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let state = {
    ..running_record(request),
    status: result.status,
    updated_at: result.recorded_at,
  }
  let state_path = match
    resolve_ref(workspace_root, state_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(state_path, state.to_json()) {
    Ok(_) => Ok(result)
    Err(error) => Err(error)
  }
}

///|
fn existing_result(
  workspace_root : String,
  request : MoonflowAdapterRequest,
) -> Result[MoonflowAdapterResult?, AdapterRuntimeIssue] {
  let path = match
    resolve_ref(workspace_root, adapter_result_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !@fsx.path_exists(path) {
    return Ok(None)
  }
  let result : MoonflowAdapterResult = match read_typed(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !same_attempt_identity(request, result) {
    return Err(
      issue(
        "attempt-identity-conflict", path, "persisted result does not match request, attempt, and idempotency identity",
      ),
    )
  }
  Ok(Some(result))
}

///|
pub fn invoke(
  workspace_root : String,
  request : MoonflowAdapterRequest,
) -> Result[MoonflowAdapterResult, AdapterRuntimeIssue] {
  let issues = request.quality_issues()
  if !issues.is_empty() {
    return Err(
      issue("invalid-adapter-request", request.operation, issues.join("; ")),
    )
  }
  let observed_input_digest = match
    input_artifact_set_digest(workspace_root, request.input_artifacts) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if observed_input_digest != request.input_digest {
    return Err(
      issue(
        "input-digest-mismatch",
        request.input_artifacts[0],
        "MoonFlow input_digest does not match the ordered input artifact set",
      ),
    )
  }
  match existing_result(workspace_root, request) {
    Ok(Some(result)) => return Ok(result)
    Ok(None) => ()
    Err(error) => return Err(error)
  }
  let state_path = match
    resolve_ref(workspace_root, state_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if @fsx.path_exists(state_path) {
    return Err(
      issue(
        "attempt-outcome-unknown",
        state_ref(request.attempt_id),
        "adapter attempt already started without a terminal result; reconcile before retry",
      ),
    )
  }
  let request_path = match
    resolve_ref(workspace_root, request_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(request_path, request.to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match write_json(state_path, running_record(request).to_json()) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  let contract = match find_operation_contract(request.operation) {
    Some(value) => value
    None =>
      return Err(
        issue(
          "unsupported-operation",
          request.operation,
          "MoonMoon adapter operation is not declared",
        ),
      )
  }
  let receipt = match execute_operation(workspace_root, request, contract) {
    Ok(value) => value
    Err(error) => operation_failure_receipt(request, contract, error)
  }
  persist_terminal(workspace_root, request, receipt)
}

///|
fn reconciliation_report(
  request : MoonflowAdapterRequest,
  decision : String,
  retry_allowed : Bool,
  evidence_refs : Array[String],
  result : MoonflowAdapterResult,
  message : String,
) -> AdapterReconciliationReport {
  {
    contract_id: "moonmoon.adapter-reconciliation.v1",
    adapter_id: adapter_id(),
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    decision,
    retry_allowed,
    evidence_refs,
    result,
    message,
    recorded_at: request.created_at,
  }
}

///|
fn persist_reconciliation(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  report : AdapterReconciliationReport,
) -> Result[AdapterReconciliationReport, AdapterRuntimeIssue] {
  let path = match
    resolve_ref(workspace_root, reconciliation_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match write_json(path, report.to_json()) {
    Ok(_) => Ok(report)
    Err(error) => Err(error)
  }
}

///|
fn persisted_operation_receipt(
  workspace_root : String,
  request : MoonflowAdapterRequest,
) -> Result[AdapterOperationReceipt?, AdapterRuntimeIssue] {
  let path = match
    resolve_ref(workspace_root, operation_receipt_ref(request.attempt_id)) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if !@fsx.path_exists(path) {
    return Ok(None)
  }
  let receipt : AdapterOperationReceipt = match read_typed(path) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if receipt.request_id != request.request_id ||
    receipt.attempt_id != request.attempt_id ||
    receipt.idempotency_key != request.idempotency_key {
    return Err(
      issue(
        "operation-receipt-identity-conflict", path, "persisted operation receipt does not match the MoonFlow attempt identity",
      ),
    )
  }
  Ok(Some(receipt))
}

///|
fn unknown_result(request : MoonflowAdapterRequest) -> MoonflowAdapterResult {
  {
    result_id: "moonmoon-result-\{request.attempt_id}-unknown",
    request_id: request.request_id,
    attempt_id: request.attempt_id,
    idempotency_key: request.idempotency_key,
    product_id: "moonmoon",
    external_job_id: "moonmoon-local-\{request.attempt_id}",
    status: "unknown",
    output_digest: "",
    output_artifacts: [],
    error_kind: "unknown-outcome",
    compensable: false,
    recorded_at: request.created_at,
  }
}

///|
fn recover_operation_receipt(
  workspace_root : String,
  request : MoonflowAdapterRequest,
  contract : AdapterOperationContract,
) -> Result[AdapterOperationReceipt?, AdapterRuntimeIssue] {
  let (input_ref, input_path, input_text) = match
    input_artifact(workspace_root, request) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  match request.operation {
    "simulation.robot-mission" => {
      let input = match decode_run_request(input_path, input_text) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      if all_exist(workspace_root, session_artifact_refs(input.session_id)) {
        match
          simulation_receipt_from_session(
            workspace_root, request, contract, input_ref, input,
          ) {
          Ok(receipt) => Ok(Some(receipt))
          Err(error) => Err(error)
        }
      } else {
        Ok(None)
      }
    }
    "simulation.mission-result.inspect" => {
      let input = match decode_result_ref(input_path, input_text) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      let output_ref = inspection_ref(input.session_id, request.attempt_id)
      if @fsx.path_exists(
          match resolve_ref(workspace_root, output_ref) {
            Ok(value) => value
            Err(error) => return Err(error)
          },
        ) {
        execute_inspection(workspace_root, request, contract).map(receipt => {
          Some(receipt)
        })
      } else {
        Ok(None)
      }
    }
    _ => Ok(None)
  }
}

///|
pub fn reconcile(
  workspace_root : String,
  request : MoonflowAdapterRequest,
) -> Result[AdapterReconciliationReport, AdapterRuntimeIssue] {
  let issues = request.quality_issues()
  if !issues.is_empty() {
    return Err(
      issue("invalid-adapter-request", request.operation, issues.join("; ")),
    )
  }
  let observed_input_digest = match
    input_artifact_set_digest(workspace_root, request.input_artifacts) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  if observed_input_digest != request.input_digest {
    return Err(
      issue(
        "input-digest-mismatch",
        request.input_artifacts[0],
        "MoonFlow input_digest does not match the ordered input artifact set",
      ),
    )
  }
  match existing_result(workspace_root, request) {
    Ok(Some(result)) if result.status != "unknown" =>
      return persist_reconciliation(
        workspace_root,
        request,
        reconciliation_report(
          request,
          "terminal-recorded",
          false,
          result.output_artifacts,
          result,
          "The exact MoonMoon attempt already has a terminal result.",
        ),
      )
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  match persisted_operation_receipt(workspace_root, request) {
    Ok(Some(receipt)) => {
      let result = match persist_terminal(workspace_root, request, receipt) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      return persist_reconciliation(
        workspace_root,
        request,
        reconciliation_report(
          request,
          "recovered-terminal",
          false,
          result.output_artifacts,
          result,
          "Reconciliation recovered the terminal result from its operation receipt.",
        ),
      )
    }
    Ok(None) => ()
    Err(error) => return Err(error)
  }
  let contract = match find_operation_contract(request.operation) {
    Some(value) => value
    None =>
      return Err(
        issue(
          "unsupported-operation",
          request.operation,
          "MoonMoon adapter operation is not declared",
        ),
      )
  }
  match recover_operation_receipt(workspace_root, request, contract) {
    Err(error) => return Err(error)
    Ok(Some(receipt)) => {
      let result = match persist_terminal(workspace_root, request, receipt) {
        Ok(value) => value
        Err(error) => return Err(error)
      }
      return persist_reconciliation(
        workspace_root,
        request,
        reconciliation_report(
          request,
          "recovered-succeeded",
          false,
          result.output_artifacts,
          result,
          "Reconciliation proved the exact operation from product-owned session evidence.",
        ),
      )
    }
    Ok(None) => ()
  }
  let partial = match input_artifact(workspace_root, request) {
    Ok((_, path, text)) =>
      if request.operation == "simulation.robot-mission" {
        match decode_run_request(path, text) {
          Ok(input) =>
            any_exist(workspace_root, session_artifact_refs(input.session_id))
          Err(_) => false
        }
      } else {
        false
      }
    Err(_) => false
  }
  if partial {
    let result = unknown_result(request)
    let result_path = match
      resolve_ref(workspace_root, adapter_result_ref(request.attempt_id)) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    match write_json(result_path, result.to_json()) {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
    return persist_reconciliation(
      workspace_root,
      request,
      reconciliation_report(
        request,
        "unknown",
        false,
        [],
        result,
        "Partial session evidence exists without a complete replay/provenance chain; preserve it for operator investigation.",
      ),
    )
  }
  let receipt = operation_failure_receipt(
    request,
    contract,
    issue(
      "reconciled-not-applied",
      request.operation,
      "no product-owned effect or receipt exists for this exact attempt",
    ),
  )
  let result = match persist_terminal(workspace_root, request, receipt) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  persist_reconciliation(
    workspace_root,
    request,
    reconciliation_report(
      request,
      "not-applied",
      true,
      result.output_artifacts,
      result,
      "Reconciliation proved that this attempt was not applied; MoonFlow may create a new attempt under review.",
    ),
  )
}
