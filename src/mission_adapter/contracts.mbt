///|
pub(all) struct AdapterOperationContract {
  operation_id : String
  version : String
  authority_class : String
  input_contracts : Array[String]
  output_contracts : Array[String]
  claim_ceiling : String
  idempotent : Bool
  review_required : Bool
  physical_execution_allowed : Bool
  evidence_outputs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonflowAdapterRequest {
  request_id : String
  run_id : String
  book_id : String
  work_item_id : String
  declaration_id : String
  attempt_id : String
  idempotency_key : String
  product_id : String
  operation : String
  requested_authority : String
  acceptance_criteria : Array[String]
  input_contracts : Array[String]
  output_contracts : Array[String]
  required_claim : String
  input_digest : String
  input_artifacts : Array[String]
  timeout_ms : Int
  created_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonflowAdapterResult {
  result_id : String
  request_id : String
  attempt_id : String
  idempotency_key : String
  product_id : String
  external_job_id : String
  status : String
  output_digest : String
  output_artifacts : Array[String]
  error_kind : String
  compensable : Bool
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterAttemptRecord {
  contract_id : String
  adapter_id : String
  request_id : String
  attempt_id : String
  idempotency_key : String
  operation : String
  status : String
  request_ref : String
  operation_receipt_ref : String
  adapter_result_ref : String
  started_at : String
  updated_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterOperationReceipt {
  contract_id : String
  adapter_id : String
  operation_id : String
  operation_version : String
  request_id : String
  attempt_id : String
  idempotency_key : String
  status : String
  authority_class : String
  physical_execution_performed : Bool
  input_digest : String
  observed_input_digests : Array[String]
  evidence_refs : Array[String]
  output_contract : String
  output : Json
  error_kind : String
  message : String
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterReconciliationReport {
  contract_id : String
  adapter_id : String
  request_id : String
  attempt_id : String
  decision : String
  retry_allowed : Bool
  evidence_refs : Array[String]
  result : MoonflowAdapterResult
  message : String
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterOperationReadiness {
  operation_id : String
  ready : Bool
  status : String
  authority_class : String
  next_route : String
  blockers : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterReadiness {
  contract_id : String
  adapter_id : String
  healthy : Bool
  physical_effects_exposed : Bool
  operations : Array[AdapterOperationReadiness]
  message : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterHealthAttestation {
  contract_id : String
  adapter_id : String
  product_id : String
  pack_id : String
  pack_version : String
  protocol : String
  status : String
  checked_at : String
  valid_until : String
  operation_refs : Array[String]
  evidence_ref : String
  evidence_digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ExternalDatasetEvidence {
  dataset_id : String
  evidence_ref : String
  license_class : String
  status : String
  digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RobotMissionRunRequest {
  contract_id : String
  session_id : String
  moonrobo_integration_receipt_ref : String
  mission_design_ref : String
  dataset_evidence : Array[ExternalDatasetEvidence]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionResultRef {
  contract_id : String
  session_id : String
  result_ref : String
  provenance_ref : String
  replay_receipt_ref : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MoonroboDigitalIntegrationReceipt {
  contract_id : String
  adapter_id : String
  operation_id : String
  request_id : String
  attempt_id : String
  idempotency_key : String
  status : String
  physical_execution_performed : Bool
  evidence_refs : Array[String]
  output : Json
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionReplayReceipt {
  contract_id : String
  session_id : String
  design_id : String
  scenario_id : String
  seed : Int
  required_replays : Int
  completed_replays : Int
  byte_equivalent : Bool
  first_result_ref : String
  replay_result_ref : String
  first_result_digest : String
  replay_result_digest : String
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionProvenanceRecord {
  contract_id : String
  session_id : String
  moonrobo_integration_receipt_ref : String
  mission_design_ref : String
  terrain_ref : String
  result_ref : String
  replay_receipt_ref : String
  source_refs : Array[String]
  source_digests : Array[String]
  dataset_evidence : Array[ExternalDatasetEvidence]
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionUncertaintySummary {
  maximum_modeled_fraction : Double
  modeled_fault_count : Int
  calibration_claim : String
  external_dataset_coverage : String
  route_coverage : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MissionEvaluationReport {
  contract_id : String
  session_id : String
  design_id : String
  revision : String
  scenario_id : String
  seed : Int
  decision : String
  result_ref : String
  provenance_ref : String
  replay_receipt_ref : String
  replay_verified : Bool
  result_claim : String
  claim_ceiling : String
  physical_readiness : Bool
  uncertainty : MissionUncertaintySummary
  blockers : Array[String]
  limitations : Array[String]
  review_required : Bool
  recorded_at : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AdapterRuntimeIssue {
  code : String
  path : String
  message : String
} derive(Debug, Eq, ToJson, FromJson)
