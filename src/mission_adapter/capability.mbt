///|
pub fn adapter_id() -> String {
  "moonmoon-local-v1"
}

///|
pub fn adapter_protocol() -> String {
  "moonflow.adapter.v2"
}

///|
pub fn pack_version() -> String {
  "0.1.0"
}

///|
pub fn operation_contracts() -> Array[AdapterOperationContract] {
  [
    {
      operation_id: "simulation.robot-mission",
      version: "0.1.0",
      authority_class: "sandbox-execution",
      input_contracts: ["moonmoon/robot-mission-run-request@1.0.0"],
      output_contracts: ["moonmoon/mission-simulation-receipt@1.0.0"],
      claim_ceiling: "calibrated-digital-twin",
      idempotent: true,
      review_required: true,
      physical_execution_allowed: false,
      evidence_outputs: [
        ".moonsuite/products/moonmoon/mission-sessions", ".moonsuite/products/moonmoon/adapter-attempts",
      ],
    },
    {
      operation_id: "simulation.mission-result.inspect",
      version: "0.1.0",
      authority_class: "observe",
      input_contracts: ["moonmoon/mission-result-ref@1.0.0"],
      output_contracts: ["moonmoon/mission-inspection-receipt@1.0.0"],
      claim_ceiling: "simulation-evidence",
      idempotent: true,
      review_required: true,
      physical_execution_allowed: false,
      evidence_outputs: [
        ".moonsuite/products/moonmoon/mission-sessions", ".moonsuite/products/moonmoon/adapter-attempts",
      ],
    },
  ]
}

///|
pub fn find_operation_contract(
  operation_id : String,
) -> AdapterOperationContract? {
  for contract in operation_contracts() {
    if contract.operation_id == operation_id {
      return Some(contract)
    }
  }
  None
}

///|
fn output_artifact_contract_id(contract : AdapterOperationContract) -> String {
  match contract.operation_id {
    "simulation.robot-mission" => "moonmoon.mission-simulation-receipt.v1"
    "simulation.mission-result.inspect" =>
      "moonmoon.mission-inspection-receipt.v1"
    _ => "moonmoon.unsupported-operation-receipt.v1"
  }
}

///|
fn unique_strings(values : Array[String]) -> Array[String] {
  let output : Array[String] = []
  for value in values {
    if !output.contains(value) {
      output.push(value)
    }
  }
  output
}

///|
fn capability_authorities() -> Array[String] {
  unique_strings(
    operation_contracts().map(contract => contract.authority_class),
  )
}

///|
fn capability_input_contracts() -> Array[String] {
  let values : Array[String] = []
  for contract in operation_contracts() {
    values.append(contract.input_contracts)
  }
  unique_strings(values)
}

///|
fn capability_output_contracts() -> Array[String] {
  let values : Array[String] = ["moonflow.adapter-result.v1"]
  for contract in operation_contracts() {
    values.append(contract.output_contracts)
  }
  unique_strings(values)
}

///|
pub fn moonflow_adapter_capability_json_with_health(healthy : Bool) -> Json {
  {
    "adapter_id": adapter_id(),
    "product_id": "moonmoon",
    "protocol": adapter_protocol(),
    "operations": operation_contracts().map(contract => contract.operation_id),
    "authority_classes": capability_authorities(),
    "input_contracts": capability_input_contracts(),
    "output_contracts": capability_output_contracts(),
    "claim_ceiling": "calibrated-digital-twin",
    "healthy": healthy,
    "supports_cancel": false,
    "supports_reconcile": true,
    "physical_deployment_claim_forbidden": true,
    "correct_refusal_is_success": true,
  }
}

///|
pub fn moonflow_adapter_capability_json() -> Json {
  moonflow_adapter_capability_json_with_health(true)
}

///|
pub fn operation_refs() -> Array[String] {
  operation_contracts().map(contract => {
    "moonmoon/\{contract.operation_id}@\{pack_version()}"
  })
}

///|
pub fn adapter_declaration_json() -> Json {
  {
    "contract_id": "moonflow.adapter-declaration.v1",
    "adapter_id": adapter_id(),
    "product_id": "moonmoon",
    "pack_id": "moonmoon",
    "pack_version": pack_version(),
    "protocol": adapter_protocol(),
    "operations": operation_contracts().map(contract => {
      let operation : Json = {
        "operation_id": contract.operation_id,
        "claim_ceiling": contract.claim_ceiling,
        "supports_cancel": false,
        "supports_reconcile": true,
      }
      operation
    }),
  }
}

///|
fn safe_identity(value : String) -> Bool {
  !value.trim().is_empty() &&
  !value.contains("/") &&
  !value.contains("\\") &&
  value != "." &&
  value != ".."
}

///|
fn add_required_issue(
  issues : Array[String],
  name : String,
  value : String,
) -> Unit {
  if value.trim().is_empty() {
    issues.push("\{name} is required")
  }
}

///|
fn claim_rank(value : String) -> Int? {
  match value {
    "" => Some(0)
    "observation" => Some(0)
    "research-evidence" => Some(1)
    "execution-result" => Some(2)
    "accepted-knowledge" => Some(3)
    "digital-artifact" => Some(4)
    "simulation-evidence" => Some(5)
    "scenario-qualified" => Some(6)
    "calibrated-digital-twin" => Some(7)
    _ => None
  }
}

///|
pub fn MoonflowAdapterRequest::quality_issues(
  self : MoonflowAdapterRequest,
) -> Array[String] {
  let issues : Array[String] = []
  add_required_issue(issues, "request_id", self.request_id)
  add_required_issue(issues, "run_id", self.run_id)
  add_required_issue(issues, "book_id", self.book_id)
  add_required_issue(issues, "work_item_id", self.work_item_id)
  add_required_issue(issues, "declaration_id", self.declaration_id)
  add_required_issue(issues, "attempt_id", self.attempt_id)
  add_required_issue(issues, "idempotency_key", self.idempotency_key)
  add_required_issue(issues, "operation", self.operation)
  add_required_issue(issues, "input_digest", self.input_digest)
  add_required_issue(issues, "created_at", self.created_at)
  if self.product_id != "moonmoon" {
    issues.push("product_id must be moonmoon")
  }
  if !self.declaration_id.trim().is_empty() &&
    !safe_identity(self.declaration_id) {
    issues.push("declaration_id must be a safe graph declaration identifier")
  }
  if !safe_identity(self.attempt_id) {
    issues.push("attempt_id must be a safe path component")
  }
  if self.timeout_ms <= 0 {
    issues.push("timeout_ms must be positive")
  }
  if self.input_artifacts.is_empty() {
    issues.push("a safe typed primary input artifact is required")
  } else if self.input_artifacts.any(reference => !safe_relative_ref(reference)) {
    issues.push(
      "all input artifacts must be safe workspace-relative references",
    )
  }
  match find_operation_contract(self.operation) {
    None => issues.push("operation is not exposed by the MoonMoon adapter")
    Some(contract) => {
      if self.requested_authority != contract.authority_class {
        issues.push("requested_authority does not match the operation contract")
      }
      for expected in contract.input_contracts {
        if !self.input_contracts.contains(expected) {
          issues.push("missing input contract: \{expected}")
        }
      }
      for expected in contract.output_contracts {
        if !self.output_contracts.contains(expected) {
          issues.push("missing output contract: \{expected}")
        }
      }
      match
        (claim_rank(self.required_claim), claim_rank(contract.claim_ceiling)) {
        (Some(required), Some(ceiling)) if required > ceiling =>
          issues.push("required_claim exceeds the operation claim ceiling")
        (None, _) =>
          issues.push("required_claim is not a supported claim class")
        _ => ()
      }
    }
  }
  issues
}

///|
pub fn same_attempt_identity(
  request : MoonflowAdapterRequest,
  result : MoonflowAdapterResult,
) -> Bool {
  request.request_id == result.request_id &&
  request.attempt_id == result.attempt_id &&
  request.idempotency_key == result.idempotency_key &&
  result.product_id == "moonmoon"
}
