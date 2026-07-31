///|
pub fn readiness(workspace_root : String) -> AdapterReadiness {
  let healthy = !workspace_root.trim().is_empty()
  let blockers = if healthy { [] } else { ["host workspace root is missing"] }
  {
    contract_id: "moonmoon.adapter-readiness.v1",
    adapter_id: adapter_id(),
    healthy,
    physical_effects_exposed: false,
    operations: operation_contracts().map(contract => {
      operation_id: contract.operation_id,
      ready: healthy,
      status: if healthy {
        "ready"
      } else {
        "blocked"
      },
      authority_class: contract.authority_class,
      next_route: "moon run cmd/moonflow_adapter -- invoke",
      blockers,
    }),
    message: if healthy {
      "MoonMoon can execute deterministic digital simulations and inspect persisted mission evidence. It cannot inspect physical readiness or submit robot commands."
    } else {
      "MoonMoon adapter is blocked until the host supplies a workspace root."
    },
  }
}

///|
fn safe_health_suffix(value : String) -> String {
  value
  .replace(old=":", new="-")
  .replace(old="/", new="-")
  .replace(old=" ", new="-")
}

///|
pub fn health_attestation(
  workspace_root : String,
  checked_at : String,
  valid_until : String,
) -> Result[AdapterHealthAttestation, AdapterRuntimeIssue] {
  if checked_at.trim().is_empty() ||
    valid_until.trim().is_empty() ||
    checked_at >= valid_until {
    return Err(
      issue(
        "invalid-health-window", checked_at, "health attestation requires an increasing, host-generated UTC validity window",
      ),
    )
  }
  let report = readiness(workspace_root)
  let operations = if report.healthy { operation_refs() } else { [] }
  let evidence_ref = ".moonsuite/products/moonmoon/adapter-health/\{adapter_id()}-\{safe_health_suffix(checked_at)}.json"
  let evidence_path = match resolve_ref(workspace_root, evidence_ref) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let evidence : Json = {
    "contract_id": "moonmoon.adapter-health-evidence.v1",
    "adapter_id": adapter_id(),
    "pack_version": pack_version(),
    "protocol": adapter_protocol(),
    "checked_at": checked_at,
    "valid_until": valid_until,
    "operation_refs": operations,
    "capability": moonflow_adapter_capability_json_with_health(report.healthy),
    "readiness": report,
    "physical_effects_exposed": false,
  }
  let evidence_text = evidence.stringify(indent=2) + "\n"
  match write_text(evidence_path, evidence_text) {
    Ok(_) => ()
    Err(error) => return Err(error)
  }
  Ok({
    contract_id: "moonflow.adapter-health.v1",
    adapter_id: adapter_id(),
    product_id: "moonmoon",
    pack_id: "moonmoon",
    pack_version: pack_version(),
    protocol: adapter_protocol(),
    status: if report.healthy && !operations.is_empty() {
      "healthy"
    } else {
      "unhealthy"
    },
    checked_at,
    valid_until,
    operation_refs: operations,
    evidence_ref,
    evidence_digest: sha256_text(evidence_text),
  })
}

///|
pub fn capability_source_bundle(
  pack_manifest : Json,
  workspace_root : String,
  compiled_at : String,
  valid_until : String,
) -> Result[Json, AdapterRuntimeIssue] {
  let health = match
    health_attestation(workspace_root, compiled_at, valid_until) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({
    "contract_id": "moonflow.capability-source-bundle.v1",
    "catalog_id": "moonmoon-\{safe_health_suffix(compiled_at)}",
    "compiled_at": compiled_at,
    "pack_manifests": [pack_manifest],
    "adapter_declarations": [adapter_declaration_json()],
    "health_attestations": [health],
  })
}
